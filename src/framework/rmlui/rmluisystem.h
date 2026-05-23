#ifndef RMLUISYSTEM_H
#define RMLUISYSTEM_H

#include <RmlUi/Core/SystemInterface.h>

class RmlUiSystemInterface : public Rml::SystemInterface {
public:
    double GetElapsedTime() override;
    bool LogMessage(Rml::Log::Type type, const Rml::String& message) override;
    void JoinPath(Rml::String& translated_path, const Rml::String& document_path,
        const Rml::String& path) override;
    void SetMouseCursor(const Rml::String& cursor_name) override;
    void SetClipboardText(const Rml::String& text) override;
    void GetClipboardText(Rml::String& text) override;
};

#endif
