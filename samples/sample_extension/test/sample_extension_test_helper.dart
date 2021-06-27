// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native extensions.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import "package:expect/expect.dart";
import "package:path/path.dart";

Future copyFileToDirectory(String file, String directory) async {
  String src = file;
  String dst = directory;
  ProcessResult result;
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      result = await Process.run('cp', [src, dst]);
      break;
    case 'windows':
      result = await Process.run('cmd.exe', ['/C', 'copy $src $dst']);
      break;
    default:
      throw 'Unknown operating system ${Platform.operatingSystem}';
  }
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw "Failed to copy test file ($file) to temporary directory ($directory)";
  }
}

Future run(String program, List<String> arguments) async {
  print("+ $program ${arguments.join(' ')}");
  ProcessResult result = await Process.run(program, arguments);
  if (result.exitCode != 0) {
    print('Failing process stdout: ${result.stdout}');
    print('Failing process stderr: ${result.stderr}');
    print('End failing process stderr');
    Expect.fail('Test failed with exit code ${result.exitCode}');
  }
}

Future runTests(
    String program, String testDirectory, String? snapshotKind) async {
  for (var test in [
    'test_sample_synchronous_extension.dart',
    'test_sample_asynchronous_extension.dart'
  ]) {
    String script = join(testDirectory, test);
    String snapshot;
    if (snapshotKind == null) {
      snapshot = script;
    } else {
      snapshot = join(testDirectory, "$test.snapshot");
      await run(Platform.executable, <String>[
        ...Platform.executableArguments,
        '--snapshot=$snapshot',
        '--snapshot-kind=$snapshotKind',
        script
      ]);
    }

    await run(program, <String>[...Platform.executableArguments, snapshot]);
  }
}

Future testNativeExtensions(String? snapshotKind) async {
  String buildDirectory = dirname(Platform.executable);
  Directory tempDirectory =
      Directory.systemTemp.createTempSync('sample_extension_');
  try {
    String testDirectory = tempDirectory.path;
    String sourceDirectory = Platform.script.resolve('..').toFilePath();

    // Copy sample_extension dart files and sample_extension tests to the
    // temporary test directory.
    for (var file in [
      'sample_synchronous_extension.dart',
      'sample_asynchronous_extension.dart',
      'test_sample_synchronous_extension.dart',
      'test_sample_asynchronous_extension.dart'
    ]) {
      await copyFileToDirectory(join(sourceDirectory, file), testDirectory);
    }

    // Test native library resolution when it's next to the binary
    await runTests(Platform.executable, testDirectory, snapshotKind);

    // Test native library resolution when it's next to the source
    await copyFileToDirectory(
        join(
            buildDirectory,
            (Platform.isWindows ? '' : 'lib') +
                'sample_extension' +
                (Platform.isWindows
                    ? '.dll'
                    : Platform.isMacOS
                        ? '.dylib'
                        : '.so')),
        testDirectory);
    Directory tempBinDirectory = Directory(join(tempDirectory.path, 'dart-bin'))
      ..createSync();
    await copyFileToDirectory(Platform.executable, tempBinDirectory.path);
    String copyPlatformExecutable =
        join(tempBinDirectory.path, basename(Platform.executable));
    await runTests(copyPlatformExecutable, testDirectory, snapshotKind);
  } finally {
    tempDirectory.deleteSync(recursive: true);
  }
}
