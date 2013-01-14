// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native extensions.

import "dart:async";
import "dart:io";

Future copyFileToDirectory(Path file, Path directory) {
  String src = file.toNativePath();
  String dst = directory.toNativePath();
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Process.run('cp', [src, dst]);
    case 'windows':
      return Process.run('cmd.exe', ['/C', 'copy $src $dst']);
    default:
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
  }
}

Path getExtensionPath(Path buildDirectory) {
  switch (Platform.operatingSystem) {
    case 'linux':
      return buildDirectory.append('lib.target/libtest_extension.so');
    case 'macos':
      return buildDirectory.append('libtest_extension.dylib');
    case 'windows':
      return buildDirectory.append('test_extension.dll');
    default:
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
  }
}

void main() {
  Options options = new Options();

  Path scriptDirectory = new Path(options.script).directoryPath;
  Path buildDirectory = new Path(options.executable).directoryPath;
  Directory tempDirectory = new Directory('').createTempSync();
  Path testDirectory = new Path(tempDirectory.path);

  // Copy test_extension shared library, test_extension.dart and
  // test_extension_fail_tester.dart to the temporary test directory.
  copyFileToDirectory(getExtensionPath(buildDirectory),
                      testDirectory).then((_) {
    Path extensionDartFile = scriptDirectory.append('test_extension.dart');
    return copyFileToDirectory(extensionDartFile, testDirectory);
  }).then((_) {
    Path testExtensionTesterFile =
        scriptDirectory.append('test_extension_fail_tester.dart');
    return copyFileToDirectory(testExtensionTesterFile, testDirectory);
  }).then((_) {
    Path script = testDirectory.append('test_extension_fail_tester.dart');
    return Process.run(options.executable, [script.toNativePath()]);
  }).then((ProcessResult result) {
    print("ERR: ${result.stderr}\n\n");
    print("OUT: ${result.stdout}\n\n");
    Expect.equals(255, result.exitCode);
    Expect.isTrue(result.stderr.contains("Unhandled exception:\nball\n"));
  }).whenComplete(() => tempDirectory.deleteSync(recursive: true));
}
