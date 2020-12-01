// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/main_options.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bin/dartdev_isolate.h"
#include "bin/error_exit.h"
#include "bin/options.h"
#include "bin/platform.h"
#include "bin/utils.h"
#include "platform/syslog.h"
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
#include "bin/security_context.h"
#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
#include "bin/socket.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

// These strings must match the enum SnapshotKind in main_options.h.
static const char* kSnapshotKindNames[] = {
    "none",
    "kernel",
    "app-jit",
    NULL,
};

SnapshotKind Options::gen_snapshot_kind_ = kNone;
bool Options::enable_vm_service_ = false;

#define OPTION_FIELD(variable) Options::variable##_

#define STRING_OPTION_DEFINITION(name, variable)                               \
  const char* OPTION_FIELD(variable) = NULL;                                   \
  DEFINE_STRING_OPTION(name, OPTION_FIELD(variable))
STRING_OPTIONS_LIST(STRING_OPTION_DEFINITION)
#undef STRING_OPTION_DEFINITION

#define BOOL_OPTION_DEFINITION(name, variable)                                 \
  bool OPTION_FIELD(variable) = false;                                         \
  DEFINE_BOOL_OPTION(name, OPTION_FIELD(variable))
BOOL_OPTIONS_LIST(BOOL_OPTION_DEFINITION)
#if defined(DEBUG)
DEBUG_BOOL_OPTIONS_LIST(BOOL_OPTION_DEFINITION)
#endif
#undef BOOL_OPTION_DEFINITION

#define SHORT_BOOL_OPTION_DEFINITION(short_name, long_name, variable)          \
  bool OPTION_FIELD(variable) = false;                                         \
  DEFINE_BOOL_OPTION_SHORT(short_name, long_name, OPTION_FIELD(variable))
SHORT_BOOL_OPTIONS_LIST(SHORT_BOOL_OPTION_DEFINITION)
#undef SHORT_BOOL_OPTION_DEFINITION

#define ENUM_OPTION_DEFINITION(name, type, variable)                           \
  DEFINE_ENUM_OPTION(name, type, OPTION_FIELD(variable))
ENUM_OPTIONS_LIST(ENUM_OPTION_DEFINITION)
#undef ENUM_OPTION_DEFINITION

#define CB_OPTION_DEFINITION(callback)                                         \
  static bool callback##Helper(const char* arg, CommandLineOptions* o) {       \
    return Options::callback(arg, o);                                          \
  }                                                                            \
  DEFINE_CB_OPTION(callback##Helper)
CB_OPTIONS_LIST(CB_OPTION_DEFINITION)
#undef CB_OPTION_DEFINITION

#if !defined(DART_PRECOMPILED_RUNTIME)
DFE* Options::dfe_ = NULL;

DEFINE_STRING_OPTION_CB(dfe, { Options::dfe()->set_frontend_filename(value); });
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

static void hot_reload_test_mode_callback(CommandLineOptions* vm_options) {
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
#if !defined(DART_PRECOMPILED_RUNTIME)
  Options::dfe()->set_use_incremental_compiler(true);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

DEFINE_BOOL_OPTION_CB(hot_reload_test_mode, hot_reload_test_mode_callback);

static void hot_reload_rollback_test_mode_callback(
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
#if !defined(DART_PRECOMPILED_RUNTIME)
  Options::dfe()->set_use_incremental_compiler(true);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

DEFINE_BOOL_OPTION_CB(hot_reload_rollback_test_mode,
                      hot_reload_rollback_test_mode_callback);

void Options::PrintVersion() {
  Syslog::PrintErr("Dart SDK version: %s\n", Dart_VersionString());
}

// clang-format off
void Options::PrintUsage() {
  Syslog::PrintErr(
      "Usage: dart [<vm-flags>] <dart-script-file> [<script-arguments>]\n"
      "\n"
      "Executes the Dart script <dart-script-file> with "
      "the given list of <script-arguments>.\n"
      "\n");
  if (!Options::verbose_option()) {
    Syslog::PrintErr(
"Common VM flags:\n"
"--enable-asserts\n"
"  Enable assert statements.\n"
"--help or -h\n"
"  Display this message (add -v or --verbose for information about\n"
"  all VM options).\n"
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
"--write-service-info=<file_uri>\n"
"  Outputs information necessary to connect to the VM service to the\n"
"  specified file in JSON format. Useful for clients which are unable to\n"
"  listen to stdout for the Observatory listening message.\n"
"--snapshot-kind=<snapshot_kind>\n"
"--snapshot=<file_name>\n"
"  These snapshot options are used to generate a snapshot of the loaded\n"
"  Dart script:\n"
"    <snapshot-kind> controls the kind of snapshot, it could be\n"
"                    kernel(default) or app-jit\n"
"    <file_name> specifies the file into which the snapshot is written\n"
"--version\n"
"  Print the SDK version.\n");
  } else {
    Syslog::PrintErr(
"Supported options:\n"
"--enable-asserts\n"
"  Enable assert statements.\n"
"--help or -h\n"
"  Display this message (add -v or --verbose for information about\n"
"  all VM options).\n"
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
"--version\n"
"  Print the VM version.\n"
"\n"
"--trace-loading\n"
"  enables tracing of library and script loading\n"
"\n"
"--enable-vm-service[=<port>[/<bind-address>]]\n"
"  Enables the VM service and listens on specified port for connections\n"
"  (default port number is 8181, default bind address is localhost).\n"
"\n"
"--disable-service-auth-codes\n"
"  Disables the requirement for an authentication code to communicate with\n"
"  the VM service. Authentication codes help protect against CSRF attacks,\n"
"  so it is not recommended to disable them unless behind a firewall on a\n"
"  secure device.\n"
"\n"
"--enable-service-port-fallback\n"
"  When the VM service is told to bind to a particular port, fallback to 0 if\n"
"  it fails to bind instead of failing to start.\n"
"\n"
"--root-certs-file=<path>\n"
"  The path to a file containing the trusted root certificates to use for\n"
"  secure socket connections.\n"
"--root-certs-cache=<path>\n"
"  The path to a cache directory containing the trusted root certificates to\n"
"  use for secure socket connections.\n"
#if defined(HOST_OS_LINUX) || \
    defined(HOST_OS_ANDROID) || \
    defined(HOST_OS_FUCHSIA)
"--namespace=<path>\n"
"  The path to a directory that dart:io calls will treat as the root of the\n"
"  filesystem.\n"
#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
"\n"
"The following options are only used for VM development and may\n"
"be changed in any future version:\n");
    const char* print_flags = "--print_flags";
    char* error = Dart_SetVMFlags(1, &print_flags);
    ASSERT(error == NULL);
  }
}
// clang-format on

dart::SimpleHashMap* Options::environment_ = NULL;
bool Options::ProcessEnvironmentOption(const char* arg,
                                       CommandLineOptions* vm_options) {
  return OptionProcessor::ProcessEnvironmentOption(arg, vm_options,
                                                   &Options::environment_);
}

void Options::DestroyEnvironment() {
  if (environment_ != NULL) {
    for (SimpleHashMap::Entry* p = environment_->Start(); p != NULL;
         p = environment_->Next(p)) {
      free(p->key);
      free(p->value);
    }
    delete environment_;
    environment_ = NULL;
  }
}

bool Options::ExtractPortAndAddress(const char* option_value,
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

// Returns true if arg starts with the characters "--" followed by option, but
// all '_' in the option name are treated as '-'.
static bool IsOption(const char* arg, const char* option) {
  if (arg[0] != '-' || arg[1] != '-') {
    // Special case first two characters to avoid recognizing __flag.
    return false;
  }
  for (int i = 0; option[i] != '\0'; i++) {
    auto c = arg[i + 2];
    if (c == '\0') {
      // Not long enough.
      return false;
    }
    if ((c == '_' ? '-' : c) != option[i]) {
      return false;
    }
  }
  return true;
}

const char* Options::vm_service_server_ip_ = DEFAULT_VM_SERVICE_SERVER_IP;
int Options::vm_service_server_port_ = INVALID_VM_SERVICE_SERVER_PORT;
bool Options::ProcessEnableVmServiceOption(const char* arg,
                                           CommandLineOptions* vm_options) {
  const char* value =
      OptionProcessor::ProcessOption(arg, "--enable-vm-service");
  if (value == NULL) {
    return false;
  }
  if (!ExtractPortAndAddress(
          value, &vm_service_server_port_, &vm_service_server_ip_,
          DEFAULT_VM_SERVICE_SERVER_PORT, DEFAULT_VM_SERVICE_SERVER_IP)) {
    Syslog::PrintErr(
        "unrecognized --enable-vm-service option syntax. "
        "Use --enable-vm-service[=<port number>[/<bind address>]]\n");
    return false;
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  dfe()->set_use_incremental_compiler(true);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  enable_vm_service_ = true;
  return true;
}

bool Options::ProcessObserveOption(const char* arg,
                                   CommandLineOptions* vm_options) {
  const char* value = OptionProcessor::ProcessOption(arg, "--observe");
  if (value == NULL) {
    return false;
  }
  if (!ExtractPortAndAddress(
          value, &vm_service_server_port_, &vm_service_server_ip_,
          DEFAULT_VM_SERVICE_SERVER_PORT, DEFAULT_VM_SERVICE_SERVER_IP)) {
    Syslog::PrintErr(
        "unrecognized --observe option syntax. "
        "Use --observe[=<port number>[/<bind address>]]\n");
    return false;
  }

  // These options should also be documented in the help message.
  vm_options->AddArgument("--pause-isolates-on-exit");
  vm_options->AddArgument("--pause-isolates-on-unhandled-exceptions");
  vm_options->AddArgument("--profiler");
  vm_options->AddArgument("--warn-on-pause-with-no-debugger");
#if !defined(DART_PRECOMPILED_RUNTIME)
  dfe()->set_use_incremental_compiler(true);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  enable_vm_service_ = true;
  return true;
}

// Explicitly handle VM flags that can be parsed by DartDev's run command.
bool Options::ProcessVMDebuggingOptions(const char* arg,
                                        CommandLineOptions* vm_options) {
#define IS_DEBUG_OPTION(name, arg)                                             \
  if (strncmp(name, arg, strlen(name)) == 0) {                                 \
    vm_options->AddArgument(arg);                                              \
    return true;                                                               \
  }

// This is an exhaustive set of VM flags that are accepted by 'dart run'. Flags
// defined in main_options.h do not need to be handled here as they already
// have handlers generated.
//
// NOTE: When updating this list of VM flags, be sure to make the corresponding
// changes in pkg/dartdev/lib/src/commands/run.dart.
#define HANDLE_DARTDEV_VM_DEBUG_OPTIONS(V, arg)                                \
  V("--enable-asserts", arg)                                                   \
  V("--pause-isolates-on-exit", arg)                                           \
  V("--no-pause-isolates-on-exit", arg)                                        \
  V("--pause-isolates-on-start", arg)                                          \
  V("--no-pause-isolates-on-start", arg)                                       \
  V("--pause-isolates-on-unhandled-exception", arg)                            \
  V("--no-pause-isolates-on-unhandled-exception", arg)                         \
  V("--warn-on-pause-with-no-debugger", arg)                                   \
  V("--no-warn-on-pause-with-no-debugger", arg)
  HANDLE_DARTDEV_VM_DEBUG_OPTIONS(IS_DEBUG_OPTION, arg);

#undef IS_DEBUG_OPTION
#undef HANDLE_DARTDEV_VM_DEBUG_OPTIONS

  return false;
}

bool Options::ParseArguments(int argc,
                             char** argv,
                             bool vm_run_app_snapshot,
                             CommandLineOptions* vm_options,
                             char** script_name,
                             CommandLineOptions* dart_options,
                             bool* print_flags_seen,
                             bool* verbose_debug_seen) {
  // Store the executable name.
  Platform::SetExecutableName(argv[0]);

  // Start the rest after the executable name.
  int i = 1;

  CommandLineOptions temp_vm_options(vm_options->max_count());

  bool enable_dartdev_analytics = false;
  bool disable_dartdev_analytics = false;

  // Parse out the vm options.
  while (i < argc) {
    bool skipVmOption = false;
    if (OptionProcessor::TryProcess(argv[i], &temp_vm_options)) {
      i++;
    } else {
      // Check if this flag is a potentially valid VM flag.
      if (!OptionProcessor::IsValidFlag(argv[i])) {
        break;
      }
      // The following flags are processed as DartDev flags and are not to
      // be treated as if they are VM flags.
      if (IsOption(argv[i], "print-flags")) {
        *print_flags_seen = true;
      } else if (IsOption(argv[i], "verbose-debug")) {
        *verbose_debug_seen = true;
      } else if (IsOption(argv[i], "enable-analytics")) {
        enable_dartdev_analytics = true;
        skipVmOption = true;
      } else if (IsOption(argv[i], "disable-analytics")) {
        disable_dartdev_analytics = true;
        skipVmOption = true;
      } else if (IsOption(argv[i], "no-analytics")) {
        // Just add this option even if we don't go to dartdev.
        // It is irelevant for the vm.
        dart_options->AddArgument("--no-analytics");
        skipVmOption = true;
      }
      if (!skipVmOption) {
        temp_vm_options.AddArgument(argv[i]);
      }
      i++;
    }
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  Options::dfe()->set_use_dfe();
#else
  // DartDev is not supported in AOT.
  Options::disable_dart_dev_ = true;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  if (Options::deterministic()) {
    // Both an embedder and VM flag.
    temp_vm_options.AddArgument("--deterministic");
  }

  Socket::set_short_socket_read(Options::short_socket_read());
  Socket::set_short_socket_write(Options::short_socket_write());
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
  SSLCertContext::set_root_certs_file(Options::root_certs_file());
  SSLCertContext::set_root_certs_cache(Options::root_certs_cache());
  SSLCertContext::set_long_ssl_cert_evaluation(
      Options::long_ssl_cert_evaluation());
#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)

  // The arguments to the VM are at positions 1 through i-1 in argv.
  Platform::SetExecutableArguments(i, argv);

  bool implicitly_use_dart_dev = false;
  bool run_script = false;
  // Get the script name.
  if (i < argc) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    // If the script name is a valid file or a URL, we'll run the script
    // directly. Otherwise, this might be a DartDev command and we need to try
    // to find the DartDev snapshot so we can forward the command and its
    // arguments.
    bool is_potential_file_path = !DartDevIsolate::ShouldParseCommand(argv[i]);
#else
    bool is_potential_file_path = true;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
    if (Options::disable_dart_dev() ||
        (Options::snapshot_filename() != nullptr) ||
        (is_potential_file_path && !enable_vm_service_)) {
      *script_name = Utils::StrDup(argv[i]);
      run_script = true;
      i++;
    }
#if !defined(DART_PRECOMPILED_RUNTIME)
    else {  // NOLINT
      DartDevIsolate::set_should_run_dart_dev(true);
    }
    if (!Options::disable_dart_dev() && enable_vm_service_) {
      // Handle the special case where the user is running a Dart program
      // without using a DartDev command and wants to use the VM service. Here
      // we'll run the program using DartDev as it's used to spawn a DDS
      // instance.
      if (is_potential_file_path) {
        implicitly_use_dart_dev = true;
      }
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  else if (!Options::disable_dart_dev() &&  // NOLINT
           ((Options::help_option() && !Options::verbose_option()) ||
            (argc == 1))) {
    DartDevIsolate::set_should_run_dart_dev(true);
    // Let DartDev handle the default help message.
    dart_options->AddArgument("help");
    return true;
  } else if (!Options::disable_dart_dev() &&
             (enable_dartdev_analytics || disable_dartdev_analytics)) {
    // The analytics flags are a special case as we don't have a target script
    // or DartDev command but we still want to launch DartDev.
    DartDevIsolate::set_should_run_dart_dev(true);

    return true;
  }

#endif    // !defined(DART_PRECOMPILED_RUNTIME)
  else {  // NOLINT
    return false;
  }
  USE(enable_dartdev_analytics);
  USE(disable_dartdev_analytics);

  const char** vm_argv = temp_vm_options.arguments();
  int vm_argc = temp_vm_options.count();

  vm_options->AddArguments(vm_argv, vm_argc);

  // If running with dartdev, attempt to parse VM flags which are part of the
  // dartdev command (e.g., --enable-vm-service, --observe, etc).
  if (!run_script) {
    int tmp_i = i;
    // We only run the CLI implicitly if the service is enabled and the user
    // didn't run with the 'run' command. If they did provide a command, we need
    // to skip it here to continue parsing VM flags.
    if (!implicitly_use_dart_dev) {
      tmp_i++;
    }
    while (tmp_i < argc) {
      // Check if this flag is a potentially valid VM flag. If not, we've likely
      // hit a script name and are done parsing VM flags.
      if (!OptionProcessor::IsValidFlag(argv[tmp_i])) {
        break;
      }
      OptionProcessor::TryProcess(argv[tmp_i], vm_options);
      tmp_i++;
    }
  }
  bool first_option = true;
  // Parse out options to be passed to dart main.
  while (i < argc) {
    if (implicitly_use_dart_dev && first_option) {
      // Special case where user enables VM service without using a dartdev
      // run command. If 'run' is provided, it will be the first argument
      // processed in this loop.
      dart_options->AddArgument("run");
    } else {
      dart_options->AddArgument(argv[i]);
      i++;
    }
    // Add DDS specific flags immediately after the dartdev command.
    if (first_option) {
      // DDS is only enabled for the run command. Make sure we don't pass DDS
      // specific flags along with other commands, otherwise argument parsing
      // will fail unexpectedly.
      bool run_command = implicitly_use_dart_dev;
      if (!run_command && strcmp(argv[i - 1], "run") == 0) {
        run_command = true;
      }
      if (!Options::disable_dart_dev() && enable_vm_service_ && run_command) {
        const char* dds_format_str = "--launch-dds=%s:%d";
        size_t size =
            snprintf(nullptr, 0, dds_format_str, vm_service_server_ip(),
                     vm_service_server_port());
        // Make room for '\0'.
        ++size;
        char* dds_uri = new char[size];
        snprintf(dds_uri, size, dds_format_str, vm_service_server_ip(),
                 vm_service_server_port());
        dart_options->AddArgument(dds_uri);

        // Only add --disable-service-auth-codes if dartdev is being run
        // implicitly. Otherwise it will already be forwarded.
        if (implicitly_use_dart_dev && Options::vm_service_auth_disabled()) {
          dart_options->AddArgument("--disable-service-auth-codes");
        }
      }
      first_option = false;
    }
  }
  // Verify consistency of arguments.

  // snapshot_depfile is an alias for depfile. Passing them both is an error.
  if ((snapshot_deps_filename_ != NULL) && (depfile_ != NULL)) {
    Syslog::PrintErr("Specify only one of --depfile and --snapshot_depfile\n");
    return false;
  }
  if (snapshot_deps_filename_ != NULL) {
    depfile_ = snapshot_deps_filename_;
    snapshot_deps_filename_ = NULL;
  }

  if ((packages_file_ != NULL) && (strlen(packages_file_) == 0)) {
    Syslog::PrintErr("Empty package file name specified.\n");
    return false;
  }
  if ((gen_snapshot_kind_ != kNone) && (snapshot_filename_ == NULL)) {
    Syslog::PrintErr(
        "Generating a snapshot requires a filename (--snapshot).\n");
    return false;
  }
  if ((gen_snapshot_kind_ == kNone) && (depfile_ != NULL) &&
      (snapshot_filename_ == NULL) && (depfile_output_filename_ == NULL)) {
    Syslog::PrintErr(
        "Generating a depfile requires an output filename"
        " (--depfile-output-filename or --snapshot).\n");
    return false;
  }
  if ((gen_snapshot_kind_ != kNone) && vm_run_app_snapshot) {
    Syslog::PrintErr(
        "Specifying an option to generate a snapshot and"
        " run using a snapshot is invalid.\n");
    return false;
  }

  // If --snapshot is given without --snapshot-kind, default to script snapshot.
  if ((snapshot_filename_ != NULL) && (gen_snapshot_kind_ == kNone)) {
    gen_snapshot_kind_ = kKernel;
  }

  return true;
}

}  // namespace bin
}  // namespace dart
