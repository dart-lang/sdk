// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"
#include "include/dart_debugger_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/dbg_connection.h"
#include "bin/directory.h"
#include "bin/eventhandler.h"
#include "bin/extensions.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "platform/globals.h"

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.
extern const uint8_t* snapshot_buffer;


// Global state that stores a pointer to the application script file.
static const char* original_script_name = NULL;
static const char* original_working_directory = NULL;
static const char* original_script_url = NULL;


// Global state that stores the import URL map specified on the
// command line.
static CommandLineOptions* import_map_options = NULL;


// Global state that indicates whether pprof symbol information is
// to be generated or not.
static const char* generate_pprof_symbols_filename = NULL;


// Global state that indicates whether there is a debug breakpoint.
// This pointer points into an argv buffer and does not need to be
// free'd.
static const char* breakpoint_at = NULL;


// Global state that indicates whether we should open a connection
// and listen for a debugger to connect.
static bool start_debugger = false;
static const int DEFAULT_DEBUG_PORT = 5858;
static const char* DEFAULT_DEBUG_IP = "127.0.0.1";
static const char* debug_ip = DEFAULT_DEBUG_IP;
static int debug_port = 0;


// Value of the --package-root flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* package_root = NULL;


// Global flag that is used to indicate that we want to compile all the
// dart functions and not run anything.
static bool has_compile_all = false;


static bool IsValidFlag(const char* name,
                        const char* prefix,
                        intptr_t prefix_length) {
  intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}


static void ProcessBreakpointOption(const char* funcname) {
  ASSERT(funcname != NULL);
  breakpoint_at = funcname;
}


static void ProcessPackageRootOption(const char* arg) {
  ASSERT(arg != NULL);
  package_root = arg;
}


static void ProcessCompileAllOption(const char* compile_all) {
  ASSERT(compile_all != NULL);
  has_compile_all = true;
}


static void ProcessDebugOption(const char* port) {
  // TODO(hausner): Add support for specifying an IP address on which
  // the debugger should listen.
  ASSERT(port != NULL);
  debug_port = 0;
  if (*port == '\0') {
    debug_port = DEFAULT_DEBUG_PORT;
  } else {
    if ((*port == '=') || (*port == ':')) {
      debug_port = atoi(port + 1);
    }
  }
  if (debug_port == 0) {
    fprintf(stderr, "unrecognized --debug option syntax. "
                    "Use --debug[:<port number>]\n");
    return;
  }
  breakpoint_at = "main";
  start_debugger = true;
}


static void ProcessPprofOption(const char* filename) {
  ASSERT(filename != NULL);
  generate_pprof_symbols_filename = filename;
}


static void ProcessImportMapOption(const char* map) {
  ASSERT(map != NULL);
  import_map_options->AddArgument(map);
}


static struct {
  const char* option_name;
  void (*process)(const char* option);
} main_options[] = {
  { "--break_at=", ProcessBreakpointOption },
  { "--compile_all", ProcessCompileAllOption },
  { "--debug", ProcessDebugOption },
  { "--generate_pprof_symbols=", ProcessPprofOption },
  { "--import_map=", ProcessImportMapOption },
  { "--package-root=", ProcessPackageRootOption },
  { NULL, NULL }
};


static bool ProcessMainOptions(const char* option) {
  int i = 0;
  const char* name = main_options[0].option_name;
  while (name != NULL) {
    int length = strlen(name);
    if (strncmp(option, name, length) == 0) {
      main_options[i].process(option + length);
      return true;
    }
    i += 1;
    name = main_options[i].option_name;
  }
  return false;
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
    if (ProcessMainOptions(argv[i])) {
      i += 1;
    } else {
      vm_options->AddArgument(argv[i]);
      i += 1;
    }
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


static Dart_Handle SetupRuntimeOptions(CommandLineOptions* options,
                                       const char* script_name) {
  int options_count = options->count();
  Dart_Handle dart_script = Dart_NewString(script_name);
  if (Dart_IsError(dart_script)) {
    return dart_script;
  }
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
  Dart_Handle script_name_name = Dart_NewString("_nativeScript");
  if (Dart_IsError(script_name_name)) {
    return script_name_name;
  }
  Dart_Handle set_script_name =
      Dart_SetField(runtime_options_class, script_name_name, dart_script);
  if (Dart_IsError(set_script_name)) {
    return set_script_name;
  }
  Dart_Handle native_name = Dart_NewString("_nativeArguments");
  if (Dart_IsError(native_name)) {
    return native_name;
  }

  return Dart_SetField(runtime_options_class, native_name, dart_arguments);
}


static void DumpPprofSymbolInfo() {
  if (generate_pprof_symbols_filename != NULL) {
    Dart_EnterScope();
    File* pprof_file =
        File::Open(generate_pprof_symbols_filename, File::kWriteTruncate);
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
                                     Dart_Handle url,
                                     Dart_Handle import_map) {
  if (!Dart_IsLibrary(library)) {
    return Dart_Error("not a library");
  }
  if (!Dart_IsString8(url)) {
    return Dart_Error("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
  bool is_dart_extension_url = DartUtils::IsDartExtensionSchemeURL(url_string);
  if (tag == kCanonicalizeUrl) {
    // If this is a Dart Scheme URL then it is not modified as it will be
    // handled by the VM internally.
    if (is_dart_scheme_url) {
      return url;
    }
    // Resolve the url within the context of the library's URL.
    Dart_Handle builtin_lib = Builtin::LoadLibrary(Builtin::kBuiltinLibrary);
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    Dart_Handle dart_args[2];
    dart_args[0] = library_url;
    dart_args[1] = url;
    return Dart_Invoke(
        builtin_lib, Dart_NewString("_resolveUri"), 2, dart_args);
  }
  if (is_dart_scheme_url) {
    ASSERT(tag == kImportTag);
    // Handle imports of other built-in libraries present in the SDK.
    if (DartUtils::IsDartIOLibURL(url_string)) {
      return Builtin::LoadLibrary(Builtin::kIOLibrary);
    } else if (DartUtils::IsDartJsonLibURL(url_string)) {
      return Builtin::LoadLibrary(Builtin::kJsonLibrary);
    } else if (DartUtils::IsDartUriLibURL(url_string)) {
      return Builtin::LoadLibrary(Builtin::kUriLibrary);
    } else if (DartUtils::IsDartUtfLibURL(url_string)) {
      return Builtin::LoadLibrary(Builtin::kUtfLibrary);
    } else {
      return Dart_Error("Do not know how to load '%s'", url_string);
    }
  } else {
    // Get the file path out of the url.
    Dart_Handle builtin_lib = Builtin::LoadLibrary(Builtin::kBuiltinLibrary);
    Dart_Handle dart_args[1];
    dart_args[0] = url;
    Dart_Handle file_path = Dart_Invoke(
        builtin_lib, Dart_NewString("_filePathFromUri"), 1, dart_args);
    if (Dart_IsError(file_path)) {
      return file_path;
    }
    Dart_StringToCString(file_path, &url_string);
  }
  if (is_dart_extension_url) {
    if (tag != kImportTag) {
      return Dart_Error("Dart extensions must use import: '%s'", url_string);
    }
    return Extensions::LoadExtension(url_string, library);
  }
  result = DartUtils::LoadSource(NULL,
                                 library,
                                 url,
                                 tag,
                                 url_string,
                                 import_map);
  if (!Dart_IsError(result) && (tag == kImportTag)) {
    Builtin::ImportLibrary(result, Builtin::kBuiltinLibrary);
  }
  return result;
}


static Dart_Handle LoadScript(Dart_Handle builtin_lib,
                              CommandLineOptions* map) {
  Dart_Handle dart_args[3];
  dart_args[0] = Dart_NewString(original_working_directory);
  dart_args[1] = Dart_NewString(original_script_name);
#if !defined(TARGET_OS_WINDOWS)
  dart_args[2] = Dart_False();
#else  // !defined(TARGET_OS_WINDOWS)
  dart_args[2] = Dart_True();
#endif  // !defined(TARGET_OS_WINDOWS)
  Dart_Handle script_url = Dart_Invoke(
      builtin_lib, Dart_NewString("_resolveScriptUri"), 3, dart_args);
  if (Dart_IsError(script_url)) {
    fprintf(stderr, "%s", Dart_GetError(script_url));
    return script_url;
  }
  if (original_script_url == NULL) {
    const char* script_url_cstr;
    Dart_StringToCString(script_url, &script_url_cstr);
    original_script_url = strdup(script_url_cstr);
  }
  dart_args[0] = script_url;
  Dart_Handle script_path = Dart_Invoke(
      builtin_lib, Dart_NewString("_filePathFromUri"), 1, dart_args);
  if (Dart_IsError(script_path)) {
    return script_path;
  }
  const char* script_path_cstr;
  Dart_StringToCString(script_path, &script_path_cstr);
  Dart_Handle source = DartUtils::ReadStringFromFile(script_path_cstr);
  if (Dart_IsError(source)) {
    return source;
  }
  intptr_t length =  (map == NULL) ? 0 : map->count();
  Dart_Handle import_map = Dart_NewList(length * 2);
  for (intptr_t i = 0; i < length; i++) {
    ASSERT(map->GetArgument(i) != NULL);
    char* name = strdup(map->GetArgument(i));
    ASSERT(name != NULL);
    char* map_name = strchr(name, ',');
    intptr_t index = i * 2;
    if (map_name != NULL) {
      *map_name = '\0';
      map_name += 1;
      Dart_ListSetAt(import_map, index, Dart_NewString(name));
      Dart_ListSetAt(import_map, (index + 1), Dart_NewString(map_name));
    } else {
      Dart_ListSetAt(import_map, index, Dart_NewString(name));
      Dart_ListSetAt(import_map, (index + 1), Dart_NewString(""));
    }
    free(name);
  }
  return Dart_LoadScript(script_url, source, LibraryTagHandler, import_map);
}


// Returns true on success, false on failure.
static bool CreateIsolateAndSetup(const char* name_prefix,
                                  void* data, char** error) {
  Dart_Isolate isolate =
      Dart_CreateIsolate(name_prefix, snapshot_buffer, data, error);
  if (isolate == NULL) {
    return false;
  }

  Dart_EnterScope();

  if (snapshot_buffer != NULL) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
  }

  // Prepare builtin and its dependent libraries for use to resolve URIs.
  Dart_Handle uri_lib = Builtin::LoadLibrary(Builtin::kUriLibrary);
  if (Dart_IsError(uri_lib)) {
    *error = strdup(Dart_GetError(uri_lib));
    return false;
  }
  Dart_Handle builtin_lib = Builtin::LoadLibrary(Builtin::kBuiltinLibrary);
  if (Dart_IsError(builtin_lib)) {
    *error = strdup(Dart_GetError(builtin_lib));
    return false;
  }
  Dart_Handle library = Dart_LibraryImportLibrary(builtin_lib, uri_lib);
  if (Dart_IsError(library)) {
    *error = strdup(Dart_GetError(library));
    return false;
  }

  if (package_root != NULL) {
    Dart_Handle dart_args[1];

    Dart_Handle handle = Dart_NewString(package_root);
    if (Dart_IsError(handle)) {
      *error = strdup(Dart_GetError(handle));
      return false;
    }
    dart_args[0] = handle;

    Dart_Handle result = Dart_Invoke(builtin_lib,
        Dart_NewString("_setPackageRoot"), 1, dart_args);
    if (Dart_IsError(result)) {
      *error = strdup(Dart_GetError(result));
      return false;
    }
  }

  // Load the specified application script into the newly created isolate.
  library = LoadScript(builtin_lib, import_map_options);
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
             original_script_name);
    *error = strdup(errbuf);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return false;
  }
  // Implicitly import builtin into app.
  Builtin::ImportLibrary(library, Builtin::kBuiltinLibrary);
  Dart_ExitScope();
  return true;
}


static void PrintUsage() {
  fprintf(stderr,
          "dart [<vm-flags>] <dart-script-file> [<dart-options>]\n");
}


static Dart_Handle SetBreakpoint(const char* breakpoint_at,
                                 Dart_Handle library) {
  Dart_Handle result;
  if (strchr(breakpoint_at, ':')) {
    char* bpt_line = strdup(breakpoint_at);
    char* colon = strchr(bpt_line, ':');
    ASSERT(colon != NULL);
    *colon = '\0';
    Dart_Handle url = Dart_NewString(bpt_line);
    Dart_Handle line_number = Dart_NewInteger(atoi(colon + 1));
    free(bpt_line);
    Dart_Breakpoint bpt;
    result = Dart_SetBreakpointAtLine(url, line_number, &bpt);
  } else {
    char* bpt_function = strdup(breakpoint_at);
    Dart_Handle class_name;
    Dart_Handle function_name;
    char* dot = strchr(bpt_function, '.');
    if (dot == NULL) {
      class_name = Dart_NewString("");
      function_name = Dart_NewString(breakpoint_at);
    } else {
      *dot = '\0';
      class_name = Dart_NewString(bpt_function);
      function_name = Dart_NewString(dot + 1);
    }
    free(bpt_function);
    Dart_Breakpoint bpt;
    result = Dart_SetBreakpointAtEntry(
                 library, class_name, function_name, &bpt);
  }
  return result;
}


char* BuildIsolateName(const char* script_name,
                       const char* func_name) {
  // Skip past any slashes in the script name.
  const char* last_slash = strrchr(script_name, '/');
  if (last_slash != NULL) {
    script_name = last_slash + 1;
  }

  const char* kFormat = "%s/%s";
  intptr_t len = strlen(script_name) + strlen(func_name) + 2;
  char* buffer = new char[len];
  ASSERT(buffer != NULL);
  snprintf(buffer, len, kFormat, script_name, func_name);
  return buffer;
}


static const int kErrorExitCode = 255;  // Indicates we encountered an error.


static int ErrorExit(const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  vfprintf(stderr, format, arguments);
  va_end(arguments);

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  free(const_cast<char*>(original_script_name));
  free(const_cast<char*>(original_working_directory));
  free(const_cast<char*>(original_script_url));

  return kErrorExitCode;
}


int main(int argc, char** argv) {
  char* script_name;
  CommandLineOptions vm_options(argc);
  CommandLineOptions dart_options(argc);
  CommandLineOptions import_map(argc);
  import_map_options = &import_map;

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
    return kErrorExitCode;
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  Dart_Initialize(CreateIsolateAndSetup, NULL);

  original_script_name = strdup(script_name);
  original_working_directory = Directory::Current();

  // Call CreateIsolateAndSetup which creates an isolate and loads up
  // the specified application script.
  char* error = NULL;
  char* isolate_name = BuildIsolateName(original_script_name, "main");
  if (!CreateIsolateAndSetup(isolate_name, NULL, &error)) {
    fprintf(stderr, "%s\n", error);
    free(const_cast<char*>(original_script_name));
    free(const_cast<char*>(original_working_directory));
    free(error);
    delete [] isolate_name;
    return 255;  // Indicates we encountered an error.
  }
  delete [] isolate_name;

  Dart_Isolate isolate = Dart_CurrentIsolate();
  ASSERT(isolate != NULL);
  Dart_Handle result;

  Dart_EnterScope();

  if (has_compile_all) {
    result = Dart_CompileAll();
    if (Dart_IsError(result)) {
      return ErrorExit("%s\n", Dart_GetError(result));
    }
  }

  // Create a dart options object that can be accessed from dart code.
  Dart_Handle options_result =
      SetupRuntimeOptions(&dart_options, original_script_name);
  if (Dart_IsError(options_result)) {
    return ErrorExit("%s\n", Dart_GetError(options_result));
  }
  // Lookup the library of the main script.
  Dart_Handle script_url = Dart_NewString(original_script_url);
  Dart_Handle library = Dart_LookupLibrary(script_url);
  if (Dart_IsError(library)) {
    return ErrorExit("%s\n", Dart_GetError(library));
  }
  // Set debug breakpoint if specified on the command line.
  if (breakpoint_at != NULL) {
    result = SetBreakpoint(breakpoint_at, library);
    if (Dart_IsError(result)) {
      return ErrorExit("Error setting breakpoint at '%s': %s\n",
          breakpoint_at,
          Dart_GetError(result));
    }
  }

  // Start the debugger wire protocol handler if necessary.
  if (start_debugger) {
    ASSERT(debug_port != 0);
    DebuggerConnectionHandler::StartHandler(debug_ip, debug_port);
  }

  // Lookup and invoke the top level main function.
  result = Dart_Invoke(library, Dart_NewString("main"), 0, NULL);
  if (Dart_IsError(result)) {
    return ErrorExit("%s\n", Dart_GetError(result));
  }
  // Keep handling messages until the last active receive port is closed.
  result = Dart_RunLoop();
  if (Dart_IsError(result)) {
    return ErrorExit("%s\n", Dart_GetError(result));
  }

  Dart_ExitScope();
  // Dump symbol information for the profiler.
  DumpPprofSymbolInfo();
  // Shutdown the isolate.
  Dart_ShutdownIsolate();
  // Terminate process exit-code handler.
  Process::TerminateExitCodeHandler();

  free(const_cast<char*>(original_script_name));
  free(const_cast<char*>(original_working_directory));
  free(const_cast<char*>(original_script_url));

  return 0;
}
