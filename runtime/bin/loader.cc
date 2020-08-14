// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/loader.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/error_exit.h"
#include "bin/extensions.h"
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
  ASSERT(isolate_data != NULL);

  return Loader::Init(isolate_data->packages_file(),
                      DartUtils::original_working_directory, snapshot_uri);
}

// Initialize package resolution state.
Dart_Handle Loader::Init(const char* packages_file,
                         const char* working_directory,
                         const char* root_script_uri) {
  const int kNumArgs = 3;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = (packages_file == NULL)
                     ? Dart_Null()
                     : Dart_NewStringFromCString(packages_file);
  dart_args[1] = Dart_NewStringFromCString(working_directory);
  dart_args[2] = (root_script_uri == NULL)
                     ? Dart_Null()
                     : Dart_NewStringFromCString(root_script_uri);
  return Dart_Invoke(DartUtils::LookupBuiltinLib(),
                     DartUtils::NewString("_Init"), kNumArgs, dart_args);
}

static bool PathContainsSeparator(const char* path) {
  return (strchr(path, '/') != NULL) ||
         ((strncmp(File::PathSeparator(), "/", 1) != 0) &&
          (strstr(path, File::PathSeparator()) != NULL));
}

#define RETURN_ERROR(result)                                                   \
  if (Dart_IsError(result)) return result;

Dart_Handle Loader::LoadImportExtension(const char* url_string,
                                        Dart_Handle library) {
  const char* lib_uri_str = NULL;
  Dart_Handle lib_uri = Dart_LibraryResolvedUrl(library);
  ASSERT(!Dart_IsError(lib_uri));
  Dart_Handle result = Dart_StringToCString(lib_uri, &lib_uri_str);
  RETURN_ERROR(result);

  UriDecoder decoder(lib_uri_str);
  lib_uri_str = decoder.decoded();

  if (strncmp(lib_uri_str, "http://", 7) == 0 ||
      strncmp(lib_uri_str, "https://", 8) == 0 ||
      strncmp(lib_uri_str, "data://", 7) == 0) {
    return DartUtils::NewError(
        "Cannot load native extensions over http: or https: or data: %s",
        lib_uri_str);
  }

  char* lib_path = NULL;
  if (strncmp(lib_uri_str, "file://", 7) == 0) {
    lib_path = DartUtils::DirName(lib_uri_str + 7);
  } else {
    lib_path = Utils::StrDup(lib_uri_str);
  }

  const char* path = DartUtils::RemoveScheme(url_string);
  if (!File::IsAbsolutePath(path) && PathContainsSeparator(path)) {
    free(lib_path);
    return DartUtils::NewError(
        "Native extension path must be absolute, or simply the file name: %s",
        path);
  }

  result = Extensions::LoadExtension(lib_path, path, library);
  free(lib_path);
  return result;
}

Dart_Handle Loader::ReloadNativeExtensions() {
  Dart_Handle scheme =
      Dart_NewStringFromCString(DartUtils::kDartExtensionScheme);
  Dart_Handle extension_imports = Dart_GetImportsOfScheme(scheme);
  RETURN_ERROR(extension_imports);

  intptr_t length = -1;
  Dart_Handle result = Dart_ListLength(extension_imports, &length);
  RETURN_ERROR(result);
  Dart_Handle* import_handles = reinterpret_cast<Dart_Handle*>(
      Dart_ScopeAllocate(sizeof(Dart_Handle) * length));
  result = Dart_ListGetRange(extension_imports, 0, length, import_handles);
  RETURN_ERROR(result);
  for (intptr_t i = 0; i < length; i += 2) {
    Dart_Handle importer = import_handles[i];
    Dart_Handle importee = import_handles[i + 1];

    const char* extension_uri = NULL;
    result = Dart_StringToCString(Dart_LibraryUrl(importee), &extension_uri);
    RETURN_ERROR(result);
    const char* extension_path = DartUtils::RemoveScheme(extension_uri);

    const char* lib_uri = NULL;
    result = Dart_StringToCString(Dart_LibraryUrl(importer), &lib_uri);
    RETURN_ERROR(result);

    char* lib_path = NULL;
    if (strncmp(lib_uri, "file://", 7) == 0) {
      lib_path = DartUtils::DirName(DartUtils::RemoveScheme(lib_uri));
    } else {
      lib_path = Utils::StrDup(lib_uri);
    }

    result = Extensions::LoadExtension(lib_path, extension_path, importer);
    free(lib_path);
    RETURN_ERROR(result);
  }

  return Dart_True();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static void MallocFinalizer(void* isolate_callback_data, void* peer) {
  free(peer);
}
#endif

Dart_Handle Loader::LibraryTagHandler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url) {
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  if (tag == Dart_kCanonicalizeUrl) {
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    const char* library_url_string = NULL;
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
    uint8_t* kernel_buffer = NULL;
    intptr_t kernel_buffer_size = 0;
    if (!DFE::TryReadKernelFile(url_string, &kernel_buffer,
                                &kernel_buffer_size)) {
      return DartUtils::NewError("'%s' is not a kernel file", url_string);
    }
    result = Dart_NewExternalTypedData(Dart_TypedData_kUint8, kernel_buffer,
                                       kernel_buffer_size);
    Dart_NewFinalizableHandle(result, kernel_buffer, kernel_buffer_size,
                              MallocFinalizer);
    return result;
  }
  if (tag == Dart_kImportExtensionTag) {
    if (!DartUtils::IsDartExtensionSchemeURL(url_string)) {
      return DartUtils::NewError(
          "Native extensions must use the dart-ext: scheme : %s", url_string);
    }
    return Loader::LoadImportExtension(url_string, library);
  }
  if (dfe.CanUseDartFrontend() && dfe.UseDartFrontend() &&
      (tag == Dart_kImportTag)) {
    // E.g., IsolateMirror.loadUri.
    char* error = NULL;
    int exit_code = 0;
    uint8_t* kernel_buffer = NULL;
    intptr_t kernel_buffer_size = -1;
    dfe.CompileAndReadScript(url_string, &kernel_buffer, &kernel_buffer_size,
                             &error, &exit_code, NULL);
    if (exit_code == 0) {
      return Dart_LoadLibraryFromKernel(kernel_buffer, kernel_buffer_size);
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
