// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/main_options.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bin/log.h"
#include "bin/options.h"
#include "bin/platform.h"
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
    "none", "script", "app-aot", "app-jit", NULL,
};

SnapshotKind Options::gen_snapshot_kind_ = kNone;

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

DEFINE_STRING_OPTION_CB(kernel_binaries,
                        { Options::dfe()->SetKernelBinaries(value); });
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

DEFINE_BOOL_OPTION_CB(hot_reload_test_mode, {
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
});

DEFINE_BOOL_OPTION_CB(hot_reload_rollback_test_mode, {
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
});

void Options::PrintVersion() {
  Log::PrintErr("Dart VM version: %s\n", Dart_VersionString());
}

// clang-format off
void Options::PrintUsage() {
  Log::PrintErr(
      "Usage: dart [<vm-flags>] <dart-script-file> [<dart-options>]\n"
      "\n"
      "Executes the Dart script passed as <dart-script-file>.\n"
      "\n");
  if (!Options::verbose_option()) {
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
    Dart_SetVMFlags(1, &print_flags);
  }
}
// clang-format on

dart::HashMap* Options::environment_ = NULL;
bool Options::ProcessEnvironmentOption(const char* arg,
                                       CommandLineOptions* vm_options) {
  return OptionProcessor::ProcessEnvironmentOption(arg, vm_options,
                                                   &Options::environment_);
}

void Options::DestroyEnvironment() {
  if (environment_ != NULL) {
    for (HashMap::Entry* p = environment_->Start(); p != NULL;
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

static const char* DEFAULT_VM_SERVICE_SERVER_IP = "localhost";
static const int DEFAULT_VM_SERVICE_SERVER_PORT = 8181;

const char* Options::vm_service_server_ip_ = DEFAULT_VM_SERVICE_SERVER_IP;
int Options::vm_service_server_port_ = -1;
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
    Log::PrintErr(
        "unrecognized --enable-vm-service option syntax. "
        "Use --enable-vm-service[=<port number>[/<bind address>]]\n");
    return false;
  }

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
    Log::PrintErr(
        "unrecognized --observe option syntax. "
        "Use --observe[=<port number>[/<bind address>]]\n");
    return false;
  }

  // These options should also be documented in the help message.
  vm_options->AddArgument("--pause-isolates-on-exit");
  vm_options->AddArgument("--pause-isolates-on-unhandled-exceptions");
  vm_options->AddArgument("--profiler");
  vm_options->AddArgument("--warn-on-pause-with-no-debugger");
  return true;
}

int Options::ParseArguments(int argc,
                            char** argv,
                            bool vm_run_app_snapshot,
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
    if (OptionProcessor::TryProcess(argv[i], vm_options)) {
      i++;
    } else {
      // Check if this flag is a potentially valid VM flag.
      const char* kChecked = "-c";
      const char* kPackageRoot = "-p";
      if (strncmp(argv[i], kPackageRoot, strlen(kPackageRoot)) == 0) {
        // If argv[i] + strlen(kPackageRoot) is \0, then look in argv[i + 1]
        // Otherwise set Option::package_root_ = argv[i] + strlen(kPackageRoot)
        const char* opt = argv[i] + strlen(kPackageRoot);
        if (opt[0] == '\0') {
          i++;
          opt = argv[i];
          if ((opt == NULL) || (opt[0] == '-')) {
            Log::PrintErr("Invalid option specification : '%s'\n", argv[i - 1]);
            i++;
            break;
          }
        }
        package_root_ = opt;
        i++;
        continue;  // '-p' is not a VM flag so don't add to vm options.
      } else if (strncmp(argv[i], kChecked, strlen(kChecked)) == 0) {
        vm_options->AddArgument("--checked");
        i++;
        continue;  // '-c' is not a VM flag so don't add to vm options.
      } else if (!OptionProcessor::IsValidFlag(argv[i], kPrefix, kPrefixLen)) {
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

  Socket::set_short_socket_read(Options::short_socket_read());
  Socket::set_short_socket_write(Options::short_socket_write());
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
  SSLCertContext::set_root_certs_file(Options::root_certs_file());
  SSLCertContext::set_root_certs_cache(Options::root_certs_cache());
#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)

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
  if ((Options::package_root() != NULL) && (packages_file_ != NULL)) {
    Log::PrintErr(
        "Specifying both a packages directory and a packages "
        "file is invalid.\n");
    return -1;
  }
  if ((Options::package_root() != NULL) &&
      (strlen(Options::package_root()) == 0)) {
    Log::PrintErr("Empty package root specified.\n");
    return -1;
  }
  if ((packages_file_ != NULL) && (strlen(packages_file_) == 0)) {
    Log::PrintErr("Empty package file name specified.\n");
    return -1;
  }
  if (((gen_snapshot_kind_ != kNone) || (snapshot_deps_filename_ != NULL)) &&
      (snapshot_filename_ == NULL)) {
    Log::PrintErr("Generating a snapshot requires a filename (--snapshot).\n");
    return -1;
  }
  if ((gen_snapshot_kind_ != kNone) && vm_run_app_snapshot) {
    Log::PrintErr(
        "Specifying an option to generate a snapshot and"
        " run using a snapshot is invalid.\n");
    return -1;
  }

  // If --snapshot is given without --snapshot-kind, default to script snapshot.
  if ((snapshot_filename_ != NULL) && (gen_snapshot_kind_ == kNone)) {
    gen_snapshot_kind_ = kScript;
  }

  return 0;
}

}  // namespace bin
}  // namespace dart
