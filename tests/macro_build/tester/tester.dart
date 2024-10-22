// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final dartSdkOutDirectory = _findSdkOutDirectory();

String _findSdkOutDirectory() {
  var dartSdkOutDirectory = File(Platform.resolvedExecutable).parent;
  if (!Directory.fromUri(dartSdkOutDirectory.uri.resolve('gen')).existsSync()) {
    // Not next to `dart`, try two levels up for `dart-sdk/bin` suffix.
    dartSdkOutDirectory = dartSdkOutDirectory.parent.parent;
  }
  if (!Directory.fromUri(dartSdkOutDirectory.uri.resolve('gen')).existsSync()) {
    fail("Can't find SDK 'gen' directory from ${Platform.resolvedExecutable}, "
        'please run from an SDK build out.');
  }
  return dartSdkOutDirectory.path;
}

/// Tests a macro build specified by [commands].
///
/// The commands are launched with current directory set to a temp folder with
/// a fresh copy of the package `package_under_test`.
///
/// The commands should build and run `bin/main.dart`. It is a test that will
/// string `OK\n` showing that the macro output ran.
///
/// In commands, the string `$DART` is replaced to refer to the `dart` command
/// in the Dart SDK under test; and `$DART_SDK` to the root of the built Dart
/// SDK under test.
///
/// The test passes if all commands return exit code 0.
Future<void> testMacroBuild(List<String> commands) async {
  var temp = Directory.systemTemp.createTempSync('macro_build_test');
  var sourceDirectory =
      Directory.current.path + '/tests/macro_build/package_under_test';
  var workingDirectory = '${temp.path}/package_under_test';
  await _copyPath(sourceDirectory, workingDirectory);

  final dartSdkPath = Directory.current.path;
  final dartPath = Platform.resolvedExecutable;
  final dartAotPath = p.absolute(dartSdkOutDirectory, 'dart-sdk/bin',
      Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime');

  if (!File(dartAotPath).existsSync()) {
    fail('This test is not supported on SDK configurations that do not have '
        'an AOT runtime');
  }

  // TODO(davidmorgan): run on more platforms.
  final configuration = String.fromEnvironment('test_runner.configuration');
  if (configuration.isEmpty) {
    print(r'''
Hint: this test is an e2e test of SDK tools, consider running using the test
runner to ensure they are built and not stale:

./tools/test.py -v -nunittest-asserts-release-linux-x64 \
    --build 'tests/macro_build/*'
''');
  }

  _fixPubspec(
      pubspecPath: '$workingDirectory/pubspec.yaml', dartSdkPath: dartSdkPath);

  var failed = false;
  var timedOut = false;
  for (var command in commands) {
    if (command.contains(r'$DART_SDK_OUT')) {
      // Only search for SDK out directory if it's needed for this test case.
      command = command.replaceAll(r'$DART_SDK_OUT', dartSdkOutDirectory);
    }
    final commandParts = command
        .replaceAll(r'$DART_SDK', dartSdkPath)
        .replaceAll(r'$DARTAOTRUNTIME', dartAotPath)
        .replaceAll(r'$DART', dartPath)
        .split(' ')
        .map((c) => c.replaceAll(r'$SPACE', ' '))
        .toList();

    print('Running: ${commandParts.join(' ')}');
    final process = await Process.start(
        commandParts.first, commandParts.skip(1).toList(),
        workingDirectory: workingDirectory);
    try {
      final result = await process.exitCode.timeout(Duration(seconds: 60));
      if (result != 0) {
        failed = true;
      }
    } on TimeoutException catch (_) {
      timedOut = true;
      process.kill();
    }

    final stdout =
        (await process.stdout.transform(utf8.decoder).toList()).join('');
    final stderr =
        (await process.stderr.transform(utf8.decoder).toList()).join('');
    print('--- stdout ---\n$stdout--- stderr ---\n$stderr---\n');

    if (timedOut || failed) break;
  }

  if (failed) {
    Expect.fail('Command exited with non-zero exit code.');
  }
  if (timedOut) {
    Expect.fail('Command ran for more than 60s.');
  }
}

Future<void> _copyPath(String from, String to) async {
  await Directory(to).create(recursive: true);
  await for (final file in Directory(from).list(recursive: true)) {
    final copyTo = p.join(to, p.relative(file.path, from: from));
    if (file is Directory) {
      await Directory(copyTo).create(recursive: true);
    } else if (file is File) {
      await File(file.path).copy(copyTo);
    }
  }
}

/// Fixes relative paths in the pubspec at [pubspecPath] to refer to the
/// Dart SDK path [dartSdkPath].
void _fixPubspec({required String pubspecPath, required String dartSdkPath}) {
  print('Updated $pubspecPath to point to SDK under $dartSdkPath.');
  var file = File(pubspecPath);
  file.writeAsStringSync(
      file.readAsStringSync().replaceAll('../../..', dartSdkPath));
}
