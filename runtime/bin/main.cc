// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/globals.h"
#include "bin/platform.h"

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.
extern const uint8_t* snapshot_buffer;


// Global state that stores a pointer to the application script file.
static char* canonical_script_name = NULL;


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


static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_Error("not a library");
  }
  if (!Dart_IsString8(url)) {
    return Dart_Error("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return Dart_Error("accessing url characters failed");
  }
  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
  if (tag == kCanonicalizeUrl) {
    // If this is a Dart Scheme URL then it is not modified as it will be
    // handled by the VM internally.
    if (is_dart_scheme_url) {
      return url;
    }
    // Create a canonical path based on the including library and current url.
    return DartUtils::CanonicalizeURL(NULL, library, url_string);
  }
  if (is_dart_scheme_url) {
    return Dart_Error("Do not know how to load '%s'", url_string);
  }
  result = DartUtils::LoadSource(NULL, library, url, tag, url_string);
  if (!Dart_IsError(result) && (tag == kImportTag)) {
    Builtin::ImportLibrary(result);
  }
  return result;
}


static Dart_Handle LoadScript(const char* script_name) {
  Dart_Handle source = DartUtils::ReadStringFromFile(script_name);
  if (Dart_IsError(source)) {
    return source;
  }
  Dart_Handle url = Dart_NewString(script_name);

  return Dart_LoadScript(url, source, LibraryTagHandler);
}


static bool CreateIsolateAndSetup(void* data, char** error) {
  Dart_Isolate isolate = Dart_CreateIsolate(snapshot_buffer, data, error);
  if (isolate == NULL) {
    return false;
  }

  Dart_Handle library;
  Dart_EnterScope();

  // Load the specified application script into the newly created isolate.
  library = LoadScript(canonical_script_name);
  if (Dart_IsError(library)) {
    *error = strdup(Dart_GetError(library));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return false;
  }
  if (!Dart_IsLibrary(library)) {
    char errbuf[256];
    snprintf(errbuf, sizeof(errbuf),
             "Expected a library when loading script: %s",
             canonical_script_name);
    *error = strdup(errbuf);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return false;
  }
  Builtin::ImportLibrary(library);  // Implicitly import builtin into app.
  if (snapshot_buffer != NULL) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver();
  }
  Dart_ExitScope();
  return true;
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

  // Perform platform specific initialization.
  if (!Platform::Initialize()) {
    fprintf(stderr, "Initialization failed\n");
  }

  // Parse command line arguments.
  if (ParseArguments(argc,
                     argv,
                     &vm_options,
                     &script_name,
                     &dart_options) < 0) {
    PrintUsage();
    return 255;
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  Dart_Initialize(CreateIsolateAndSetup);

  canonical_script_name = File::GetCanonicalPath(script_name);
  if (canonical_script_name == NULL) {
    fprintf(stderr, "Unable to find '%s'\n", script_name);
    return 255;  // Indicates we encountered an error.
  }

  // Call CreateIsolateAndSetup which creates an isolate and loads up
  // the specified application script.
  char* error = NULL;
  if (!CreateIsolateAndSetup(NULL, &error)) {
    fprintf(stderr, "%s\n", error);
    free(canonical_script_name);
    free(error);
    return 255;  // Indicates we encountered an error.
  }

  Dart_Isolate isolate = Dart_CurrentIsolate();
  ASSERT(isolate != NULL);
  Dart_Handle result;

  Dart_EnterScope();

  if (HasCompileAll(vm_options)) {
    result = Dart_CompileAll();
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
  result = Dart_InvokeStatic(library,
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
