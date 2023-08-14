// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/loader.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/error_exit.h"
#include "bin/file.h"
#include "bin/gzip.h"
#include "bin/lockers.h"
#include "bin/snapshot_utils.h"
#include "bin/utils.h"
#include "include/dart_tools_api.h"
#include "platform/growable_array.h"

namespace dart {
namespace bin {

#if !defined(DART_PRECOMPILED_RUNTIME)
extern DFE dfe;
#endif

Dart_Handle Loader::InitForSnapshot(const char* snapshot_uri,
                                    IsolateData* isolate_data) {
  ASSERT(isolate_data != nullptr);

  return Loader::Init(isolate_data->packages_file(),
                      DartUtils::original_working_directory, snapshot_uri);
}

// Initialize package resolution state.
Dart_Handle Loader::Init(const char* packages_file,
                         const char* working_directory,
                         const char* root_script_uri) {
  const int kNumArgs = 3;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = (packages_file == nullptr)
                     ? Dart_Null()
                     : Dart_NewStringFromCString(packages_file);
  dart_args[1] = Dart_NewStringFromCString(working_directory);
  dart_args[2] = (root_script_uri == nullptr)
                     ? Dart_Null()
                     : Dart_NewStringFromCString(root_script_uri);
  return Dart_Invoke(DartUtils::LookupBuiltinLib(),
                     DartUtils::NewString("_Init"), kNumArgs, dart_args);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static void MallocFinalizer(void* isolate_callback_data, void* peer) {
  free(peer);
}
static Dart_Handle WrapMallocedKernelBuffer(uint8_t* kernel_buffer,
                                            intptr_t kernel_buffer_size) {
  Dart_Handle result = Dart_NewExternalTypedDataWithFinalizer(
      Dart_TypedData_kUint8, kernel_buffer, kernel_buffer_size, kernel_buffer,
      kernel_buffer_size, MallocFinalizer);
  if (Dart_IsError(result)) {
    free(kernel_buffer);
  }
  return result;
}
#endif

Dart_Handle Loader::LibraryTagHandler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url) {
  const char* url_string = nullptr;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  if (tag == Dart_kCanonicalizeUrl) {
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    const char* library_url_string = nullptr;
    result = Dart_StringToCString(library_url, &library_url_string);
    if (Dart_IsError(result)) {
      return result;
    }
    bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
    bool is_dart_library = DartUtils::IsDartSchemeURL(library_url_string);
    if (is_dart_scheme_url || is_dart_library) {
      return url;
    }
    return Dart_DefaultCanonicalizeUrl(library_url, url);
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (tag == Dart_kKernelTag) {
    uint8_t* kernel_buffer = nullptr;
    intptr_t kernel_buffer_size = 0;
    if (!dfe.TryReadKernelFile(url_string, &kernel_buffer,
                               &kernel_buffer_size)) {
      return DartUtils::NewError("'%s' is not a kernel file", url_string);
    }
    return WrapMallocedKernelBuffer(kernel_buffer, kernel_buffer_size);
  }
  if (dfe.CanUseDartFrontend() && dfe.UseDartFrontend() &&
      (tag == Dart_kImportTag)) {
    // E.g., IsolateMirror.loadUri.
    char* error = nullptr;
    int exit_code = 0;
    uint8_t* kernel_buffer = nullptr;
    intptr_t kernel_buffer_size = -1;
    dfe.CompileAndReadScript(url_string, &kernel_buffer, &kernel_buffer_size,
                             &error, &exit_code, nullptr, false);
    if (exit_code == 0) {
      return Dart_LoadLibrary(
          WrapMallocedKernelBuffer(kernel_buffer, kernel_buffer_size));
    } else if (exit_code == kCompilationErrorExitCode) {
      Dart_Handle result = Dart_NewCompilationError(error);
      free(error);
      return result;
    } else {
      Dart_Handle result = Dart_NewApiError(error);
      free(error);
      return result;
    }
  }
  return DartUtils::NewError("Invalid tag : %d '%s'", tag, url_string);
#else   // !defined(DART_PRECOMPILED_RUNTIME)
  return DartUtils::NewError("Unimplemented tag : %d '%s'", tag, url_string);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

Dart_Handle Loader::DeferredLoadHandler(intptr_t loading_unit_id) {
  // A synchronous implementation. An asynchronous implementation would be
  // better, but the standalone embedder only implements AOT for testing.

  auto isolate_group_data =
      reinterpret_cast<IsolateGroupData*>(Dart_CurrentIsolateGroupData());
  char* unit_url = Utils::SCreate(
      "%s-%" Pd ".part.so", isolate_group_data->script_url, loading_unit_id);

  AppSnapshot* loading_unit_snapshot = Snapshot::TryReadAppSnapshot(unit_url);
  Dart_Handle result;
  if (loading_unit_snapshot != nullptr) {
    isolate_group_data->AddLoadingUnit(loading_unit_snapshot);
    const uint8_t* isolate_snapshot_data = nullptr;
    const uint8_t* isolate_snapshot_instructions = nullptr;
    const uint8_t* ignore_vm_snapshot_data;
    const uint8_t* ignore_vm_snapshot_instructions;
    loading_unit_snapshot->SetBuffers(
        &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
        &isolate_snapshot_data, &isolate_snapshot_instructions);
    result = Dart_DeferredLoadComplete(loading_unit_id, isolate_snapshot_data,
                                       isolate_snapshot_instructions);
    if (Dart_IsApiError(result)) {
      result =
          Dart_DeferredLoadCompleteError(loading_unit_id, Dart_GetError(result),
                                         /*transient*/ false);
    }
  } else {
    char* error_message = Utils::SCreate("Failed to load %s", unit_url);
    result = Dart_DeferredLoadCompleteError(loading_unit_id, error_message,
                                            /*transient*/ false);
    free(error_message);
  }

  free(unit_url);
  return result;
}

void Loader::InitOnce() {
}

}  // namespace bin
}  // namespace dart
