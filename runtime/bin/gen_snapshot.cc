// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generate a snapshot file after loading all the scripts specified on the
// command line.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/file.h"
#include "bin/globals.h"
#include "bin/process_script.h"

// Global state that indicates whether a snapshot is to be created and
// if so which file to write the snapshot into.
static const char* snapshot_filename = NULL;

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
  const char* kSnapshotOption = "--snapshot=";
  snapshot_filename = ProcessOption(option, kSnapshotOption);
  return snapshot_filename != NULL;
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
    if (ProcessSnapshotOption(argv[i])) {
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
  const bool kWritable = true;
  File* file = File::Open(snapshot_filename, kWritable);
  ASSERT(file != NULL);
  for (intptr_t i = 0; i < size; i++) {
    file->WriteByte(buffer[i]);
  }
  delete file;
}


static void* SnapshotCreateCallback(void* data) {
  const char* script_name = reinterpret_cast<const char*>(data);
  Dart_Handle result;
  Dart_EnterScope();

  ASSERT(snapshot_filename != NULL);

  // If a file is specified on the command line, load it up before a snapshot
  // is created.
  if (script_name != NULL) {
    // Load the specified script.
    Dart_Handle library = LoadSnapshotCreationScript(script_name);
    if (Dart_IsError(library)) {
      const char* err_msg = Dart_GetError(library);
      fprintf(stderr, "Errors encountered while loading script: %s\n", err_msg);
      Dart_ExitScope();
      exit(255);
    }

    if (!Dart_IsLibrary(library)) {
      fprintf(stderr,
              "Expected a library when loading script: %s",
              script_name);
      Dart_ExitScope();
      exit(255);
    }
  } else {
    // Implicitly load builtin library.
    Builtin_LoadLibrary();
    // Setup the native resolver for built in library functions.
    Builtin_SetNativeResolver();
  }

  uint8_t* buffer = NULL;
  intptr_t size = 0;
  // First create the snapshot.
  result = Dart_CreateSnapshot(&buffer, &size);
  if (Dart_IsError(result)) {
    const char* err_msg = Dart_GetError(result);
    fprintf(stderr, "Error while creating snapshot: %s\n", err_msg);
    Dart_ExitScope();
    exit(255);
  }
  // Now write the snapshot out to specified file and exit.
  WriteSnapshotFile(buffer, size);
  Dart_ExitScope();
  return data;
}


static void PrintUsage() {
  fprintf(stderr,
          "dart [<vm-flags>] "
          "[<dart-script-file>]\n");
}


int main(int argc, char** argv) {
  CommandLineOptions vm_options(argc);
  char* script_name;

  // Parse command line arguments.
  if (ParseArguments(argc,
                     argv,
                     &vm_options,
                     &script_name) < 0) {
    PrintUsage();
    return 255;
  }

  if (snapshot_filename == NULL) {
    fprintf(stderr, "No snapshot output file specified\n");
    return 255;
  }

  // Initialize the Dart VM.
  Dart_Initialize(vm_options.count(),
                  vm_options.arguments(),
                  SnapshotCreateCallback);

  // Create an isolate. As a side effect, SnapshotCreateCallback
  // gets called, which loads the script (if one is specified), its libraries
  // and writes out a snapshot.
  Dart_Isolate isolate = Dart_CreateIsolate(NULL, script_name);
  if (isolate == NULL) {
    return 255;
  }

  // Shutdown the isolate.
  Dart_ShutdownIsolate();
  return 0;
}
