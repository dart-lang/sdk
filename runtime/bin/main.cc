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
#include "bin/isolate_data.h"
#include "bin/log.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "platform/globals.h"

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.
extern const uint8_t* snapshot_buffer;


// Global state that indicates whether perf_events symbol information
// is to be generated or not.
static File* perf_events_symbols_file = NULL;


// Global state that indicates whether pprof symbol information is
// to be generated or not.
static const char* generate_pprof_symbols_filename = NULL;


// Global state that stores a pointer to the application script snapshot.
static bool use_script_snapshot = false;
static File* snapshot_file = NULL;

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


static bool has_version_option = false;
static bool ProcessVersionOption(const char* arg) {
  if (*arg != '\0') {
    return false;
  }
  has_version_option = true;
  return true;
}


static bool has_help_option = false;
static bool ProcessHelpOption(const char* arg) {
  if (*arg != '\0') {
    return false;
  }
  has_help_option = true;
  return true;
}


static bool has_verbose_option = false;
static bool ProcessVerboseOption(const char* arg) {
  if (*arg != '\0') {
    return false;
  }
  has_verbose_option = true;
  return true;
}


static bool ProcessBreakpointOption(const char* funcname) {
  ASSERT(funcname != NULL);
  breakpoint_at = funcname;
  return true;
}


static bool ProcessPackageRootOption(const char* arg) {
  ASSERT(arg != NULL);
  package_root = arg;
  return true;
}


static bool ProcessCompileAllOption(const char* arg) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  has_compile_all = true;
  return true;
}


static bool ProcessDebugOption(const char* port) {
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
    Log::PrintErr("unrecognized --debug option syntax. "
                    "Use --debug[:<port number>]\n");
    return false;
  }
  breakpoint_at = "main";
  start_debugger = true;
  return true;
}


static bool ProcessPerfEventsOption(const char* option) {
  ASSERT(option != NULL);
  if (perf_events_symbols_file == NULL) {
    // TODO(cshapiro): eliminate the #ifdef by moving this code to a
    // Linux specific source file.
#if defined(TARGET_OS_LINUX)
    const char* format = "/tmp/perf-%ld.map";
    intptr_t pid = Process::CurrentProcessId();
    intptr_t len = snprintf(NULL, 0, format, pid);
    char* filename = new char[len + 1];
    snprintf(filename, len + 1, format, pid);
    perf_events_symbols_file = File::Open(filename, File::kWriteTruncate);
    ASSERT(perf_events_symbols_file != NULL);
    delete[] filename;
#endif
  }
  return true;
}


static bool ProcessPprofOption(const char* filename) {
  ASSERT(filename != NULL);
  generate_pprof_symbols_filename = filename;
  return true;
}


static bool ProcessScriptSnapshotOption(const char* filename) {
  if (filename != NULL && strlen(filename) != 0) {
    use_script_snapshot = true;
    snapshot_file = File::Open(filename, File::kRead);
  }
  return true;
}


static struct {
  const char* option_name;
  bool (*process)(const char* option);
} main_options[] = {
  // Standard options shared with dart2js.
  { "--version", ProcessVersionOption },
  { "--help", ProcessHelpOption },
  { "-h", ProcessHelpOption },
  { "--verbose", ProcessVerboseOption },
  { "-v", ProcessVerboseOption },
  { "--package-root=", ProcessPackageRootOption },
  { "-p", ProcessPackageRootOption },
  // VM specific options to the standalone dart program.
  { "--break_at=", ProcessBreakpointOption },
  { "--compile_all", ProcessCompileAllOption },
  { "--debug", ProcessDebugOption },
  { "--generate_perf_events_symbols", ProcessPerfEventsOption },
  { "--generate_pprof_symbols=", ProcessPprofOption },
  { "--use_script_snapshot=", ProcessScriptSnapshotOption },
  { NULL, NULL }
};


static bool ProcessMainOptions(const char* option) {
  int i = 0;
  const char* name = main_options[0].option_name;
  while (name != NULL) {
    int length = strlen(name);
    if (strncmp(option, name, length) == 0) {
      return main_options[i].process(option + length);
    }
    i += 1;
    name = main_options[i].option_name;
  }
  return false;
}


static void WriteToPerfEventsFile(const char* buffer, int64_t num_bytes) {
  ASSERT(perf_events_symbols_file != NULL);
  perf_events_symbols_file->WriteFully(buffer, num_bytes);
}

// Convert all the arguments to UTF8. On Windows, the arguments are
// encoded in the current code page and not UTF8.
//
// Returns true if the arguments are converted. In that case
// each of the arguments need to be deallocated using free.
static bool Utf8ConvertArgv(int argc, char** argv) {
  bool result = false;
  for (int i = 0; i < argc; i++) {
    char* arg = argv[i];
    argv[i] = StringUtils::SystemStringToUtf8(arg);
    if (i == 0) {
      result = argv[i] != arg;
    } else {
      ASSERT(result == (argv[i] != arg));
    }
  }
  return result;
}


// Parse out the command line arguments. Returns -1 if the arguments
// are incorrect, 0 otherwise.
static int ParseArguments(int argc,
                          char** argv,
                          CommandLineOptions* vm_options,
                          char** executable_name,
                          char** script_name,
                          CommandLineOptions* dart_options,
                          bool* print_flags_seen) {
  const char* kPrefix = "--";
  const intptr_t kPrefixLen = strlen(kPrefix);

  // Get the executable name.
  *executable_name = argv[0];

  // Start the rest after the executable name.
  int i = 1;

  // Parse out the vm options.
  while (i < argc) {
    if (ProcessMainOptions(argv[i])) {
      i++;
    } else {
      // Check if this flag is a potentially valid VM flag.
      if (!IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
        break;
      }
      const char* kPrintFlags1 = "--print-flags";
      const char* kPrintFlags2 = "--print_flags";
      if ((strncmp(argv[i], kPrintFlags1, strlen(kPrintFlags1)) == 0) ||
          (strncmp(argv[i], kPrintFlags2, strlen(kPrintFlags2)) == 0)) {
        *print_flags_seen = true;
      }
      vm_options->AddArgument(argv[i]);
      i++;
    }
  }

  if (perf_events_symbols_file != NULL) {
    Dart_InitPerfEventsSupport(&WriteToPerfEventsFile);
  }

  if (generate_pprof_symbols_filename != NULL) {
    Dart_InitPprofSupport();
  }

  // Get the script name.
  if (i < argc) {
    *script_name = argv[i];
    i++;
  } else {
    return -1;
  }

  // Parse out options to be passed to dart main.
  while (i < argc) {
    dart_options->AddArgument(argv[i]);
    i++;
  }

  return 0;
}


static Dart_Handle SetupRuntimeOptions(CommandLineOptions* options,
                                       const char* executable_name,
                                       const char* script_name) {
  int options_count = options->count();
  Dart_Handle dart_executable = DartUtils::NewString(executable_name);
  if (Dart_IsError(dart_executable)) {
    return dart_executable;
  }
  Dart_Handle dart_script = DartUtils::NewString(script_name);
  if (Dart_IsError(dart_script)) {
    return dart_script;
  }
  Dart_Handle dart_arguments = Dart_NewList(options_count);
  if (Dart_IsError(dart_arguments)) {
    return dart_arguments;
  }
  for (int i = 0; i < options_count; i++) {
    Dart_Handle argument_value =
        DartUtils::NewString(options->GetArgument(i));
    if (Dart_IsError(argument_value)) {
      return argument_value;
    }
    Dart_Handle result = Dart_ListSetAt(dart_arguments, i, argument_value);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  Dart_Handle core_lib_url = DartUtils::NewString("dart:core");
  if (Dart_IsError(core_lib_url)) {
    return core_lib_url;
  }
  Dart_Handle core_lib = Dart_LookupLibrary(core_lib_url);
  if (Dart_IsError(core_lib)) {
    return core_lib;
  }
  Dart_Handle runtime_options_class_name =
      DartUtils::NewString("_OptionsImpl");
  if (Dart_IsError(runtime_options_class_name)) {
    return runtime_options_class_name;
  }
  Dart_Handle runtime_options_class = Dart_GetClass(
      core_lib, runtime_options_class_name);
  if (Dart_IsError(runtime_options_class)) {
    return runtime_options_class;
  }
  Dart_Handle executable_name_name =
      DartUtils::NewString("_nativeExecutable");
  if (Dart_IsError(executable_name_name)) {
    return executable_name_name;
  }
  Dart_Handle set_executable_name =
      Dart_SetField(runtime_options_class,
                    executable_name_name,
                    dart_executable);
  if (Dart_IsError(set_executable_name)) {
    return set_executable_name;
  }
  Dart_Handle script_name_name = DartUtils::NewString("_nativeScript");
  if (Dart_IsError(script_name_name)) {
    return script_name_name;
  }
  Dart_Handle set_script_name =
      Dart_SetField(runtime_options_class, script_name_name, dart_script);
  if (Dart_IsError(set_script_name)) {
    return set_script_name;
  }
  Dart_Handle native_name = DartUtils::NewString("_nativeArguments");
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


#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    *error = strdup(Dart_GetError(result));                                    \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return false;                                                              \
  }                                                                            \


// Returns true on success, false on failure.
static bool CreateIsolateAndSetupHelper(const char* script_uri,
                                        const char* main,
                                        void* data,
                                        char** error) {
  Dart_Isolate isolate =
      Dart_CreateIsolate(script_uri, main, snapshot_buffer, data, error);
  if (isolate == NULL) {
    return false;
  }

  Dart_EnterScope();

  if (snapshot_buffer != NULL) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
  }

  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(DartUtils::LibraryTagHandler);
  CHECK_RESULT(result);

  // Load the specified application script into the newly created isolate.
  Dart_Handle library;
  if (use_script_snapshot) {
    if (snapshot_file == NULL) {
      use_script_snapshot = false;
      *error = strdup("Invalid script snapshot file name specified");
      Dart_ExitScope();
      Dart_ShutdownIsolate();
      return false;
    }
    size_t len = snapshot_file->Length();
    uint8_t* buffer = reinterpret_cast<uint8_t*>(malloc(len));
    if (buffer == NULL) {
      delete snapshot_file;
      snapshot_file = NULL;
      use_script_snapshot = false;
      *error = strdup("Unable to read contents of script snapshot file");
      Dart_ExitScope();
      Dart_ShutdownIsolate();
      return false;
    }
    // Prepare for script loading by setting up the 'print' and 'timer'
    // closures and setting up 'package root' for URI resolution.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    DartUtils::PrepareForScriptLoading(package_root, builtin_lib);

    snapshot_file->ReadFully(buffer, len);
    library = Dart_LoadScriptFromSnapshot(buffer);
    free(buffer);
    delete snapshot_file;
    snapshot_file = NULL;
    use_script_snapshot = false;  // No further usage of script snapshots.
  } else {
    // Prepare builtin and its dependent libraries for use to resolve URIs.
    Dart_Handle uri_lib = Builtin::LoadAndCheckLibrary(Builtin::kUriLibrary);
    CHECK_RESULT(uri_lib);
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    CHECK_RESULT(builtin_lib);

    // Prepare for script loading by setting up the 'print' and 'timer'
    // closures and setting up 'package root' for URI resolution.
    result = DartUtils::PrepareForScriptLoading(package_root, builtin_lib);
    CHECK_RESULT(result);

    library = DartUtils::LoadScript(script_uri, builtin_lib);
  }
  CHECK_RESULT(library);
  if (!Dart_IsLibrary(library)) {
    char errbuf[256];
    snprintf(errbuf, sizeof(errbuf),
             "Expected a library when loading script: %s",
             script_uri);
    *error = strdup(errbuf);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return false;
  }
  Dart_ExitScope();
  return true;
}


static bool CreateIsolateAndSetup(const char* script_uri,
                                  const char* main,
                                  void* data, char** error) {
  return CreateIsolateAndSetupHelper(script_uri,
                                     main,
                                     new IsolateData(),
                                     error);
}


static void PrintVersion() {
  Log::PrintErr("Dart VM version: %s\n", Dart_VersionString());
}


static void PrintUsage() {
  Log::PrintErr(
      "Usage: dart [<vm-flags>] <dart-script-file> [<dart-options>]\n"
      "\n"
      "Executes the Dart script passed as <dart-script-file>.\n"
      "\n");
  if (!has_verbose_option) {
    Log::PrintErr(
"Common options:\n"
"--checked Insert runtime type checks and enable assertions (checked mode).\n"
"--version Print the VM version.\n"
"--help    Display this message (add --verbose for information about all\n"
"          VM options).\n");
  } else {
    Log::PrintErr(
"Supported options:\n"
"--checked\n"
"  Insert runtime type checks and enable assertions (checked mode).\n"
"\n"
"--version\n"
"  Print the VM version.\n"
"\n"
"--help\n"
"  Display this message (add --verbose for information about all VM options).\n"
"\n"
"--package-root=<path>\n"
"  Where to find packages, that is, \"package:...\" imports.\n"
"\n"
"--debug[:<port number>]\n"
"  enables debugging and listens on specified port for debugger connections\n"
"  (default port number is 5858)\n"
"\n"
"--break_at=<location>\n"
"  sets a breakpoint at specified location where <location> is one of :\n"
"  url:<line_num> e.g. test.dart:10\n"
"  [<class_name>.]<function_name> e.g. B.foo\n"
"\n"
"--use_script_snapshot=<file_name>\n"
"  executes Dart script present in the specified snapshot file\n"
"\n"
"The following options are only used for VM development and may\n"
"be changed in any future version:\n");
    const char* print_flags = "--print_flags";
    Dart_SetVMFlags(1, &print_flags);
  }
}


static Dart_Handle SetBreakpoint(const char* breakpoint_at,
                                 Dart_Handle library) {
  Dart_Handle result;
  if (strchr(breakpoint_at, ':')) {
    char* bpt_line = strdup(breakpoint_at);
    char* colon = strchr(bpt_line, ':');
    ASSERT(colon != NULL);
    *colon = '\0';
    Dart_Handle url = DartUtils::NewString(bpt_line);
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
      class_name = DartUtils::NewString("");
      function_name = DartUtils::NewString(breakpoint_at);
    } else {
      *dot = '\0';
      class_name = DartUtils::NewString(bpt_function);
      function_name = DartUtils::NewString(dot + 1);
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
  Log::VPrintErr(format, arguments);
  va_end(arguments);
  fflush(stderr);

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  return kErrorExitCode;
}


static void ShutdownIsolate(void* callback_data) {
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  EventHandler* handler = isolate_data->event_handler;
  if (handler != NULL) handler->Shutdown();
  delete isolate_data;
}


int main(int argc, char** argv) {
  char* executable_name;
  char* script_name;
  CommandLineOptions vm_options(argc);
  CommandLineOptions dart_options(argc);
  bool print_flags_seen = false;

  // Perform platform specific initialization.
  if (!Platform::Initialize()) {
    Log::PrintErr("Initialization failed\n");
  }

  // On Windows, the argv strings are code page encoded and not
  // utf8. We need to convert them to utf8.
  bool argv_converted = Utf8ConvertArgv(argc, argv);

  // Parse command line arguments.
  if (ParseArguments(argc,
                     argv,
                     &vm_options,
                     &executable_name,
                     &script_name,
                     &dart_options,
                     &print_flags_seen) < 0) {
    if (has_help_option) {
      PrintUsage();
      return 0;
    } else if (has_version_option) {
      PrintVersion();
      return 0;
    } else if (print_flags_seen) {
      // Will set the VM flags, print them out and then we exit as no
      // script was specified on the command line.
      Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
      return 0;
    } else {
      PrintUsage();
      return kErrorExitCode;
    }
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  if (!Dart_Initialize(CreateIsolateAndSetup,
                       NULL,
                       NULL,
                       ShutdownIsolate)) {
    fprintf(stderr, "%s", "VM initialization failed\n");
    fflush(stderr);
    return kErrorExitCode;
  }

  DartUtils::SetOriginalWorkingDirectory();

  // Start the debugger wire protocol handler if necessary.
  if (start_debugger) {
    ASSERT(debug_port != 0);
    DebuggerConnectionHandler::StartHandler(debug_ip, debug_port);
  }

  // Call CreateIsolateAndSetup which creates an isolate and loads up
  // the specified application script.
  char* error = NULL;
  char* isolate_name = BuildIsolateName(script_name, "main");
  if (!CreateIsolateAndSetupHelper(script_name,
                                   "main",
                                   new IsolateData(),
                                   &error)) {
    Log::PrintErr("%s\n", error);
    free(error);
    delete [] isolate_name;
    return kErrorExitCode;  // Indicates we encountered an error.
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
      SetupRuntimeOptions(&dart_options, executable_name, script_name);
  if (Dart_IsError(options_result)) {
    return ErrorExit("%s\n", Dart_GetError(options_result));
  }
  // Lookup the library of the root script.
  Dart_Handle library = Dart_RootLibrary();
  if (Dart_IsNull(library)) {
    return ErrorExit("Unable to find root library for '%s'\n",
                     script_name);
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

  // Lookup and invoke the top level main function.
  result = Dart_Invoke(library, DartUtils::NewString("main"), 0, NULL);
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
  // Free copied argument strings if converted.
  if (argv_converted) {
    for (int i = 0; i < argc; i++) free(argv[i]);
  }

  return 0;
}
