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
  generate_pprof_symbols_filename = ProcessOption(option, kProfOption);
  return generate_pprof_symbols_filename != NULL;
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
      Dart_InitPprofSupport();
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
    return -1;
  }

  // Parse out options to be passed to dart main.
  while (i < argc) {
    dart_options->AddArgument(argv[i]);
    i += 1;
  }

  return 0;
}


static void DumpPprofSymbolInfo() {
  if (generate_pprof_symbols_filename != NULL) {
    Dart_EnterScope();
    File* pprof_file = File::OpenFile(generate_pprof_symbols_filename, true);
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
  Dart_Result result;
  Dart_EnterScope();

  // Load the specified script.
  result = LoadScript(script_name);
  if (!Dart_IsValidResult(result)) {
    const char* err_msg = Dart_GetErrorCString(result);
    fprintf(stderr, "Errors encountered while loading script: %s\n", err_msg);
    Dart_ExitScope();
    exit(255);
  }

  Dart_Handle library = Dart_GetResult(result);
  if (!Dart_IsLibrary(library)) {
    fprintf(stderr,
            "Expected a library when loading script: %s",
            script_name);
    Dart_ExitScope();
    exit(255);
  }
  Builtin_ImportLibrary(library);
  // Setup the native resolver for built in library functions.
  Builtin_SetNativeResolver();

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


static void PrintObject(FILE* out, Dart_Handle object) {
  Dart_Result result = Dart_ObjectToString(object);
  if (Dart_IsValidResult(result)) {
    Dart_Handle string = Dart_GetResult(result);
    PrintString(out, string);
  } else {
    fprintf(out, "%s\n", Dart_GetErrorCString(result));
  }
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

  // Initialize the Dart VM.
  Dart_Initialize(vm_options.count(),
                  vm_options.arguments(),
                  MainIsolateInitCallback);

  // Create an isolate. As a side effect, MainIsolateInitCallback
  // gets called, which loads the scripts and libraries.
  Dart_Isolate isolate = Dart_CreateIsolate(snapshot_buffer, script_name);
  if (isolate == NULL) {
    return 255;
  }

  Dart_EnterScope();
  // TODO(asiva): Create a dart options object that can be accessed from
  // dart code.
  if (HasCompileAll(vm_options)) {
    Dart_Result result = Dart_CompileAll();
    if (!Dart_IsValidResult(result)) {
      fprintf(stderr, "%s\n", Dart_GetErrorCString(result));
      Dart_ExitScope();
      Dart_ShutdownIsolate();
      return 255;  // Indicates we encountered an error.
    }
  }

  // Lookup and invoke the top level main function.
  Dart_Handle script_url = Dart_NewString(script_name);
  Dart_Result result = Dart_LookupLibrary(script_url);
  if (!Dart_IsValidResult(result)) {
    fprintf(stderr, "%s\n", Dart_GetErrorCString(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return 255;  // Indicates we encountered an error.
  }
  Dart_Handle library = Dart_GetResult(result);
  result = Dart_InvokeStatic(library,
                             Dart_NewString(""),
                             Dart_NewString("main"),
                             0,
                             NULL);

  if (Dart_IsValidResult(result)) {
    Dart_Handle result_obj = Dart_GetResult(result);
    if (Dart_ExceptionOccurred(result_obj)) {
      // Print the exception object.
      fprintf(stderr, "An unhandled exception has been thrown\n");
      Dart_Result exception_result = Dart_GetException(result_obj);
      ASSERT(Dart_IsValidResult(exception_result));
      PrintObject(stderr, Dart_GetResult(exception_result));
      // Print the stack trace.
      Dart_Result stacktrace = Dart_GetStacktrace(result_obj);
      ASSERT(Dart_IsValidResult(stacktrace));
      PrintObject(stderr, Dart_GetResult(stacktrace));
      fprintf(stderr, "\n");
      Dart_ExitScope();
      Dart_ShutdownIsolate();
      return 255;  // We had an unhandled exception, hence indicate an error.
    }
  } else {
    fprintf(stderr, "%s\n", Dart_GetErrorCString(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return 255;  // Indicates we encountered an error.
  }
  // Keep handling messages until the last active receive port is closed.
  result = Dart_RunLoop();
  if (!Dart_IsValidResult(result)) {
    fprintf(stderr, "%s\n", Dart_GetErrorCString(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return 255;  // Indicates we encountered an error.
  }
  Dart_ExitScope();
  // Dump symbol information for the profiler.
  DumpPprofSymbolInfo();
  // Shutdown the isolate.
  Dart_ShutdownIsolate();
  return 0;
}
