// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'repository.dart';

class FuchsiaEmulator {
  static String fsshTool = "./third_party/fuchsia/sdk/linux/tools/x64/fssh";
  static String ffx = "./third_party/fuchsia/sdk/linux/tools/x64/ffx";
  static String pm = "./third_party/fuchsia/sdk/linux/tools/x64/pm";

  static Future<void> publishPackage(
      String buildDir, String mode, String arch) async {
    _run(ffx, ["emu", "stop", "--all"]);
    _run(ffx, ["repository", "server", "stop"]);

    // Setup package server.
    var packageRepositoryPath = "dart-test-package-repository-$mode-$arch";
    var packageRepositoryName = "dart-test-package-repository-$mode-$arch-name";
    var f = Directory(packageRepositoryPath);
    if (f.existsSync()) f.deleteSync(recursive: true);
    _run(pm, ["newrepo", "-repo", packageRepositoryPath]);
    _run(pm, [
      "publish",
      "-a",
      "-repo",
      packageRepositoryPath,
      "-f",
      "$buildDir/gen/dart_ffi_test_$mode/dart_ffi_test_$mode.far"
    ]);
    _run(ffx, [
      "repository",
      "add-from-pm",
      packageRepositoryPath,
      "-r",
      packageRepositoryName
    ]);
    _run(ffx, ["repository", "server", "start"]);

    // Setup emulator.
    var emulatorName = "dart-fuchsia-$mode-$arch";
    _run(ffx, ["product-bundle", "get", "terminal.qemu-$arch"]);
    _run(ffx, [
      "emu",
      "start",
      "terminal.qemu-$arch",
      "--name",
      emulatorName,
      "--headless",
    ]);
    _run(ffx, [
      "target",
      "repository",
      "register",
      "-r",
      packageRepositoryName,
      "--alias",
      "fuchsia.com"
    ]);
  }

  static void stop() {}

  static List<String> getTestArgs(String mode, List<String> arguments) {
    arguments = arguments
        .map((arg) => arg.replaceAll(Repository.uri.toFilePath(), '/pkg/data/'))
        .toList();
    return [
      "run",
      "fuchsia-pkg://fuchsia.com/dart_ffi_test_$mode#meta/fuchsia_ffi_test_component.cmx",
      ...arguments
    ];
  }

  static String _run(String exec, List<String> args) {
    var line = "$exec ${args.join(' ')}";
    print("+ $line");
    var result = Process.runSync(exec, args);
    print(result.stdout);
    print(result.stderr);
    if (result.exitCode != 0) {
      throw "$line failed";
    }
    return (result.stdout as String).trim();
  }
}
