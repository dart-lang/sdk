// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartdev_options.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bin/common_options.h"
#include "bin/error_exit.h"
#include "bin/file_system_watcher.h"
#include "bin/platform.h"
#include "bin/socket.h"
#include "bin/utils.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/hashmap.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

#if defined(DART_PRECOMPILED_RUNTIME)

static bool PotentialDartdevCommand(const char* script_uri) {
  // If script_uri is a known DartDev command, we should not try to run it.
  //
  // Otherwise if script_uri is not a file path or of a known URI scheme, we
  // assume this is a mistyped DartDev command.
  //
  // This should be kept in sync with the commands in
  // `pkg/dartdev/lib/dartdev.dart`.
  return (
      (strcmp(script_uri, "analyze") == 0) ||
      (strcmp(script_uri, "compilation-server") == 0) ||
      (strcmp(script_uri, "build") == 0) ||
      (strcmp(script_uri, "compile") == 0) ||
      (strcmp(script_uri, "create") == 0) ||
      (strcmp(script_uri, "development-service") == 0) ||
      (strcmp(script_uri, "devtools") == 0) ||
      (strcmp(script_uri, "doc") == 0) || (strcmp(script_uri, "fix") == 0) ||
      (strcmp(script_uri, "format") == 0) ||
      (strcmp(script_uri, "info") == 0) ||
      (strcmp(script_uri, "mcp-server") == 0) ||
      (strcmp(script_uri, "pub") == 0) || (strcmp(script_uri, "run") == 0) ||
      (strcmp(script_uri, "test") == 0) || (strcmp(script_uri, "info") == 0) ||
      (strcmp(script_uri, "language-server") == 0) ||
      (strcmp(script_uri, "tooling-daemon") == 0) ||
      (!File::ExistsUri(nullptr, script_uri) &&
       (strncmp(script_uri, "http://", 7) != 0) &&
       (strncmp(script_uri, "https://", 8) != 0) &&
       (strncmp(script_uri, "file://", 7) != 0) &&
       (strncmp(script_uri, "package:", 8) != 0) &&
       (strncmp(script_uri, "google3://", 10) != 0)));
}

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
#undef BOOL_OPTION_DEFINITION

#define SHORT_BOOL_OPTION_DEFINITION(short_name, long_name, variable)          \
  bool OPTION_FIELD(variable) = false;                                         \
  DEFINE_BOOL_OPTION_SHORT(short_name, long_name, OPTION_FIELD(variable))
SHORT_BOOL_OPTIONS_LIST(SHORT_BOOL_OPTION_DEFINITION)
#undef SHORT_BOOL_OPTION_DEFINITION

#define CB_OPTION_DEFINITION(callback)                                         \
  static bool callback##Helper(const char* arg, CommandLineOptions* o) {       \
    return Options::callback(arg, o);                                          \
  }                                                                            \
  DEFINE_CB_OPTION(callback##Helper)
CB_OPTIONS_LIST(CB_OPTION_DEFINITION)
#undef CB_OPTION_DEFINITION

// Explicitly handle VM flags that can be parsed by DartDev's run command.
bool Options::ProcessVMOptions(const char* arg,
                               CommandLineOptions* vm_options) {
#define IS_VM_OPTION(name, arg)                                                \
  if (OptionProcessor::ProcessOption(arg, name) != nullptr) {                  \
    vm_options->AddArgument(arg);                                              \
    return true;                                                               \
  }

// This is an exhaustive set of VM flags that are accepted by 'dart run' and
// 'dart test' commands, these options need to be collected and passed to
// the dart VM process that is going to run the command.
//
// NOTE: When updating this list of VM flags, be sure to make the corresponding
// changes in pkg/dartdev/lib/src/commands/run.dart.
#define HANDLE_DARTDEV_VM_OPTIONS(V, arg)                                      \
  V("--enable-asserts", arg)                                                   \
  V("--pause-isolates-on-exit", arg)                                           \
  V("--no-pause-isolates-on-exit", arg)                                        \
  V("--pause-isolates-on-start", arg)                                          \
  V("--no-pause-isolates-on-start", arg)                                       \
  V("--pause-isolates-on-unhandled-exception", arg)                            \
  V("--no-pause-isolates-on-unhandled-exception", arg)                         \
  V("--warn-on-pause-with-no-debugger", arg)                                   \
  V("--no-warn-on-pause-with-no-debugger", arg)                                \
  V("--timeline-streams", arg)                                                 \
  V("--timeline-recorder", arg)                                                \
  V("--dds", arg)                                                              \
  V("--no-dds", arg)                                                           \
  V("--profiler", arg)                                                         \
  V("--disable-service-auth-codes", arg)                                       \
  V("--write-service-info", arg)                                               \
  V("--enable-service-port-fallback", arg)                                     \
  V("--define", arg)                                                           \
  V("-D", arg)                                                                 \
  V("--disable-service-auth-codes", arg)                                       \
  V("--serve-observatory", arg)                                                \
  V("--print-dtd", arg)                                                        \
  V("--packages", arg)                                                         \
  V("--resident", arg)                                                         \
  V("--resident-server-info-file", arg)                                        \
  V("--resident-compiler-info-file", arg)                                      \
  V("--observe", arg)                                                          \
  V("--enable-vm-service", arg)                                                \
  V("--serve-devtools", arg)                                                   \
  V("--no-serve-devtools", arg)                                                \
  V("--serve-observatory", arg)                                                \
  V("--no-serve-observatory", arg)                                             \
  V("--profile-microtasks", arg)                                               \
  V("--profile-startup", arg)                                                  \
  V("--enable-experiment", arg)
  HANDLE_DARTDEV_VM_OPTIONS(IS_VM_OPTION, arg);

#undef IS_VM_OPTION
#undef HANDLE_DARTDEV_VM_OPTIONS

  return false;
}

bool Options::ParseDartDevArguments(int argc,
                                    char** argv,
                                    CommandLineOptions* vm_options,
                                    CommandLineOptions* dart_vm_options,
                                    CommandLineOptions* dart_options,
                                    bool* skip_dartdev) {
  // Store the executable name.
  Platform::SetExecutableName(argv[0]);

  // First figure out if a dartdev command has been explicitly specified.
  *skip_dartdev = false;
  int tmp_i = 1;
  while (tmp_i < argc) {
    // Check if this flag is a potentially valid VM flag, we skip over all
    // VM flags until we see a command or a script file.
    if (!OptionProcessor::IsValidFlag(argv[tmp_i]) &&
        !OptionProcessor::IsValidShortFlag(argv[tmp_i])) {
      break;
    }
    tmp_i++;
  }
  if (tmp_i < argc) {
    // Check if we have a dartdev command.
    if (!PotentialDartdevCommand(argv[tmp_i])) {
      // We don't have a dartdev command so skip dartdev and execute the
      // script directly.
      *skip_dartdev = true;
      return true;
    }
  }

  bool enable_dartdev_analytics = false;
  bool disable_dartdev_analytics = false;
  char* packages_argument = nullptr;

  // First parse out the vm options into dart_vm_options so that it can be
  // passed down to the 'run' and 'test' commands.
  // Start processing arguments after argv[0] which would be the executable.
  int i = 1;
  while (i < argc) {
    bool skipVmOption = false;
    if (!OptionProcessor::TryProcess(argv[i], dart_vm_options)) {
      // Check if this flag is a potentially valid VM flag.
      if (!OptionProcessor::IsValidFlag(argv[i])) {
        break;
      }
      // The following flags are processed as DartDev flags and are not to
      // be treated as if they are VM flags.
      if (IsOption(argv[i], "enable-analytics")) {
        enable_dartdev_analytics = true;
        skipVmOption = true;
      } else if (IsOption(argv[i], "disable-analytics")) {
        disable_dartdev_analytics = true;
        skipVmOption = true;
      } else if (IsOption(argv[i], "disable-telemetry")) {
        disable_dartdev_analytics = true;
        skipVmOption = true;
      } else if (IsOption(argv[i], "suppress-analytics")) {
        dart_options->AddArgument("--suppress-analytics");
        skipVmOption = true;
      } else if (IsOption(argv[i], "no-analytics")) {
        // Just add this option even if we don't go to dartdev.
        // It is irrelevant for the vm.
        dart_options->AddArgument("--no-analytics");
        skipVmOption = true;
      } else if (IsOption(argv[i], "serve-observatory")) {
        // This flag is currently set by default in vmservice_io.dart, so we
        // ignore it. --no-serve-observatory is a VM flag so we don't need to
        // handle that case here.
        skipVmOption = true;
      } else if (IsOption(argv[i], "print-dtd-uri")) {
        skipVmOption = true;
      } else if (IsOption(argv[i], "executable-name")) {
        skipVmOption = true;
      } else if (IsOption(argv[i], "enable-experiment")) {
        dart_options->AddArgument(argv[i]);
      }
    }
    if (!skipVmOption) {
      dart_vm_options->AddArgument(argv[i]);
    }
    if (IsOption(argv[i], "packages")) {
      packages_argument = argv[i];
    }
    i++;
  }

  // The arguments to the VM are at positions 1 through i-1 in argv.
  Platform::SetExecutableArguments(i, argv);

  // If we have exhausted all the arguments and haven't see a dartdev
  // command then we set up some scenarios where it still makes sense
  // to start up dartdev and have it process the options.
  if (i >= argc) {
    // Handles following invocation arguments:
    //   - dart help
    //   - dart --help
    //   - dart
    if (((Options::help_option() && !Options::verbose_option()) ||
         (argc == 1))) {
      // Let DartDev handle the default help message.
      dart_options->AddArgument("help");
      return true;
    }
    // Handles cases where only analytics flags are provided. We need to launch
    // DartDev for this.
    else if (enable_dartdev_analytics || disable_dartdev_analytics) {  // NOLINT
      // The analytics flags are a special case as we don't have a target script
      // or DartDev command but we still want to launch DartDev.
      dart_options->AddArgument(enable_dartdev_analytics
                                    ? "--enable-analytics"
                                    : "--disable-analytics");
      return true;
    }
    // If it is not '--version' and '--help' we will launch DartDev
    // to print its help message and set an error exit code.
    else if (!Options::help_option() && !Options::version_option()) {  // NOLINT
      // Pass in an invalid option so that dartdev prints the help message
      // and exits with an error exit code.
      dart_options->Reset();
      dart_options->AddArgument(argv[argc - 1]);
      dart_options->AddArgument("help");
      return true;
    }
    return false;
  }

  USE(enable_dartdev_analytics);
  USE(disable_dartdev_analytics);
  USE(packages_argument);

  // Record the dartdev command.
  dart_options->AddArgument(argv[i++]);

  // Bring any --packages option into the dartdev command
  if (packages_argument != nullptr) {
    dart_options->AddArgument(packages_argument);
    dart_vm_options->AddArgument(packages_argument);
  }

  // Scan remaining arguments and separate them into
  // dart_vm_options (vm options to be passed to the dart process executing
  // the dartdev command) or dart_options (options to be passed to the
  // executing dart script).
  bool script_seen = false;
  while (i < argc) {
    if (!IsOption(argv[i], "disable-dart-dev")) {
      if (!script_seen) {
        // We scan for VM options that are passed to the 'run' and 'test'
        // command. These options are accepted by both the VM and dartdev
        // commands and need to be carried over to the VM running the app for
        // these commands.
        if (Options::ProcessVMOptions(argv[i], dart_vm_options)) {
          // dartdev isn't able to parse these options properly. Since it
          // doesn't need to use the values from these options, just strip them
          // from the argument list passed to dartdev.
          if (!IsOption(argv[i], "observe") &&
              !IsOption(argv[i], "enable-vm-service")) {
            dart_options->AddArgument(argv[i]);
          }
        } else {
          if (!OptionProcessor::IsValidFlag(argv[i]) &&
              !OptionProcessor::IsValidShortFlag(argv[i])) {
            script_seen = true;
          }
          dart_options->AddArgument(argv[i]);
        }
      } else {
        dart_options->AddArgument(argv[i]);
      }
    } else {
      Syslog::PrintErr(
          "Attempted to use --disable-dart-dev with a Dart CLI command.\n");
      return false;
    }
    i++;
  }

  // Verify consistency of arguments.
  if ((packages_file_ != nullptr) && (strlen(packages_file_) == 0)) {
    Syslog::PrintErr("Empty package file name specified.\n");
    return false;
  }

  return true;
}

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

char** Options::GetEnvArguments(int* argc) {
  return nullptr;
}

void Options::DestroyEnvArgv() {}

#endif  // defined(DART_PRECOMPILED_RUNTIME)

}  // namespace bin
}  // namespace dart
