// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native extensions.

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
      return join(buildDirectory, 'lib.target', 'libtest_extension.so');
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
  return ((code == 255) || (code == 253));
}

bool checkStdError(String err) {
  return err.contains("Unhandled exception:") ||
      err.contains(
          "Native extension path must be absolute, or simply the file name");
}

// name is either "extension" or "relative_extension"
Future test(String name, bool checkForBall) {
  String scriptDirectory = dirname(Platform.script.toFilePath());
  String buildDirectory = dirname(Platform.executable);
  Directory tempDirectory =
      Directory.systemTemp.createTempSync('dart_test_${name}_fail');
  String testDirectory = tempDirectory.path;

  // Copy test_extension shared library, test_extension.dart and
  // test_extension_fail_tester.dart to the temporary test directory.
  copyFileToDirectory(getExtensionPath(buildDirectory), testDirectory)
      .then((_) {
    var extensionDartFile = join(scriptDirectory, 'test_${name}.dart');
    return copyFileToDirectory(extensionDartFile, testDirectory);
  }).then((_) {
    var testExtensionTesterFile =
        join(scriptDirectory, 'test_${name}_fail_tester.dart');
    return copyFileToDirectory(testExtensionTesterFile, testDirectory);
  }).then((_) {
    var script = join(testDirectory, 'test_${name}_fail_tester.dart');
    return Process.run(Platform.executable, ['--trace-loading', script]);
  }).then((ProcessResult result) {
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
  }).whenComplete(() => tempDirectory.deleteSync(recursive: true));
}

main() async {
  await test("extension", true);
  await test("relative_extension", false);
}
