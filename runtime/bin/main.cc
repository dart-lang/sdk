// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"
#include "include/dart_tools_api.h"

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
#include "bin/thread.h"
#include "bin/vmservice_impl.h"
#include "platform/globals.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

// vm_isolate_snapshot_buffer points to a snapshot for the vm isolate if we
// link in a snapshot otherwise it is initialized to NULL.
extern const uint8_t* vm_isolate_snapshot_buffer;

// isolate_snapshot_buffer points to a snapshot for an isolate if we link in a
// snapshot otherwise it is initialized to NULL.
extern const uint8_t* isolate_snapshot_buffer;

// Global state that stores a pointer to the application script snapshot.
static bool generate_script_snapshot = false;
static const char* snapshot_filename = NULL;


// Global state that indicates whether there is a debug breakpoint.
// This pointer points into an argv buffer and does not need to be
// free'd.
static const char* breakpoint_at = NULL;


// Global state that indicates whether we should open a connection
// and listen for a debugger to connect.
static bool start_debugger = false;
static const char* debug_ip = NULL;
static int debug_port = -1;
static const char* DEFAULT_DEBUG_IP = "127.0.0.1";
static const int DEFAULT_DEBUG_PORT = 5858;

// Value of the --package-root flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* commandline_package_root = NULL;

// Value of the --packages flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* commandline_packages_file = NULL;


// Global flag that is used to indicate that we want to compile all the
// dart functions and not run anything.
static bool has_compile_all = false;


// Global flag that is used to indicate that we want to compile all the
// dart functions before running main and not compile anything thereafter.
static bool has_gen_precompiled_snapshot = false;


// Global flag that is used to indicate that we want to run from a precompiled
// snapshot.
static bool has_run_precompiled_snapshot = false;


extern const char* kPrecompiledLibraryName;
extern const char* kPrecompiledSymbolName;
static const char* kPrecompiledVmIsolateName = "precompiled.vmisolate";
static const char* kPrecompiledIsolateName = "precompiled.isolate";
static const char* kPrecompiledInstructionsName = "precompiled.S";


// Global flag that is used to indicate that we want to trace resolution of
// URIs and the loading of libraries, parts and scripts.
static bool has_trace_loading = false;


static const char* DEFAULT_VM_SERVICE_SERVER_IP = "127.0.0.1";
static const int DEFAULT_VM_SERVICE_SERVER_PORT = 8181;
// VM Service options.
static bool start_vm_service = false;
static const char* vm_service_server_ip = DEFAULT_VM_SERVICE_SERVER_IP;
// The 0 port is a magic value which results in the first available port
// being allocated.
static int vm_service_server_port = -1;


// Exit code indicating an API error.
static const int kApiErrorExitCode = 253;
// Exit code indicating a compilation error.
static const int kCompilationErrorExitCode = 254;
// Exit code indicating an unhandled error that is not a compilation error.
static const int kErrorExitCode = 255;

static void ErrorExit(int exit_code, const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  Log::VPrintErr(format, arguments);
  va_end(arguments);
  fflush(stderr);

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  Dart_Cleanup();

  DebuggerConnectionHandler::StopHandler();
  // TODO(zra): Stop the EventHandler once thread shutdown is enabled.
  // EventHandler::Stop();
  exit(exit_code);
}


// The environment provided through the command line using -D options.
static dart::HashMap* environment = NULL;

static bool IsValidFlag(const char* name,
                        const char* prefix,
                        intptr_t prefix_length) {
  intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}


static bool has_version_option = false;
static bool ProcessVersionOption(const char* arg,
                                 CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  has_version_option = true;
  return true;
}


static bool has_help_option = false;
static bool ProcessHelpOption(const char* arg, CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  has_help_option = true;
  return true;
}


static bool has_verbose_option = false;
static bool ProcessVerboseOption(const char* arg,
                                 CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  has_verbose_option = true;
  return true;
}


static bool ProcessBreakpointOption(const char* funcname,
                                    CommandLineOptions* vm_options) {
  ASSERT(funcname != NULL);
  if (*funcname == '\0') {
    return false;
  }
  breakpoint_at = funcname;
  return true;
}


static bool ProcessPackageRootOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '\0' || *arg == '-') {
    return false;
  }
  commandline_package_root = arg;
  return true;
}


static bool ProcessPackagesOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '\0' || *arg == '-') {
    return false;
  }
  commandline_packages_file = arg;
  return true;
}


static void* GetHashmapKeyFromString(char* key) {
  return reinterpret_cast<void*>(key);
}


static bool ExtractPortAndIP(const char *option_value,
                             int *out_port,
                             const char **out_ip,
                             int default_port,
                             const char *default_ip) {
  // [option_value] has to be one of the following formats:
  //   - ""
  //   - ":8181"
  //   - "=8181"
  //   - ":8181/192.168.0.1"
  //   - "=8181/192.168.0.1"

  if (*option_value== '\0') {
    *out_ip = default_ip;
    *out_port = default_port;
    return true;
  }

  if ((*option_value != '=') && (*option_value != ':')) {
    return false;
  }

  int port = atoi(option_value + 1);
  const char *slash = strstr(option_value, "/");
  if (slash == NULL) {
    *out_ip = default_ip;
    *out_port = port;
    return true;
  }

  int _, n;
  if (sscanf(option_value + 1, "%d/%d.%d.%d.%d%n",  // NOLINT(runtime/printf)
             &_, &_, &_, &_, &_, &n)) {
    if (option_value[1 + n] == '\0') {
      *out_ip = slash + 1;
      *out_port = port;
      return true;
    }
  }
  return false;
}


static bool ProcessEnvironmentOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '\0') {
    // Ignore empty -D option.
    Log::PrintErr("No arguments given to -D option\n");
    return true;
  }
  if (environment == NULL) {
    environment = new HashMap(&HashMap::SameStringValue, 4);
  }
  // Split the name=value part of the -Dname=value argument.
  char* name;
  char* value = NULL;
  const char* equals_pos = strchr(arg, '=');
  if (equals_pos == NULL) {
    // No equal sign (name without value) currently not supported.
    Log::PrintErr("No value given to -D option\n");
    return false;
  } else {
    int name_len = equals_pos - arg;
    if (name_len == 0) {
      Log::PrintErr("No name given to -D option\n");
      return false;
    }
    // Split name=value into name and value.
    name = reinterpret_cast<char*>(malloc(name_len + 1));
    strncpy(name, arg, name_len);
    name[name_len] = '\0';
    value = strdup(equals_pos + 1);
  }
  HashMap::Entry* entry = environment->Lookup(
      GetHashmapKeyFromString(name), HashMap::StringHash(name), true);
  ASSERT(entry != NULL);  // Lookup adds an entry if key not found.
  entry->value = value;
  return true;
}


static bool ProcessCompileAllOption(const char* arg,
                                    CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  has_compile_all = true;
  return true;
}


static bool ProcessGenPrecompiledSnapshotOption(
    const char* arg,
    CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  // Ensure that we are not already running using a full snapshot.
  if (isolate_snapshot_buffer != NULL) {
    Log::PrintErr("Precompiled snapshots must be generated with"
                  " dart_no_snapshot.");
    return false;
  }
  has_gen_precompiled_snapshot = true;
  vm_options->AddArgument("--precompile");
  return true;
}


static bool ProcessRunPrecompiledSnapshotOption(
    const char* arg,
    CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  has_run_precompiled_snapshot = true;
  vm_options->AddArgument("--precompile");
  return true;
}


static bool ProcessDebugOption(const char* option_value,
                               CommandLineOptions* vm_options) {
  ASSERT(option_value != NULL);
  if (!ExtractPortAndIP(option_value, &debug_port, &debug_ip,
                        DEFAULT_DEBUG_PORT, DEFAULT_DEBUG_IP)) {
    Log::PrintErr("unrecognized --debug option syntax. "
                  "Use --debug[:<port number>[/<IPv4 address>]]\n");
    return false;
  }

  breakpoint_at = "main";
  start_debugger = true;
  return true;
}


static bool ProcessGenScriptSnapshotOption(const char* filename,
                                           CommandLineOptions* vm_options) {
  if (filename != NULL && strlen(filename) != 0) {
    // Ensure that we are already running using a full snapshot.
    if (isolate_snapshot_buffer == NULL) {
      Log::PrintErr("Script snapshots cannot be generated in this version of"
                    " dart\n");
      return false;
    }
    snapshot_filename = filename;
    generate_script_snapshot = true;
    return true;
  }
  return false;
}


static bool ProcessEnableVmServiceOption(const char* option_value,
                                         CommandLineOptions* vm_options) {
  ASSERT(option_value != NULL);

  if (!ExtractPortAndIP(option_value,
                        &vm_service_server_port,
                        &vm_service_server_ip,
                        DEFAULT_VM_SERVICE_SERVER_PORT,
                        DEFAULT_VM_SERVICE_SERVER_IP)) {
    Log::PrintErr("unrecognized --enable-vm-service option syntax. "
                  "Use --enable-vm-service[:<port number>[/<IPv4 address>]]\n");
    return false;
  }

  start_vm_service = true;
  return true;
}


static bool ProcessObserveOption(const char* option_value,
                                 CommandLineOptions* vm_options) {
  ASSERT(option_value != NULL);

  if (!ExtractPortAndIP(option_value,
                        &vm_service_server_port,
                        &vm_service_server_ip,
                        DEFAULT_VM_SERVICE_SERVER_PORT,
                        DEFAULT_VM_SERVICE_SERVER_IP)) {
    Log::PrintErr("unrecognized --observe option syntax. "
                  "Use --observe[:<port number>[/<IPv4 address>]]\n");
    return false;
  }

  start_vm_service = true;

  vm_options->AddArgument("--pause-isolates-on-exit");
  return true;
}


extern bool trace_debug_protocol;
static bool ProcessTraceDebugProtocolOption(const char* arg,
                                            CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  trace_debug_protocol = true;
  return true;
}


static bool ProcessTraceLoadingOption(const char* arg,
                                      CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  has_trace_loading = true;
  return true;
}


static struct {
  const char* option_name;
  bool (*process)(const char* option, CommandLineOptions* vm_options);
} main_options[] = {
  // Standard options shared with dart2js.
  { "--version", ProcessVersionOption },
  { "--help", ProcessHelpOption },
  { "-h", ProcessHelpOption },
  { "--verbose", ProcessVerboseOption },
  { "-v", ProcessVerboseOption },
  { "--package-root=", ProcessPackageRootOption },
  { "--packages=", ProcessPackagesOption },
  { "-D", ProcessEnvironmentOption },
  // VM specific options to the standalone dart program.
  { "--break-at=", ProcessBreakpointOption },
  { "--compile_all", ProcessCompileAllOption },
  { "--gen-precompiled-snapshot", ProcessGenPrecompiledSnapshotOption },
  { "--run-precompiled-snapshot", ProcessRunPrecompiledSnapshotOption },
  { "--debug", ProcessDebugOption },
  { "--snapshot=", ProcessGenScriptSnapshotOption },
  { "--enable-vm-service", ProcessEnableVmServiceOption },
  { "--observe", ProcessObserveOption },
  { "--trace-debug-protocol", ProcessTraceDebugProtocolOption },
  { "--trace-loading", ProcessTraceLoadingOption},
  { NULL, NULL }
};


static bool ProcessMainOptions(const char* option,
                               CommandLineOptions* vm_options) {
  int i = 0;
  const char* name = main_options[0].option_name;
  int option_length = strlen(option);
  while (name != NULL) {
    int length = strlen(name);
    if ((option_length >= length) && (strncmp(option, name, length) == 0)) {
      if (main_options[i].process(option + length, vm_options)) {
        return true;
      }
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
                          CommandLineOptions* dart_options,
                          bool* print_flags_seen,
                          bool* verbose_debug_seen) {
  const char* kPrefix = "--";
  const intptr_t kPrefixLen = strlen(kPrefix);

  // Store the executable name.
  Platform::SetExecutableName(argv[0]);

  // Start the rest after the executable name.
  int i = 1;

  // Parse out the vm options.
  while (i < argc) {
    if (ProcessMainOptions(argv[i], vm_options)) {
      i++;
    } else {
      // Check if this flag is a potentially valid VM flag.
      const char* kChecked = "-c";
      const char* kPackageRoot = "-p";
      if (strncmp(argv[i], kPackageRoot, strlen(kPackageRoot)) == 0) {
        if (!ProcessPackageRootOption(argv[i] + strlen(kPackageRoot),
                                      vm_options)) {
          i++;
          if ((argv[i] == NULL) ||
               !ProcessPackageRootOption(argv[i], vm_options)) {
            Log::PrintErr("Invalid option specification : '%s'\n", argv[i - 1]);
            i++;
            break;
          }
        }
        i++;
        continue;  // '-p' is not a VM flag so don't add to vm options.
      } else if (strncmp(argv[i], kChecked, strlen(kChecked)) == 0) {
        vm_options->AddArgument("--checked");
        i++;
        continue;  // '-c' is not a VM flag so don't add to vm options.
      } else if (!IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
        break;
      }
      // The following two flags are processed by both the embedder and
      // the VM.
      const char* kPrintFlags1 = "--print-flags";
      const char* kPrintFlags2 = "--print_flags";
      const char* kVerboseDebug1 = "--verbose_debug";
      const char* kVerboseDebug2 = "--verbose-debug";
      if ((strncmp(argv[i], kPrintFlags1, strlen(kPrintFlags1)) == 0) ||
          (strncmp(argv[i], kPrintFlags2, strlen(kPrintFlags2)) == 0)) {
        *print_flags_seen = true;
      } else if ((strncmp(argv[i],
                          kVerboseDebug1,
                          strlen(kVerboseDebug1)) == 0) ||
                 (strncmp(argv[i],
                          kVerboseDebug2,
                          strlen(kVerboseDebug2)) == 0)) {
        *verbose_debug_seen = true;
      }
      vm_options->AddArgument(argv[i]);
      i++;
    }
  }

  // The arguments to the VM are at positions 1 through i-1 in argv.
  Platform::SetExecutableArguments(i, argv);

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

  // Verify consistency of arguments.
  if ((commandline_package_root != NULL) &&
      (commandline_packages_file != NULL)) {
    Log::PrintErr("Specifying both a packages directory and a packages "
                  "file is invalid.");
    return -1;
  }

  return 0;
}


static Dart_Handle CreateRuntimeOptions(CommandLineOptions* options) {
  int options_count = options->count();
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
  return dart_arguments;
}


static Dart_Handle EnvironmentCallback(Dart_Handle name) {
  uint8_t* utf8_array;
  intptr_t utf8_len;
  Dart_Handle result = Dart_Null();
  Dart_Handle handle = Dart_StringToUTF8(name, &utf8_array, &utf8_len);
  if (Dart_IsError(handle)) {
    handle = Dart_ThrowException(
        DartUtils::NewDartArgumentError(Dart_GetError(handle)));
  } else {
    char* name_chars = reinterpret_cast<char*>(malloc(utf8_len + 1));
    memmove(name_chars, utf8_array, utf8_len);
    name_chars[utf8_len] = '\0';
    const char* value = NULL;
    if (environment != NULL) {
      HashMap::Entry* entry = environment->Lookup(
          GetHashmapKeyFromString(name_chars),
          HashMap::StringHash(name_chars),
          false);
      if (entry != NULL) {
        value = reinterpret_cast<char*>(entry->value);
      }
    }
    if (value != NULL) {
      result = Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(value),
                                      strlen(value));
    }
    free(name_chars);
  }
  return result;
}


#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    *error = strdup(Dart_GetError(result));                                    \
    *exit_code = Dart_IsCompilationError(result) ? kCompilationErrorExitCode : \
        (Dart_IsApiError(result) ? kApiErrorExitCode : kErrorExitCode);        \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return NULL;                                                               \
  }                                                                            \


// Returns true on success, false on failure.
static Dart_Isolate CreateIsolateAndSetupHelper(const char* script_uri,
                                                const char* main,
                                                const char* package_root,
                                                const char* packages_file,
                                                Dart_IsolateFlags* flags,
                                                char** error,
                                                int* exit_code) {
  ASSERT(script_uri != NULL);
  IsolateData* isolate_data = new IsolateData(script_uri,
                                              package_root,
                                              packages_file);
  Dart_Isolate isolate = NULL;

  isolate = Dart_CreateIsolate(script_uri,
                               main,
                               isolate_snapshot_buffer,
                               flags,
                               isolate_data,
                               error);

  if (isolate == NULL) {
    return NULL;
  }

  Dart_EnterScope();

  if (isolate_snapshot_buffer != NULL) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
  }

  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(DartUtils::LibraryTagHandler);
  CHECK_RESULT(result);

  if (Dart_IsServiceIsolate(isolate)) {
    // If this is the service isolate, load embedder specific bits and return.
    if (!VmService::Setup(vm_service_server_ip, vm_service_server_port)) {
      *error = strdup(VmService::GetErrorMessage());
      return NULL;
    }
    if (has_gen_precompiled_snapshot) {
      result = Dart_Precompile();
      CHECK_RESULT(result);
    } else if (has_compile_all) {
      result = Dart_CompileAll();
      CHECK_RESULT(result);
    }
    Dart_ExitScope();
    Dart_ExitIsolate();
    return isolate;
  }

  // Load the specified application script into the newly created isolate.

  // Prepare builtin and its dependent libraries for use to resolve URIs.
  // The builtin library is part of the core snapshot and would already be
  // available here in the case of script snapshot loading.
  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  CHECK_RESULT(builtin_lib);

  // Prepare for script loading by setting up the 'print' and 'timer'
  // closures and setting up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(package_root,
                                              packages_file,
                                              false,
                                              has_trace_loading,
                                              builtin_lib);
  CHECK_RESULT(result);

  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);

  // Load the script.
  result = DartUtils::LoadScript(script_uri, builtin_lib);
  CHECK_RESULT(result);

  // Run event-loop and wait for script loading to complete.
  result = Dart_RunLoop();
  CHECK_RESULT(result);

  if (isolate_data->load_async_id >= 0) {
    Dart_TimelineAsyncEnd("LoadScript", isolate_data->load_async_id);
  }

  Platform::SetPackageRoot(package_root);

  DartUtils::SetupIOLibrary(script_uri);

  // Make the isolate runnable so that it is ready to handle messages.
  Dart_ExitScope();
  Dart_ExitIsolate();
  bool retval = Dart_IsolateMakeRunnable(isolate);
  if (!retval) {
    *error = strdup("Invalid isolate state - Unable to make it runnable");
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return NULL;
  }

  return isolate;
}

#undef CHECK_RESULT

static Dart_Isolate CreateIsolateAndSetup(const char* script_uri,
                                          const char* main,
                                          const char* package_root,
                                          Dart_IsolateFlags* flags,
                                          void* data, char** error) {
  // The VM should never call the isolate helper with a NULL flags.
  ASSERT(flags != NULL);
  ASSERT(flags->version == DART_FLAGS_CURRENT_VERSION);
  IsolateData* parent_isolate_data = reinterpret_cast<IsolateData*>(data);
  int exit_code = 0;
  if (script_uri == NULL) {
    if (data == NULL) {
      *error = strdup("Invalid 'callback_data' - Unable to spawn new isolate");
      return NULL;
    }
    script_uri = parent_isolate_data->script_url;
    if (script_uri == NULL) {
      *error = strdup("Invalid 'callback_data' - Unable to spawn new isolate");
      return NULL;
    }
  }
  const char* packages_file = NULL;
  if (package_root == NULL) {
    if (parent_isolate_data != NULL) {
      package_root = parent_isolate_data->package_root;
      packages_file = parent_isolate_data->packages_file;
    }
  }
  return CreateIsolateAndSetupHelper(script_uri,
                                     main,
                                     package_root,
                                     packages_file,
                                     flags,
                                     error,
                                     &exit_code);
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
"--checked or -c\n"
"  Insert runtime type checks and enable assertions (checked mode).\n"
"--help or -h\n"
"  Display this message (add -v or --verbose for information about\n"
"  all VM options).\n"
"--package-root=<path> or -p<path>\n"
"  Where to find packages, that is, \"package:...\" imports.\n"
"--packages=<path>\n"
"  Where to find a package spec file.\n"
"--observe[=<port>[/<bind-address>]]\n"
"  Enable the VM service and cause isolates to pause on exit (default port is\n"
"  8181, default bind address is 127.0.0.1). With the default options,\n"
"  Observatory will be available locally at http://127.0.0.1:8181/\n"
"--version\n"
"  Print the VM version.\n");
  } else {
    Log::PrintErr(
"Supported options:\n"
"--checked or -c\n"
"  Insert runtime type checks and enable assertions (checked mode).\n"
"--help or -h\n"
"  Display this message (add -v or --verbose for information about\n"
"  all VM options).\n"
"--package-root=<path> or -p<path>\n"
"  Where to find packages, that is, \"package:...\" imports.\n"
"--packages=<path>\n"
"  Where to find a package spec file.\n"
"--observe[=<port>[/<bind-address>]]\n"
"  Enable the VM service and cause isolates to pause on exit (default port is\n"
"  8181, default bind address is 127.0.0.1). With the default options,\n"
"  Observatory will be available locally at http://127.0.0.1:8181/\n"
"--version\n"
"  Print the VM version.\n"
"\n"
"--debug[:<port number>]\n"
"  enables debugging and listens on specified port for debugger connections\n"
"  (default port number is 5858)\n"
"\n"
"--break-at=<location>\n"
"  sets a breakpoint at specified location where <location> is one of :\n"
"  url:<line_num> e.g. test.dart:10\n"
"  [<class_name>.]<function_name> e.g. B.foo\n"
"\n"
"--snapshot=<file_name>\n"
"  loads Dart script and generates a snapshot in the specified file\n"
"\n"
"--trace-loading\n"
"  enables tracing of library and script loading\n"
"\n"
"--enable-vm-service[:<port number>]\n"
"  enables the VM service and listens on specified port for connections\n"
"  (default port number is 8181)\n"
"\n"
"--noopt\n"
"  run unoptimized code only\n"
"\n"
"The following options are only used for VM development and may\n"
"be changed in any future version:\n");
    const char* print_flags = "--print_flags";
    Dart_SetVMFlags(1, &print_flags);
  }
}


static Dart_Handle SetBreakpoint(const char* breakpoint_at,
                                 Dart_Handle library) {
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
  return Dart_OneTimeBreakAtEntry(library, class_name, function_name);
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

static void DartExitOnError(Dart_Handle error) {
  if (!Dart_IsError(error)) {
    return;
  }
  const int exit_code = Dart_IsCompilationError(error) ?
      kCompilationErrorExitCode : kErrorExitCode;
  ErrorExit(exit_code, "%s\n", Dart_GetError(error));
}


static void ShutdownIsolate(void* callback_data) {
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  delete isolate_data;
}


static const char* ServiceRequestError(Dart_Handle error) {
  TextBuffer buffer(128);
  buffer.Printf("{\"type\":\"Error\",\"text\":\"Internal error %s\"}",
                Dart_GetError(error));
  return buffer.Steal();
}


class DartScope {
 public:
  DartScope() { Dart_EnterScope(); }
  ~DartScope() { Dart_ExitScope(); }
};


static const char* ServiceGetIOHandler(
    const char* method,
    const char** param_keys,
    const char** param_values,
    intptr_t num_params,
    void* user_data) {
  DartScope scope;
  // TODO(ajohnsen): Store the library/function in isolate data or user_data.
  Dart_Handle dart_io_str = Dart_NewStringFromCString("dart:io");
  if (Dart_IsError(dart_io_str)) return ServiceRequestError(dart_io_str);
  Dart_Handle io_lib = Dart_LookupLibrary(dart_io_str);
  if (Dart_IsError(io_lib)) return ServiceRequestError(io_lib);
  Dart_Handle handler_function_name =
      Dart_NewStringFromCString("_serviceObjectHandler");
  if (Dart_IsError(handler_function_name)) {
    return ServiceRequestError(handler_function_name);
  }
  // TODO(johnmccutchan): paths is no longer used.  Update the io
  // _serviceObjectHandler function to use json rpc.
  Dart_Handle paths = Dart_NewList(0);
  Dart_Handle keys = Dart_NewList(num_params);
  Dart_Handle values = Dart_NewList(num_params);
  for (int i = 0; i < num_params; i++) {
    Dart_ListSetAt(keys, i, Dart_NewStringFromCString(param_keys[i]));
    Dart_ListSetAt(values, i, Dart_NewStringFromCString(param_values[i]));
  }
  Dart_Handle args[] = {paths, keys, values};
  Dart_Handle result = Dart_Invoke(io_lib, handler_function_name, 3, args);
  if (Dart_IsError(result)) return ServiceRequestError(result);
  const char *json;
  result = Dart_StringToCString(result, &json);
  if (Dart_IsError(result)) return ServiceRequestError(result);
  return strdup(json);
}


extern bool capture_stdio;
extern bool capture_stdout;
extern bool capture_stderr;
static const char* kStdoutStreamId = "Stdout";
static const char* kStderrStreamId = "Stderr";


static bool ServiceStreamListenCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    capture_stdio = true;
    capture_stdout = true;
    return true;
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    capture_stdio = true;
    capture_stderr = true;
    return true;
  }
  return false;
}


static void ServiceStreamCancelCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    capture_stdout = false;
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    capture_stderr = false;
  }
  capture_stdio = (capture_stdout || capture_stderr);
}


static void WriteSnapshotFile(const char* filename,
                              const uint8_t* buffer,
                              const intptr_t size) {
  File* file = File::Open(filename, File::kWriteTruncate);
  ASSERT(file != NULL);
  if (!file->WriteFully(buffer, size)) {
    Log::PrintErr("Error: Failed to write snapshot file.\n\n");
  }
  delete file;
}


static void ReadSnapshotFile(const char* filename,
                             const uint8_t** buffer) {
  void* file = DartUtils::OpenFile(filename, false);
  if (file == NULL) {
    Log::PrintErr("Error: Failed to open '%s'.\n\n", filename);
    exit(kErrorExitCode);
  }
  intptr_t len = -1;
  DartUtils::ReadFile(buffer, &len, file);
  if (*buffer == NULL || len == -1) {
    Log::PrintErr("Error: Failed to read '%s'.\n\n", filename);
    exit(kErrorExitCode);
  }
  DartUtils::CloseFile(file);
}


static void* LoadLibrarySymbol(const char* libname, const char* symname) {
  void* library = Extensions::LoadExtensionLibrary(libname);
  if (library == NULL) {
    Log::PrintErr("Error: Failed to load library '%s'.\n\n", libname);
    exit(kErrorExitCode);
  }
  void* symbol = Extensions::ResolveSymbol(library, symname);
  if (symbol == NULL) {
    Log::PrintErr("Failed to load symbol '%s'\n", symname);
    exit(kErrorExitCode);
  }
  return symbol;
}


void main(int argc, char** argv) {
  char* script_name;
  const int EXTRA_VM_ARGUMENTS = 2;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);
  CommandLineOptions dart_options(argc);
  bool print_flags_seen = false;
  bool verbose_debug_seen = false;

  vm_options.AddArgument("--no_write_protect_code");
  // Perform platform specific initialization.
  if (!Platform::Initialize()) {
    Log::PrintErr("Initialization failed\n");
  }

  // On Windows, the argv strings are code page encoded and not
  // utf8. We need to convert them to utf8.
  bool argv_converted = ShellUtils::GetUtf8Argv(argc, argv);

  // Parse command line arguments.
  if (ParseArguments(argc,
                     argv,
                     &vm_options,
                     &script_name,
                     &dart_options,
                     &print_flags_seen,
                     &verbose_debug_seen) < 0) {
    if (has_help_option) {
      PrintUsage();
      exit(0);
    } else if (has_version_option) {
      PrintVersion();
      exit(0);
    } else if (print_flags_seen) {
      // Will set the VM flags, print them out and then we exit as no
      // script was specified on the command line.
      Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
      exit(0);
    } else {
      PrintUsage();
      exit(kErrorExitCode);
    }
  }

  Thread::InitOnce();

  if (!DartUtils::SetOriginalWorkingDirectory()) {
    OSError err;
    fprintf(stderr, "Error determining current directory: %s\n", err.message());
    fflush(stderr);
    exit(kErrorExitCode);
  }

  if (generate_script_snapshot) {
    vm_options.AddArgument("--load_deferred_eagerly");
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Start event handler.
  EventHandler::Start();

  // Start the debugger wire protocol handler if necessary.
  if (start_debugger) {
    ASSERT(debug_port >= 0);
    bool print_msg = verbose_debug_seen || (debug_port == 0);
    debug_port = DebuggerConnectionHandler::StartHandler(debug_ip, debug_port);
    if (print_msg) {
      Log::Print("Debugger listening on port %d\n", debug_port);
    }
  } else {
    DebuggerConnectionHandler::InitForVmService();
  }

  const uint8_t* instructions_snapshot = NULL;
  if (has_run_precompiled_snapshot) {
    instructions_snapshot = reinterpret_cast<const uint8_t*>(
        LoadLibrarySymbol(kPrecompiledLibraryName, kPrecompiledSymbolName));
    ReadSnapshotFile(kPrecompiledVmIsolateName, &vm_isolate_snapshot_buffer);
    ReadSnapshotFile(kPrecompiledIsolateName, &isolate_snapshot_buffer);
  }

  // Initialize the Dart VM.
  if (!Dart_Initialize(vm_isolate_snapshot_buffer, instructions_snapshot,
                       CreateIsolateAndSetup, NULL, NULL, ShutdownIsolate,
                       DartUtils::OpenFile,
                       DartUtils::ReadFile,
                       DartUtils::WriteFile,
                       DartUtils::CloseFile,
                       DartUtils::EntropySource)) {
    fprintf(stderr, "%s", "VM initialization failed\n");
    fflush(stderr);
    DebuggerConnectionHandler::StopHandler();
    // TODO(zra): Stop the EventHandler once thread shutdown is enabled.
    // EventHandler::Stop();
    exit(kErrorExitCode);
  }

  Dart_RegisterIsolateServiceRequestCallback(
        "getIO", &ServiceGetIOHandler, NULL);
  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);

  // Call CreateIsolateAndSetup which creates an isolate and loads up
  // the specified application script.
  char* error = NULL;
  int exit_code = 0;
  char* isolate_name = BuildIsolateName(script_name, "main");
  Dart_Isolate isolate = CreateIsolateAndSetupHelper(script_name,
                                                     "main",
                                                     commandline_package_root,
                                                     commandline_packages_file,
                                                     NULL,
                                                     &error,
                                                     &exit_code);
  if (isolate == NULL) {
    Log::PrintErr("%s\n", error);
    free(error);
    delete [] isolate_name;
    DebuggerConnectionHandler::StopHandler();
    // TODO(zra): Stop the EventHandler once thread shutdown is enabled.
    // EventHandler::Stop();
    exit((exit_code != 0) ? exit_code : kErrorExitCode);
  }
  delete [] isolate_name;

  Dart_EnterIsolate(isolate);
  ASSERT(isolate == Dart_CurrentIsolate());
  ASSERT(isolate != NULL);
  Dart_Handle result;

  Dart_EnterScope();

  if (generate_script_snapshot) {
    // First create a snapshot.
    Dart_Handle result;
    uint8_t* buffer = NULL;
    intptr_t size = 0;
    result = Dart_CreateScriptSnapshot(&buffer, &size);
    DartExitOnError(result);

    // Open the snapshot file.
    File* snapshot_file = File::Open(snapshot_filename, File::kWriteTruncate);
    if (snapshot_file == NULL) {
      ErrorExit(kErrorExitCode,
                "Unable to open file %s for writing the snapshot\n",
                snapshot_filename);
    }

    // Write the magic number to indicate file is a script snapshot.
    DartUtils::WriteMagicNumber(snapshot_file);

    // Now write the snapshot out to specified file.
    bool bytes_written = snapshot_file->WriteFully(buffer, size);
    ASSERT(bytes_written);
    delete snapshot_file;
    snapshot_file = NULL;
  } else {
    // Lookup the library of the root script.
    Dart_Handle root_lib = Dart_RootLibrary();
    // Import the root library into the builtin library so that we can easily
    // lookup the main entry point exported from the root library.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    ASSERT(!Dart_IsError(builtin_lib));
    result = Dart_LibraryImportLibrary(builtin_lib, root_lib, Dart_Null());

    if (has_gen_precompiled_snapshot) {
      result = Dart_Precompile();
      DartExitOnError(result);

      uint8_t* vm_isolate_buffer = NULL;
      intptr_t vm_isolate_size = 0;
      uint8_t* isolate_buffer = NULL;
      intptr_t isolate_size = 0;
      uint8_t* instructions_buffer = NULL;
      intptr_t instructions_size = 0;
      result = Dart_CreatePrecompiledSnapshot(&vm_isolate_buffer,
                                              &vm_isolate_size,
                                              &isolate_buffer,
                                              &isolate_size,
                                              &instructions_buffer,
                                              &instructions_size);
      DartExitOnError(result);
      WriteSnapshotFile(kPrecompiledVmIsolateName,
                        vm_isolate_buffer,
                        vm_isolate_size);
      WriteSnapshotFile(kPrecompiledIsolateName,
                        isolate_buffer,
                        isolate_size);
      WriteSnapshotFile(kPrecompiledInstructionsName,
                        instructions_buffer,
                        instructions_size);
    } else if (has_compile_all) {
      result = Dart_CompileAll();
      DartExitOnError(result);
    }

    if (Dart_IsNull(root_lib)) {
      ErrorExit(kErrorExitCode,
                "Unable to find root library for '%s'\n",
                script_name);
    }

    // The helper function _getMainClosure creates a closure for the main
    // entry point which is either explicitly or implictly exported from the
    // root library.
    Dart_Handle main_closure = Dart_Invoke(
        builtin_lib, Dart_NewStringFromCString("_getMainClosure"), 0, NULL);
    DartExitOnError(main_closure);

    // Set debug breakpoint if specified on the command line before calling
    // the main function.
    if (breakpoint_at != NULL) {
      result = SetBreakpoint(breakpoint_at, root_lib);
      if (Dart_IsError(result)) {
        ErrorExit(kErrorExitCode,
                  "Error setting breakpoint at '%s': %s\n",
                  breakpoint_at,
                  Dart_GetError(result));
      }
    }

    // Call _startIsolate in the isolate library to enable dispatching the
    // initial startup message.
    const intptr_t kNumIsolateArgs = 2;
    Dart_Handle isolate_args[kNumIsolateArgs];
    isolate_args[0] = main_closure;                         // entryPoint
    isolate_args[1] = CreateRuntimeOptions(&dart_options);  // args

    Dart_Handle isolate_lib = Dart_LookupLibrary(
        Dart_NewStringFromCString("dart:isolate"));
    result = Dart_Invoke(isolate_lib,
                         Dart_NewStringFromCString("_startMainIsolate"),
                         kNumIsolateArgs, isolate_args);
    DartExitOnError(result);

    // Keep handling messages until the last active receive port is closed.
    result = Dart_RunLoop();
    DartExitOnError(result);
  }

  Dart_ExitScope();
  // Shutdown the isolate.
  Dart_ShutdownIsolate();
  // Terminate process exit-code handler.
  Process::TerminateExitCodeHandler();

  Dart_Cleanup();

  DebuggerConnectionHandler::StopHandler();
  // TODO(zra): Stop the EventHandler once thread shutdown is enabled.
  // EventHandler::Stop();

  // Free copied argument strings if converted.
  if (argv_converted) {
    for (int i = 0; i < argc; i++) free(argv[i]);
  }

  // Free environment if any.
  if (environment != NULL) {
    for (HashMap::Entry* p = environment->Start();
         p != NULL;
         p = environment->Next(p)) {
      free(p->key);
      free(p->value);
    }
    delete environment;
  }

  exit(Process::GlobalExitCode());
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  dart::bin::main(argc, argv);
  UNREACHABLE();
}
