#ifndef RMLUIMANAGER_H
#define RMLUIMANAGER_H

#include <RmlUi/Core/Context.h>
#include <RmlUi/Core/Element.h>
#include <RmlUi/Core/ElementDocument.h>
#include <RmlUi/Core/DataModelHandle.h>
#include <RmlUi/Core/EventListener.h>
#include <RmlUi/Core/Variant.h>
#include <string>
#include <unordered_map>
#include <memory>
#include <mutex>
#include <variant>
#include <vector>

class LuaEventListener : public Rml::EventListener {
public:
    LuaEventListener(Rml::Element* element, const std::string& eventName, const std::string& code);
    void ProcessEvent(Rml::Event& event) override;
    Rml::ElementDocument* getDocument() const { return m_document; }
    void detach();
private:
    Rml::Element* m_element;
    Rml::ElementDocument* m_document;
    std::string m_eventName;
    std::string m_code;
};

class RmlUiRenderInterface;
class RmlUiSystemInterface;
class RmlUiFileInterface;

class RmlUiManager {
public:
    void init();
    void terminate();

    void update();
    void render();

    void resize(int width, int height);

    Rml::Context* getMainContext();
    Rml::Context* getContext(const std::string& name);
    Rml::Context* createContext(const std::string& name, int width, int height);
    void removeContext(const std::string& name);

    Rml::ElementDocument* loadDocument(const std::string& path, Rml::Context* context = nullptr);
    Rml::ElementDocument* loadDocumentFromString(const std::string& rml, Rml::Context* context = nullptr);
    void closeDocument(Rml::ElementDocument* doc);

    bool processKeyDown(Rml::Input::KeyIdentifier key, int modifiers);
    bool processKeyUp(Rml::Input::KeyIdentifier key, int modifiers);
    bool processTextInput(Rml::Character c);
    bool processTextInput(const std::string& text);
    bool processMouseMove(int x, int y, int modifiers);
    bool processMouseButtonDown(int button, int modifiers);
    bool processMouseButtonUp(int button, int modifiers);
    bool processMouseWheel(float delta, int modifiers);

    bool loadFontFace(const std::string& path);

    bool createDataModel(const std::string& contextName, const std::string& modelName);
    void setModelVar(const std::string& modelName, const std::string& varName, const Rml::Variant& value);
    Rml::Variant getModelVar(const std::string& modelName, const std::string& varName);
    void dirtyModelVar(const std::string& modelName, const std::string& varName);
    std::string buildDataModelKey(const std::string& contextName, const std::string& modelName) const;
    std::string resolveDataModelKey(const std::string& modelName) const;

    void addEventListener(uintptr_t elemPtr, const std::string& event, const std::string& luaCode);

    std::unordered_map<std::string, Rml::Context*> m_contexts;
    std::unordered_map<std::string, Rml::Variant> m_dataVars;
    std::unordered_map<std::string, Rml::DataModelHandle> m_dataModels;
    std::unordered_map<std::string, Rml::Context*> m_dataModelContexts;

private:
    Rml::Context* m_mainContext = nullptr;
    RmlUiRenderInterface* m_renderInterface = nullptr;
    RmlUiSystemInterface* m_systemInterface = nullptr;
    bool m_initialized = false;
    std::vector<LuaEventListener*> m_listeners;
    mutable std::mutex m_contextsMutex;
};

extern RmlUiManager g_rmlui;

#endif
