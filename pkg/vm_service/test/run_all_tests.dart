// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

Never usage() {
  print('Usage: ${Platform.executable} ${Platform.script} [--update-goldens]');
  exit(1);
}

const int testPoolSize = 15;

/// This script updates all the stops goldens in the vm_service tests.
Future<void> main(List<String> args) async {
  args = [...args];
  final updateGoldens = args.remove('--update-goldens');
  final verbose = args.remove('--verbose');
  if (args.isNotEmpty) {
    usage();
  }

  final tests = collectTests();
  final futures = <Future<void>>[];
  final readyCompleters = <Completer<void>>[];

  for (var test in tests) {
    if (futures.length < testPoolSize) {
      futures.add(runTest(
          test,
          Future<void>.value().then((_) => readyCompleters.isEmpty
              ? null
              : readyCompleters.removeLast().complete()),
          updateGoldens: updateGoldens,
          verbose: verbose));
    } else {
      final ready = Completer<void>();
      readyCompleters.add(ready);
      futures.add(runTest(test, ready.future,
              updateGoldens: updateGoldens, verbose: verbose)
          .then((_) => readyCompleters.isEmpty
              ? null
              : readyCompleters.removeLast().complete()));
    }
  }
  await Future.wait(futures);
}

List<File> collectTests() {
  final dataFolder = Directory.fromUri(Platform.script.resolve('.'));
  final files = <File>[];
  for (var file in dataFolder.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('_test.dart')) {
      files.add(file);
    }
  }
  return files;
}

Future<void> runTest(File testFile, Future<void> ready,
    {required bool updateGoldens, required bool verbose}) async {
  await ready;
  final result = await Process.run(
    Platform.executable,
    [
      testFile.path,
      if (updateGoldens) '--update-goldens',
    ],
  );
  if (result.exitCode != 0) {
    print('Test failed: ${testFile.path}');
    if (verbose) {
      print('stdout:');
      print(result.stdout);
      print('stderr:');
      print(result.stderr);
    }
  } else {
    print('Test passed: ${testFile.path}');
  }
}
