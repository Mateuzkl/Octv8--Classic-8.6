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

RmlUiManager g_rmlui;

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

    for (auto& pair : m_contexts) {
        Rml::RemoveContext(pair.first);
    }
    m_contexts.clear();
    m_mainContext = nullptr;

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

    for (auto& pair : m_contexts) {
        pair.second->Update();
    }

    for (auto it = m_contexts.begin(); it != m_contexts.end();) {
        if (it->second->GetNumDocuments() == 0) {
            it = m_contexts.erase(it);
        } else {
            ++it;
        }
    }
}

void RmlUiManager::render()
{
    if (!m_initialized) return;

    for (auto& pair : m_contexts) {
        pair.second->Render();
    }
}

void RmlUiManager::resize(int width, int height)
{
    for (auto& pair : m_contexts) {
        pair.second->SetDimensions(Rml::Vector2i(width, height));
    }
}

Rml::Context* RmlUiManager::createContext(const std::string& name, int width, int height)
{
    if (!m_initialized) return nullptr;

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
    if (m_mainContext && m_mainContext->GetName() == name)
        m_mainContext = nullptr;
    Rml::RemoveContext(name);
    m_contexts.erase(name);
}

Rml::ElementDocument* RmlUiManager::loadDocument(const std::string& path, Rml::Context* context)
{
    if (!m_initialized) return nullptr;

    Rml::Context* ctx = context ? context : m_mainContext;
    if (!ctx) return nullptr;

    std::string resolvedPath = path;
    if (!stdext::starts_with(path, "/") && !stdext::starts_with(path, "\\"))
        resolvedPath = "/" + g_lua.getCurrentSourcePath() + "/" + path;
    stdext::replace_all(resolvedPath, "//", "/");
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

    Rml::Context* ctx = context ? context : m_mainContext;
    if (!ctx) return nullptr;

    auto doc = ctx->LoadDocumentFromMemory(rml, "memory.rml");
    if (doc) {
        doc->Show();
    }
    return doc;
}

void RmlUiManager::closeDocument(Rml::ElementDocument* doc)
{
    if (!doc) return;

    for (auto* listener : m_listeners)
        delete listener;
    m_listeners.clear();

    doc->Close();
}

void RmlUiManager::addEventListener(uintptr_t elemPtr, const std::string& event, const std::string& luaCode)
{
    auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
    if (!elem) return;
    auto* listener = new LuaEventListener(luaCode);
    m_listeners.push_back(listener);
    elem->AddEventListener(event, listener);
}

bool RmlUiManager::loadFontFace(const std::string& path)
{
    const char* realDir = PHYSFS_getRealDir(path.c_str());
    if (realDir) {
        std::string dir(realDir);
        while (!dir.empty() && (dir.back() == '/' || dir.back() == '\\'))
            dir.pop_back();
        std::string cleanPath = path;
        if (!cleanPath.empty() && (cleanPath[0] == '/' || cleanPath[0] == '\\'))
            cleanPath = cleanPath.substr(1);
        stdext::replace_all(cleanPath, "/", "\\");
        std::string realPath = dir + "\\" + cleanPath;
        return Rml::LoadFontFace(realPath);
    }

    g_logger.warning(stdext::format("[RmlUi] Font not found in PhysicsFS: %s", path));
    return Rml::LoadFontFace(path);
}

void RmlUiManager::processKeyDown(Rml::Input::KeyIdentifier key, int modifiers)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessKeyDown(key, modifiers);
}

void RmlUiManager::processKeyUp(Rml::Input::KeyIdentifier key, int modifiers)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessKeyUp(key, modifiers);
}

void RmlUiManager::processTextInput(Rml::Character c)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessTextInput(c);
}

void RmlUiManager::processTextInput(const std::string& text)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessTextInput(text);
}

void RmlUiManager::processMouseMove(int x, int y, int modifiers)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessMouseMove(x, y, modifiers);
}

void RmlUiManager::processMouseButtonDown(int button, int modifiers)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessMouseButtonDown(button, modifiers);
}

void RmlUiManager::processMouseButtonUp(int button, int modifiers)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessMouseButtonUp(button, modifiers);
}

void RmlUiManager::processMouseWheel(float delta, int modifiers)
{
    for (auto& pair : m_contexts)
        pair.second->ProcessMouseWheel(delta, modifiers);
}

bool RmlUiManager::createDataModel(const std::string& contextName, const std::string& modelName)
{
    Rml::Context* ctx = contextName.empty() ? m_mainContext : m_contexts[contextName];
    if (!ctx) return false;

    Rml::DataModelConstructor constructor = ctx->CreateDataModel(modelName);
    if (!constructor) return false;

    m_dataModels[modelName] = constructor.GetModelHandle();
    m_dataModelContexts[modelName] = ctx;
    return true;
}

void RmlUiManager::setModelVar(const std::string& modelName, const std::string& varName,
    const Rml::Variant& value)
{
    std::string key = modelName + "." + varName;
    m_dataVars[key] = value;

    auto modelIt = m_dataModels.find(modelName);
    if (modelIt != m_dataModels.end()) {
        modelIt->second.DirtyVariable(varName);
    }
}

Rml::Variant RmlUiManager::getModelVar(const std::string& modelName, const std::string& varName)
{
    std::string key = modelName + "." + varName;
    auto it = m_dataVars.find(key);
    if (it != m_dataVars.end())
        return it->second;
    return Rml::Variant();
}

void RmlUiManager::dirtyModelVar(const std::string& modelName, const std::string& varName)
{
    auto modelIt = m_dataModels.find(modelName);
    if (modelIt != m_dataModels.end()) {
        modelIt->second.DirtyVariable(varName);
    }
}
