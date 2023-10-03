// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'command.dart';
import 'fuchsia.dart';

// Runs tests on a fuchsia emulator with chromium maintained test-scripts and
// CFv2 targets.
// TODO(#38752): Need implementation.
class FuchsiaEmulatorCFv2 extends FuchsiaEmulator {
  static const String ffx = "./third_party/fuchsia/sdk/linux/tools/x64/ffx";
  static const String testScriptRoot =
      "./third_party/fuchsia/test_scripts/test/";

  Process? daemonProc;
  Process? emuProc;
  String? emuName;

  @override
  Future<void> publishPackage(String buildDir, String mode, String arch) async {
    housekeeping();

    assert(daemonProc == null);
    daemonProc = await runWithOutput("isolate_daemon.py", []);
    assert(emuProc == null);
    emuProc = await run(
        "start_emulator.py", ["--disable-graphics", "--target-id-only"]);
    emuName = await emuProc!.stdout.transform(utf8.decoder).first;
    print("+ Targeting emu name $emuName");
  }

  @override
  void stop() {
    // isolate_daemon.py should respect the sigterm and gracefully stop the
    // daemon process.
    assert(daemonProc != null);
    daemonProc!.kill();
    emuProc!.kill();

    // In case anything goes wrong, ensure everything is cleaned up.
    housekeeping();
  }

  @override
  VMCommand getTestCommand(String mode, String arch, List<String> arguments) {
    return VMCommand("echo", arguments, <String, String>{});
  }

  static void housekeeping() {
    Process.runSync(ffx, ["emu", "stop", "--all"]);
    Process.runSync(ffx, ["repository", "server", "stop"]);
    Process.runSync(ffx, ["daemon", "stop", "-t", "10000"]);
  }

  // Same as run, but capture the stdout and stderr.
  static Future<Process> runWithOutput(String script, List<String> args) async {
    return run(script, args).then((proc) {
      proc.stdout.transform(utf8.decoder).forEach((x) {
        print("++ [$script] stdout: $x");
      });
      proc.stderr.transform(utf8.decoder).forEach((x) {
        print("++ [$script] stderr: $x");
      });
      return proc;
    });
  }

  // Executes a test script inside of third_party/fuchsia/test_scripts/test/
  // with the required environment setup and the arguments.
  static Future<Process> run(String script, List<String> args) async {
    return Process.start("./build/fuchsia/with_envs.py",
        [Uri.directory(testScriptRoot).resolve(script).toString(), ...args]);
  }
}
