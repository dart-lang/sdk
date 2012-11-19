// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generate a snapshot file after loading all the scripts specified on the
// command line.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/log.h"

#include "platform/globals.h"

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    free(snapshot_buffer);                                                     \
    Log::PrintErr("Error: %s", Dart_GetError(result));                    \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    exit(255);                                                                 \
  }                                                                            \


// Global state that indicates whether a snapshot is to be created and
// if so which file to write the snapshot into.
static const char* snapshot_filename = NULL;
static bool script_snapshot = false;
static const char* package_root = NULL;
static uint8_t* snapshot_buffer = NULL;


// Global state which contains a pointer to the script name for which
// a snapshot needs to be created (NULL would result in the creation
// of a generic snapshot that contains only the corelibs).
static char* app_script_name = NULL;


// Global state that captures the URL mappings specified on the command line.
static CommandLineOptions* url_mapping = NULL;

static bool IsValidFlag(const char* name,
                        const char* prefix,
                        intptr_t prefix_length) {
  intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}


static const char* ProcessOption(const char* option, const char* name) {
  const intptr_t length = strlen(name);
  if (strncmp(option, name, length) == 0) {
    return (option + length);
  }
  return NULL;
}


static bool ProcessSnapshotOption(const char* option) {
  const char* name = ProcessOption(option, "--snapshot=");
  if (name != NULL) {
    script_snapshot = false;
    snapshot_filename = name;
    return true;
  }
  name = ProcessOption(option, "--script_snapshot=");
  if (name != NULL) {
    script_snapshot = true;
    snapshot_filename = name;
    return true;
  }
  return false;
}


static bool ProcessPackageRootOption(const char* option) {
  const char* name = ProcessOption(option, "--package_root=");
  if (name != NULL) {
    package_root = name;
    return true;
  }
  return false;
}


static bool ProcessURLmappingOption(const char* option) {
  const char* mapping = ProcessOption(option, "--url_mapping=");
  if (mapping == NULL) {
    mapping = ProcessOption(option, "--url-mapping=");
  }
  if (mapping != NULL) {
    url_mapping->AddArgument(mapping);
    return true;
  }
  return false;
}


// Parse out the command line arguments. Returns -1 if the arguments
// are incorrect, 0 otherwise.
static int ParseArguments(int argc,
                          char** argv,
                          CommandLineOptions* vm_options,
                          char** script_name) {
  const char* kPrefix = "--";
  const intptr_t kPrefixLen = strlen(kPrefix);

  // Skip the binary name.
  int i = 1;

  // Parse out the vm options.
  while ((i < argc) && IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
    if (ProcessSnapshotOption(argv[i]) ||
        ProcessURLmappingOption(argv[i]) ||
        ProcessPackageRootOption(argv[i])) {
      i += 1;
      continue;
    }
    vm_options->AddArgument(argv[i]);
    i += 1;
  }

  // Get the script name.
  if (i < argc) {
    *script_name = argv[i];
    i += 1;
  } else {
    *script_name = NULL;
  }

  return 0;
}


static void WriteSnapshotFile(const uint8_t* buffer, const intptr_t size) {
  File* file = File::Open(snapshot_filename, File::kWriteTruncate);
  ASSERT(file != NULL);
  for (intptr_t i = 0; i < size; i++) {
    file->WriteByte(buffer[i]);
  }
  delete file;
}


static Dart_Handle CreateSnapshotLibraryTagHandler(Dart_LibraryTag tag,
                                                   Dart_Handle library,
                                                   Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_Error("not a library");
  }
  if (!Dart_IsString(url)) {
    return Dart_Error("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }

  // If the URL starts with "dart:" then it is handled specially.
  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
  if (tag == kCanonicalizeUrl) {
    if (is_dart_scheme_url) {
      return url;
    }
    return DartUtils::CanonicalizeURL(url_mapping, library, url_string);
  }
  return DartUtils::LoadSource(url_mapping,
                               library,
                               url,
                               tag,
                               url_string);
}


static Dart_Handle LoadSnapshotCreationScript(const char* script_name) {
  Dart_Handle source = DartUtils::ReadStringFromFile(script_name);
  if (Dart_IsError(source)) {
    return source;  // source contains the error string.
  }
  Dart_Handle url = DartUtils::NewString(script_name);

  return Dart_LoadScript(url, source);
}


static Dart_Handle LoadGenericSnapshotCreationScript(
    Builtin::BuiltinLibraryId id) {
  Dart_Handle source = Builtin::Source(id);
  if (Dart_IsError(source)) {
    return source;  // source contains the error string.
  }
  Dart_Handle lib;
  // Load the builtin library to make it available in the snapshot
  // for importing.
  lib = Builtin::LoadAndCheckLibrary(id);
  ASSERT(!Dart_IsError(lib));
  return lib;
}


static void PrintUsage() {
  Log::PrintErr("dart [<vm-flags>] [<dart-script-file>]\n");
}


static void VerifyLoaded(Dart_Handle library) {
  if (Dart_IsError(library)) {
    const char* err_msg = Dart_GetError(library);
    Log::PrintErr("Errors encountered while loading: %s\n", err_msg);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(255);
  }
  ASSERT(Dart_IsLibrary(library));
}


static void CreateAndWriteSnapshot(bool script_snapshot) {
  Dart_Handle result;
  uint8_t* buffer = NULL;
  intptr_t size = 0;

  // First create a snapshot.
  if (script_snapshot) {
    // Script snapshot specified so create a script snapshot.
    result = Dart_CreateScriptSnapshot(&buffer, &size);
  } else {
    // Create a full snapshot.
    result = Dart_CreateSnapshot(&buffer, &size);
  }
  CHECK_RESULT(result);

  // Now write the snapshot out to specified file and exit.
  WriteSnapshotFile(buffer, size);
  Dart_ExitScope();

  // Shutdown the isolate.
  Dart_ShutdownIsolate();
}


static void SetupForGenericSnapshotCreation() {
  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(DartUtils::LibraryTagHandler);
  if (Dart_IsError(result)) {
    Log::PrintErr("%s", Dart_GetError(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    exit(255);
  }
  // This is a generic dart snapshot which needs builtin library setup.
  Dart_Handle library =
      LoadGenericSnapshotCreationScript(Builtin::kBuiltinLibrary);
  VerifyLoaded(library);
  library = LoadGenericSnapshotCreationScript(Builtin::kJsonLibrary);
  VerifyLoaded(library);
  library = LoadGenericSnapshotCreationScript(Builtin::kUriLibrary);
  VerifyLoaded(library);
  library = LoadGenericSnapshotCreationScript(Builtin::kCryptoLibrary);
  VerifyLoaded(library);
  library = LoadGenericSnapshotCreationScript(Builtin::kIOLibrary);
  VerifyLoaded(library);
  library = LoadGenericSnapshotCreationScript(Builtin::kUtfLibrary);
  VerifyLoaded(library);
}


int main(int argc, char** argv) {
  CommandLineOptions vm_options(argc);

  // Initialize the URL mapping array.
  CommandLineOptions url_mapping_array(argc);
  url_mapping = &url_mapping_array;

  // Parse command line arguments.
  if (ParseArguments(argc,
                     argv,
                     &vm_options,
                     &app_script_name) < 0) {
    PrintUsage();
    return 255;
  }

  if (snapshot_filename == NULL) {
    Log::PrintErr("No snapshot output file specified\n");
    return 255;
  }

  DartUtils::SetOriginalWorkingDirectory();

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  // Note: We don't expect isolates to be created from dart code during
  // snapshot generation.
  if (!Dart_Initialize(NULL, NULL, NULL)) {
    Log::PrintErr("VM initialization failed\n");
    return 255;
  }

  char* error;
  Dart_Isolate isolate = Dart_CreateIsolate(NULL, NULL, NULL, NULL, &error);
  if (isolate == NULL) {
    Log::PrintErr("Error: %s", error);
    free(error);
    exit(255);
  }

  Dart_Handle result;
  Dart_Handle library;
  Dart_EnterScope();

  ASSERT(snapshot_filename != NULL);
  // Load up the script before a snapshot is created.
  if (app_script_name != NULL) {
    if (!script_snapshot) {
      // This is the case of a custom embedder (e.g: dartium) trying to
      // create a full snapshot. Set up the library tag handler for this case
      // in such a manner that it will use the URL mapping specified on the
      // command line to load the libraries.
      result = Dart_SetLibraryTagHandler(CreateSnapshotLibraryTagHandler);
      CHECK_RESULT(result);
      // Load the specified script.
      library = LoadSnapshotCreationScript(app_script_name);
      VerifyLoaded(library);
      CreateAndWriteSnapshot(false);
    } else {
      // This is the case where we want to create a script snapshot of
      // the specified script. There will be no URL mapping specified for
      // this case, use the generic library tag handler.

      // First setup and create a generic full snapshot.
      SetupForGenericSnapshotCreation();
      uint8_t* buffer = NULL;
      intptr_t size = 0;
      result = Dart_CreateSnapshot(&buffer, &size);
      CHECK_RESULT(result);

      // Save the snapshot buffer as we are about to shutdown the isolate.
      snapshot_buffer = reinterpret_cast<uint8_t*>(malloc(size));
      ASSERT(snapshot_buffer != NULL);
      memmove(snapshot_buffer, buffer, size);

      // Shutdown the isolate.
      Dart_ExitScope();
      Dart_ShutdownIsolate();

      // Now load the specified script and create a script snapshot.
      Dart_Isolate isolate = Dart_CreateIsolate(NULL,
                                                NULL,
                                                snapshot_buffer,
                                                NULL,
                                                &error);
      if (isolate == NULL) {
        Log::PrintErr("%s", error);
        free(error);
        free(snapshot_buffer);
        exit(255);
      }
      Dart_EnterScope();

      // Setup generic library tag handler.
      result = Dart_SetLibraryTagHandler(DartUtils::LibraryTagHandler);
      CHECK_RESULT(result);

      // Get handle to builtin library.
      Dart_Handle builtin_lib =
          Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
      CHECK_RESULT(builtin_lib);

      // Prepare for script loading by setting up the 'print' and 'timer'
      // closures and setting up 'package root' for URI resolution.
      result = DartUtils::PrepareForScriptLoading(package_root, builtin_lib);
      CHECK_RESULT(result);

      // Load specified script.
      library = DartUtils::LoadScript(app_script_name, builtin_lib);

      // Now create and write snapshot of script.
      CreateAndWriteSnapshot(true);

      free(snapshot_buffer);
    }
  } else {
    SetupForGenericSnapshotCreation();
    CreateAndWriteSnapshot(false);
  }
  return 0;
}
