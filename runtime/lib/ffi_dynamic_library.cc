// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/ffi_dynamic_library.h"

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)
#include <Psapi.h>
#include <Windows.h>
#include <combaseapi.h>
#include <stdio.h>
#include <tchar.h>
#endif

#include "vm/bootstrap_natives.h"
#include "vm/dart_api_impl.h"
#include "vm/exceptions.h"
#include "vm/ffi/native_assets.h"
#include "vm/globals.h"
#include "vm/hash_table.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/symbols.h"
#include "vm/uri.h"

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
#include <dlfcn.h>
#endif

namespace dart {

#if defined(USING_SIMULATOR) || (defined(DART_PRECOMPILER) && !defined(TESTING))

DART_NORETURN static void SimulatorUnsupported() {
#if defined(USING_SIMULATOR)
  Exceptions::ThrowUnsupportedError(
      "Not supported on simulated architectures.");
#else
  Exceptions::ThrowUnsupportedError("Not supported in precompiler.");
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_dl_open, 0, 1) {
  SimulatorUnsupported();
}
DEFINE_NATIVE_ENTRY(Ffi_dl_processLibrary, 0, 0) {
  SimulatorUnsupported();
}
DEFINE_NATIVE_ENTRY(Ffi_dl_executableLibrary, 0, 0) {
  SimulatorUnsupported();
}
DEFINE_NATIVE_ENTRY(Ffi_dl_lookup, 1, 2) {
  SimulatorUnsupported();
}
DEFINE_NATIVE_ENTRY(Ffi_dl_getHandle, 0, 1) {
  SimulatorUnsupported();
}
DEFINE_NATIVE_ENTRY(Ffi_dl_close, 0, 1) {
  SimulatorUnsupported();
}
DEFINE_NATIVE_ENTRY(Ffi_dl_providesSymbol, 0, 2) {
  SimulatorUnsupported();
}

DEFINE_NATIVE_ENTRY(Ffi_GetFfiNativeResolver, 1, 0) {
  SimulatorUnsupported();
}

#else  // defined(USING_SIMULATOR) ||                                          \
       // (defined(DART_PRECOMPILER) && !defined(TESTING))

// If an error occurs populates |error| (if provided) with an error message
// (caller must free this message when it is no longer needed).
static void* LoadDynamicLibrary(const char* library_file,
                                char** error = nullptr) {
  char* utils_error = nullptr;
  void* handle = Utils::LoadDynamicLibrary(library_file, &utils_error);
  if (utils_error != nullptr) {
    if (error != nullptr) {
      *error = OS::SCreate(
          /*use malloc*/ nullptr, "Failed to load dynamic library '%s': %s",
          library_file != nullptr ? library_file : "<process>", utils_error);
    }
    free(utils_error);
  }
  return handle;
}

#if defined(DART_HOST_OS_WINDOWS)
// On windows, nullptr signals trying a lookup in all loaded modules.
const nullptr_t kWindowsDynamicLibraryProcessPtr = nullptr;

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
    *error = OS::SCreate(nullptr, "Failed to open current process.");
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

  *error = OS::SCreate(
      nullptr,  // Use `malloc`.
      "None of the loaded modules contained the requested symbol '%s'.",
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

static bool SymbolExists(void* handle, const char* symbol) {
  char* error = nullptr;
#if !defined(DART_HOST_OS_WINDOWS)
  Utils::ResolveSymbolInDynamicLibrary(handle, symbol, &error);
#else
  if (handle == nullptr) {
    LookupSymbolInProcess(symbol, &error);
  } else {
    Utils::ResolveSymbolInDynamicLibrary(handle, symbol, &error);
  }
#endif
  if (error != nullptr) {
    free(error);
    return false;
  }
  return true;
}

DEFINE_NATIVE_ENTRY(Ffi_dl_open, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, lib_path, arguments->NativeArgAt(0));

  char* error = nullptr;
  void* handle = LoadDynamicLibrary(lib_path.ToCString(), &error);
  if (error != nullptr) {
    const String& msg = String::Handle(String::New(error));
    free(error);
    Exceptions::ThrowArgumentError(msg);
  }
  return DynamicLibrary::New(handle, true);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_processLibrary, 0, 0) {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
  return DynamicLibrary::New(RTLD_DEFAULT, false);
#else
  return DynamicLibrary::New(kWindowsDynamicLibraryProcessPtr, false);
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_dl_executableLibrary, 0, 0) {
  return DynamicLibrary::New(LoadDynamicLibrary(nullptr), false);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_close, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));
  if (dlib.IsClosed()) {
    // Already closed, nothing to do
  } else if (!dlib.CanBeClosed()) {
    const String& msg = String::Handle(
        String::New("DynamicLibrary.process() and DynamicLibrary.executable() "
                    "can't be closed."));
    Exceptions::ThrowStateError(msg);
  } else {
    void* handle = dlib.GetHandle();
    char* error = nullptr;
    Utils::UnloadDynamicLibrary(handle, &error);

    if (error == nullptr) {
      dlib.SetClosed(true);
    } else {
      const String& msg = String::Handle(String::New(error));
      free(error);
      Exceptions::ThrowStateError(msg);
    }
  }

  return Object::null();
}

DEFINE_NATIVE_ENTRY(Ffi_dl_lookup, 1, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, argSymbolName,
                               arguments->NativeArgAt(1));

  if (dlib.IsClosed()) {
    const String& msg =
        String::Handle(String::New("Cannot lookup symbols in closed library."));
    Exceptions::ThrowStateError(msg);
  }

  void* handle = dlib.GetHandle();

  char* error = nullptr;
  const uword pointer = reinterpret_cast<uword>(
      ResolveSymbol(handle, argSymbolName.ToCString(), &error));
  if (error != nullptr) {
    const String& msg = String::Handle(String::NewFormatted(
        "Failed to lookup symbol '%s': %s", argSymbolName.ToCString(), error));
    free(error);
    Exceptions::ThrowArgumentError(msg);
  }
  return Pointer::New(pointer);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_getHandle, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));

  intptr_t handle = reinterpret_cast<intptr_t>(dlib.GetHandle());
  return Integer::NewFromUint64(handle);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_providesSymbol, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, argSymbolName,
                               arguments->NativeArgAt(1));

  void* handle = dlib.GetHandle();
  return Bool::Get(SymbolExists(handle, argSymbolName.ToCString())).ptr();
}

// nullptr if no native resolver is installed.
static Dart_FfiNativeResolver GetFfiNativeResolver(Thread* const thread,
                                                   const String& lib_url_str) {
  const Library& lib =
      Library::Handle(Library::LookupLibrary(thread, lib_url_str));
  if (lib.IsNull()) {
    // It is not an error to not have a native resolver installed.
    return nullptr;
  }
  return lib.ffi_native_resolver();
}

// If an error occurs populates |error| with an error message
// (caller must free this message when it is no longer needed).
static void* FfiResolveWithFfiNativeResolver(Thread* const thread,
                                             Dart_FfiNativeResolver resolver,
                                             const String& symbol,
                                             intptr_t args_n,
                                             char** error) {
  auto* result = resolver(symbol.ToCString(), args_n);
  if (result == nullptr) {
    *error = OS::SCreate(/*use malloc*/ nullptr,
                         "Couldn't resolve function: '%s'", symbol.ToCString());
  }
  return result;
}

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

// Get a file path with only forward slashes from the script path.
static StringPtr GetPlatformScriptPath(Thread* thread) {
  IsolateGroupSource* const source = thread->isolate_group()->source();

#if defined(DART_TARGET_OS_WINDOWS)
  // Isolate.spawnUri sets a `source` including the file schema.
  // And on Windows we get an extra forward slash in that case.
  const char* file_schema_slash = "file:///";
  const int file_schema_slash_length = 8;
  const char* path = source->script_uri;
  if (strlen(source->script_uri) > file_schema_slash_length &&
      strncmp(source->script_uri, file_schema_slash,
              file_schema_slash_length) == 0) {
    path = (source->script_uri + file_schema_slash_length);
  }

  // Replace backward slashes with forward slashes.
  const intptr_t len = strlen(path);
  char* path_copy = reinterpret_cast<char*>(malloc(len + 1));
  snprintf(path_copy, len + 1, "%s", path);
  ReplaceBackSlashes(path_copy);
  const auto& result = String::Handle(String::New(path_copy));
  free(path_copy);
  return result.ptr();
#else
  // Isolate.spawnUri sets a `source` including the file schema.
  if (strlen(source->script_uri) > file_schema_length &&
      strncmp(source->script_uri, file_schema, file_schema_length) == 0) {
    const char* path = (source->script_uri + file_schema_length);
    return String::New(path);
  }
  return String::New(source->script_uri);
#endif
}

// Array::null if asset is not in mapping or no mapping.
static ArrayPtr GetAssetLocation(Thread* const thread, const String& asset) {
  Zone* const zone = thread->zone();
  auto& result = Array::Handle(zone);

  const auto& native_assets_map =
      Array::Handle(zone, GetNativeAssetsMap(thread));
  if (!native_assets_map.IsNull()) {
    NativeAssetsMap map(native_assets_map.ptr());
    const auto& lookup = Object::Handle(zone, map.GetOrNull(asset));
    if (!lookup.IsNull()) {
      result = Array::Cast(lookup).ptr();
    }
    map.Release();
  }
  return result.ptr();
}

// If an error occurs populates |error| with an error message
// (caller must free this message when it is no longer needed).
//
// The |asset_location| is formatted as follows:
// ['<path_type>', '<path (optional)>']
// The |asset_location| is conform to: pkg/vm/lib/native_assets/validator.dart
static void* FfiResolveAsset(Thread* const thread,
                             const Array& asset_location,
                             const String& symbol,
                             char** error) {
  Zone* const zone = thread->zone();

  const auto& asset_type =
      String::Cast(Object::Handle(zone, asset_location.At(0)));
  String& path = String::Handle(zone);
  if (asset_type.Equals(Symbols::absolute()) ||
      asset_type.Equals(Symbols::relative()) ||
      asset_type.Equals(Symbols::system())) {
    path = String::RawCast(asset_location.At(1));
  }
  void* handle = nullptr;
  if (asset_type.Equals(Symbols::absolute())) {
    handle = LoadDynamicLibrary(path.ToCString(), error);
  } else if (asset_type.Equals(Symbols::relative())) {
    const auto& platform_script_uri = String::Handle(
        zone,
        String::NewFormatted(
            "%s%s", file_schema,
            String::Handle(zone, GetPlatformScriptPath(thread)).ToCString()));
    const char* target_uri = nullptr;
    char* path_cstr = path.ToMallocCString();
#if defined(DART_TARGET_OS_WINDOWS)
    ReplaceBackSlashes(path_cstr);
#endif
    const bool resolved =
        ResolveUri(path_cstr, platform_script_uri.ToCString(), &target_uri);
    free(path_cstr);
    if (!resolved) {
      *error = OS::SCreate(/*use malloc*/ nullptr,
                           "Failed to resolve '%s' relative to '%s'.",
                           path.ToCString(), platform_script_uri.ToCString());
    } else {
      const char* target_path = target_uri + file_schema_length;
      handle = LoadDynamicLibrary(target_path, error);
    }
  } else if (asset_type.Equals(Symbols::system())) {
    handle = LoadDynamicLibrary(path.ToCString(), error);
  } else if (asset_type.Equals(Symbols::process())) {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
    handle = RTLD_DEFAULT;
#else
    handle = kWindowsDynamicLibraryProcessPtr;
#endif
  } else if (asset_type.Equals(Symbols::executable())) {
    handle = LoadDynamicLibrary(nullptr, error);
  } else {
    UNREACHABLE();
  }
  if (*error != nullptr) {
    char* inner_error = *error;
    *error = OS::SCreate(/*use malloc*/ nullptr,
                         "Failed to load dynamic library '%s': %s",
                         path.ToCString(), inner_error);
    free(inner_error);
  } else {
    void* const result = ResolveSymbol(handle, symbol.ToCString(), error);
    if (*error != nullptr) {
      char* inner_error = *error;
      *error = OS::SCreate(/*use malloc*/ nullptr,
                           "Failed to lookup symbol '%s': %s",
                           symbol.ToCString(), inner_error);
      free(inner_error);
    } else {
      return result;
    }
  }
  ASSERT(*error != nullptr);
  return nullptr;
}

// Frees |error|.
static void ThrowFfiResolveError(const String& symbol,
                                 const String& asset,
                                 char* error) {
  const String& error_message = String::Handle(String::NewFormatted(
      "Couldn't resolve native function '%s' in '%s' : %s.\n",
      symbol.ToCString(), asset.ToCString(), error));
  free(error);
  Exceptions::ThrowArgumentError(error_message);
}

intptr_t FfiResolveInternal(const String& asset,
                            const String& symbol,
                            uintptr_t args_n,
                            char** error) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  // Resolver resolution.
  auto resolver = GetFfiNativeResolver(thread, asset);
  if (resolver != nullptr) {
    void* ffi_native_result = FfiResolveWithFfiNativeResolver(
        thread, resolver, symbol, args_n, error);
    return reinterpret_cast<intptr_t>(ffi_native_result);
  }

  // Native assets resolution.
  const auto& asset_location =
      Array::Handle(zone, GetAssetLocation(thread, asset));
  if (!asset_location.IsNull()) {
    void* asset_result = FfiResolveAsset(thread, asset_location, symbol, error);
    return reinterpret_cast<intptr_t>(asset_result);
  }

  // Resolution in current process.
#if !defined(DART_HOST_OS_WINDOWS)
  void* const result = Utils::ResolveSymbolInDynamicLibrary(
      RTLD_DEFAULT, symbol.ToCString(), error);
#else
  void* const result = LookupSymbolInProcess(symbol.ToCString(), error);
#endif
  return reinterpret_cast<intptr_t>(result);
}

// FFI native C function pointer resolver.
static intptr_t FfiResolve(Dart_Handle asset_handle,
                           Dart_Handle symbol_handle,
                           uintptr_t args_n) {
  auto* const thread = Thread::Current();
  DARTSCOPE(thread);
  auto* const zone = thread->zone();
  const String& asset = Api::UnwrapStringHandle(zone, asset_handle);
  const String& symbol = Api::UnwrapStringHandle(zone, symbol_handle);
  char* error = nullptr;

  const intptr_t result = FfiResolveInternal(asset, symbol, args_n, &error);
  if (error != nullptr) {
    ThrowFfiResolveError(symbol, asset, error);
  }
  ASSERT(result != 0x0);
  return result;
}

// Bootstrap to get the FFI Native resolver through a `native` call.
DEFINE_NATIVE_ENTRY(Ffi_GetFfiNativeResolver, 1, 0) {
  return Pointer::New(reinterpret_cast<intptr_t>(FfiResolve));
}

#endif  // defined(USING_SIMULATOR) ||                                         \
        // (defined(DART_PRECOMPILER) && !defined(TESTING))

}  // namespace dart
