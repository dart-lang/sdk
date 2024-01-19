// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'command.dart';

// Runs tests on a fuchsia emulator with chromium maintained test-scripts and
// CFv2 targets.
class FuchsiaEmulator {
  static const String ffx = "./third_party/fuchsia/sdk/linux/tools/x64/ffx";
  static const String testScriptRoot =
      "./third_party/fuchsia/test_scripts/test/";
  static const String withEnv = "./build/fuchsia/with_envs.py";
  static const String tmpRoot = "/tmp/dart_ffi_test/";
  // TODO(#38752): Once we have vm/cc and AOT tests running, this will sometimes
  // need to be the component for run_vm_tests or dart_precompiled_runtime.
  static const String cmName = "dart_test_component.cm";

  final Map<String, String> envs = <String, String>{};
  Process? daemonProc;
  Process? emuProc;
  String? emuName;
  Process? repoProc;

  // Publishes the packages to the Fuchsia environment.
  Future<void> publishPackage(String buildDir, String mode, String arch) async {
    try {
      await Directory(tmpRoot).delete(recursive: true);
    } catch (_) {}
    // The /tmp/ should always be present, recursive creation is not expected.
    await Directory(tmpRoot).create();
    assert(daemonProc == null);
    daemonProc = await _run("isolate_daemon.py", []);
    var isolateDir = await _captureStdout(daemonProc!);
    print("+ ffx daemon running on $isolateDir should be ready now.");
    envs["FFX_ISOLATE_DIR"] = isolateDir;
    assert(emuProc == null);
    emuProc = await _run("start_emulator.py", [
      "--disable-graphics",
      "--target-id-only",
      "--device-spec",
      "virtual_device_large"
    ]);
    emuName = await _captureStdout(emuProc!);
    print("+ Targeting emu name $emuName");
    await _assertRun("test_connection.py", [emuName!]);
    await _assertRun("publish_package.py", [
      "--packages",
      _testPackagePath(buildDir, mode),
      "--purge-repo",
      "--repo",
      _tempDirectoryOf("repo")
    ]);
    repoProc = await _run("serve_repo.py", [
      "run",
      "--serve-repo",
      _tempDirectoryOf("repo"),
      "--repo-name",
      "dart-ffi-test-repo",
      "--target-id",
      emuName!
    ]);
    print("+ Fuchsia repo ${await _captureStdout(repoProc!)} is running "
        "at ${_tempDirectoryOf('repo')}");
    await _assertRun("pkg_resolve.py", [emuName!, _testPackageName(mode)]);
  }

  // Tears down the Fuchsia environment.
  Future<void> stop() async {
    assert(repoProc != null);
    repoProc!.kill();
    await repoProc!.exitCode;
    assert(emuProc != null);
    emuProc!.kill();
    await emuProc!.exitCode;
    assert(daemonProc != null);
    daemonProc!.kill();
    await daemonProc!.exitCode;
  }

  // Returns a command to execute a set of tests against the running Fuchsia
  // environment.
  VMCommand getTestCommand(
      String buildDir, String mode, String arch, List<String> arguments) {
    return VMCommand(
        withEnv,
        _runArgs("run_executable_test.py", [
          "--target-id",
          emuName!,
          "--out-dir",
          _tempDirectoryOf("out"),
          "--test-name",
          "fuchsia-pkg://fuchsia.com/${_testPackageName(mode)}#meta/$cmName",
          "--test-realm",
          // VmexResource not available in default hermetic realm
          // TODO(38752): Setup a Dart test realm.
          "/core/testing:system-tests",
          "--logs-dir",
          _tempDirectoryOf("logs"),
          "--package-deps",
          _testPackagePath(buildDir, mode),
          ...arguments
        ]),
        envs);
  }

  static String _testPackageName(String mode) {
    return "dart_test_$mode";
  }

  static String _testPackagePath(String buildDir, String mode) {
    var farName = _testPackageName(mode);
    return "$buildDir/gen/$farName/$farName.far";
  }

  static String _tempDirectoryOf(String name) {
    return tmpRoot + name;
  }

  List<String> _runArgs(String script, List<String> args) {
    return [testScriptRoot + script, ...args];
  }

  /// Executes a test script inside of third_party/fuchsia/test_scripts/test/
  /// with the required environment setup and the arguments.
  Future<Process> _run(String script, List<String> args) async {
    var newArgs = _runArgs(script, args);
    print("+ Start $withEnv with $newArgs with environment $envs.");
    return Process.start(withEnv, newArgs, environment: envs);
  }

  /// Executes a test script and asserts its return code is 0; see _run and
  /// _assert.
  Future<void> _assertRun(String script, List<String> args) async {
    _assert((await (await _run(script, args)).exitCode) == 0);
  }

  /// Captures the first line of output in utf8.
  Future<String> _captureStdout(Process proc) async {
    // The stderr needs to be fully consumed as well.
    proc.stderr.transform(utf8.decoder).forEach((x) => stderr.write(x));
    return (await proc.stdout.transform(utf8.decoder).first).trim();
  }

  /// Unlike assert keyword, always evaluates the input function and throws
  /// exception when the evaluated result is false.
  void _assert(bool condition) {
    if (!condition) {
      throw AssertionError();
    }
  }

  static final FuchsiaEmulator _instance = _create();

  static FuchsiaEmulator _create() {
    return FuchsiaEmulator();
  }

  static FuchsiaEmulator instance() {
    return _instance;
  }
}
