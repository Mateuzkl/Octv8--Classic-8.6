#include "rmluimanager.h"
#include "rmluirenderer.h"
#include "rmluisystem.h"
#include "rmluifileinterface.h"
#include <framework/global.h>
#include <framework/core/logger.h>
#include <framework/core/eventdispatcher.h>
#include <framework/luaengine/luainterface.h>
#include <framework/stdext/string.h>
#include <RmlUi/Core.h>
#include <RmlUi/Debugger.h>
#include <physfs.h>
#include <algorithm>
#include <filesystem>

RmlUiManager g_rmlui;

LuaEventListener::LuaEventListener(Rml::Element* element, const std::string& eventName, const std::string& code) :
    m_element(element),
    m_document(element ? element->GetOwnerDocument() : nullptr),
    m_eventName(eventName),
    m_code(code)
{
}

void LuaEventListener::ProcessEvent(Rml::Event& event)
{
    std::string code = m_code;
    g_dispatcher.addEvent([code]() {
        try {
            g_lua.evaluateExpression(code);
        } catch (std::exception& e) {
            g_logger.error(stdext::format("[RmlUi] Event error: %s", e.what()));
        }
    });
}

void LuaEventListener::detach()
{
    if (m_element) {
        m_element->RemoveEventListener(m_eventName, this);
        m_element = nullptr;
    }
}

void RmlUiManager::init()
{
    if (m_initialized) return;

    m_renderInterface = new RmlUiRenderInterface();
    m_systemInterface = new RmlUiSystemInterface();

    Rml::SetRenderInterface(m_renderInterface);
    Rml::SetSystemInterface(m_systemInterface);
    Rml::SetFileInterface(new RmlUiFileInterface());

    Rml::Initialise();

    m_initialized = true;
    g_logger.info("[RmlUi] Initialized");
}

void RmlUiManager::terminate()
{
    if (!m_initialized) return;

    for (auto* listener : m_listeners) {
        listener->detach();
        delete listener;
    }
    m_listeners.clear();

    {
        std::lock_guard<std::mutex> lock(m_contextsMutex);
        for (auto& pair : m_contexts) {
            Rml::RemoveContext(pair.first);
        }
        m_contexts.clear();
        m_mainContext = nullptr;
    }

    Rml::Shutdown();

    delete m_systemInterface;
    m_systemInterface = nullptr;

    delete m_renderInterface;
    m_renderInterface = nullptr;

    m_initialized = false;
    g_logger.info("[RmlUi] Terminated");
}

void RmlUiManager::update()
{
    if (!m_initialized) return;

    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second)
            pair.second->Update();
    }

    for (auto it = m_contexts.begin(); it != m_contexts.end();) {
        Rml::Context* context = it->second;
        if (!context || (context != m_mainContext && context->GetNumDocuments() == 0)) {
            if (context)
                Rml::RemoveContext(it->first);
            it = m_contexts.erase(it);
        } else {
            ++it;
        }
    }
}

void RmlUiManager::render()
{
    if (!m_initialized) return;

    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second)
            pair.second->Render();
    }
}

void RmlUiManager::resize(int width, int height)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second)
            pair.second->SetDimensions(Rml::Vector2i(width, height));
    }
}

Rml::Context* RmlUiManager::getMainContext()
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    return m_mainContext;
}

Rml::Context* RmlUiManager::getContext(const std::string& name)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    if (name.empty())
        return m_mainContext;

    auto it = m_contexts.find(name);
    return it != m_contexts.end() ? it->second : nullptr;
}

Rml::Context* RmlUiManager::createContext(const std::string& name, int width, int height)
{
    if (!m_initialized) return nullptr;

    std::lock_guard<std::mutex> lock(m_contextsMutex);
    Rml::Context* ctx = Rml::CreateContext(name, Rml::Vector2i(width, height));
    if (ctx) {
        m_contexts[name] = ctx;
        if (!m_mainContext)
            m_mainContext = ctx;
    }
    return ctx;
}

void RmlUiManager::removeContext(const std::string& name)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    if (m_mainContext && m_mainContext->GetName() == name)
        m_mainContext = nullptr;
    Rml::RemoveContext(name);
    m_contexts.erase(name);
}

Rml::ElementDocument* RmlUiManager::loadDocument(const std::string& path, Rml::Context* context)
{
    if (!m_initialized) return nullptr;

    Rml::Context* ctx = context ? context : getMainContext();
    if (!ctx) return nullptr;

    std::string resolvedPath = path;
    if (!stdext::starts_with(path, "/") && !stdext::starts_with(path, "\\"))
        resolvedPath = "/" + g_lua.getCurrentSourcePath() + "/" + path;
    stdext::replace_all(resolvedPath, "//", "/");
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    auto doc = ctx->LoadDocument(resolvedPath);
    if (doc) {
        doc->Show();
        g_logger.info(stdext::format("[RmlUi] Loaded document: %s", resolvedPath));
    } else {
        g_logger.error(stdext::format("[RmlUi] Failed to load document: %s", resolvedPath));
    }
    return doc;
}

Rml::ElementDocument* RmlUiManager::loadDocumentFromString(const std::string& rml, Rml::Context* context)
{
    if (!m_initialized) return nullptr;

    Rml::Context* ctx = context ? context : getMainContext();
    if (!ctx) return nullptr;

    std::lock_guard<std::mutex> lock(m_contextsMutex);
    auto doc = ctx->LoadDocumentFromMemory(rml, "memory.rml");
    if (doc) {
        doc->Show();
    }
    return doc;
}

void RmlUiManager::closeDocument(Rml::ElementDocument* doc)
{
    if (!doc) return;

    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto it = m_listeners.begin(); it != m_listeners.end();) {
        auto* listener = *it;
        if (listener->getDocument() == doc) {
            listener->detach();
            delete listener;
            it = m_listeners.erase(it);
        } else {
            ++it;
        }
    }

    doc->Close();
}

void RmlUiManager::addEventListener(uintptr_t elemPtr, const std::string& event, const std::string& luaCode)
{
    auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
    if (!elem) return;
    auto* listener = new LuaEventListener(elem, event, luaCode);
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    m_listeners.push_back(listener);
    elem->AddEventListener(event, listener);
}

bool RmlUiManager::loadFontFace(const std::string& path)
{
    const char* realDir = PHYSFS_getRealDir(path.c_str());
    if (realDir) {
        std::string cleanPath = path;
        if (!cleanPath.empty() && (cleanPath[0] == '/' || cleanPath[0] == '\\'))
            cleanPath = cleanPath.substr(1);
        std::filesystem::path realPath = std::filesystem::path(realDir) / std::filesystem::path(cleanPath);
        realPath.make_preferred();
        return Rml::LoadFontFace(realPath.string());
    }

    g_logger.warning(stdext::format("[RmlUi] Font not found in PhysicsFS: %s", path));
    return Rml::LoadFontFace(path);
}

bool RmlUiManager::processKeyDown(Rml::Input::KeyIdentifier key, int modifiers)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessKeyDown(key, modifiers))
            return false;
    }
    return true;
}

bool RmlUiManager::processKeyUp(Rml::Input::KeyIdentifier key, int modifiers)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessKeyUp(key, modifiers))
            return false;
    }
    return true;
}

bool RmlUiManager::processTextInput(Rml::Character c)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessTextInput(c))
            return false;
    }
    return true;
}

bool RmlUiManager::processTextInput(const std::string& text)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessTextInput(text))
            return false;
    }
    return true;
}

bool RmlUiManager::processMouseMove(int x, int y, int modifiers)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessMouseMove(x, y, modifiers))
            return false;
    }
    return true;
}

bool RmlUiManager::processMouseButtonDown(int button, int modifiers)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessMouseButtonDown(button, modifiers))
            return false;
    }
    return true;
}

bool RmlUiManager::processMouseButtonUp(int button, int modifiers)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessMouseButtonUp(button, modifiers))
            return false;
    }
    return true;
}

bool RmlUiManager::processMouseWheel(float delta, int modifiers)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    for (auto& pair : m_contexts) {
        if (pair.second && !pair.second->ProcessMouseWheel(delta, modifiers))
            return false;
    }
    return true;
}

bool RmlUiManager::createDataModel(const std::string& contextName, const std::string& modelName)
{
    std::lock_guard<std::mutex> lock(m_contextsMutex);
    Rml::Context* ctx = m_mainContext;
    if (!contextName.empty()) {
        auto it = m_contexts.find(contextName);
        ctx = it != m_contexts.end() ? it->second : nullptr;
    }
    if (!ctx) return false;

    Rml::DataModelConstructor constructor = ctx->CreateDataModel(modelName);
    if (!constructor) return false;

    const std::string modelKey = buildDataModelKey(contextName, modelName);
    m_dataModels[modelKey] = constructor.GetModelHandle();
    m_dataModelContexts[modelKey] = ctx;
    return true;
}

void RmlUiManager::setModelVar(const std::string& modelName, const std::string& varName,
    const Rml::Variant& value)
{
    const std::string modelKey = resolveDataModelKey(modelName);
    std::string key = modelKey + "." + varName;
    m_dataVars[key] = value;

    auto modelIt = m_dataModels.find(modelKey);
    if (modelIt != m_dataModels.end()) {
        modelIt->second.DirtyVariable(varName);
    }
}

Rml::Variant RmlUiManager::getModelVar(const std::string& modelName, const std::string& varName)
{
    const std::string modelKey = resolveDataModelKey(modelName);
    std::string key = modelKey + "." + varName;
    auto it = m_dataVars.find(key);
    if (it != m_dataVars.end())
        return it->second;
    return Rml::Variant();
}

void RmlUiManager::dirtyModelVar(const std::string& modelName, const std::string& varName)
{
    const std::string modelKey = resolveDataModelKey(modelName);
    auto modelIt = m_dataModels.find(modelKey);
    if (modelIt != m_dataModels.end()) {
        modelIt->second.DirtyVariable(varName);
    }
}

std::string RmlUiManager::buildDataModelKey(const std::string& contextName, const std::string& modelName) const
{
    std::string contextKey = contextName.empty() ? "main" : contextName;
    return contextKey + ":" + modelName;
}

std::string RmlUiManager::resolveDataModelKey(const std::string& modelName) const
{
    if (m_dataModels.find(modelName) != m_dataModels.end())
        return modelName;

    const std::string suffix = ":" + modelName;
    std::string foundKey;
    for (const auto& pair : m_dataModels) {
        if (pair.first.size() >= suffix.size() &&
            pair.first.compare(pair.first.size() - suffix.size(), suffix.size(), suffix) == 0) {
            if (!foundKey.empty())
                return buildDataModelKey("", modelName);
            foundKey = pair.first;
        }
    }

    return foundKey.empty() ? buildDataModelKey("", modelName) : foundKey;
}
