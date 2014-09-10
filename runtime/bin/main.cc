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
#include "bin/thread.h"
#include "bin/vmservice_impl.h"
#include "platform/globals.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.
extern const uint8_t* snapshot_buffer;

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
static const char* package_root = NULL;


// Global flag that is used to indicate that we want to compile all the
// dart functions and not run anything.
static bool has_compile_all = false;

// Global flag that is used to indicate that we want to print the source code
// for script that is being run.
static bool has_print_script = false;


static const char* DEFAULT_VM_SERVICE_SERVER_IP = "127.0.0.1";
static const int DEFAULT_VM_SERVICE_SERVER_PORT = 8181;
// VM Service options.
static bool start_vm_service = false;
static const char* vm_service_server_ip = DEFAULT_VM_SERVICE_SERVER_IP;
// The 0 port is a magic value which results in the first available port
// being allocated.
static int vm_service_server_port = 0;

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
  package_root = arg;
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


static bool ProcessPrintScriptOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  has_print_script = true;
  return true;
}


static bool ProcessGenScriptSnapshotOption(const char* filename,
                                           CommandLineOptions* vm_options) {
  if (filename != NULL && strlen(filename) != 0) {
    // Ensure that are already running using a full snapshot.
    if (snapshot_buffer == NULL) {
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


bool trace_debug_protocol = false;
static bool ProcessTraceDebugProtocolOption(const char* arg,
                                            CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  trace_debug_protocol = true;
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
  { "-D", ProcessEnvironmentOption },
  // VM specific options to the standalone dart program.
  { "--break-at=", ProcessBreakpointOption },
  { "--compile_all", ProcessCompileAllOption },
  { "--debug", ProcessDebugOption },
  { "--snapshot=", ProcessGenScriptSnapshotOption },
  { "--print-script", ProcessPrintScriptOption },
  { "--enable-vm-service", ProcessEnableVmServiceOption },
  { "--observe", ProcessObserveOption },
  { "--trace-debug-protocol", ProcessTraceDebugProtocolOption },
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


// Convert all the arguments to UTF8. On Windows, the arguments are
// encoded in the current code page and not UTF8.
//
// Returns true if the arguments are converted. In that case
// each of the arguments need to be deallocated using free.
static bool Utf8ConvertArgv(int argc, char** argv) {
  int unicode_argc = 0;
  wchar_t** unicode_argv = ShellUtils::GetUnicodeArgv(&unicode_argc);
  if (unicode_argv == NULL) return false;
  for (int i = 0; i < unicode_argc; i++) {
    wchar_t* arg = unicode_argv[i];
    argv[i] = StringUtils::WideToUtf8(arg);
  }
  ShellUtils::FreeUnicodeArgv(unicode_argv);
  return true;
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
    *is_compile_error = Dart_IsCompilationError(result);                       \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return NULL;                                                               \
  }                                                                            \

// Returns true on success, false on failure.
static Dart_Isolate CreateIsolateAndSetupHelper(const char* script_uri,
                                                const char* main,
                                                void* data,
                                                char** error,
                                                bool* is_compile_error) {
  Dart_Isolate isolate =
      Dart_CreateIsolate(script_uri, main, snapshot_buffer, data, error);
  if (isolate == NULL) {
    return NULL;
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

  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);

  // Load the specified application script into the newly created isolate.

  // Prepare builtin and its dependent libraries for use to resolve URIs.
  // The builtin library is part of the core snapshot and would already be
  // available here in the case of script snapshot loading.
  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  CHECK_RESULT(builtin_lib);

  // Prepare for script loading by setting up the 'print' and 'timer'
  // closures and setting up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(package_root, builtin_lib);
  CHECK_RESULT(result);

  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(data);
  ASSERT(isolate_data != NULL);
  ASSERT(isolate_data->script_url != NULL);
  result = DartUtils::LoadScript(isolate_data->script_url, builtin_lib);
  CHECK_RESULT(result);

  // Run event-loop and wait for script loading to complete.
  result = Dart_RunLoop();
  CHECK_RESULT(result);

  Platform::SetPackageRoot(package_root);
  Dart_Handle io_lib_url = DartUtils::NewString(DartUtils::kIOLibURL);
  CHECK_RESULT(io_lib_url);
  Dart_Handle io_lib = Dart_LookupLibrary(io_lib_url);
  CHECK_RESULT(io_lib);
  Dart_Handle platform_type = DartUtils::GetDartType(DartUtils::kIOLibURL,
                                                     "_Platform");
  CHECK_RESULT(platform_type);
  Dart_Handle script_name = DartUtils::NewString("_nativeScript");
  CHECK_RESULT(script_name);
  Dart_Handle dart_script = DartUtils::NewString(script_uri);
  CHECK_RESULT(dart_script);
  Dart_Handle set_script_name =
      Dart_SetField(platform_type, script_name, dart_script);
  CHECK_RESULT(set_script_name);

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
                                          void* data, char** error) {
  bool is_compile_error = false;
  if (script_uri == NULL) {
    if (data == NULL) {
      *error = strdup("Invalid 'callback_data' - Unable to spawn new isolate");
      return NULL;
    }
    IsolateData* parent_isolate_data = reinterpret_cast<IsolateData*>(data);
    script_uri = parent_isolate_data->script_url;
    if (script_uri == NULL) {
      *error = strdup("Invalid 'callback_data' - Unable to spawn new isolate");
      return NULL;
    }
  }
  IsolateData* isolate_data = new IsolateData(script_uri);
  return CreateIsolateAndSetupHelper(script_uri,
                                     main,
                                     isolate_data,
                                     error,
                                     &is_compile_error);
}


#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    *error = strdup(Dart_GetError(result));                                    \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return NULL;                                                               \
  }                                                                            \

static Dart_Isolate CreateServiceIsolate(void* data, char** error) {
  const char* script_uri = DartUtils::kVMServiceLibURL;
  IsolateData* isolate_data = new IsolateData(script_uri);
  Dart_Isolate isolate =
      Dart_CreateIsolate(script_uri, "main", snapshot_buffer, isolate_data,
                         error);
  if (isolate == NULL) {
    return NULL;
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
  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);
  // Prepare builtin and its dependent libraries for use to resolve URIs.
  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  CHECK_RESULT(builtin_lib);
  // Prepare for script loading by setting up the 'print' and 'timer'
  // closures and setting up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(package_root, builtin_lib);
  CHECK_RESULT(result);
  Platform::SetPackageRoot(package_root);
  Dart_Handle io_lib_url = DartUtils::NewString(DartUtils::kIOLibURL);
  CHECK_RESULT(io_lib_url);
  Dart_Handle io_lib = Dart_LookupLibrary(io_lib_url);
  CHECK_RESULT(io_lib);
  Dart_Handle platform_type = DartUtils::GetDartType(DartUtils::kIOLibURL,
                                                     "_Platform");
  CHECK_RESULT(platform_type);
  Dart_Handle script_name = DartUtils::NewString("_nativeScript");
  CHECK_RESULT(script_name);
  Dart_Handle dart_script = DartUtils::NewString(script_uri);
  CHECK_RESULT(dart_script);
  Dart_Handle set_script_name =
      Dart_SetField(platform_type, script_name, dart_script);
  CHECK_RESULT(set_script_name);
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}

#undef CHECK_RESULT

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
"--print-script\n"
"  generates Dart source code back and prints it after parsing a Dart script\n"
"\n"
"--enable-vm-service[:<port number>]\n"
"  enables the VM service and listens on specified port for connections\n"
"  (default port number is 8181)\n"
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

  exit(exit_code);
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


static Dart_Handle GenerateScriptSource() {
  Dart_Handle library_url = Dart_LibraryUrl(Dart_RootLibrary());
  if (Dart_IsError(library_url)) {
    return library_url;
  }
  Dart_Handle script_urls = Dart_GetScriptURLs(library_url);
  if (Dart_IsError(script_urls)) {
    return script_urls;
  }
  intptr_t length;
  Dart_Handle result = Dart_ListLength(script_urls, &length);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < length; i++) {
    Dart_Handle script_url = Dart_ListGetAt(script_urls, i);
    if (Dart_IsError(script_url)) {
      return script_url;
    }
    result = Dart_GenerateScriptSource(library_url, script_url);
    if (Dart_IsError(result)) {
      return result;
    }
    const char* script_source = NULL;
    result = Dart_StringToCString(result, &script_source);
    if (Dart_IsError(result)) {
      return result;
    }
    Log::Print("%s\n", script_source);
  }
  return Dart_True();
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


static const char* ServiceRequestHandler(
    const char* name,
    const char** arguments,
    intptr_t num_arguments,
    const char** option_keys,
    const char** option_values,
    intptr_t num_options,
    void* user_data) {
  DartScope scope;
  ASSERT(num_arguments > 0);
  ASSERT(strncmp(arguments[0], "io", 2) == 0);
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
  Dart_Handle paths = Dart_NewList(num_arguments - 1);
  for (int i = 0; i < num_arguments - 1; i++) {
    Dart_ListSetAt(paths, i, Dart_NewStringFromCString(arguments[i + 1]));
  }
  Dart_Handle keys = Dart_NewList(num_options);
  Dart_Handle values = Dart_NewList(num_options);
  for (int i = 0; i < num_options; i++) {
    Dart_ListSetAt(keys, i, Dart_NewStringFromCString(option_keys[i]));
    Dart_ListSetAt(values, i, Dart_NewStringFromCString(option_values[i]));
  }
  Dart_Handle args[] = {paths, keys, values};
  Dart_Handle result = Dart_Invoke(io_lib, handler_function_name, 3, args);
  if (Dart_IsError(result)) return ServiceRequestError(result);
  const char *json;
  result = Dart_StringToCString(result, &json);
  if (Dart_IsError(result)) return ServiceRequestError(result);
  return strdup(json);
}


void main(int argc, char** argv) {
  char* script_name;
  CommandLineOptions vm_options(argc);
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
  bool argv_converted = Utf8ConvertArgv(argc, argv);

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

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Initialize the Dart VM.
  if (!Dart_Initialize(CreateIsolateAndSetup, NULL, NULL, ShutdownIsolate,
                       DartUtils::OpenFile,
                       DartUtils::ReadFile,
                       DartUtils::WriteFile,
                       DartUtils::CloseFile,
                       DartUtils::EntropySource,
                       CreateServiceIsolate)) {
    fprintf(stderr, "%s", "VM initialization failed\n");
    fflush(stderr);
    exit(kErrorExitCode);
  }

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
  }

  ASSERT(Dart_CurrentIsolate() == NULL);
  // Start the VM service isolate, if necessary.
  if (start_vm_service) {
    if (!start_debugger) {
      DebuggerConnectionHandler::InitForVmService();
    }
    bool r = VmService::Start(vm_service_server_ip, vm_service_server_port);
    if (!r) {
      Log::PrintErr("Could not start VM Service isolate %s\n",
                    VmService::GetErrorMessage());
    }
    Dart_RegisterIsolateServiceRequestCallback(
        "io", &ServiceRequestHandler, NULL);
  }
  ASSERT(Dart_CurrentIsolate() == NULL);

  // Call CreateIsolateAndSetup which creates an isolate and loads up
  // the specified application script.
  char* error = NULL;
  bool is_compile_error = false;
  char* isolate_name = BuildIsolateName(script_name, "main");
  IsolateData* isolate_data = new IsolateData(script_name);
  Dart_Isolate isolate = CreateIsolateAndSetupHelper(script_name,
                                                     "main",
                                                     isolate_data,
                                                     &error,
                                                     &is_compile_error);
  if (isolate == NULL) {
    Log::PrintErr("%s\n", error);
    free(error);
    delete [] isolate_name;
    exit(is_compile_error ? kCompilationErrorExitCode : kErrorExitCode);
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
    result = Dart_LibraryImportLibrary(builtin_lib, root_lib, Dart_Null());

    if (has_compile_all) {
      result = Dart_CompileAll();
      DartExitOnError(result);
    }

    if (Dart_IsNull(root_lib)) {
      ErrorExit(kErrorExitCode,
                "Unable to find root library for '%s'\n",
                script_name);
    }
    if (has_print_script) {
      result = GenerateScriptSource();
      DartExitOnError(result);
    } else {
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
  }

  Dart_ExitScope();
  // Shutdown the isolate.
  Dart_ShutdownIsolate();
  // Terminate process exit-code handler.
  Process::TerminateExitCodeHandler();

  Dart_Cleanup();

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
    free(environment);
  }

  exit(Process::GlobalExitCode());
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  dart::bin::main(argc, argv);
  UNREACHABLE();
}
