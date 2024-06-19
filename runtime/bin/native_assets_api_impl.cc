// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/bin/native_assets_api.h"

#include "platform/globals.h"

#if defined(DART_HOST_OS_WINDOWS)
#include <Psapi.h>
#include <Windows.h>
#include <combaseapi.h>
#include <stdio.h>
#include <tchar.h>
#endif
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
#include <dlfcn.h>
#endif

#include "bin/file.h"
#include "bin/uri.h"

namespace dart {
namespace bin {

#define SET_ERROR_MSG(error_msg, format, ...)                                  \
  intptr_t len = snprintf(nullptr, 0, format, __VA_ARGS__);                    \
  char* msg = reinterpret_cast<char*>(malloc(len + 1));                        \
  snprintf(msg, len + 1, format, __VA_ARGS__);                                 \
  *error_msg = msg

#if defined(DART_TARGET_OS_WINDOWS)
// Replaces back slashes with forward slashes in place.
static void ReplaceBackSlashes(char* cstr) {
  const intptr_t length = strlen(cstr);
  for (int i = 0; i < length; i++) {
    cstr[i] = cstr[i] == '\\' ? '/' : cstr[i];
  }
}
#endif

const char* file_schema = "file://";
const int file_schema_length = 7;

// Get a file uri with only forward slashes from the script path.
// Returned string must be freed by caller.
static char* CleanScriptUri(const char* script_uri) {
  const char* path = script_uri;
#if defined(DART_TARGET_OS_WINDOWS)
  // Isolate.spawnUri sets a `source` including the file schema.
  // And on Windows we get an extra forward slash in that case.
  const char* file_schema_slash = "file:///";
  const int file_schema_slash_length = 8;

  if (strlen(script_uri) > file_schema_slash_length &&
      strncmp(script_uri, file_schema_slash, file_schema_slash_length) == 0) {
    path = (script_uri + file_schema_slash_length);
  }
#else
  // Isolate.spawnUri sets a `source` including the file schema.
  if (strlen(script_uri) > file_schema_length &&
      strncmp(script_uri, file_schema, file_schema_length) == 0) {
    path = (script_uri + file_schema_length);
  }
#endif

  // Resolve symlinks.
  char canon_path[PATH_MAX];
  File::GetCanonicalPath(nullptr, path, canon_path, PATH_MAX);

  // Replace backward slashes with forward slashes.
  const intptr_t len = strlen(canon_path);
  char* path_copy =
      reinterpret_cast<char*>(malloc(file_schema_length + len + 1));
  snprintf(path_copy, len + 1, "%s%s", file_schema, canon_path);
#if defined(DART_TARGET_OS_WINDOWS)
  ReplaceBackSlashes(path_copy);
#endif
  return path_copy;
}

// If an error occurs populates |error| (if provided) with an error message
// (caller must free this message when it is no longer needed).
static void* LoadDynamicLibrary(const char* library_file,
                                char** error = nullptr) {
  char* utils_error = nullptr;
  void* handle = Utils::LoadDynamicLibrary(library_file, &utils_error);
  if (utils_error != nullptr) {
    if (error != nullptr) {
      SET_ERROR_MSG(error, "Failed to load dynamic library '%s': %s",
                    library_file != nullptr ? library_file : "<process>",
                    utils_error);
    }
    free(utils_error);
  }
  return handle;
}

#if defined(DART_HOST_OS_WINDOWS)
// On windows, nullptr signals trying a lookup in all loaded modules.
const nullptr_t kWindowsDynamicLibraryProcessPtr = nullptr;
#endif

static void WrapError(const char* path, char** error) {
  if (*error != nullptr) {
    char* inner_error = *error;
    SET_ERROR_MSG(error, "Failed to load dynamic library '%s': %s", path,
                  inner_error);
    free(inner_error);
  }
}

void* NativeAssets::DlopenAbsolute(const char* path, char** error) {
  // If we'd want to be strict, it should not take into account include paths.
  void* handle = LoadDynamicLibrary(path, error);
  WrapError(path, error);
  return handle;
}

void* NativeAssets::DlopenRelative(const char* path,
                                   const char* script_uri,
                                   char** error) {
  void* handle = nullptr;
  char* platform_script_cstr = CleanScriptUri(script_uri);
  const intptr_t len = strlen(path);
  char* path_copy = reinterpret_cast<char*>(malloc(len + 1));
  snprintf(path_copy, len + 1, "%s", path);
#if defined(DART_TARGET_OS_WINDOWS)
  ReplaceBackSlashes(path_copy);
#endif
  auto target_uri = ResolveUri(path_copy, platform_script_cstr);
  if (!target_uri) {
    SET_ERROR_MSG(error, "Failed to resolve '%s' relative to '%s'.", path_copy,
                  platform_script_cstr);
  } else {
    const char* target_path = target_uri.get() + file_schema_length;
    handle = LoadDynamicLibrary(target_path, error);
  }
  free(path_copy);
  free(platform_script_cstr);
  WrapError(path, error);
  return handle;
}

void* NativeAssets::DlopenSystem(const char* path, char** error) {
  // Should take into account LD_PATH etc.
  void* handle = LoadDynamicLibrary(path, error);
  WrapError(path, error);
  return handle;
}

void* NativeAssets::DlopenProcess(char** error) {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
  return RTLD_DEFAULT;
#else
  return kWindowsDynamicLibraryProcessPtr;
#endif
}

void* NativeAssets::DlopenExecutable(char** error) {
  return LoadDynamicLibrary(nullptr, error);
}

#if defined(DART_HOST_OS_WINDOWS)
void* co_task_mem_allocated = nullptr;

// If an error occurs populates |error| with an error message
// (caller must free this message when it is no longer needed).
void* LookupSymbolInProcess(const char* symbol, char** error) {
  // Force loading ole32.dll.
  if (co_task_mem_allocated == nullptr) {
    co_task_mem_allocated = CoTaskMemAlloc(sizeof(intptr_t));
    CoTaskMemFree(co_task_mem_allocated);
  }

  HANDLE current_process =
      OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE,
                  GetCurrentProcessId());
  if (current_process == nullptr) {
    SET_ERROR_MSG(error, "Failed to open current process.");
    return nullptr;
  }

  HMODULE modules[1024];
  DWORD cb_needed;
  if (EnumProcessModules(current_process, modules, sizeof(modules),
                         &cb_needed) != 0) {
    for (intptr_t i = 0; i < (cb_needed / sizeof(HMODULE)); i++) {
      if (auto result =
              reinterpret_cast<void*>(GetProcAddress(modules[i], symbol))) {
        CloseHandle(current_process);
        return result;
      }
    }
  }
  CloseHandle(current_process);

  SET_ERROR_MSG(
      error, "None of the loaded modules contained the requested symbol '%s'.",
      symbol);
  return nullptr;
}
#endif

// If an error occurs populates |error| with an error message
// (caller must free this message when it is no longer needed).
static void* ResolveSymbol(void* handle, const char* symbol, char** error) {
#if defined(DART_HOST_OS_WINDOWS)
  if (handle == kWindowsDynamicLibraryProcessPtr) {
    return LookupSymbolInProcess(symbol, error);
  }
#endif
  return Utils::ResolveSymbolInDynamicLibrary(handle, symbol, error);
}

void* NativeAssets::Dlsym(void* handle, const char* symbol, char** error) {
  void* const result = ResolveSymbol(handle, symbol, error);
  if (*error != nullptr) {
    char* inner_error = *error;
    SET_ERROR_MSG(error, "Failed to lookup symbol '%s': %s", symbol,
                  inner_error);
    free(inner_error);
  }
  return result;
}

}  // namespace bin
}  // namespace dart
