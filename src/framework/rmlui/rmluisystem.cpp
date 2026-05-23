#include "rmluisystem.h"
#include <framework/global.h>
#include <framework/stdext/time.h>
#include <framework/stdext/format.h>
#include <framework/core/logger.h>
#include <framework/platform/platformwindow.h>
#include <framework/input/mouse.h>

double RmlUiSystemInterface::GetElapsedTime()
{
    return stdext::micros() / 1000000.0;
}

bool RmlUiSystemInterface::LogMessage(Rml::Log::Type type, const Rml::String& message)
{
    switch (type) {
    case Rml::Log::LT_ALWAYS:
    case Rml::Log::LT_INFO:
        g_logger.info(stdext::format("[RmlUi] %s", message));
        break;
    case Rml::Log::LT_WARNING:
        g_logger.warning(stdext::format("[RmlUi] %s", message));
        break;
    case Rml::Log::LT_ASSERT:
    case Rml::Log::LT_ERROR:
        g_logger.error(stdext::format("[RmlUi] %s", message));
        break;
    case Rml::Log::LT_DEBUG:
        g_logger.debug(stdext::format("[RmlUi] %s", message));
        break;
    default:
        g_logger.info(stdext::format("[RmlUi] %s", message));
        break;
    }
    return true;
}

void RmlUiSystemInterface::JoinPath(Rml::String& translated_path,
    const Rml::String& document_path, const Rml::String& path)
{
    if (path.empty()) {
        translated_path = document_path;
        return;
    }
    if (path[0] == '/' || path[0] == '\\') {
        translated_path = path;
        return;
    }

    auto slash = document_path.rfind('/');
    auto backslash = document_path.rfind('\\');
    auto dirEnd = slash;
    if (backslash != Rml::String::npos && (slash == Rml::String::npos || backslash > slash))
        dirEnd = backslash;
    if (dirEnd != Rml::String::npos)
        translated_path = document_path.substr(0, dirEnd + 1) + path;
    else
        translated_path = path;
}

void RmlUiSystemInterface::SetMouseCursor(const Rml::String& cursor_name)
{
    g_mouse.pushCursor(cursor_name);
}

void RmlUiSystemInterface::SetClipboardText(const Rml::String& text)
{
    g_window.setClipboardText(text);
}

void RmlUiSystemInterface::GetClipboardText(Rml::String& text)
{
    text = g_window.getClipboardText();
}
