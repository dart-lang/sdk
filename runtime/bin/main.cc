// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/file.h"
#include "bin/globals.h"
#include "bin/process_script.h"

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.
extern const uint8_t* snapshot_buffer;


// Global state that indicates whether pprof symbol information is
// to be generated or not.
static const char* generate_pprof_symbols_filename = NULL;


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


static bool ProcessPprofOption(const char* option) {
  const char* kProfOption = "--generate_pprof_symbols=";
  const char* filename = ProcessOption(option, kProfOption);
  if (filename != NULL) {
    generate_pprof_symbols_filename = filename;
  }
  return filename != NULL;
}


// Parse out the command line arguments. Returns -1 if the arguments
// are incorrect, 0 otherwise.
static int ParseArguments(int argc,
                          char** argv,
                          CommandLineOptions* vm_options,
                          char** script_name,
                          CommandLineOptions* dart_options) {
  const char* kPrefix = "--";
  const intptr_t kPrefixLen = strlen(kPrefix);

  // Skip the binary name.
  int i = 1;

  // Parse out the vm options.
  while ((i < argc) && IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
    if (ProcessPprofOption(argv[i])) {
      i += 1;
      continue;
    }
    vm_options->AddArgument(argv[i]);
    i += 1;
  }
  if (generate_pprof_symbols_filename != NULL) {
    Dart_InitPprofSupport();
  }

  // Get the script name.
  if (i < argc) {
    *script_name = argv[i];
    i += 1;
  } else {
    return -1;
  }

  // Parse out options to be passed to dart main.
  while (i < argc) {
    dart_options->AddArgument(argv[i]);
    i += 1;
  }

  return 0;
}


static Dart_Handle SetupRuntimeOptions(CommandLineOptions* options) {
  int options_count = options->count();
  Dart_Handle dart_arguments = Dart_NewList(options_count);
  if (Dart_IsError(dart_arguments)) {
    return dart_arguments;
  }
  for (int i = 0; i < options_count; i++) {
    Dart_Handle argument_value = Dart_NewString(options->GetArgument(i));
    if (Dart_IsError(argument_value)) {
      return argument_value;
    }
    Dart_Handle result = Dart_ListSetAt(dart_arguments, i, argument_value);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  Dart_Handle core_lib_url = Dart_NewString("dart:coreimpl");
  if (Dart_IsError(core_lib_url)) {
    return core_lib_url;
  }
  Dart_Handle core_lib = Dart_LookupLibrary(core_lib_url);
  if (Dart_IsError(core_lib)) {
    return core_lib;
  }
  Dart_Handle runtime_options_class_name = Dart_NewString("RuntimeOptions");
  if (Dart_IsError(runtime_options_class_name)) {
    return runtime_options_class_name;
  }
  Dart_Handle runtime_options_class = Dart_GetClass(
      core_lib, runtime_options_class_name);
  if (Dart_IsError(runtime_options_class)) {
    return runtime_options_class;
  }
  Dart_Handle native_name = Dart_NewString("_nativeArguments");
  if (Dart_IsError(native_name)) {
    return native_name;
  }

  return Dart_SetStaticField(runtime_options_class,
                             native_name,
                             dart_arguments);
}


static void DumpPprofSymbolInfo() {
  if (generate_pprof_symbols_filename != NULL) {
    Dart_EnterScope();
    File* pprof_file = File::Open(generate_pprof_symbols_filename, true);
    ASSERT(pprof_file != NULL);
    void* buffer;
    int buffer_size;
    Dart_GetPprofSymbolInfo(&buffer, &buffer_size);
    if (buffer_size > 0) {
      ASSERT(buffer != NULL);
      pprof_file->WriteFully(buffer, buffer_size);
    }
    delete pprof_file;  // Closes the file.
    Dart_ExitScope();
  }
}


static void* MainIsolateInitCallback(void* data) {
  const char* script_name = reinterpret_cast<const char*>(data);
  Dart_Handle library;
  Dart_EnterScope();

  // Load the specified script.
  library = LoadScript(script_name);
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
  Builtin_ImportLibrary(library);  // Import builtin library.

  Dart_ExitScope();
  return data;
}


static void PrintUsage() {
  fprintf(stderr,
          "dart [<vm-flags>] <dart-script-file> [<dart-options>]\n");
}


static bool HasCompileAll(const CommandLineOptions& options) {
  for (int i = 0; i < options.count(); i++) {
    if (strcmp(options.GetArgument(i), "--compile_all") == 0) {
      return true;
    }
  }
  return false;
}


int main(int argc, char** argv) {
  char* script_name;
  CommandLineOptions vm_options(argc);
  CommandLineOptions dart_options(argc);

  // Parse command line arguments.
  if (ParseArguments(argc,
                     argv,
                     &vm_options,
                     &script_name,
                     &dart_options) < 0) {
    PrintUsage();
    return 255;
  }

  // Initialize the Dart VM (TODO(asiva) - remove const_cast once
  // dart API is fixed to take a const char** in Dart_Initialize).
  Dart_Initialize(vm_options.count(),
                  const_cast<char**>(vm_options.arguments()),
                  MainIsolateInitCallback);

  // Create an isolate. As a side effect, MainIsolateInitCallback
  // gets called, which loads the scripts and libraries.
  char* canonical_script_name = File::GetCanonicalPath(script_name);
  if (canonical_script_name == NULL) {
    fprintf(stderr, "Unable to find '%s'\n", script_name);
    return 255;  // Indicates we encountered an error.
  }
  Dart_Isolate isolate = Dart_CreateIsolate(snapshot_buffer,
                                            canonical_script_name);
  if (isolate == NULL) {
    free(canonical_script_name);
    return 255;
  }

  Dart_EnterScope();

  if (snapshot_buffer != NULL) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin_SetNativeResolver();
  }

  if (HasCompileAll(vm_options)) {
    Dart_Handle result = Dart_CompileAll();
    if (Dart_IsError(result)) {
      fprintf(stderr, "%s\n", Dart_GetError(result));
      Dart_ExitScope();
      Dart_ShutdownIsolate();
      free(canonical_script_name);
      return 255;  // Indicates we encountered an error.
    }
  }

  // Create a dart options object that can be accessed from dart code.
  Dart_Handle options_result = SetupRuntimeOptions(&dart_options);
  if (Dart_IsError(options_result)) {
    fprintf(stderr, "%s\n", Dart_GetError(options_result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    free(canonical_script_name);
    return 255;  // Indicates we encountered an error.
  }

  // Lookup and invoke the top level main function.
  Dart_Handle script_url = Dart_NewString(canonical_script_name);
  Dart_Handle library = Dart_LookupLibrary(script_url);
  if (Dart_IsError(library)) {
    fprintf(stderr, "%s\n", Dart_GetError(library));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    free(canonical_script_name);
    return 255;  // Indicates we encountered an error.
  }
  Dart_Handle result = Dart_InvokeStatic(library,
                                         Dart_NewString(""),
                                         Dart_NewString("main"),
                                         0,
                                         NULL);
  if (Dart_IsError(result)) {
    fprintf(stderr, "%s\n", Dart_GetError(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    free(canonical_script_name);
    return 255;  // Indicates we encountered an error.
  }
  // Keep handling messages until the last active receive port is closed.
  result = Dart_RunLoop();
  if (Dart_IsError(result)) {
    fprintf(stderr, "%s\n", Dart_GetError(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    free(canonical_script_name);
    return 255;  // Indicates we encountered an error.
  }
  free(canonical_script_name);
  Dart_ExitScope();
  // Dump symbol information for the profiler.
  DumpPprofSymbolInfo();
  // Shutdown the isolate.
  Dart_ShutdownIsolate();
  return 0;
}
