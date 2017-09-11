// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_MAIN_OPTIONS_H_
#define RUNTIME_BIN_MAIN_OPTIONS_H_

#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "platform/globals.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

// A list of options taking string arguments. Organized as:
//   V(flag_name, field_name)
// The value of the flag can then be accessed with Options::field_name().
#define STRING_OPTIONS_LIST(V)                                                 \
  V(packages, packages_file)                                                   \
  V(package_root, package_root)                                                \
  V(snapshot, snapshot_filename)                                               \
  V(snapshot_depfile, snapshot_deps_filename)                                  \
  V(save_obfuscation_map, obfuscation_map_filename)                            \
  V(save_compilation_trace, save_compilation_trace_filename)                   \
  V(load_compilation_trace, load_compilation_trace_filename)                   \
  V(save_feedback, save_feedback_filename)                                     \
  V(load_feedback, load_feedback_filename)                                     \
  V(root_certs_file, root_certs_file)                                          \
  V(root_certs_cache, root_certs_cache)                                        \
  V(namespace, namespc)

// As STRING_OPTIONS_LIST but for boolean valued options. The default value is
// always false, and the presence of the flag switches the value to true.
#define BOOL_OPTIONS_LIST(V)                                                   \
  V(version, version_option)                                                   \
  V(compile_all, compile_all)                                                  \
  V(parse_all, parse_all)                                                      \
  V(disable_service_origin_check, vm_service_dev_mode)                         \
  V(use_blobs, use_blobs)                                                      \
  V(obfuscate, obfuscate)                                                      \
  V(trace_loading, trace_loading)                                              \
  V(short_socket_read, short_socket_read)                                      \
  V(short_socket_write, short_socket_write)                                    \
  V(disable_exit, exit_disabled)

// Boolean flags that have a short form.
#define SHORT_BOOL_OPTIONS_LIST(V)                                             \
  V(h, help, help_option)                                                      \
  V(v, verbose, verbose_option)

// A list of flags taking arguments from an enum. Organized as:
//   V(flag_name, enum_type, field_name)
// In main_options.cc there must be a list of strings that matches the enum
// called k{enum_type}Names. The field is not automatically declared in
// main_options.cc. It must be explicitly declared.
#define ENUM_OPTIONS_LIST(V) V(snapshot_kind, SnapshotKind, gen_snapshot_kind)

// Callbacks passed to DEFINE_CB_OPTION().
#define CB_OPTIONS_LIST(V)                                                     \
  V(ProcessEnvironmentOption)                                                  \
  V(ProcessEnableVmServiceOption)                                              \
  V(ProcessObserveOption)

// This enum must match the strings in kSnapshotKindNames in main_options.cc.
enum SnapshotKind {
  kNone,
  kScript,
  kAppAOT,
  kAppJIT,
};

class Options {
 public:
  static int ParseArguments(int argc,
                            char** argv,
                            bool vm_run_app_shapshot,
                            CommandLineOptions* vm_options,
                            char** script_name,
                            CommandLineOptions* dart_options,
                            bool* print_flags_seen,
                            bool* verbose_debug_seen);

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

#define ENUM_OPTIONS_GETTER(flag, type, variable)                              \
  static type variable() { return variable##_; }
  ENUM_OPTIONS_LIST(ENUM_OPTIONS_GETTER)
#undef ENUM_OPTIONS_GETTER

// Callbacks have to be public.
#define CB_OPTIONS_DECL(callback)                                              \
  static bool callback(const char* arg, CommandLineOptions* vm_options);
  CB_OPTIONS_LIST(CB_OPTIONS_DECL)
#undef CB_OPTIONS_DECL

  static dart::HashMap* environment() { return environment_; }

  static const char* vm_service_server_ip() { return vm_service_server_ip_; }
  static int vm_service_server_port() { return vm_service_server_port_; }

#if !defined(DART_PRECOMPILED_RUNTIME)
  static DFE* dfe() { return dfe_; }
  static void set_dfe(DFE* dfe) { dfe_ = dfe; }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  static void PrintUsage();
  static void PrintVersion();

  static void DestroyEnvironment();

 private:
#define STRING_OPTION_DECL(flag, variable)                                     \
  static const char* variable##_;                                              \
  static bool Process_##variable(const char* arg,                              \
                                 CommandLineOptions* vm_options);
  STRING_OPTIONS_LIST(STRING_OPTION_DECL)
#undef STRING_OPTION_DECL

#define BOOL_OPTION_DECL(flag, variable)                                       \
  static bool variable##_;                                                     \
  static bool Process_##variable(const char* arg,                              \
                                 CommandLineOptions* vm_options);
  BOOL_OPTIONS_LIST(BOOL_OPTION_DECL)
#undef BOOL_OPTION_DECL

#define SHORT_BOOL_OPTION_DECL(short_name, long_name, variable)                \
  static bool variable##_;                                                     \
  static bool Process_##variable(const char* arg,                              \
                                 CommandLineOptions* vm_options);
  SHORT_BOOL_OPTIONS_LIST(SHORT_BOOL_OPTION_DECL)
#undef SHORT_BOOL_OPTION_DECL

#define ENUM_OPTION_DECL(flag, type, variable)                                 \
  static type variable##_;                                                     \
  static bool Process_##variable(const char* arg,                              \
                                 CommandLineOptions* vm_options);
  ENUM_OPTIONS_LIST(ENUM_OPTION_DECL)
#undef ENUM_OPTION_DECL

  static dart::HashMap* environment_;

// Frontend argument processing.
#if !defined(DART_PRECOMPILED_RUNTIME)
  static DFE* dfe_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // VM Service argument processing.
  static const char* vm_service_server_ip_;
  static int vm_service_server_port_;
  static bool ExtractPortAndAddress(const char* option_value,
                                    int* out_port,
                                    const char** out_ip,
                                    int default_port,
                                    const char* default_ip);

#define OPTION_FRIEND(flag, variable) friend class OptionProcessor_##flag;
  STRING_OPTIONS_LIST(OPTION_FRIEND)
  BOOL_OPTIONS_LIST(OPTION_FRIEND)
#undef STRING_OPTION_FRIEND

#define SHORT_BOOL_OPTION_FRIEND(short_name, long_name, variable)              \
  friend class OptionProcessor_##long_name;
  SHORT_BOOL_OPTIONS_LIST(SHORT_BOOL_OPTION_FRIEND)
#undef SHORT_BOOL_OPTION_FRIEND

#define ENUM_OPTION_FRIEND(flag, type, variable)                               \
  friend class OptionProcessor_##flag;
  ENUM_OPTIONS_LIST(ENUM_OPTION_FRIEND)
#undef ENUM_OPTION_FRIEND

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Options);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_MAIN_OPTIONS_H_
