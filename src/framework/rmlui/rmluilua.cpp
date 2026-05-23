#include <framework/luaengine/luainterface.h>
#include <framework/core/logger.h>
#include <framework/core/resourcemanager.h>
#include <framework/stdext/string.h>
#include "rmluimanager.h"
#include <RmlUi/Core.h>
#include <RmlUi/Debugger.h>

static void pushModelVarsFromLuaTable(Rml::DataModelConstructor& constructor,
    const std::string& modelName, int tableIdx)
{
    g_lua.pushNil();
    while (g_lua.next(tableIdx < 0 ? tableIdx - 1 : tableIdx)) {
        std::string varName = g_lua.toString(-2);

        std::string key = modelName + "." + varName;
        if (g_lua.isNumber(-1)) {
            double v = g_lua.toNumber(-1);
            g_rmlui.m_dataVars[key] = Rml::Variant((int)v);
            g_lua.pop(1);
        } else if (g_lua.isString(-1)) {
            std::string v = g_lua.toString(-1);
            g_rmlui.m_dataVars[key] = Rml::Variant(v.c_str());
            g_lua.pop(1);
        } else {
            g_lua.pop(1);
        }
        constructor.BindFunc(varName,
            [key](Rml::Variant& out) {
                auto it = g_rmlui.m_dataVars.find(key);
                if (it != g_rmlui.m_dataVars.end()) out = it->second;
            },
            [key](const Rml::Variant& v) {
                g_rmlui.m_dataVars[key] = v;
            }
        );
    }
}

void registerRmlUiLuaFunctions()
{
    g_lua.registerSingletonClass("g_rmlui");
    g_lua.bindSingletonFunction("g_rmlui", "init", &RmlUiManager::init, &g_rmlui);
    g_lua.bindSingletonFunction("g_rmlui", "terminate", &RmlUiManager::terminate, &g_rmlui);
    g_lua.bindSingletonFunction("g_rmlui", "update", &RmlUiManager::update, &g_rmlui);
    g_lua.bindSingletonFunction("g_rmlui", "render", &RmlUiManager::render, &g_rmlui);
    g_lua.bindSingletonFunction("g_rmlui", "resize", &RmlUiManager::resize, &g_rmlui);

    g_lua.bindSingletonFunction("g_rmlui", "createContext", [](const std::string& name, int w, int h) {
        auto* ctx = g_rmlui.createContext(name, w, h);
        return ctx ? name : "";
    });

    g_lua.bindSingletonFunction("g_rmlui", "removeContext", &RmlUiManager::removeContext, &g_rmlui);

    g_lua.bindSingletonFunction("g_rmlui", "loadFontFace", &RmlUiManager::loadFontFace, &g_rmlui);

    g_lua.bindSingletonFunction("g_rmlui", "loadDocument", [](const std::string& path, const std::string& contextName) {
        Rml::Context* ctx = contextName.empty() ? g_rmlui.getMainContext() : g_rmlui.m_contexts[contextName];
        auto* doc = g_rmlui.loadDocument(path, ctx);
        return reinterpret_cast<uintptr_t>(doc);
    });

    g_lua.bindSingletonFunction("g_rmlui", "closeDocument", [](uintptr_t docPtr) {
        auto* doc = reinterpret_cast<Rml::ElementDocument*>(docPtr);
        g_rmlui.closeDocument(doc);
    });

    g_lua.bindSingletonFunction("g_rmlui", "setProperty", [](uintptr_t elemPtr, const std::string& name, const std::string& value) {
        auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
        if (elem) elem->SetProperty(name, value);
    });

    g_lua.bindSingletonFunction("g_rmlui", "getProperty", [](uintptr_t elemPtr, const std::string& name) -> std::string {
        auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
        if (elem) return elem->GetProperty<Rml::String>(name);
        return "";
    });

    g_lua.bindSingletonFunction("g_rmlui", "getElementById", [](uintptr_t docPtr, const std::string& id) -> uintptr_t {
        auto* doc = reinterpret_cast<Rml::ElementDocument*>(docPtr);
        if (doc) return reinterpret_cast<uintptr_t>(doc->GetElementById(id));
        return 0;
    });

    g_lua.bindSingletonFunction("g_rmlui", "setInnerRML", [](uintptr_t elemPtr, const std::string& rml) {
        auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
        if (elem) elem->SetInnerRML(rml);
    });

    g_lua.bindSingletonFunction("g_rmlui", "getInnerRML", [](uintptr_t elemPtr) -> std::string {
        auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
        return elem ? elem->GetInnerRML() : "";
    });

    g_lua.bindSingletonFunction("g_rmlui", "setAttribute", [](uintptr_t elemPtr, const std::string& name, const std::string& value) {
        auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
        if (elem) elem->SetAttribute(name, value);
    });

    g_lua.bindSingletonFunction("g_rmlui", "getAttribute", [](uintptr_t elemPtr, const std::string& name) -> std::string {
        auto* elem = reinterpret_cast<Rml::Element*>(elemPtr);
        if (elem) return elem->GetAttribute<Rml::String>(name, "");
        return "";
    });

    g_lua.bindSingletonFunction("g_rmlui", "addEventListener", [](uintptr_t elemPtr, const std::string& event, const std::string& luaCode) {
        g_rmlui.addEventListener(elemPtr, event, luaCode);
    });

    g_lua.bindSingletonFunction("g_rmlui", "debugger", [](bool visible) {
        Rml::Debugger::SetVisible(visible);
    });

    g_lua.bindSingletonFunction("g_rmlui", "createDataModel", [](const std::string& ctxName, const std::string& modelName) -> bool {
        Rml::Context* ctx = ctxName.empty() ? g_rmlui.getMainContext() : g_rmlui.m_contexts[ctxName];
        if (!ctx) return false;

        Rml::DataModelConstructor constructor = ctx->CreateDataModel(modelName);
        if (!constructor) return false;

        g_rmlui.m_dataModels[modelName] = constructor.GetModelHandle();
        g_rmlui.m_dataModelContexts[modelName] = ctx;

        if (g_lua.getTop() >= 3 && g_lua.isTable(3)) {
            pushModelVarsFromLuaTable(constructor, modelName, 3);
        }

        return true;
    });

    g_lua.bindSingletonFunction("g_rmlui", "setModelVar", [](const std::string& model, const std::string& var, const std::string& value) {
        int n = std::atoi(value.c_str());
        if (n != 0 || value == "0")
            g_rmlui.setModelVar(model, var, Rml::Variant(n));
        else
            g_rmlui.setModelVar(model, var, Rml::Variant(value.c_str()));
    });

    g_lua.bindSingletonFunction("g_rmlui", "getModelVar", [](const std::string& model, const std::string& var) -> std::string {
        auto val = g_rmlui.getModelVar(model, var);
        if (val.GetType() == Rml::Variant::INT)
            return std::to_string(val.Get<int>());
        if (val.GetType() == Rml::Variant::STRING)
            return val.Get<Rml::String>();
        return "";
    });

    g_logger.info("[RmlUi] Lua bindings registered");
}
