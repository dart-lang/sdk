// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_DARTDEV_OPTIONS_H_
#define RUNTIME_BIN_DARTDEV_OPTIONS_H_

#include "bin/dartutils.h"
#include "bin/options.h"
#include "platform/globals.h"
#include "platform/growable_array.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

#if defined(DART_PRECOMPILED_RUNTIME)

// A list of options taking string arguments. Organized as:
//   V(flag_name, field_name)
// The value of the flag can then be accessed with Options::field_name().
#define STRING_OPTIONS_LIST(V)                                                 \
  V(packages, packages_file)                                                   \
  V(namespace, namespc)

// As STRING_OPTIONS_LIST but for boolean valued options. The default value is
// always false, and the presence of the flag switches the value to true.
#define BOOL_OPTIONS_LIST(V)                                                   \
  V(disable_exit, exit_disabled)                                               \
  V(version, version_option)                                                   \
  V(suppress_core_dump, suppress_core_dump)

// Boolean flags that have a short form.
#define SHORT_BOOL_OPTIONS_LIST(V)                                             \
  V(h, help, help_option)                                                      \
  V(v, verbose, verbose_option)

// Callbacks passed to DEFINE_CB_OPTION().
#define CB_OPTIONS_LIST(V)                                                     \
  V(ProcessEnvironmentOption)                                                  \
  V(ProcessVMOptions)

enum VerbosityLevel {
  kError,
  kWarning,
  kInfo,
  kAll,
};

static const char* const kVerbosityLevelNames[] = {
    "error", "warning", "info", "all", nullptr,
};

class Options {
 public:
  // Returns true if argument parsing succeeded. False otherwise.
  static bool ParseDartDevArguments(int argc,
                                    char** argv,
                                    CommandLineOptions* vm_options,
                                    CommandLineOptions* dart_vm_options,
                                    CommandLineOptions* dart_options,
                                    bool* skip_dartdev);

#define STRING_OPTION_GETTER(flag, variable)                                   \
  static const char* variable() { return variable##_; }
  STRING_OPTIONS_LIST(STRING_OPTION_GETTER)
#undef STRING_OPTION_GETTER

#define BOOL_OPTION_GETTER(flag, variable)                                     \
  static bool variable() { return variable##_; }
  BOOL_OPTIONS_LIST(BOOL_OPTION_GETTER)
#undef BOOL_OPTION_GETTER

#define SHORT_BOOL_OPTION_GETTER(short_name, long_name, variable)              \
  static bool variable() { return variable##_; }
  SHORT_BOOL_OPTIONS_LIST(SHORT_BOOL_OPTION_GETTER)
#undef SHORT_BOOL_OPTION_GETTER

// Callbacks have to be public.
#define CB_OPTIONS_DECL(callback)                                              \
  static bool callback(const char* arg, CommandLineOptions* vm_options);
  CB_OPTIONS_LIST(CB_OPTIONS_DECL)
#undef CB_OPTIONS_DECL

  static dart::SimpleHashMap* environment() { return environment_; }

  static void PrintUsage();
  static void PrintVersion();

  static void Cleanup();

#if defined(DART_PRECOMPILED_RUNTIME)
  // Get the list of options in DART_VM_OPTIONS.
  static char** GetEnvArguments(int* argc);
#endif  // defined(DART_PRECOMPILED_RUNTIME)

 private:
  static void DestroyEnvironment();
#if defined(DART_PRECOMPILED_RUNTIME)
  static void DestroyEnvArgv();
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#define STRING_OPTION_DECL(flag, variable) static const char* variable##_;
  STRING_OPTIONS_LIST(STRING_OPTION_DECL)
#undef STRING_OPTION_DECL

#define BOOL_OPTION_DECL(flag, variable) static bool variable##_;
  BOOL_OPTIONS_LIST(BOOL_OPTION_DECL)
#undef BOOL_OPTION_DECL

#define SHORT_BOOL_OPTION_DECL(short_name, long_name, variable)                \
  static bool variable##_;
  SHORT_BOOL_OPTIONS_LIST(SHORT_BOOL_OPTION_DECL)
#undef SHORT_BOOL_OPTION_DECL

  static dart::SimpleHashMap* environment_;

  static char** env_argv_;
  static int env_argc_;

#define OPTION_FRIEND(flag, variable) friend class OptionProcessor_##flag;
  STRING_OPTIONS_LIST(OPTION_FRIEND)
  BOOL_OPTIONS_LIST(OPTION_FRIEND)
#undef OPTION_FRIEND

#define SHORT_BOOL_OPTION_FRIEND(short_name, long_name, variable)              \
  friend class OptionProcessor_##long_name;
  SHORT_BOOL_OPTIONS_LIST(SHORT_BOOL_OPTION_FRIEND)
#undef SHORT_BOOL_OPTION_FRIEND

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Options);
};

#endif  // defined(DART_PRECOMPILED_RUNTIME)

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_DARTDEV_OPTIONS_H_
