// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'command.dart';

// Runs tests on a fuchsia emulator with chromium maintained test-scripts and
// CFv2 targets.
class FuchsiaEmulator {
  static const String withEnv = "./build/fuchsia/with_envs.py";

  final Map<String, String> envs = <String, String>{};
  Directory? daemonIsolateDir;
  Process? publisher;

  // Publishes the packages to the Fuchsia environment.
  Future<void> publishPackage(String buildDir, String mode, String arch) async {
    assert(daemonIsolateDir == null);
    daemonIsolateDir = Directory.systemTemp.createTempSync();
    envs["FFX_ISOLATE_DIR"] = daemonIsolateDir!.path;
    assert(publisher == null);
    var args = <String>[
      "./build/fuchsia/test_env.py",
      "--out-dir=${_outDir(buildDir, mode)}",
      "--device-spec=$arch-emu-large",
      "--packages=dart_test_$mode.far",
      "--logs-dir=${daemonIsolateDir!.path}"
    ];
    if (arch == "arm64") {
      args.add("--product=terminal.qemu-arm64");
    }
    publisher = await Process.start(withEnv, args,
        environment: envs, mode: ProcessStartMode.inheritStdio);
    while (!await File(
                "${daemonIsolateDir!.path}/test_env_setup.${publisher!.pid}.pid")
            .exists() &&
        await _isProcessRunning(publisher!, 1000)) {}
    // TODO(38752): Should return a value to indicate the failure of the
    // enviornment setup.
    if (await _isProcessRunning(publisher!, 1)) {
      print("+ ffx daemon running on $daemonIsolateDir should be ready now.");
    } else {
      print("+ environment setup failure.");
    }
  }

  // Returns a command to execute a set of tests against the running Fuchsia
  // environment.
  VMCommand getTestCommand(String buildDir, String mode, String arch,
      List<String> arguments, Map<String, String> environmentOverrides) {
    environmentOverrides.addAll(envs);
    return VMCommand(
        withEnv,
        [
          "./third_party/fuchsia/test_scripts/test/run_executable_test.py",
          "--test-name=fuchsia-pkg://fuchsia.com/dart_test_$mode#meta/dart_test_component.cm",
          // VmexResource not available in default hermetic realm
          // TODO(38752): Setup a Dart test realm.
          "--test-realm=/core/testing:system-tests",
          "--out-dir=${_outDir(buildDir, mode)}",
          "--package-deps=dart_test_$mode.far",
          ...arguments
        ],
        environmentOverrides);
  }

  // Tears down the Fuchsia environment.
  Future<void> stop() async {
    publisher!.kill();
    await publisher!.exitCode;
    publisher = null;
    daemonIsolateDir!.deleteSync(recursive: true);
    daemonIsolateDir = null;
  }

  Future<bool> _isProcessRunning(Process proc, int waitMs) async {
    try {
      await proc.exitCode.timeout(Duration(milliseconds: waitMs));
      return false;
    } on TimeoutException {
      return true;
    }
  }

  String _outDir(String buildDir, String mode) {
    return "$buildDir/gen/dart_test_$mode";
  }

  static final FuchsiaEmulator _instance = _create();

  static FuchsiaEmulator _create() {
    return FuchsiaEmulator();
  }

  static FuchsiaEmulator instance() {
    return _instance;
  }
}
