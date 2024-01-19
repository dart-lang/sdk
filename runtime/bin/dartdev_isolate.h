// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_DARTDEV_ISOLATE_H_
#define RUNTIME_BIN_DARTDEV_ISOLATE_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <memory>

#include "bin/thread.h"
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/globals.h"
#include "platform/utils.h"

#define DART_DEV_ISOLATE_NAME "dartdev"

namespace dart {
namespace bin {

class CommandLineOptions;

class DartDevIsolate {
 public:
  // Note: keep in sync with pkg/dartdev/lib/vm_interop_handler.dart
  typedef enum {
    DartDev_Result_Unknown = -1,
    DartDev_Result_Run = 1,
    DartDev_Result_Exit = 2,
  } DartDev_Result;

  // Returns true if there does not exist a file at |script_uri| or the URI is
  // not an HTTP resource.
  static bool ShouldParseCommand(const char* script_uri);

  static void set_should_run_dart_dev(bool enable) {
    should_run_dart_dev_ = enable;
  }

  static void PrintUsageErrorOnRun() {
    set_should_run_dart_dev(true);
    print_usage_error_ = true;
  }

  static bool should_run_dart_dev() { return should_run_dart_dev_; }

  // Attempts to find the path of the DartDev snapshot.
  static Utils::CStringUniquePtr TryResolveDartDevSnapshotPath();

  // Starts a DartDev instance in a new isolate and runs it to completion.
  //
  // Returns true if the VM should run the result in `script`, in which case
  // `script` and `dart_options` will have been repopulated with the correct
  // values.
  static DartDev_Result RunDartDev(
      Dart_IsolateGroupCreateCallback create_isolate,
      char** packages_file,
      char** script,
      bool* sound_null_safety,
      CommandLineOptions* dart_options);

 protected:
  class DartDevRunner {
   public:
    DartDevRunner() {}

    void Run(Dart_IsolateGroupCreateCallback create_isolate,
             char** package_config_override_,
             char** script,
             bool* force_no_sound_null_safety,
             CommandLineOptions* dart_options);

    DartDev_Result result() const { return result_; }

   private:
    static void DartDevResultCallback(Dart_Port dest_port_id,
                                      Dart_CObject* message);
    static void RunCallback(uword arg);
    static void ProcessError(const char* msg, int32_t exit_code);

    static DartDev_Result result_;
    static char** script_;
    static char** package_config_override_;
    static bool* force_no_sound_null_safety_;
    static std::unique_ptr<char*[], void (*)(char**)> argv_;
    static intptr_t argc_;

    Dart_IsolateGroupCreateCallback create_isolate_;
    CommandLineOptions* dart_options_;
    const char* packages_file_;
    static Monitor* monitor_;

    DISALLOW_ALLOCATION();
  };

 private:
  static Utils::CStringUniquePtr TryResolveArtifactPath(const char* filename);

  static DartDevRunner runner_;
  static bool should_run_dart_dev_;
  static bool print_usage_error_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartDevIsolate);
};

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_BIN_DARTDEV_ISOLATE_H_
