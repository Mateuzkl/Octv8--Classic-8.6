#include "rmluifileinterface.h"
#include <framework/global.h>
#include <framework/core/logger.h>
#include <framework/stdext/string.h>
#include <physfs.h>
#include <cstring>

struct PhysicsFSFileHandle {
    PHYSFS_File* handle;
    FILE* filePtr;
    size_t size;
    size_t pos;
};

#define CAST_HANDLE(file) reinterpret_cast<PhysicsFSFileHandle*>(file)
#define MAKE_HANDLE(p) (Rml::FileHandle)(p)

Rml::FileHandle RmlUiFileInterface::Open(const Rml::String& path)
{
    if (PHYSFS_exists(path.c_str())) {
        PHYSFS_File* physFile = PHYSFS_openRead(path.c_str());
        if (physFile) {
            auto* data = new PhysicsFSFileHandle();
            data->handle = physFile;
            data->size = PHYSFS_fileLength(physFile);
            data->pos = 0;
            return MAKE_HANDLE(data);
        }
    }

    FILE* f = fopen(path.c_str(), "rb");
    if (f) {
        fseek(f, 0, SEEK_END);
        size_t fileSize = ftell(f);
        fseek(f, 0, SEEK_SET);

        auto* data = new PhysicsFSFileHandle();
        data->handle = nullptr;
        data->filePtr = f;
        data->size = fileSize;
        data->pos = 0;
        return MAKE_HANDLE(data);
    }

    g_logger.warning(stdext::format("[RmlUi] File not found: %s", path));
    return 0;
}

void RmlUiFileInterface::Close(Rml::FileHandle file)
{
    auto* data = CAST_HANDLE(file);
    if (!data) return;
    if (data->handle)
        PHYSFS_close(data->handle);
    if (data->filePtr)
        fclose(data->filePtr);
    delete data;
}

size_t RmlUiFileInterface::Read(void* buffer, size_t size, Rml::FileHandle file)
{
    auto* data = CAST_HANDLE(file);
    if (!data) return 0;
    if (data->handle) {
        PHYSFS_sint64 read = PHYSFS_readBytes(data->handle, buffer, size);
        if (read > 0) data->pos += (size_t)read;
        return read > 0 ? (size_t)read : 0;
    }
    if (data->filePtr) {
        size_t read = fread(buffer, 1, size, data->filePtr);
        data->pos += read;
        return read;
    }
    return 0;
}

bool RmlUiFileInterface::Seek(Rml::FileHandle file, long offset, int origin)
{
    auto* data = CAST_HANDLE(file);
    if (!data) return false;
    if (data->handle) {
        int result = 0;
        switch (origin) {
        case SEEK_SET: result = PHYSFS_seek(data->handle, offset); break;
        case SEEK_CUR: result = PHYSFS_seek(data->handle, PHYSFS_tell(data->handle) + offset); break;
        case SEEK_END: result = PHYSFS_seek(data->handle, data->size + offset); break;
        }
        if (result) data->pos = PHYSFS_tell(data->handle);
        return result != 0;
    }
    if (data->filePtr) {
        int result = fseek(data->filePtr, offset, origin);
        if (result == 0) data->pos = ftell(data->filePtr);
        return result == 0;
    }
    return false;
}

size_t RmlUiFileInterface::Tell(Rml::FileHandle file)
{
    auto* data = CAST_HANDLE(file);
    if (!data) return 0;
    if (data->handle) {
        data->pos = PHYSFS_tell(data->handle);
        return data->pos;
    }
    if (data->filePtr) {
        data->pos = ftell(data->filePtr);
        return data->pos;
    }
    return 0;
}

size_t RmlUiFileInterface::Length(Rml::FileHandle file)
{
    auto* data = CAST_HANDLE(file);
    if (!data) return 0;
    return data->size;
}
