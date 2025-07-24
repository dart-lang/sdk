// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/main_options.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bin/common_options.h"
#include "bin/error_exit.h"
#include "bin/file_system_watcher.h"
#if defined(DART_IO_SECURE_SOCKET_DISABLED)
#include "bin/io_service_no_ssl.h"
#else  // defined(DART_IO_SECURE_SOCKET_DISABLED)
#include "bin/io_service.h"
#endif  // defined(DART_IO_SECURE_SOCKET_DISABLED)
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
static const char* const kSnapshotKindNames[] = {
    "none",
    "kernel",
    "app-jit",
    nullptr,
};

SnapshotKind Options::gen_snapshot_kind_ = kNone;

#if !defined(DART_PRECOMPILED_RUNTIME)
DFE* Options::dfe_ = nullptr;

DEFINE_STRING_OPTION_CB(dfe, { Options::dfe()->set_frontend_filename(value); });
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#define OPTION_FIELD(variable) Options::variable##_

#define STRING_OPTION_DEFINITION(name, variable)                               \
  const char* OPTION_FIELD(variable) = nullptr;                                \
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

bool Options::ParseArguments(int argc,
                             char** argv,
                             bool vm_run_app_snapshot,
                             bool parsing_dart_vm_options,
                             CommandLineOptions* vm_options,
                             char** script_name,
                             CommandLineOptions* dart_options,
                             bool* print_flags_seen) {
  int i = 0;
#if !defined(DART_PRECOMPILED_RUNTIME)
  // DART_VM_OPTIONS is only implemented for compiled executables.
  ASSERT(!parsing_dart_vm_options);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  if (!parsing_dart_vm_options) {
    // Start processing arguments after argv[0] which would be the executable.
    i = 1;
  }

  CommandLineOptions temp_vm_options(vm_options->max_count());
  // Parse out the vm options.
  while (i < argc) {
    bool skipVmOption = false;
    if (!OptionProcessor::TryProcess(argv[i], &temp_vm_options)) {
      // Check if this flag is a potentially valid VM flag.
      if (!OptionProcessor::IsValidFlag(argv[i])) {
        break;
      }
      if (IsOption(argv[i], "print-flags")) {
        *print_flags_seen = true;
      } else if (IsOption(argv[i], "disable-dart-dev")) {
        skipVmOption = true;
      }
      if (!skipVmOption) {
        temp_vm_options.AddArgument(argv[i]);
      }
    } else if (IsOption(argv[i], "profile-microtasks")) {
      temp_vm_options.AddArgument(argv[i]);
    }
    i++;
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  Options::dfe()->set_use_dfe();
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
  SSLCertContext::set_bypass_trusting_system_roots(
      Options::bypass_trusting_system_roots());
#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)

  FileSystemWatcher::set_delayed_filewatch_callback(
      Options::delayed_filewatch_callback());

  if (Options::deterministic()) {
    IOService::set_max_concurrency(1);
  }

  // The arguments to the VM are at positions 1 through i-1 in argv.
  Platform::SetExecutableArguments(i, argv);

  // Get the script name.
  if (i < argc) {
    *script_name = Utils::StrDup(argv[i]);
    i++;
    // Handle argument parsing errors and missing script / command name when not
    // processing options set via DART_VM_OPTIONS.
  } else if (!parsing_dart_vm_options || Options::help_option() ||  // NOLINT
             Options::version_option()) {                           // NOLINT
    return false;
  }

  const char** vm_argv = temp_vm_options.arguments();
  int vm_argc = temp_vm_options.count();
  vm_options->AddArguments(vm_argv, vm_argc);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // If we're parsing DART_VM_OPTIONS, there shouldn't be any script set or
  // Dart arguments left to parse.
  if (parsing_dart_vm_options) {
    ASSERT(i == argc);
    return true;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Parse out options to be passed to dart main.
  while (i < argc) {
    dart_options->AddArgument(argv[i]);
    i++;
  }
  if (!parsing_dart_vm_options) {
    // Store the executable name.
    if (Options::executable_name() != nullptr) {
      Platform::SetExecutableName(Options::executable_name());
      Platform::SetResolvedExecutableName(Options::executable_name());
    } else {
      Platform::SetExecutableName(argv[0]);
    }
  }

  // Verify consistency of arguments.

  // snapshot_depfile is an alias for depfile. Passing them both is an error.
  if ((snapshot_deps_filename_ != nullptr) && (depfile_ != nullptr)) {
    Syslog::PrintErr("Specify only one of --depfile and --snapshot_depfile\n");
    return false;
  }
  if (snapshot_deps_filename_ != nullptr) {
    depfile_ = snapshot_deps_filename_;
    snapshot_deps_filename_ = nullptr;
  }

  if ((packages_file_ != nullptr) && (strlen(packages_file_) == 0)) {
    Syslog::PrintErr("Empty package file name specified.\n");
    return false;
  }
  if ((gen_snapshot_kind_ != kNone) && (snapshot_filename_ == nullptr)) {
    Syslog::PrintErr(
        "Generating a snapshot requires a filename (--snapshot).\n");
    return false;
  }
  if ((gen_snapshot_kind_ == kNone) && (depfile_ != nullptr) &&
      (snapshot_filename_ == nullptr) &&
      (depfile_output_filename_ == nullptr)) {
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
  if ((snapshot_filename_ != nullptr) && (gen_snapshot_kind_ == kNone)) {
    gen_snapshot_kind_ = kKernel;
  }

  return true;
}

// These strings must match the enum VerbosityLevel in main_options.h.
VerbosityLevel Options::verbosity_ = kAll;
bool Options::enable_vm_service_ = false;
bool Options::enable_dds_ = true;

void Options::PrintVersion() {
  _PrintVersion();
}

// clang-format off
void Options::PrintUsage() {
  _PrintUsage();
  if (!Options::verbose_option()) {
    _PrintNonVerboseUsage();
  } else {
    _PrintVerboseUsage();
  }
}
// clang-format on

dart::SimpleHashMap* Options::environment_ = nullptr;
bool Options::ProcessEnvironmentOption(const char* arg,
                                       CommandLineOptions* vm_options) {
  return OptionProcessor::ProcessEnvironmentOption(arg, vm_options,
                                                   &Options::environment_);
}

void Options::Cleanup() {
#if defined(DART_PRECOMPILED_RUNTIME)
  DestroyEnvArgv();
#endif
  DestroyEnvironment();
}

void Options::DestroyEnvironment() {
  if (environment_ != nullptr) {
    for (SimpleHashMap::Entry* p = environment_->Start(); p != nullptr;
         p = environment_->Next(p)) {
      free(p->key);
      free(p->value);
    }
    delete environment_;
    environment_ = nullptr;
  }
}

#if defined(DART_PRECOMPILED_RUNTIME)
// Retrieves the set of arguments stored in the DART_VM_OPTIONS environment
// variable.
//
// DART_VM_OPTIONS should contain a list of comma-separated options and flags
// with no spaces. Options that support providing multiple values as
// comma-separated lists (e.g., --timeline-streams=Dart,GC,Compiler,Microtask)
// are not supported and will cause argument parsing to fail.
char** Options::GetEnvArguments(int* argc) {
  ASSERT(argc != nullptr);
  const char* env_args_str = std::getenv("DART_VM_OPTIONS");
  if (env_args_str == nullptr) {
    *argc = 0;
    return nullptr;
  }

  intptr_t n = strlen(env_args_str);
  if (n == 0) {
    return nullptr;
  }

  // Find the number of arguments based on the number of ','s.
  //
  // WARNING: this won't work for arguments that support CSVs. There's less
  // than a handful of options that support multiple values. If we want to
  // support this case, we need to determine a way to specify groupings of CSVs
  // in environment variables.
  int arg_count = 1;
  for (int i = 0; i < n; ++i) {
    // Ignore the last comma if it's the last character in the string.
    if (env_args_str[i] == ',' && i + 1 != n) {
      arg_count++;
    }
  }

  env_argv_ = new char*[arg_count];
  env_argc_ = arg_count;
  *argc = arg_count;

  int current_arg = 0;
  char* token;
  char* rest = const_cast<char*>(env_args_str);

  // Split out the individual arguments.
  while ((token = strtok_r(rest, ",", &rest)) != nullptr) {
    // TODO(bkonyi): consider stripping leading/trailing whitespace from
    // arguments.
    env_argv_[current_arg++] = Utils::StrNDup(token, rest - token);
  }

  return env_argv_;
}

char** Options::env_argv_ = nullptr;
int Options::env_argc_ = 0;

void Options::DestroyEnvArgv() {
  for (int i = 0; i < env_argc_; ++i) {
    free(env_argv_[i]);
  }
  delete[] env_argv_;
  env_argv_ = nullptr;
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

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
  if (slash == nullptr) {
    *out_ip = default_ip;
    *out_port = port;
    return true;
  }

  *out_ip = slash + 1;
  *out_port = port;
  return true;
}

#if !defined(PRODUCT)
static constexpr const char* DEFAULT_VM_SERVICE_SERVER_IP = "localhost";
static constexpr int DEFAULT_VM_SERVICE_SERVER_PORT = 8181;
static constexpr int INVALID_VM_SERVICE_SERVER_PORT = -1;
const char* Options::vm_service_server_ip_ = DEFAULT_VM_SERVICE_SERVER_IP;
int Options::vm_service_server_port_ = INVALID_VM_SERVICE_SERVER_PORT;
#endif  // !defined(PRODUCT)

bool Options::ProcessEnableVmServiceOption(const char* arg,
                                           CommandLineOptions* vm_options) {
  const char* value =
      OptionProcessor::ProcessOption(arg, "--enable-vm-service");
  if (value == nullptr) {
    return false;
  }
#if !defined(PRODUCT)
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
#else
  // VM service not available in product mode.
  return false;
#endif  // !defined(PRODUCT)
}

bool Options::ProcessObserveOption(const char* arg,
                                   CommandLineOptions* vm_options) {
  const char* value = OptionProcessor::ProcessOption(arg, "--observe");
  if (value == nullptr) {
    return false;
  }
#if !defined(PRODUCT)
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
  vm_options->AddArgument("--timeline-streams=\"Compiler,Dart,GC,Microtask\"");
#if !defined(DART_PRECOMPILED_RUNTIME)
  dfe()->set_use_incremental_compiler(true);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  enable_vm_service_ = true;
  return true;
#else
  // VM service not available in product mode.
  return false;
#endif  // !defined(PRODUCT)
}

bool Options::ProcessDdsOption(const char* arg,
                               CommandLineOptions* vm_options) {
  const char* value = OptionProcessor::ProcessOption(arg, "--dds");
  if (value == nullptr) {
    value = OptionProcessor::ProcessOption(arg, "--no-dds");
    if (value == nullptr) {
      return false;
    }
    enable_dds_ = false;
  } else {
    enable_dds_ = true;
  }
  return true;
}

}  // namespace bin
}  // namespace dart
