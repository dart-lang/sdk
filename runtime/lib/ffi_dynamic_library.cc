// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)
#include <Psapi.h>
#include <Windows.h>
#include <combaseapi.h>
#include <stdio.h>
#include <tchar.h>
#endif

#include "include/dart_api.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/native_entry.h"

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
#include <dlfcn.h>
#endif

namespace dart {

#if defined(USING_SIMULATOR) || defined(DART_PRECOMPILER)

DART_NORETURN static void SimulatorUnsupported() {
  Exceptions::ThrowUnsupportedError(
      "Not supported on simulated architectures.");
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
DEFINE_NATIVE_ENTRY(Ffi_dl_providesSymbol, 0, 2) {
  SimulatorUnsupported();
}

#else  // defined(USING_SIMULATOR) || defined(DART_PRECOMPILER)

static void* LoadDynamicLibrary(const char* library_file) {
  char* error = nullptr;
  void* handle = Utils::LoadDynamicLibrary(library_file, &error);
  if (error != nullptr) {
    const String& msg = String::Handle(String::NewFormatted(
        "Failed to load dynamic library '%s': %s",
        library_file != nullptr ? library_file : "<process>", error));
    free(error);
    Exceptions::ThrowArgumentError(msg);
  }
  return handle;
}

#if defined(DART_HOST_OS_WINDOWS)
// On windows, nullptr signals trying a lookup in all loaded modules.
const nullptr_t kWindowsDynamicLibraryProcessPtr = nullptr;

void* co_task_mem_alloced = nullptr;

void* LookupSymbolInProcess(const char* symbol, char** error) {
  // Force loading ole32.dll.
  if (co_task_mem_alloced == nullptr) {
    co_task_mem_alloced = CoTaskMemAlloc(sizeof(intptr_t));
    CoTaskMemFree(co_task_mem_alloced);
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
      nullptr,
      "None of the loaded modules contained the requested symbol '%s'.",
      symbol);
  return nullptr;
}
#endif

static void* ResolveSymbol(void* handle, const char* symbol) {
  char* error = nullptr;
#if !defined(DART_HOST_OS_WINDOWS)
  void* const result =
      Utils::ResolveSymbolInDynamicLibrary(handle, symbol, &error);
#else
  void* const result =
      handle == kWindowsDynamicLibraryProcessPtr
          ? LookupSymbolInProcess(symbol, &error)
          : Utils::ResolveSymbolInDynamicLibrary(handle, symbol, &error);
#endif
  if (error != nullptr) {
    const String& msg = String::Handle(String::NewFormatted(
        "Failed to lookup symbol '%s': %s", symbol, error));
    free(error);
    Exceptions::ThrowArgumentError(msg);
  }
  return result;
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

  void* handle = LoadDynamicLibrary(lib_path.ToCString());

  return DynamicLibrary::New(handle);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_processLibrary, 0, 0) {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
  return DynamicLibrary::New(RTLD_DEFAULT);
#else
  return DynamicLibrary::New(kWindowsDynamicLibraryProcessPtr);
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_dl_executableLibrary, 0, 0) {
  return DynamicLibrary::New(LoadDynamicLibrary(nullptr));
}

DEFINE_NATIVE_ENTRY(Ffi_dl_lookup, 1, 2) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));

  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, argSymbolName,
                               arguments->NativeArgAt(1));

  void* handle = dlib.GetHandle();

  const uword pointer =
      reinterpret_cast<uword>(ResolveSymbol(handle, argSymbolName.ToCString()));
  return Pointer::New(type_arg, pointer);
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

#endif  // defined(USING_SIMULATOR)

}  // namespace dart
