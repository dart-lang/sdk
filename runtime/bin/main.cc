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
#include "bin/directory.h"
#include "bin/embedded_dart_io.h"
#include "bin/error_exit.h"
#include "bin/eventhandler.h"
#include "bin/extensions.h"
#include "bin/file.h"
#include "bin/isolate_data.h"
#include "bin/loader.h"
#include "bin/log.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "bin/snapshot_utils.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"
#include "platform/globals.h"
#include "platform/growable_array.h"
#include "platform/hashmap.h"
#include "platform/text_buffer.h"
#if !defined(DART_PRECOMPILER)
#include "zlib/zlib.h"
#endif

#include "vm/kernel.h"

namespace dart {
namespace bin {

// Snapshot pieces if we link in a snapshot, otherwise initialized to NULL.
extern const uint8_t* vm_snapshot_data;
extern const uint8_t* vm_snapshot_instructions;
extern const uint8_t* core_isolate_snapshot_data;
extern const uint8_t* core_isolate_snapshot_instructions;

/**
 * Global state used to control and store generation of application snapshots
 * An application snapshot can be generated and run using the following
 * command
 *   dart --snapshot-kind=app-jit --snapshot=<app_snapshot_filename>
 *       <script_uri> [<script_options>]
 * To Run the application snapshot generated above, use :
 *   dart <app_snapshot_filename> [<script_options>]
 */
static bool vm_run_app_snapshot = false;
static const char* snapshot_filename = NULL;
enum SnapshotKind {
  kNone,
  kScript,
  kAppAOT,
  kAppJIT,
};
static SnapshotKind gen_snapshot_kind = kNone;
static const char* snapshot_deps_filename = NULL;

static bool use_dart_frontend = false;

static const char* frontend_filename = NULL;

// True if the VM should boostrap the SDK from a binary (.dill) file.  The
// filename points into an argv buffer and does not need to be freed.
static bool use_platform_binary = false;
static const char* platform_binary_filename = NULL;

// Value of the --save-feedback flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* save_feedback_filename = NULL;

// Value of the --load-feedback flag.
// (This pointer points into an argv buffer and does not need to be
// free'd.)
static const char* load_feedback_filename = NULL;

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
static bool compile_all = false;
static bool parse_all = false;


// Global flag that is used to indicate that we want to use blobs/mmap instead
// of assembly/shared libraries for precompilation.
static bool use_blobs = false;


// Global flag that is used to indicate that we want to trace resolution of
// URIs and the loading of libraries, parts and scripts.
static bool trace_loading = false;


static char* app_script_uri = NULL;
static const uint8_t* app_isolate_snapshot_data = NULL;
static const uint8_t* app_isolate_snapshot_instructions = NULL;


static Dart_Isolate main_isolate = NULL;


static const char* DEFAULT_VM_SERVICE_SERVER_IP = "localhost";
static const int DEFAULT_VM_SERVICE_SERVER_PORT = 8181;
// VM Service options.
static const char* vm_service_server_ip = DEFAULT_VM_SERVICE_SERVER_IP;
// The 0 port is a magic value which results in the first available port
// being allocated.
static int vm_service_server_port = -1;
// True when we are running in development mode and cross origin security
// checks are disabled.
static bool vm_service_dev_mode = false;


// The environment provided through the command line using -D options.
static dart::HashMap* environment = NULL;

static bool IsValidFlag(const char* name,
                        const char* prefix,
                        intptr_t prefix_length) {
  intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}


static bool version_option = false;
static bool ProcessVersionOption(const char* arg,
                                 CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  version_option = true;
  return true;
}


static bool help_option = false;
static bool ProcessHelpOption(const char* arg, CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  help_option = true;
  return true;
}


static bool verbose_option = false;
static bool ProcessVerboseOption(const char* arg,
                                 CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  verbose_option = true;
  return true;
}


static bool ProcessPackageRootOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '-') {
    return false;
  }
  commandline_package_root = arg;
  return true;
}


static bool ProcessPackagesOption(const char* arg,
                                  CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '-') {
    return false;
  }
  commandline_packages_file = arg;
  return true;
}


static bool ProcessSaveFeedbackOption(const char* arg,
                                      CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '-') {
    return false;
  }
  save_feedback_filename = arg;
  return true;
}


static bool ProcessLoadFeedbackOption(const char* arg,
                                      CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '-') {
    return false;
  }
  load_feedback_filename = arg;
  return true;
}


static void* GetHashmapKeyFromString(char* key) {
  return reinterpret_cast<void*>(key);
}


static bool ExtractPortAndAddress(const char* option_value,
                                  int* out_port,
                                  const char** out_ip,
                                  int default_port,
                                  const char* default_ip) {
  // [option_value] has to be one of the following formats:
  //   - ""
  //   - ":8181"
  //   - "=8181"
  //   - ":8181/192.168.0.1"
  //   - "=8181/192.168.0.1"
  //   - "=8181/::1"

  if (*option_value == '\0') {
    *out_ip = default_ip;
    *out_port = default_port;
    return true;
  }

  if ((*option_value != '=') && (*option_value != ':')) {
    return false;
  }

  int port = atoi(option_value + 1);
  const char* slash = strstr(option_value, "/");
  if (slash == NULL) {
    *out_ip = default_ip;
    *out_port = port;
    return true;
  }

  *out_ip = slash + 1;
  *out_port = port;
  return true;
}


static bool ProcessEnvironmentOption(const char* arg,
                                     CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '\0') {
    // Ignore empty -D option.
    Log::PrintErr("No arguments given to -D option, ignoring it\n");
    return true;
  }
  // Split the name=value part of the -Dname=value argument.
  const char* equals_pos = strchr(arg, '=');
  if (equals_pos == NULL) {
    // No equal sign (name without value) currently not supported.
    Log::PrintErr("No value given in -D%s option, ignoring it\n", arg);
    return true;
  }

  char* name;
  char* value = NULL;
  int name_len = equals_pos - arg;
  if (name_len == 0) {
    Log::PrintErr("No name given in -D%s option, ignoring it\n", arg);
    return true;
  }
  // Split name=value into name and value.
  name = reinterpret_cast<char*>(malloc(name_len + 1));
  strncpy(name, arg, name_len);
  name[name_len] = '\0';
  value = strdup(equals_pos + 1);
  if (environment == NULL) {
    environment = new HashMap(&HashMap::SameStringValue, 4);
  }
  HashMap::Entry* entry = environment->Lookup(GetHashmapKeyFromString(name),
                                              HashMap::StringHash(name), true);
  ASSERT(entry != NULL);  // Lookup adds an entry if key not found.
  if (entry->value != NULL) {
    free(name);
    free(entry->value);
  }
  entry->value = value;
  return true;
}


static bool ProcessCompileAllOption(const char* arg,
                                    CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  compile_all = true;
  return true;
}


static bool ProcessParseAllOption(const char* arg,
                                  CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  parse_all = true;
  return true;
}


static bool ProcessFrontendOption(const char* filename,
                                  CommandLineOptions* vm_options) {
  ASSERT(filename != NULL);
  if (filename[0] == '\0') {
    return false;
  }
  use_dart_frontend = true;
  frontend_filename = filename;
  vm_options->AddArgument("--use-dart-frontend");
  return true;
}


static bool ProcessPlatformOption(const char* filename,
                                  CommandLineOptions* vm_options) {
  ASSERT(filename != NULL);
  if (filename[0] == '\0') {
    return false;
  }
  use_platform_binary = true;
  platform_binary_filename = filename;
  return true;
}


static bool ProcessUseBlobsOption(const char* arg,
                                  CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg != '\0') {
    return false;
  }
  use_blobs = true;
  return true;
}


static bool ProcessSnapshotFilenameOption(const char* filename,
                                          CommandLineOptions* vm_options) {
  snapshot_filename = filename;
  if (gen_snapshot_kind == kNone) {
    gen_snapshot_kind = kScript;  // Default behavior.
  }
  return true;
}


static bool ProcessSnapshotKindOption(const char* kind,
                                      CommandLineOptions* vm_options) {
  if (strcmp(kind, "script") == 0) {
    gen_snapshot_kind = kScript;
    return true;
  } else if (strcmp(kind, "app-aot") == 0) {
    gen_snapshot_kind = kAppAOT;
    return true;
  } else if (strcmp(kind, "app-jit") == 0) {
    gen_snapshot_kind = kAppJIT;
    return true;
  }
  Log::PrintErr(
      "Unrecognized snapshot kind: '%s'\nValid kinds are: "
      "script, app-aot, app-jit\n",
      kind);
  return false;
}


static bool ProcessSnapshotDepsFilenameOption(const char* filename,
                                              CommandLineOptions* vm_options) {
  snapshot_deps_filename = filename;
  return true;
}


static bool ProcessEnableVmServiceOption(const char* option_value,
                                         CommandLineOptions* vm_options) {
  ASSERT(option_value != NULL);

  if (!ExtractPortAndAddress(
          option_value, &vm_service_server_port, &vm_service_server_ip,
          DEFAULT_VM_SERVICE_SERVER_PORT, DEFAULT_VM_SERVICE_SERVER_IP)) {
    Log::PrintErr(
        "unrecognized --enable-vm-service option syntax. "
        "Use --enable-vm-service[=<port number>[/<bind address>]]\n");
    return false;
  }

  return true;
}


static bool ProcessDisableServiceOriginCheckOption(
    const char* option_value,
    CommandLineOptions* vm_options) {
  ASSERT(option_value != NULL);
  Log::PrintErr(
      "WARNING: You are running with the service protocol in an "
      "insecure mode.\n");
  vm_service_dev_mode = true;
  return true;
}


static bool ProcessObserveOption(const char* option_value,
                                 CommandLineOptions* vm_options) {
  ASSERT(option_value != NULL);

  if (!ExtractPortAndAddress(
          option_value, &vm_service_server_port, &vm_service_server_ip,
          DEFAULT_VM_SERVICE_SERVER_PORT, DEFAULT_VM_SERVICE_SERVER_IP)) {
    Log::PrintErr(
        "unrecognized --observe option syntax. "
        "Use --observe[=<port number>[/<bind address>]]\n");
    return false;
  }

  // These options should also be documented in the help message.
  vm_options->AddArgument("--pause-isolates-on-exit");
  vm_options->AddArgument("--pause-isolates-on-unhandled-exceptions");
  vm_options->AddArgument("--warn-on-pause-with-no-debugger");
  return true;
}


static bool ProcessTraceLoadingOption(const char* arg,
                                      CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }
  trace_loading = true;
  return true;
}


static bool ProcessHotReloadTestModeOption(const char* arg,
                                           CommandLineOptions* vm_options) {
  if (*arg != '\0') {
    return false;
  }

  // Identity reload.
  vm_options->AddArgument("--identity_reload");
  // Start reloading quickly.
  vm_options->AddArgument("--reload_every=4");
  // Reload from optimized and unoptimized code.
  vm_options->AddArgument("--reload_every_optimized=false");
  // Reload less frequently as time goes on.
  vm_options->AddArgument("--reload_every_back_off");
  // Ensure that every isolate has reloaded once before exiting.
  vm_options->AddArgument("--check_reloaded");

  return true;
}


static bool ProcessHotReloadRollbackTestModeOption(
    const char* arg,
    CommandLineOptions* vm_options) {
  // Identity reload.
  vm_options->AddArgument("--identity_reload");
  // Start reloading quickly.
  vm_options->AddArgument("--reload_every=4");
  // Reload from optimized and unoptimized code.
  vm_options->AddArgument("--reload_every_optimized=false");
  // Reload less frequently as time goes on.
  vm_options->AddArgument("--reload_every_back_off");
  // Ensure that every isolate has reloaded once before exiting.
  vm_options->AddArgument("--check_reloaded");
  // Force all reloads to fail and execute the rollback code.
  vm_options->AddArgument("--reload_force_rollback");

  return true;
}


extern bool short_socket_read;

extern bool short_socket_write;

static bool ProcessShortSocketReadOption(const char* arg,
                                         CommandLineOptions* vm_options) {
  short_socket_read = true;
  return true;
}


static bool ProcessShortSocketWriteOption(const char* arg,
                                          CommandLineOptions* vm_options) {
  short_socket_write = true;
  return true;
}


#if !defined(HOST_OS_MACOS)
extern const char* commandline_root_certs_file;
extern const char* commandline_root_certs_cache;

static bool ProcessRootCertsFileOption(const char* arg,
                                       CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '-') {
    return false;
  }
  if (commandline_root_certs_cache != NULL) {
    Log::PrintErr(
        "Only one of --root-certs-file and --root-certs-cache "
        "may be specified");
    return false;
  }
  commandline_root_certs_file = arg;
  return true;
}


static bool ProcessRootCertsCacheOption(const char* arg,
                                        CommandLineOptions* vm_options) {
  ASSERT(arg != NULL);
  if (*arg == '-') {
    return false;
  }
  if (commandline_root_certs_file != NULL) {
    Log::PrintErr(
        "Only one of --root-certs-file and --root-certs-cache "
        "may be specified");
    return false;
  }
  commandline_root_certs_cache = arg;
  return true;
}
#endif  // !defined(HOST_OS_MACOS)


static struct {
  const char* option_name;
  bool (*process)(const char* option, CommandLineOptions* vm_options);
} main_options[] = {
    // Standard options shared with dart2js.
    {"-D", ProcessEnvironmentOption},
    {"-h", ProcessHelpOption},
    {"--help", ProcessHelpOption},
    {"--packages=", ProcessPackagesOption},
    {"--package-root=", ProcessPackageRootOption},
    {"-v", ProcessVerboseOption},
    {"--verbose", ProcessVerboseOption},
    {"--version", ProcessVersionOption},

    // VM specific options to the standalone dart program.
    {"--compile_all", ProcessCompileAllOption},
    {"--parse_all", ProcessParseAllOption},
    {"--dfe=", ProcessFrontendOption},
    {"--platform=", ProcessPlatformOption},
    {"--enable-vm-service", ProcessEnableVmServiceOption},
    {"--disable-service-origin-check", ProcessDisableServiceOriginCheckOption},
    {"--observe", ProcessObserveOption},
    {"--snapshot=", ProcessSnapshotFilenameOption},
    {"--snapshot-kind=", ProcessSnapshotKindOption},
    {"--snapshot-depfile=", ProcessSnapshotDepsFilenameOption},
    {"--use-blobs", ProcessUseBlobsOption},
    {"--save-feedback=", ProcessSaveFeedbackOption},
    {"--load-feedback=", ProcessLoadFeedbackOption},
    {"--trace-loading", ProcessTraceLoadingOption},
    {"--hot-reload-test-mode", ProcessHotReloadTestModeOption},
    {"--hot-reload-rollback-test-mode", ProcessHotReloadRollbackTestModeOption},
    {"--short_socket_read", ProcessShortSocketReadOption},
    {"--short_socket_write", ProcessShortSocketWriteOption},
#if !defined(HOST_OS_MACOS)
    {"--root-certs-file=", ProcessRootCertsFileOption},
    {"--root-certs-cache=", ProcessRootCertsCacheOption},
#endif  // !defined(HOST_OS_MACOS)
    {NULL, NULL}};


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
      } else if ((strncmp(argv[i], kVerboseDebug1, strlen(kVerboseDebug1)) ==
                  0) ||
                 (strncmp(argv[i], kVerboseDebug2, strlen(kVerboseDebug2)) ==
                  0)) {
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
    Log::PrintErr(
        "Specifying both a packages directory and a packages "
        "file is invalid.\n");
    return -1;
  }
  if ((commandline_package_root != NULL) &&
      (strlen(commandline_package_root) == 0)) {
    Log::PrintErr("Empty package root specified.\n");
    return -1;
  }
  if ((commandline_packages_file != NULL) &&
      (strlen(commandline_packages_file) == 0)) {
    Log::PrintErr("Empty package file name specified.\n");
    return -1;
  }
  if (((gen_snapshot_kind != kNone) || (snapshot_deps_filename != NULL)) &&
      (snapshot_filename == NULL)) {
    Log::PrintErr("Generating a snapshot requires a filename (--snapshot).\n");
    return -1;
  }
  if ((gen_snapshot_kind != kNone) && vm_run_app_snapshot) {
    Log::PrintErr(
        "Specifying an option to generate a snapshot and"
        " run using a snapshot is invalid.\n");
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
    Dart_Handle argument_value = DartUtils::NewString(options->GetArgument(i));
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
      HashMap::Entry* entry =
          environment->Lookup(GetHashmapKeyFromString(name_chars),
                              HashMap::StringHash(name_chars), false);
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
    if (Dart_IsCompilationError(result)) {                                     \
      *exit_code = kCompilationErrorExitCode;                                  \
    } else if (Dart_IsApiError(result)) {                                      \
      *exit_code = kApiErrorExitCode;                                          \
    } else {                                                                   \
      *exit_code = kErrorExitCode;                                             \
    }                                                                          \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return NULL;                                                               \
  }


static void SnapshotOnExitHook(int64_t exit_code) {
  if (Dart_CurrentIsolate() != main_isolate) {
    Log::PrintErr(
        "A snapshot was requested, but a secondary isolate "
        "performed a hard exit (%" Pd64 ").\n",
        exit_code);
    Platform::Exit(kErrorExitCode);
  }
  if (exit_code == 0) {
    Snapshot::GenerateAppJIT(snapshot_filename);
  }
}

// Returns newly created Isolate on success, NULL on failure.
static Dart_Isolate CreateIsolateAndSetupHelper(bool is_main_isolate,
                                                const char* script_uri,
                                                const char* main,
                                                const char* package_root,
                                                const char* packages_config,
                                                Dart_IsolateFlags* flags,
                                                char** error,
                                                int* exit_code) {
  ASSERT(script_uri != NULL);
  const bool is_kernel_isolate =
      strcmp(script_uri, DART_KERNEL_ISOLATE_NAME) == 0;
  if (is_kernel_isolate) {
    if (!use_dart_frontend) {
      *error = strdup("Kernel isolate not supported.");
      return NULL;
    }
    script_uri = frontend_filename;
    if (packages_config == NULL) {
      packages_config = commandline_packages_file;
    }
  }

  void* kernel_platform = NULL;
  void* kernel_program = NULL;
  AppSnapshot* app_snapshot = NULL;

#if defined(DART_PRECOMPILED_RUNTIME)
  // AOT: All isolates start from the app snapshot.
  bool isolate_run_app_snapshot = true;
  const uint8_t* isolate_snapshot_data = app_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      app_isolate_snapshot_instructions;
#else
  // JIT: Main isolate starts from the app snapshot, if any. Other isolates
  // use the core libraries snapshot.
  bool isolate_run_app_snapshot = false;
  const uint8_t* isolate_snapshot_data = core_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      core_isolate_snapshot_instructions;
  if ((app_isolate_snapshot_data != NULL) &&
      (is_main_isolate || ((app_script_uri != NULL) &&
                           (strcmp(script_uri, app_script_uri) == 0)))) {
    isolate_run_app_snapshot = true;
    isolate_snapshot_data = app_isolate_snapshot_data;
    isolate_snapshot_instructions = app_isolate_snapshot_instructions;
  } else if (!is_main_isolate) {
    app_snapshot = Snapshot::TryReadAppSnapshot(script_uri);
    if (app_snapshot != NULL) {
      isolate_run_app_snapshot = true;
      const uint8_t* ignore_vm_snapshot_data;
      const uint8_t* ignore_vm_snapshot_instructions;
      app_snapshot->SetBuffers(
          &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
          &isolate_snapshot_data, &isolate_snapshot_instructions);
    }
  }
  const bool is_service_isolate =
      strcmp(script_uri, DART_VM_SERVICE_ISOLATE_NAME) == 0;
  if (!is_kernel_isolate && !is_service_isolate) {
    const uint8_t* platform_file = NULL;
    if (use_platform_binary) {
      intptr_t platform_length = -1;
      bool success = TryReadKernel(platform_binary_filename, &platform_file,
                                   &platform_length);
      if (!success) {
        *error = strdup("The platform binary is not a valid Dart Kernel file.");
        *exit_code = kErrorExitCode;
        return NULL;
      }
      kernel_platform = Dart_ReadKernelBinary(platform_file, platform_length);
    }

    bool is_kernel = false;
    const uint8_t* kernel_file = NULL;
    intptr_t kernel_length = -1;
    if (use_dart_frontend) {
      Dart_KernelCompilationResult result = Dart_CompileToKernel(script_uri);
      *error = result.error;  // Copy error message (if any).
      switch (result.status) {
        case Dart_KernelCompilationStatus_Ok:
          is_kernel = true;
          kernel_file = result.kernel;
          kernel_length = result.kernel_size;
          break;
        case Dart_KernelCompilationStatus_Error:
          *exit_code = kCompilationErrorExitCode;
          break;
        case Dart_KernelCompilationStatus_Crash:
          *exit_code = kDartFrontendErrorExitCode;
          break;
        case Dart_KernelCompilationStatus_Unknown:
          *exit_code = kErrorExitCode;
          break;
      }
      if (!is_kernel) {
        free(const_cast<uint8_t*>(platform_file));
        delete reinterpret_cast<kernel::Program*>(kernel_platform);
        return NULL;
      }
    } else if (!isolate_run_app_snapshot) {
      is_kernel = TryReadKernel(script_uri, &kernel_file, &kernel_length);
    }

    if (is_kernel) {
      kernel_program = Dart_ReadKernelBinary(kernel_file, kernel_length);
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  IsolateData* isolate_data =
      new IsolateData(script_uri, package_root, packages_config, app_snapshot);
  if (is_main_isolate && (snapshot_deps_filename != NULL)) {
    isolate_data->set_dependencies(new MallocGrowableArray<char*>());
  }
  Dart_Isolate isolate = NULL;
  if (kernel_platform != NULL) {
    isolate = Dart_CreateIsolateFromKernel(script_uri, main, kernel_platform,
                                           flags, isolate_data, error);
  } else if (kernel_program != NULL) {
    isolate = Dart_CreateIsolateFromKernel(script_uri, main, kernel_program,
                                           flags, isolate_data, error);
  } else {
    isolate = Dart_CreateIsolate(script_uri, main, isolate_snapshot_data,
                                 isolate_snapshot_instructions, flags,
                                 isolate_data, error);
  }
  if (isolate == NULL) {
    delete isolate_data;
    return NULL;
  }

  Dart_EnterScope();

  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(Loader::LibraryTagHandler);
  CHECK_RESULT(result);

  if (kernel_program != NULL) {
    Dart_Handle result = Dart_LoadKernel(kernel_program);
    CHECK_RESULT(result);
  }
  if ((kernel_platform != NULL) || (isolate_snapshot_data != NULL)) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
  }
  if (isolate_run_app_snapshot) {
    Dart_Handle result = Loader::ReloadNativeExtensions();
    CHECK_RESULT(result);
  }

  if (Dart_IsServiceIsolate(isolate)) {
    // If this is the service isolate, load embedder specific bits and return.
    bool skip_library_load = isolate_run_app_snapshot;
    if (!VmService::Setup(vm_service_server_ip, vm_service_server_port,
                          skip_library_load, vm_service_dev_mode,
                          trace_loading)) {
      *error = strdup(VmService::GetErrorMessage());
      return NULL;
    }
    if (compile_all) {
      result = Dart_CompileAll();
      CHECK_RESULT(result);
    }
    result = Dart_SetEnvironmentCallback(EnvironmentCallback);
    CHECK_RESULT(result);
    Dart_ExitScope();
    Dart_ExitIsolate();
    return isolate;
  }

  // Prepare builtin and other core libraries for use to resolve URIs.
  // Set up various closures, e.g: printing, timers etc.
  // Set up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(false, trace_loading);
  CHECK_RESULT(result);

  // Set up the load port provided by the service isolate so that we can
  // load scripts.
  result = DartUtils::SetupServiceLoadPort();
  CHECK_RESULT(result);

  // Setup package root if specified.
  result = DartUtils::SetupPackageRoot(package_root, packages_config);
  CHECK_RESULT(result);

  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);

  if (isolate_run_app_snapshot) {
    result = DartUtils::SetupIOLibrary(script_uri);
    CHECK_RESULT(result);
    Loader::InitForSnapshot(script_uri);
#if !defined(DART_PRECOMPILED_RUNTIME)
    if (is_main_isolate) {
      // Find the canonical uri of the app snapshot. We'll use this to decide if
      // other isolates should use the app snapshot or the core snapshot.
      const char* resolved_script_uri = NULL;
      result = Dart_StringToCString(
          DartUtils::ResolveScript(Dart_NewStringFromCString(script_uri)),
          &resolved_script_uri);
      CHECK_RESULT(result);
      ASSERT(app_script_uri == NULL);
      app_script_uri = strdup(resolved_script_uri);
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  } else {
    // Load the specified application script into the newly created isolate.
    Dart_Handle uri =
        DartUtils::ResolveScript(Dart_NewStringFromCString(script_uri));
    CHECK_RESULT(uri);
    if (kernel_program == NULL) {
      result = Loader::LibraryTagHandler(Dart_kScriptTag, Dart_Null(), uri);
      CHECK_RESULT(result);
    } else {
      // Various core-library parts will send requests to the Loader to resolve
      // relative URIs and perform other related tasks. We need Loader to be
      // initialized for this to work because loading from Kernel binary
      // bypasses normal source code loading paths that initialize it.
      Loader::InitForSnapshot(script_uri);
    }

    Dart_TimelineEvent("LoadScript", Dart_TimelineGetMicros(),
                       Dart_GetMainPortId(), Dart_Timeline_Event_Async_End, 0,
                       NULL, NULL);

    result = DartUtils::SetupIOLibrary(script_uri);
    CHECK_RESULT(result);
  }

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
                                          const char* package_config,
                                          Dart_IsolateFlags* flags,
                                          void* data,
                                          char** error) {
  // The VM should never call the isolate helper with a NULL flags.
  ASSERT(flags != NULL);
  ASSERT(flags->version == DART_FLAGS_CURRENT_VERSION);
  if ((package_root != NULL) && (package_config != NULL)) {
    *error = strdup(
        "Invalid arguments - Cannot simultaneously specify "
        "package root and package map.");
    return NULL;
  }

  bool is_main_isolate = false;
  int exit_code = 0;
  return CreateIsolateAndSetupHelper(is_main_isolate, script_uri, main,
                                     package_root, package_config, flags, error,
                                     &exit_code);
}


static void PrintVersion() {
  Log::PrintErr("Dart VM version: %s\n", Dart_VersionString());
}


// clang-format off
static void PrintUsage() {
  Log::PrintErr(
      "Usage: dart [<vm-flags>] <dart-script-file> [<dart-options>]\n"
      "\n"
      "Executes the Dart script passed as <dart-script-file>.\n"
      "\n");
  if (!verbose_option) {
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
"  The observe flag is a convenience flag used to run a program with a\n"
"  set of options which are often useful for debugging under Observatory.\n"
"  These options are currently:\n"
"      --enable-vm-service[=<port>[/<bind-address>]]\n"
"      --pause-isolates-on-exit\n"
"      --pause-isolates-on-unhandled-exceptions\n"
"      --warn-on-pause-with-no-debugger\n"
"  This set is subject to change.\n"
"  Please see these options (--help --verbose) for further documentation.\n"
"--snapshot-kind=<snapshot_kind>\n"
"--snapshot=<file_name>\n"
"  These snapshot options are used to generate a snapshot of the loaded\n"
"  Dart script:\n"
"    <snapshot-kind> controls the kind of snapshot, it could be\n"
"                    script(default), app-aot or app-jit\n"
"    <file_name> specifies the file into which the snapshot is written\n"
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
"  The observe flag is a convenience flag used to run a program with a\n"
"  set of options which are often useful for debugging under Observatory.\n"
"  These options are currently:\n"
"      --enable-vm-service[=<port>[/<bind-address>]]\n"
"      --pause-isolates-on-exit\n"
"      --pause-isolates-on-unhandled-exceptions\n"
"      --warn-on-pause-with-no-debugger\n"
"  This set is subject to change.\n"
"  Please see these options for further documentation.\n"
"--snapshot-kind=<snapshot_kind>\n"
"--snapshot=<file_name>\n"
"  These snapshot options are used to generate a snapshot of the loaded\n"
"  Dart script:\n"
"    <snapshot-kind> controls the kind of snapshot, it could be\n"
"                    script(default), app-aot or app-jit\n"
"    <file_name> specifies the file into which the snapshot is written\n"
"--version\n"
"  Print the VM version.\n"
"\n"
"--trace-loading\n"
"  enables tracing of library and script loading\n"
"\n"
"--enable-vm-service[=<port>[/<bind-address>]]\n"
"  enables the VM service and listens on specified port for connections\n"
"  (default port number is 8181, default bind address is localhost).\n"
#if !defined(HOST_OS_MACOS)
"\n"
"--root-certs-file=<path>\n"
"  The path to a file containing the trusted root certificates to use for\n"
"  secure socket connections.\n"
"--root-certs-cache=<path>\n"
"  The path to a cache directory containing the trusted root certificates to\n"
"  use for secure socket connections.\n"
#endif  // !defined(HOST_OS_MACOS)
"\n"
"The following options are only used for VM development and may\n"
"be changed in any future version:\n");
    const char* print_flags = "--print_flags";
    Dart_SetVMFlags(1, &print_flags);
  }
}
// clang-format on


char* BuildIsolateName(const char* script_name, const char* func_name) {
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


static void OnIsolateShutdown(void* callback_data) {
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  isolate_data->OnIsolateShutdown();
}


static void DeleteIsolateData(void* callback_data) {
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  delete isolate_data;
}


static const char* kStdoutStreamId = "Stdout";
static const char* kStderrStreamId = "Stderr";


static bool ServiceStreamListenCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    SetCaptureStdout(true);
    return true;
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    SetCaptureStderr(true);
    return true;
  }
  return false;
}


static void ServiceStreamCancelCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    SetCaptureStdout(false);
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    SetCaptureStderr(false);
  }
}


static bool FileModifiedCallback(const char* url, int64_t since) {
  if (strncmp(url, "file:///", 8) == 0) {
    // If it isn't a file on local disk, we don't know if it has been
    // modified.
    return true;
  }
  int64_t data[File::kStatSize];
  File::Stat(url + 7, data);
  if (data[File::kType] == File::kDoesNotExist) {
    return true;
  }
  bool modified = data[File::kModifiedTime] > since;
  return modified;
}


static void GenerateAppAOTSnapshot() {
  if (use_blobs) {
    Snapshot::GenerateAppAOTAsBlobs(snapshot_filename);
  } else {
    Snapshot::GenerateAppAOTAsAssembly(snapshot_filename);
  }
}


#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    const int exit_code = Dart_IsCompilationError(result)                      \
                              ? kCompilationErrorExitCode                      \
                              : kErrorExitCode;                                \
    ErrorExit(exit_code, "%s\n", Dart_GetError(result));                       \
  }


static void WriteFile(const char* filename,
                      const uint8_t* buffer,
                      const intptr_t size) {
  File* file = File::Open(filename, File::kWriteTruncate);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to open file %s\n", filename);
  }
  if (!file->WriteFully(buffer, size)) {
    ErrorExit(kErrorExitCode, "Unable to write file %s\n", filename);
  }
  file->Release();
}


bool RunMainIsolate(const char* script_name, CommandLineOptions* dart_options) {
  // Call CreateIsolateAndSetup which creates an isolate and loads up
  // the specified application script.
  char* error = NULL;
  bool is_main_isolate = true;
  int exit_code = 0;
  char* isolate_name = BuildIsolateName(script_name, "main");
  Dart_Isolate isolate = CreateIsolateAndSetupHelper(
      is_main_isolate, script_name, "main", commandline_package_root,
      commandline_packages_file, NULL, &error, &exit_code);
  if (isolate == NULL) {
    delete[] isolate_name;
    Log::PrintErr("%s\n", error);
    free(error);
    error = NULL;
    Process::TerminateExitCodeHandler();
    error = Dart_Cleanup();
    if (error != NULL) {
      Log::PrintErr("VM cleanup failed: %s\n", error);
      free(error);
    }
    Process::ClearAllSignalHandlers();
    EventHandler::Stop();
    Platform::Exit((exit_code != 0) ? exit_code : kErrorExitCode);
  }
  main_isolate = isolate;
  delete[] isolate_name;

  Dart_EnterIsolate(isolate);
  ASSERT(isolate == Dart_CurrentIsolate());
  ASSERT(isolate != NULL);
  Dart_Handle result;

  Dart_EnterScope();

  if (gen_snapshot_kind == kScript) {
    Snapshot::GenerateScript(snapshot_filename);
  } else {
    // Lookup the library of the root script.
    Dart_Handle root_lib = Dart_RootLibrary();
    // Import the root library into the builtin library so that we can easily
    // lookup the main entry point exported from the root library.
    IsolateData* isolate_data =
        reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
    result = Dart_LibraryImportLibrary(isolate_data->builtin_lib(), root_lib,
                                       Dart_Null());
    if ((gen_snapshot_kind == kAppAOT) || (gen_snapshot_kind == kAppJIT)) {
      // Load the embedder's portion of the VM service's Dart code so it will
      // be included in the app snapshot.
      if (!VmService::LoadForGenPrecompiled()) {
        Log::PrintErr("VM service loading failed: %s\n",
                      VmService::GetErrorMessage());
        exit(kErrorExitCode);
      }
    }

    if (compile_all) {
      result = Dart_CompileAll();
      CHECK_RESULT(result);
    }

    if (parse_all) {
      result = Dart_ParseAll();
      CHECK_RESULT(result);
      Dart_ExitScope();
      // Shutdown the isolate.
      Dart_ShutdownIsolate();
      return false;
    }

    if (gen_snapshot_kind == kAppAOT) {
      Dart_QualifiedFunctionName standalone_entry_points[] = {
          {"dart:_builtin", "::", "_getMainClosure"},
          {"dart:_builtin", "::", "_getPrintClosure"},
          {"dart:_builtin", "::", "_getUriBaseClosure"},
          {"dart:_builtin", "::", "_libraryFilePath"},
          {"dart:_builtin", "::", "_resolveInWorkingDirectory"},
          {"dart:_builtin", "::", "_setPackageRoot"},
          {"dart:_builtin", "::", "_setPackagesMap"},
          {"dart:_builtin", "::", "_setWorkingDirectory"},
          {"dart:async", "::", "_setScheduleImmediateClosure"},
          {"dart:io", "::", "_getWatchSignalInternal"},
          {"dart:io", "::", "_makeDatagram"},
          {"dart:io", "::", "_makeUint8ListView"},
          {"dart:io", "::", "_setupHooks"},
          {"dart:io", "CertificateException", "CertificateException."},
          {"dart:io", "Directory", "Directory."},
          {"dart:io", "File", "File."},
          {"dart:io", "FileSystemException", "FileSystemException."},
          {"dart:io", "HandshakeException", "HandshakeException."},
          {"dart:io", "Link", "Link."},
          {"dart:io", "OSError", "OSError."},
          {"dart:io", "TlsException", "TlsException."},
          {"dart:io", "X509Certificate", "X509Certificate._"},
          {"dart:io", "_ExternalBuffer", "get:end"},
          {"dart:io", "_ExternalBuffer", "get:start"},
          {"dart:io", "_ExternalBuffer", "set:data"},
          {"dart:io", "_ExternalBuffer", "set:end"},
          {"dart:io", "_ExternalBuffer", "set:start"},
          {"dart:io", "_Platform", "set:_nativeScript"},
          {"dart:io", "_ProcessStartStatus", "set:_errorCode"},
          {"dart:io", "_ProcessStartStatus", "set:_errorMessage"},
          {"dart:io", "_SecureFilterImpl", "get:ENCRYPTED_SIZE"},
          {"dart:io", "_SecureFilterImpl", "get:SIZE"},
          {"dart:io", "_SecureFilterImpl", "get:buffers"},
          {"dart:isolate", "::", "_getIsolateScheduleImmediateClosure"},
          {"dart:isolate", "::", "_setupHooks"},
          {"dart:isolate", "::", "_startMainIsolate"},
          {"dart:vmservice_io", "::", "main"},
          {NULL, NULL, NULL}  // Must be terminated with NULL entries.
      };

      uint8_t* feedback_buffer = NULL;
      intptr_t feedback_length = 0;
      if (load_feedback_filename != NULL) {
        File* file = File::Open(load_feedback_filename, File::kRead);
        if (file == NULL) {
          ErrorExit(kErrorExitCode, "Failed to read JIT feedback.\n");
        }
        feedback_length = file->Length();
        feedback_buffer = reinterpret_cast<uint8_t*>(malloc(feedback_length));
        if (!file->ReadFully(feedback_buffer, feedback_length)) {
          ErrorExit(kErrorExitCode, "Failed to read JIT feedback.\n");
        }
        file->Release();
      }

      result = Dart_Precompile(standalone_entry_points, feedback_buffer,
                               feedback_length);
      if (feedback_buffer != NULL) {
        free(feedback_buffer);
      }
      CHECK_RESULT(result);
    }

    if (gen_snapshot_kind == kAppAOT) {
      GenerateAppAOTSnapshot();
    } else {
      if (Dart_IsNull(root_lib)) {
        ErrorExit(kErrorExitCode, "Unable to find root library for '%s'\n",
                  script_name);
      }

      if (gen_snapshot_kind == kAppJIT) Dart_SortClasses();

      // The helper function _getMainClosure creates a closure for the main
      // entry point which is either explicitly or implictly exported from the
      // root library.
      Dart_Handle main_closure =
          Dart_Invoke(isolate_data->builtin_lib(),
                      Dart_NewStringFromCString("_getMainClosure"), 0, NULL);
      CHECK_RESULT(main_closure);

      // Call _startIsolate in the isolate library to enable dispatching the
      // initial startup message.
      const intptr_t kNumIsolateArgs = 2;
      Dart_Handle isolate_args[kNumIsolateArgs];
      isolate_args[0] = main_closure;                        // entryPoint
      isolate_args[1] = CreateRuntimeOptions(dart_options);  // args

      Dart_Handle isolate_lib =
          Dart_LookupLibrary(Dart_NewStringFromCString("dart:isolate"));
      result = Dart_Invoke(isolate_lib,
                           Dart_NewStringFromCString("_startMainIsolate"),
                           kNumIsolateArgs, isolate_args);
      CHECK_RESULT(result);

      // Keep handling messages until the last active receive port is closed.
      result = Dart_RunLoop();
      // Generate an app snapshot after execution if specified.
      if (gen_snapshot_kind == kAppJIT) {
        if (!Dart_IsCompilationError(result)) {
          Snapshot::GenerateAppJIT(snapshot_filename);
        }
      }
      CHECK_RESULT(result);

      if (save_feedback_filename != NULL) {
        uint8_t* buffer = NULL;
        intptr_t size = 0;
        result = Dart_SaveJITFeedback(&buffer, &size);
        if (Dart_IsError(result)) {
          ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
        }
        WriteFile(save_feedback_filename, buffer, size);
      }
    }
  }

  if (snapshot_deps_filename != NULL) {
    Loader::ResolveDependenciesAsFilePaths();
    IsolateData* isolate_data =
        reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
    ASSERT(isolate_data != NULL);
    MallocGrowableArray<char*>* dependencies = isolate_data->dependencies();
    ASSERT(dependencies != NULL);
    File* file = File::Open(snapshot_deps_filename, File::kWriteTruncate);
    if (file == NULL) {
      ErrorExit(kErrorExitCode,
                "Error: Unable to open snapshot depfile: %s\n\n",
                snapshot_deps_filename);
    }
    bool success = true;
    success &= file->Print("%s: ", snapshot_filename);
    for (intptr_t i = 0; i < dependencies->length(); i++) {
      char* dep = dependencies->At(i);
      success &= file->Print("%s ", dep);
      free(dep);
    }
    success &= file->Print("\n");
    if (!success) {
      ErrorExit(kErrorExitCode,
                "Error: Unable to write snapshot depfile: %s\n\n",
                snapshot_deps_filename);
    }
    file->Release();
    isolate_data->set_dependencies(NULL);
    delete dependencies;
  }

  Dart_ExitScope();

  // Shutdown the isolate.
  Dart_ShutdownIsolate();

  // No restart.
  return false;
}

#undef CHECK_RESULT


// Observatory assets are only needed in the regular dart binary.
#if !defined(DART_PRECOMPILER) && !defined(NO_OBSERVATORY)
extern unsigned int observatory_assets_archive_len;
extern const uint8_t* observatory_assets_archive;


// |input| is assumed to be a gzipped stream.
// This function allocates the output buffer in the C heap and the caller
// is responsible for freeing it.
void Decompress(const uint8_t* input,
                unsigned int input_len,
                uint8_t** output,
                unsigned int* output_length) {
  ASSERT(input != NULL);
  ASSERT(input_len > 0);
  ASSERT(output != NULL);
  ASSERT(output_length != NULL);

  // Initialize output.
  *output = NULL;
  *output_length = 0;

  const unsigned int kChunkSize = 256 * 1024;
  uint8_t chunk_out[kChunkSize];
  z_stream strm;
  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  strm.avail_in = 0;
  strm.next_in = 0;
  int ret = inflateInit2(&strm, 32 + MAX_WBITS);
  ASSERT(ret == Z_OK);

  unsigned int input_cursor = 0;
  unsigned int output_cursor = 0;
  do {
    // Setup input.
    unsigned int size_in = input_len - input_cursor;
    if (size_in > kChunkSize) {
      size_in = kChunkSize;
    }
    strm.avail_in = size_in;
    strm.next_in = const_cast<uint8_t*>(&input[input_cursor]);

    // Inflate until we've exhausted the current input chunk.
    do {
      // Setup output.
      strm.avail_out = kChunkSize;
      strm.next_out = &chunk_out[0];
      // Inflate.
      ret = inflate(&strm, Z_SYNC_FLUSH);
      // We either hit the end of the stream or made forward progress.
      ASSERT((ret == Z_STREAM_END) || (ret == Z_OK));
      // Grow output buffer size.
      unsigned int size_out = kChunkSize - strm.avail_out;
      *output_length += size_out;
      *output = reinterpret_cast<uint8_t*>(realloc(*output, *output_length));
      // Copy output.
      memmove(&((*output)[output_cursor]), &chunk_out[0], size_out);
      output_cursor += size_out;
    } while (strm.avail_out == 0);

    // We've processed size_in bytes.
    input_cursor += size_in;

    // We're finished decompressing when zlib tells us.
  } while (ret != Z_STREAM_END);

  inflateEnd(&strm);
}


Dart_Handle GetVMServiceAssetsArchiveCallback() {
  uint8_t* decompressed = NULL;
  unsigned int decompressed_len = 0;
  Decompress(observatory_assets_archive, observatory_assets_archive_len,
             &decompressed, &decompressed_len);
  Dart_Handle tar_file =
      DartUtils::MakeUint8Array(decompressed, decompressed_len);
  // Free decompressed memory as it has been copied into a Dart array.
  free(decompressed);
  return tar_file;
}
#else   // !defined(DART_PRECOMPILER)
static Dart_GetVMServiceAssetsArchive GetVMServiceAssetsArchiveCallback = NULL;
#endif  // !defined(DART_PRECOMPILER)


void main(int argc, char** argv) {
  char* script_name;
  const int EXTRA_VM_ARGUMENTS = 8;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);
  CommandLineOptions dart_options(argc);
  bool print_flags_seen = false;
  bool verbose_debug_seen = false;

  // Perform platform specific initialization.
  if (!Platform::Initialize()) {
    Log::PrintErr("Initialization failed\n");
  }

  // On Windows, the argv strings are code page encoded and not
  // utf8. We need to convert them to utf8.
  bool argv_converted = ShellUtils::GetUtf8Argv(argc, argv);

  // Parse command line arguments.
  if (ParseArguments(argc, argv, &vm_options, &script_name, &dart_options,
                     &print_flags_seen, &verbose_debug_seen) < 0) {
    if (help_option) {
      PrintUsage();
      Platform::Exit(0);
    } else if (version_option) {
      PrintVersion();
      Platform::Exit(0);
    } else if (print_flags_seen) {
      // Will set the VM flags, print them out and then we exit as no
      // script was specified on the command line.
      Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
      Platform::Exit(0);
    } else {
      PrintUsage();
      Platform::Exit(kErrorExitCode);
    }
  }

  Thread::InitOnce();

  Loader::InitOnce();

  if (!DartUtils::SetOriginalWorkingDirectory()) {
    OSError err;
    Log::PrintErr("Error determining current directory: %s\n", err.message());
    Platform::Exit(kErrorExitCode);
  }

  AppSnapshot* app_snapshot = Snapshot::TryReadAppSnapshot(script_name);
  if (app_snapshot != NULL) {
    vm_run_app_snapshot = true;
    app_snapshot->SetBuffers(&vm_snapshot_data, &vm_snapshot_instructions,
                             &app_isolate_snapshot_data,
                             &app_isolate_snapshot_instructions);
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // Constant true if PRODUCT or DART_PRECOMPILED_RUNTIME.
  if ((gen_snapshot_kind != kNone) || vm_run_app_snapshot) {
    vm_options.AddArgument("--load_deferred_eagerly");
  }
#endif

  if (gen_snapshot_kind == kAppJIT) {
    vm_options.AddArgument("--fields_may_be_reset");
#if !defined(PRODUCT)
    vm_options.AddArgument("--collect_code=false");
#endif
  }
  if (gen_snapshot_kind == kAppAOT) {
    vm_options.AddArgument("--precompilation");
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  vm_options.AddArgument("--precompilation");
#endif
  if (gen_snapshot_kind == kAppJIT) {
    Process::SetExitHook(SnapshotOnExitHook);
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

  // Start event handler.
  TimerUtils::InitOnce();
  EventHandler::Start();

  // Initialize the Dart VM.
  Dart_InitializeParams init_params;
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  init_params.vm_snapshot_data = vm_snapshot_data;
  init_params.vm_snapshot_instructions = vm_snapshot_instructions;
  init_params.create = CreateIsolateAndSetup;
  init_params.shutdown = OnIsolateShutdown;
  init_params.cleanup = DeleteIsolateData;
  init_params.file_open = DartUtils::OpenFile;
  init_params.file_read = DartUtils::ReadFile;
  init_params.file_write = DartUtils::WriteFile;
  init_params.file_close = DartUtils::CloseFile;
  init_params.entropy_source = DartUtils::EntropySource;
  init_params.get_service_assets = GetVMServiceAssetsArchiveCallback;

  char* error = Dart_Initialize(&init_params);
  if (error != NULL) {
    EventHandler::Stop();
    Log::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    Platform::Exit(kErrorExitCode);
  }

  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);
  Dart_SetFileModifiedCallback(&FileModifiedCallback);

  // Run the main isolate until we aren't told to restart.
  while (RunMainIsolate(script_name, &dart_options)) {
    Log::PrintErr("Restarting VM\n");
  }

  // Terminate process exit-code handler.
  Process::TerminateExitCodeHandler();

  error = Dart_Cleanup();
  if (error != NULL) {
    Log::PrintErr("VM cleanup failed: %s\n", error);
    free(error);
  }
  Process::ClearAllSignalHandlers();
  EventHandler::Stop();

  delete app_snapshot;
  free(app_script_uri);

  // Free copied argument strings if converted.
  if (argv_converted) {
    for (int i = 0; i < argc; i++) {
      free(argv[i]);
    }
  }

  // Free environment if any.
  if (environment != NULL) {
    for (HashMap::Entry* p = environment->Start(); p != NULL;
         p = environment->Next(p)) {
      free(p->key);
      free(p->value);
    }
    delete environment;
  }

  Platform::Exit(Process::GlobalExitCode());
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  dart::bin::main(argc, argv);
  UNREACHABLE();
}
