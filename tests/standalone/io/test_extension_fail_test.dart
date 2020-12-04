// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native extensions.

// OtherResources=test_extension.dart
// OtherResources=test_extension_fail_tester.dart
// OtherResources=test_relative_extension.dart
// OtherResources=test_relative_extension_fail_tester.dart

import "package:path/path.dart";
import "dart:async";
import "dart:io";

Future copyFileToDirectory(String file, String directory) {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Process.run('cp', [file, directory]);
    case 'windows':
      return Process.run('cmd.exe', ['/C', 'copy $file $directory']);
    default:
      throw new StateError(
          'Unknown operating system ${Platform.operatingSystem}');
  }
}

String getExtensionPath(String buildDirectory) {
  switch (Platform.operatingSystem) {
    case 'linux':
      return join(buildDirectory, 'libtest_extension.so');
    case 'macos':
      return join(buildDirectory, 'libtest_extension.dylib');
    case 'windows':
      return join(buildDirectory, 'test_extension.dll');
    default:
      throw new StateError(
          'Unknown operating system ${Platform.operatingSystem}');
  }
}

bool checkExitCode(int code) {
  return ((code == 255) || (code == 254) || (code == 253));
}

bool checkStdError(String err) {
  return err.contains("Unhandled exception:") ||
      err.contains(
          "Native extension path must be absolute, or simply the file name");
}

// name is either "extension" or "relative_extension"
Future test(String name, bool checkForBall) async {
  String scriptDirectory = dirname(Platform.script.toFilePath());
  String buildDirectory = dirname(Platform.executable);
  Directory tempDirectory =
      Directory.systemTemp.createTempSync('dart_test_${name}_fail');
  String testDirectory = tempDirectory.path;

  // Copy test_extension shared library, test_extension.dart and
  // test_extension_fail_tester.dart to the temporary test directory.
  try {
    if (name == "extension") {
      print(getExtensionPath(buildDirectory));
      await copyFileToDirectory(
          getExtensionPath(buildDirectory), testDirectory);
    } else {
      var extensionDir = testDirectory + "/extension";
      Directory dir = await (new Directory(extensionDir).create());
      await copyFileToDirectory(getExtensionPath(buildDirectory), extensionDir);
    }
    var extensionDartFile = join(scriptDirectory, 'test_${name}.dart');
    await copyFileToDirectory(extensionDartFile, testDirectory);
    var testExtensionTesterFile =
        join(scriptDirectory, 'test_${name}_fail_tester.dart');
    await copyFileToDirectory(testExtensionTesterFile, testDirectory);
    var args = new List<String>.from(Platform.executableArguments)
      ..add('--trace-loading')
      ..add(join(testDirectory, 'test_${name}_fail_tester.dart'));
    var result = await Process.run(Platform.executable, args);
    print("ERR: ${result.stderr}\n\n");
    print("OUT: ${result.stdout}\n\n");
    if (!checkExitCode(result.exitCode)) {
      throw new StateError("bad exit code: ${result.exitCode}");
    }
    if (!checkStdError(result.stderr)) {
      throw new StateError("stderr doesn't contain unhandled exception.");
    }
    if (checkForBall) {
      if (!result.stderr.contains("ball")) {
        throw new StateError("stderr doesn't contain 'ball'.");
      }
    }
  } finally {
    tempDirectory.deleteSync(recursive: true);
  }
}

main() async {
  await test("extension", true);
  await test("relative_extension", false);
}
