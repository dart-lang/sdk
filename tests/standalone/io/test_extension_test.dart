// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native extensions.

import "package:expect/expect.dart";
import "package:path/path.dart";
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

Future copyFileToDirectory(String file, String directory) {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Process.run('cp', [file, directory]);
    case 'windows':
      return Process.run('cmd.exe', ['/C', 'copy $file $directory']);
    default:
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
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
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
  }
}

void main() {
  String scriptDirectory = dirname(Platform.script.toFilePath());
  String buildDirectory = dirname(Platform.executable);
  Directory tempDirectory =
      Directory.systemTemp.createTempSync('dart_test_extension');
  String testDirectory = tempDirectory.path;

  // Copy test_extension shared library, test_extension.dart and
  // test_extension_tester.dart to the temporary test directory.
  copyFileToDirectory(getExtensionPath(buildDirectory),
                      testDirectory).then((_) {
    var extensionDartFile = join(scriptDirectory, 'test_extension.dart');
    return copyFileToDirectory(extensionDartFile, testDirectory);
  }).then((_) {
    var testExtensionTesterFile =
        join(scriptDirectory, 'test_extension_tester.dart');
    return copyFileToDirectory(testExtensionTesterFile, testDirectory);
  }).then((_) {
    var script = join(testDirectory, 'test_extension_tester.dart');
    return Process.run(Platform.executable, [script]);
  })..then((ProcessResult result) {
    Expect.equals(0, result.exitCode);
    tempDirectory.deleteSync(recursive: true);
  })..catchError((_) {
    tempDirectory.deleteSync(recursive: true);
  });
}
