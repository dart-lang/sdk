// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import 'generate_stress_test.dart';

final sdkRoot = path.canonicalize(path.join(thisDirectory, '../../../'));
final tempFile = path.join(thisDirectory, 'temp.dart');

final dartDirectories = [
  'runtime/tests/vm/dart',
  'tests/corelib',
  'tests/language',
  'tests/lib',
  'tests/standalone',
];
final dart2Directories = [
  'tests/corelib_2',
  'tests/language_2',
  'tests/lib_2',
];

main(List<String> args) async {
  final testFiles = await findValidTests(dart2Directories, false);
  final nnbdTestFiles = await findValidTests(dartDirectories, true);

  File(stressTestListJson)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'nnbd': nnbdTestFiles,
    'non-nnbd': testFiles,
  }));
}

Future<List<String>> findValidTests(List<String> directories, bool nnbd) async {
  print('Using SDK root: $sdkRoot');
  final testFiles = <String>[];
  final failedOrTimedOut = <String>[];
  final filteredTests = <String>[];
  await for (final testFile
      in listTestFiles(sdkRoot, directories, filteredTests)) {
    print(testFile);
    final duration = await run(sdkRoot, testFile, tempFile, nnbd);
    if (duration != null && duration.inSeconds < 6) {
      print('-> good');
      testFiles.add(testFile);
    } else {
      print('-> failed or timed out');
      failedOrTimedOut.add(testFile);
    }
  }
  testFiles.sort();
  failedOrTimedOut.sort();
  filteredTests.sort();

  dumpTestList(testFiles, 'The following tests will be included:');
  dumpTestList(failedOrTimedOut,
      'The following tests will be excluded due to timeout or test failure:');
  dumpTestList(filteredTests,
      'The following tests were filtered due to using blacklisted things:');

  for (int i = 0; i < testFiles.length; ++i) {
    testFiles[i] = path.relative(testFiles[i], from: thisDirectory);
  }
  if (File(tempFile).existsSync()) {
    File(tempFile).deleteSync();
  }
  return testFiles;
}

void dumpTestList(List<String> testFiles, String message) {
  if (testFiles.isEmpty) return;

  print(message);
  for (final testFile in testFiles) {
    print('  ${path.basename(testFile)}');
  }
}

Stream<String> listTestFiles(String sdkRoot, List<String> directories,
    List<String> filteredTests) async* {
  for (final dir in directories) {
    await for (final file
        in Directory(path.join(sdkRoot, dir)).list(recursive: true)) {
      if (file is File && file.path.endsWith('_test.dart')) {
        final contents = file.readAsStringSync();
        if (contents.contains(RegExp('//# .* compile-time error')) ||
            contents.contains('DynamicLibrary.process') ||
            contents.contains('DynamicLibrary.executable') ||
            contents.contains('\npart') ||
            contents.contains('mirror') ||
            contents.contains('Directory.current =') ||
            contents.contains('dart:isolate') ||
            file.path.contains('wait_for') ||
            file.path.contains('mirror') ||
            file.path.contains('non_utf8')) {
          filteredTests.add(file.path);
          continue;
        }
        yield file.path;
      }
    }
  }
}

Future<Duration?> run(
    String sdkRoot, String testFile, String wrapFile, bool nnbd) async {
  final env = Map<String, String>.from(Platform.environment);
  env['LD_LIBRARY_PATH'] = path.join(sdkRoot, 'out/ReleaseX64');
  final sw = Stopwatch()..start();
  final f = File(wrapFile);
  f.writeAsStringSync('''
import 'dart:isolate';
import 'dart:io' as io;
import '$testFile' as m;

wrapper(dynamic arg) {
  m.main();
}

main() async {
  final exit = ReceivePort();
  final errors = ReceivePort();
  await Isolate.spawn(wrapper, null, onExit: exit.sendPort, onError: errors.sendPort);
  errors.listen((_) {
    io.exit(123);
  });
  await exit.first;
  // We delay it a bit in case the real test exit()s, in which case we
  // wouldn't print the line below, which would exclude the test from
  // being used in the big fuzzing test.
  await Future.delayed(const Duration(milliseconds: 100));
  print('Success: WORKED!');
  errors.close();
}
''');
  final Process process = await Process.start(Platform.executable,
      <String>[nnbd ? '--sound-null-safety' : '--no-sound-null-safety', f.path],
      environment: env);
  final timer = Timer(const Duration(seconds: 3), () => process.kill());
  bool good = false;
  final stdoutF = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        if (line.contains('Success: WORKED!')) {
          good = true;
        }
      }, onError: (e, s) {})
      .asFuture()
      .catchError((e, s) {});
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {}, onError: (e, s) {});
  if (await process.exitCode != 0) return null;
  await stdoutF;
  f.deleteSync();
  if (!good) {
    return null;
  }
  timer.cancel();
  return sw.elapsed;
}
