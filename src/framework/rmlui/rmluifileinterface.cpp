#include "rmluifileinterface.h"
#include <framework/global.h>
#include <framework/core/logger.h>
#include <framework/stdext/string.h>
#include <physfs.h>
#include <cstdio>
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
            PHYSFS_sint64 fileSize = PHYSFS_fileLength(physFile);
            PHYSFS_sint64 pos = PHYSFS_tell(physFile);
            if (fileSize < 0 || pos < 0) {
                PHYSFS_close(physFile);
                return 0;
            }

            auto* data = new PhysicsFSFileHandle();
            data->handle = physFile;
            data->filePtr = nullptr;
            data->size = static_cast<size_t>(fileSize);
            data->pos = static_cast<size_t>(pos);
            return MAKE_HANDLE(data);
        }
    }

    FILE* f = fopen(path.c_str(), "rb");
    if (f) {
        if (fseek(f, 0, SEEK_END) != 0) {
            fclose(f);
            return 0;
        }
        long fileSize = ftell(f);
        if (fileSize < 0 || fseek(f, 0, SEEK_SET) != 0) {
            fclose(f);
            return 0;
        }
        long pos = ftell(f);
        if (pos < 0) {
            fclose(f);
            return 0;
        }

        auto* data = new PhysicsFSFileHandle();
        data->handle = nullptr;
        data->filePtr = f;
        data->size = static_cast<size_t>(fileSize);
        data->pos = static_cast<size_t>(pos);
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
        PHYSFS_sint64 target = 0;
        switch (origin) {
        case SEEK_SET:
            target = offset;
            break;
        case SEEK_CUR: {
            PHYSFS_sint64 current = PHYSFS_tell(data->handle);
            if (current < 0) return false;
            target = current + offset;
            break;
        }
        case SEEK_END:
            target = static_cast<PHYSFS_sint64>(data->size) + offset;
            break;
        default:
            return false;
        }
        if (target < 0) return false;
        result = PHYSFS_seek(data->handle, static_cast<PHYSFS_uint64>(target));
        if (result) {
            PHYSFS_sint64 pos = PHYSFS_tell(data->handle);
            if (pos < 0) return false;
            data->pos = static_cast<size_t>(pos);
        }
        return result != 0;
    }
    if (data->filePtr) {
        int result = fseek(data->filePtr, offset, origin);
        if (result == 0) {
            long pos = ftell(data->filePtr);
            if (pos < 0) return false;
            data->pos = static_cast<size_t>(pos);
        }
        return result == 0;
    }
    return false;
}

size_t RmlUiFileInterface::Tell(Rml::FileHandle file)
{
    auto* data = CAST_HANDLE(file);
    if (!data) return 0;
    if (data->handle) {
        PHYSFS_sint64 pos = PHYSFS_tell(data->handle);
        if (pos < 0) return data->pos;
        data->pos = static_cast<size_t>(pos);
        return data->pos;
    }
    if (data->filePtr) {
        long pos = ftell(data->filePtr);
        if (pos < 0) return data->pos;
        data->pos = static_cast<size_t>(pos);
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
