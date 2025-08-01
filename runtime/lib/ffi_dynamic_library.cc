// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/ffi_dynamic_library.h"

#include "platform/globals.h"
#include "platform/utils.h"
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
#include "vm/native_entry.h"
#include "vm/symbols.h"
#include "vm/zone_text_buffer.h"

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
#include <dlfcn.h>
#endif

namespace dart {

#if (defined(DART_INCLUDE_SIMULATOR) && !defined(SIMULATOR_FFI)) ||            \
    (defined(DART_PRECOMPILER) && !defined(TESTING))

DART_NORETURN static void SimulatorUnsupported() {
#if defined(DART_INCLUDE_SIMULATOR)
  Exceptions::ThrowUnsupportedError("Not supported on this simulator.");
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

#else  // defined(DART_INCLUDE_SIMULATOR) ||                                   \
       // (defined(DART_PRECOMPILER) && !defined(TESTING))

// If an error occurs populates |error| (if provided) with an error message
// (caller must free this message when it is no longer needed).
static void* LoadDynamicLibrary(const char* library_file,
                                char** error = nullptr) {
  char* utils_error = nullptr;
  void* handle = Utils::LoadDynamicLibrary(
      library_file, /* search_dll_load_dir= */ false, &utils_error);
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

// String is zone allocated.
static char* AvailableAssetsToCString(Thread* const thread) {
  Zone* const zone = thread->zone();

  const auto& native_assets_map =
      Array::Handle(zone, GetNativeAssetsMap(thread));
  ZoneTextBuffer buffer(zone, 1024);

  if (native_assets_map.IsNull()) {
    buffer.Printf("No available native assets.");
  } else {
    bool first = true;
    buffer.Printf("Available native assets: ");
    NativeAssetsMap map(native_assets_map.ptr());
    NativeAssetsMap::Iterator it(&map);
    auto& asset_id = String::Handle(zone);
    while (it.MoveNext()) {
      if (!first) {
        buffer.Printf(" ,");
        first = false;
      }
      auto entry = it.Current();
      asset_id ^= map.GetKey(entry);
      buffer.Printf("%s", asset_id.ToCString());
    }
    buffer.Printf(".");
    map.Release();
  }
  return buffer.buffer();
}

// If an error occurs populates |error| with an error message
// (caller must free this message when it is no longer needed).
//
// The |asset_location| is formatted as follows:
// ['<path_type>', '<path (optional)>']
// The |asset_location| is conform to: pkg/vm/lib/native_assets/validator.dart
static void* FfiResolveAsset(Thread* const thread,
                             const String& asset,
                             const String& symbol,
                             char** error) {
  void* handle = nullptr;
  NativeAssetsApi* native_assets_api =
      thread->isolate_group()->native_assets_api();
  if (native_assets_api->dlopen != nullptr) {
    // Let embedder resolve the asset id to asset path.
    NoActiveIsolateScope no_active_isolate_scope;
    handle = native_assets_api->dlopen(asset.ToCString(), error);
  }
  if (*error == nullptr && handle == nullptr) {
    // Fall back on VM reading ffi:native-assets from special library in kernel.
    // Allow for both embedder and VM resolution so flutter/engine and
    // flutter/flutter PRs can land without manual roll.
    Zone* const zone = thread->zone();
    const auto& asset_location =
        Array::Handle(zone, GetAssetLocation(thread, asset));
    if (asset_location.IsNull()) {
      return nullptr;
    }

    const auto& asset_type =
        String::Cast(Object::Handle(zone, asset_location.At(0)));
    String& path = String::Handle(zone);
    const char* path_cstr = nullptr;
    if (asset_type.Equals(Symbols::absolute()) ||
        asset_type.Equals(Symbols::relative()) ||
        asset_type.Equals(Symbols::system())) {
      path = String::RawCast(asset_location.At(1));
      path_cstr = path.ToCString();
    }

    if (asset_type.Equals(Symbols::absolute())) {
      if (native_assets_api->dlopen_absolute == nullptr) {
        *error = OS::SCreate(/*use malloc*/ nullptr,
                             "NativeAssetsApi::dlopen_absolute not set.");
        return nullptr;
      }
      NoActiveIsolateScope no_active_isolate_scope;
      handle = native_assets_api->dlopen_absolute(path_cstr, error);
    } else if (asset_type.Equals(Symbols::relative())) {
      if (native_assets_api->dlopen_relative == nullptr) {
        *error = OS::SCreate(/*use malloc*/ nullptr,
                             "NativeAssetsApi::dlopen_relative not set.");
        return nullptr;
      }
      NoActiveIsolateScope no_active_isolate_scope;
      handle = native_assets_api->dlopen_relative(path_cstr, error);
    } else if (asset_type.Equals(Symbols::system())) {
      if (native_assets_api->dlopen_system == nullptr) {
        *error = OS::SCreate(/*use malloc*/ nullptr,
                             "NativeAssetsApi::dlopen_system not set.");
        return nullptr;
      }
      NoActiveIsolateScope no_active_isolate_scope;
      handle = native_assets_api->dlopen_system(path_cstr, error);
    } else if (asset_type.Equals(Symbols::executable())) {
      if (native_assets_api->dlopen_executable == nullptr) {
        *error = OS::SCreate(/*use malloc*/ nullptr,
                             "NativeAssetsApi::dlopen_executable not set.");
        return nullptr;
      }
      NoActiveIsolateScope no_active_isolate_scope;
      handle = native_assets_api->dlopen_executable(error);
    } else {
      RELEASE_ASSERT(asset_type.Equals(Symbols::process()));
      if (native_assets_api->dlopen_process == nullptr) {
        *error = OS::SCreate(/*use malloc*/ nullptr,
                             "NativeAssetsApi::dlopen_process not set.");
        return nullptr;
      }
      NoActiveIsolateScope no_active_isolate_scope;
      handle = native_assets_api->dlopen_process(error);
    }
  }

  if (*error != nullptr) {
    return nullptr;
  }
  if (native_assets_api->dlsym == nullptr) {
    *error =
        OS::SCreate(/*use malloc*/ nullptr, "NativeAssetsApi::dlsym not set.");
    return nullptr;
  }
  void* const result =
      native_assets_api->dlsym(handle, symbol.ToCString(), error);
  return result;
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
  // Resolver resolution.
  auto resolver = GetFfiNativeResolver(thread, asset);
  if (resolver != nullptr) {
    void* ffi_native_result = FfiResolveWithFfiNativeResolver(
        thread, resolver, symbol, args_n, error);
    return reinterpret_cast<intptr_t>(ffi_native_result);
  }

  // Native assets resolution.
  void* asset_result = FfiResolveAsset(thread, asset, symbol, error);
  if (asset_result != nullptr || *error != nullptr) {
    return reinterpret_cast<intptr_t>(asset_result);
  }

  // Resolution in current process.
#if !defined(DART_HOST_OS_WINDOWS)
  void* const result = Utils::ResolveSymbolInDynamicLibrary(
      RTLD_DEFAULT, symbol.ToCString(), error);
#else
  void* const result = LookupSymbolInProcess(symbol.ToCString(), error);
#endif

  if (*error != nullptr) {
    // Process lookup failed, but the user might have tried to use native
    // asset lookup. So augment the error message to include native assets info.
    char* process_lookup_error = *error;
    NativeAssetsApi* native_assets_api =
        thread->isolate_group()->native_assets_api();
    const char* const format =
        "No asset with id '%s' found. %s "
        "Attempted to fallback to process lookup. %s";
    if (native_assets_api->available_assets != nullptr) {
      // Embedder is resolving asset ids to asset paths.
      char* available_assets = native_assets_api->available_assets();
      *error = OS::SCreate(/*use malloc*/ nullptr, format, asset.ToCString(),
                           available_assets, process_lookup_error);
      free(available_assets);
    } else {
      // VM is resolving asset ids to asset paths.
      *error =
          OS::SCreate(/*use malloc*/ nullptr, format, asset.ToCString(),
                      AvailableAssetsToCString(thread), process_lookup_error);
    }
    free(process_lookup_error);
  }

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

#endif  // (defined(DART_INCLUDE_SIMULATOR) && !defined (SIMULATOR_FFI)) ||    \
        // (defined(DART_PRECOMPILER) && !defined(TESTING))

}  // namespace dart
