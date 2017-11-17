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
    case 'android':
    case 'linux':
    case 'macos':
      return Process.run('cp', [file, directory]);
    case 'windows':
      return Process.run('cmd.exe', ['/C', 'copy $file $directory']);
    default:
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
  }
}

// Returns a list containing the source file name in the first element and the
// target file name in the second element.
List<String> getExtensionNames(String arch) {
  switch (Platform.operatingSystem) {
    case 'android':
    case 'linux':
      return ['libtest_extension.so', 'libtest_extension$arch.so'];
    case 'macos':
      return ['libtest_extension.dylib', 'libtest_extension$arch.dylib'];
    case 'windows':
      return ['test_extension.dll', 'test_extension$arch.dll'];
    default:
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
  }
}

String getExtensionPath(String buildDirectory, String filename) {
  switch (Platform.operatingSystem) {
    case 'android':
    case 'linux':
      return join(buildDirectory, 'lib.target', filename);
    case 'macos':
    case 'windows':
      return join(buildDirectory, filename);
    default:
      Expect.fail('Unknown operating system ${Platform.operatingSystem}');
  }
}

String getArchFromBuildDir(String buildDirectory) {
  if (buildDirectory.endsWith('SIMARM')) return '';
  if (buildDirectory.endsWith('SIMARM64')) return '';
  if (buildDirectory.endsWith('SIMDBC')) return '';
  if (buildDirectory.endsWith('SIMDBC64')) return '';
  if (buildDirectory.endsWith('ARM')) return '-arm';
  if (buildDirectory.endsWith('ARM64')) return '-arm64';
  if (buildDirectory.endsWith('IA32')) return '-ia32';
  if (buildDirectory.endsWith('X64')) return '-x64';
  return 'unknown';
}

Future testExtension(bool withArchSuffix) {
  String scriptDirectory = dirname(Platform.script.toFilePath());
  String buildDirectory = dirname(Platform.executable);
  Directory tempDirectory =
      Directory.systemTemp.createTempSync('dart_test_extension');
  String testDirectory = tempDirectory.path;

  List<String> fileNames;
  if (withArchSuffix) {
    String arch = getArchFromBuildDir(buildDirectory);
    fileNames = getExtensionNames(arch);
  } else {
    fileNames = getExtensionNames('');
  }

  // Copy test_extension shared library, test_extension.dart and
  // test_extension_tester.dart to the temporary test directory.
  return copyFileToDirectory(getExtensionPath(buildDirectory, fileNames[0]),
      join(testDirectory, fileNames[1])).then((_) {
    var extensionDartFile = join(scriptDirectory, 'test_extension.dart');
    return copyFileToDirectory(extensionDartFile, testDirectory);
  }).then((_) {
    var testExtensionTesterFile =
        join(scriptDirectory, 'test_extension_tester.dart');
    return copyFileToDirectory(testExtensionTesterFile, testDirectory);
  }).then<ProcessResult>((_) {
    var script = join(testDirectory, 'test_extension_tester.dart');
    return Process.run(Platform.executable, [script]);
  })
    ..then((ProcessResult result) {
      if (result.exitCode != 0) {
        print('Subprocess failed with exit code ${result.exitCode}');
        print('stdout:');
        print('${result.stdout}');
        print('stderr:');
        print('${result.stderr}');
      }
      Expect.equals(0, result.exitCode);
      tempDirectory.deleteSync(recursive: true);
    })
    ..catchError((_) {
      tempDirectory.deleteSync(recursive: true);
    });
}

Future testWithArchSuffix() {
  return testExtension(true);
}

Future testWithoutArchSuffix() {
  return testExtension(false);
}

main() async {
  await testWithArchSuffix();
  await testWithoutArchSuffix();
}
