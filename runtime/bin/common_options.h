// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_COMMON_OPTIONS_H_
#define RUNTIME_BIN_COMMON_OPTIONS_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

static void _PrintVersion() {
  Syslog::Print("Dart SDK version: %s\n", Dart_VersionString());
}

// clang-format off
static void _PrintUsage() {
  Syslog::Print(
      "Usage: dartvm [<vm-flags>] <dart-script-file> [<script-arguments>]\n"
      "\n"
      "Executes the Dart script <dart-script-file> with "
      "the given list of <script-arguments>.\n"
      "\n");
}

static void _PrintNonVerboseUsage() {
  Syslog::Print(
"Common VM flags:\n"
#if !defined(PRODUCT)
"--enable-asserts\n"
"  Enable assert statements.\n"
#endif  // !defined(PRODUCT)
"--help or -h\n"
"  Display this message (add -v or --verbose for information about\n"
"  all VM options).\n"
"--packages=<path>\n"
"  Where to find a package spec file.\n"
"--define=<key>=<value> or -D<key>=<value>\n"
"  Define an environment declaration. To specify multiple declarations,\n"
"  use multiple instances of this option.\n"
#if !defined(PRODUCT)
"--observe[=<port>[/<bind-address>]]\n"
"  The observe flag is a convenience flag used to run a program with a\n"
"  set of options which are often useful for debugging under Dart DevTools.\n"
"  These options are currently:\n"
"      --enable-vm-service[=<port>[/<bind-address>]]\n"
"      --serve-devtools\n"
"      --pause-isolates-on-exit\n"
"      --pause-isolates-on-unhandled-exceptions\n"
"      --warn-on-pause-with-no-debugger\n"
"      --timeline-streams=\"Compiler, Dart, GC, Microtask\"\n"
"  This set is subject to change.\n"
"  Please see these options (--help --verbose) for further documentation.\n"
"--write-service-info=<file_uri>\n"
"  Outputs information necessary to connect to the VM service to the\n"
"  specified file in JSON format. Useful for clients which are unable to\n"
"  listen to stdout for the Dart VM service listening message.\n"
#endif  // !defined(PRODUCT)
"--snapshot-kind=<snapshot_kind>\n"
"--snapshot=<file_name>\n"
"  These snapshot options are used to generate a snapshot of the loaded\n"
"  Dart script:\n"
"    <snapshot-kind> controls the kind of snapshot, it could be\n"
"                    kernel(default) or app-jit\n"
"    <file_name> specifies the file into which the snapshot is written\n"
"--version\n"
"  Print the SDK version.\n");
}

static void _PrintVerboseUsage() {
  Syslog::Print(
"Supported options:\n"
#if !defined(PRODUCT)
"--enable-asserts\n"
"  Enable assert statements.\n"
#endif  // !defined(PRODUCT)
"--help or -h\n"
"  Display this message (add -v or --verbose for information about\n"
"  all VM options).\n"
"--packages=<path>\n"
"  Where to find a package spec file.\n"
"--define=<key>=<value> or -D<key>=<value>\n"
"  Define an environment declaration. To specify multiple declarations,\n"
"  use multiple instances of this option.\n"
#if !defined(PRODUCT)
"--observe[=<port>[/<bind-address>]]\n"
"  The observe flag is a convenience flag used to run a program with a\n"
"  set of options which are often useful for debugging under Dart DevTools.\n"
"  These options are currently:\n"
"      --enable-vm-service[=<port>[/<bind-address>]]\n"
"      --serve-devtools\n"
"      --pause-isolates-on-exit\n"
"      --pause-isolates-on-unhandled-exceptions\n"
"      --warn-on-pause-with-no-debugger\n"
"      --timeline-streams=\"Compiler, Dart, GC, Microtask\"\n"
"  This set is subject to change.\n"
"  Please see these options for further documentation.\n"
"--profile-microtasks\n"
"  Record information about each microtask. Information about completed\n"
"  microtasks will be written to the \"Microtask\" timeline stream.\n"
"--profile-startup\n"
"  Make the profiler discard new samples once the profiler sample buffer is\n"
"  full. When this flag is not set, the profiler sample buffer is used as a\n"
"  ring buffer, meaning that once it is full, new samples start overwriting\n"
"  the oldest ones. This flag itself does not enable the profiler; the\n"
"  profiler must be enabled separately, e.g. with --profiler.\n"
#endif  // !defined(PRODUCT)
"--version\n"
"  Print the VM version.\n"
"\n"
"--trace-loading\n"
"  enables tracing of library and script loading\n"
"\n"
#if !defined(PRODUCT)
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
#endif  // !defined(PRODUCT)
"--root-certs-file=<path>\n"
"  The path to a file containing the trusted root certificates to use for\n"
"  secure socket connections.\n"
"--root-certs-cache=<path>\n"
"  The path to a cache directory containing the trusted root certificates to\n"
"  use for secure socket connections.\n"
#if defined(DART_HOST_OS_LINUX) || \
    defined(DART_HOST_OS_ANDROID) || \
    defined(DART_HOST_OS_FUCHSIA)
"--namespace=<path>\n"
"  The path to a directory that dart:io calls will treat as the root of the\n"
"  filesystem.\n"
#endif  // defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
"\n"
"The following options are only used for VM development and may\n"
"be changed in any future version:\n");
    const char* print_flags = "--print_flags";
    char* error = Dart_SetVMFlags(1, &print_flags);
    ASSERT(error == nullptr);
}
// clang-format on

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

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_COMMON_OPTIONS_H_
