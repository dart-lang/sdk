// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Executes `main` function from given Dart kernel binary (by default uses
// compiled ./hello.dart).
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <vector>
#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/platform.h"
#include "include/dart_api.h"
#include "include/dart_embedder_api.h"
#include "platform/assert.h"

Dart_Handle CheckHandle(Dart_Handle handle,
                        const char* context = "unknown context") {
  if (Dart_IsError(handle)) {
    FATAL("Dart error (%s): %s", context, Dart_GetError(handle));
  }
  return handle;
}

void CheckError(bool condition, const char* error, const char* context) {
  if (!condition) {
    FATAL("Dart error (%s): %s", context, error);
  }
}

void CheckError(const char* error, const char* context) {
  if (error != nullptr) {
    FATAL("Dart error (%s): %s", context, error);
  }
}

Dart_InitializeParams CreateInitializeParams() {
  Dart_InitializeParams params;
  memset(&params, 0, sizeof(params));
  params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  return params;
}

std::string GetExecutablePath() {
  const size_t kPathBufSize = PATH_MAX + 1;
  char executable_path[kPathBufSize] = {};

  intptr_t path_length = dart::bin::Platform::ResolveExecutablePathInto(
      executable_path, kPathBufSize);
  CheckError(path_length > 0, "empty executable path",
             "ResolveExecutablePathInfo");
  return std::string(executable_path, path_length);
}

std::string GetDefaultSnapshotPath() {
  std::string executable_path = GetExecutablePath();
  std::string directory =
      executable_path.substr(0, executable_path.find_last_of("/\\"));
  return directory + "/gen/hello_kernel.dart.snapshot";
}

std::string ReadSnapshot(std::string_view path) {
  std::string path_string{path};
  std::ifstream source_file{path_string, std::ios::binary};

  ASSERT(source_file.good());
  source_file.seekg(0, source_file.end);
  uint64_t length = source_file.tellg();
  source_file.seekg(0, source_file.beg);

  char* bytes = static_cast<char*>(std::malloc(length));
  source_file.read(bytes, length);
  return std::string(bytes, length);
}

Dart_Handle ToDartStringList(const std::vector<std::string>& values) {
  Dart_Handle string_type =
      CheckHandle(dart::bin::DartUtils::GetDartType("dart:core", "String"));
  Dart_Handle filler = CheckHandle(Dart_NewStringFromCString(""));

  Dart_Handle result =
      CheckHandle(Dart_NewListOfTypeFilled(string_type, filler, values.size()));
  for (size_t i = 0; i < values.size(); i++) {
    Dart_Handle element =
        CheckHandle(Dart_NewStringFromCString(values[i].c_str()));
    CheckHandle(Dart_ListSetAt(result, i, element));
  }

  return result;
}

int main(int argc, char** argv) {
  std::string snapshot_path =
      argc == 1 ? GetDefaultSnapshotPath() : std::string(argv[1]);

  std::string snapshot_name =
      snapshot_path.substr(snapshot_path.find_last_of("/\\") + 1);
  std::string snapshot_data = ReadSnapshot(snapshot_path);
  std::string snapshot_uri = "file://" + snapshot_path;
  std::cout << "Snapshot path: " << snapshot_path << std::endl;
  char* error;

  // Start Dart VM.
  CheckError(dart::embedder::InitOnce(&error), error,
             "dart::embedder::InitOnce");

  std::vector<const char*> flags{};
  CheckError(Dart_SetVMFlags(flags.size(), flags.data()), "Dart_SetVMFlags");

  Dart_InitializeParams initialize_params = CreateInitializeParams();
  CheckError(Dart_Initialize(&initialize_params), "Dart_Initialize");

  dart::bin::DFE dfe;
  dfe.Init();
  const uint8_t* platform_buffer = nullptr;
  intptr_t platform_buffer_size = 0;

  dfe.LoadPlatform(&platform_buffer, &platform_buffer_size);

  // Start an isolate from a platform kernel.
  Dart_IsolateFlags isolate_flags;

  Dart_CreateIsolateGroupFromKernel(
      /*script_uri=*/snapshot_uri.c_str(),
      /*name=*/snapshot_name.c_str(),
      /*kernel_buffer=*/platform_buffer,
      /*kernel_buffer_size=*/platform_buffer_size,
      /*flags=*/&isolate_flags,
      /*isolate_group_data=*/nullptr,
      /*isolate_data=*/nullptr, &error);
  CheckError(error, "Dart_CreateIsolateGroupFromKernel");
  Dart_EnterScope();
  CheckHandle(dart::bin::DartUtils::PrepareForScriptLoading(
                  /*is_service_isolate=*/false, /*trace_loading=*/false),
              "PrepareForScriptLoading");

  // Load kernel snapshot to run `main` from.
  Dart_Handle library =
      CheckHandle(Dart_LoadLibraryFromKernel(
                      reinterpret_cast<const uint8_t*>(snapshot_data.c_str()),
                      snapshot_data.size()),
                  "Dart_LoadLibraryFromKernel");

  // Call main function with args.
  std::initializer_list<Dart_Handle> main_args{ToDartStringList({"universe"})};
  CheckHandle(Dart_Invoke(library, Dart_NewStringFromCString("main"), 1,
                          const_cast<Dart_Handle*>(main_args.begin())),
              "Dart_Invoke('main')");
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}
