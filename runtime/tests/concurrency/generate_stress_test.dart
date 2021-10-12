// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

final thisDirectory = path.join('runtime', 'tests', 'concurrency');
final stressTestListJson = path.join(thisDirectory, 'stress_test_list.json');
final generatedTest = path.join(thisDirectory, 'generated_stress_test.dart');
final generatedNnbdTest =
    path.join(path.join(thisDirectory, 'generated_stress_test_nnbd.dart'));

final Map testMap = json.decode(File(stressTestListJson).readAsStringSync());
final testFiles = testMap['non-nnbd'].cast<String>();
final testFilesNnbd = testMap['nnbd'].cast<String>();
final dart = 'tools/sdks/dart-sdk/bin/dart';

main(List<String> args) async {
  File(generatedNnbdTest)
      .writeAsStringSync(await generateStressTest(testFilesNnbd));
  File(generatedTest).writeAsStringSync(await generateStressTest(testFiles));
}

Future<String> generateStressTest(List<String> testFiles) async {
  testFiles = testFiles
      .map((String file) => path.absolute(path.join(thisDirectory, file)))
      .toList();

  final sb = StringBuffer();
  sb.writeln(r'''
import 'dart:async';
import 'dart:isolate';
import 'dart:io';

''');
  for (int i = 0; i < testFiles.length; ++i) {
    final testFile = testFiles[i];
    sb.writeln('import "$testFile" as test$i;');
  }
  for (int i = 0; i < testFiles.length; ++i) {
    final testFile = testFiles[i];
    sb.writeln('''
        wrapper$i(dynamic _) {
          print('[$testFile] starting ...');
          runZoned(() {
            test$i.main();
          }, zoneSpecification: ZoneSpecification(
            handleUncaughtError: (_, ZoneDelegate parent, Zone zone, error, stack) {
              parent.print(zone, 'Error($testFile): \$error \\nstack:\$stack');
              parent.handleUncaughtError(zone, error, stack);
            },
            print: (_, _2, _3, String line) {}));
        }
        ''');
  }
  sb.writeln('');
  sb.writeln(r'''
    class Test {
      final String name;
      final dynamic Function(dynamic) fun;
      Test(this.name, this.fun);
    }
  ''');
  sb.writeln('final List<Test> tests = [');
  for (int i = 0; i < testFiles.length; ++i) {
    final testFile = testFiles[i];
    sb.writeln('  Test("$testFile", wrapper$i),');
  }
  sb.writeln('];');
  sb.writeln('');

  sb.writeln('''
class Runner {
  static const progressEvery = 100;

  final List<Test> tests;
  late final ReceivePort onExit;
  late final List<ReceivePort> onExits;
  late final List<ReceivePort> onErrors;
  final List<String> errorLog = [];

  Runner(this.tests) {
    onExit = ReceivePort();
    onExits = List<ReceivePort>.generate(tests.length, (int i) {
      return ReceivePort()..listen((_) {
        print('[\${tests[i].name}] finished');
        onExit.sendPort.send(null);
      });
    });
    onErrors = List<ReceivePort>.generate(tests.length, (int i) {
      return ReceivePort()..listen((error) {
        errorLog.add('[\${tests[i].name}] error: \$error');
      });
    });
  }

  Future runWithUnlimitedParallelism() async {
    for (int i = 0; i < tests.length; ++i) {
      await Isolate.spawn(
          tests[i].fun,
          null,
          onExit: onExits[i].sendPort,
          onError: onErrors[i].sendPort);
    }
    await waitUntilDone();
  }

  Future runWithParallelism(int parallelism) async {
    int _current = 0;

    Future run() async {
      final int current = _current++;
      await Isolate.spawn(
          tests[current].fun,
          null,
          onExit: onExits[current].sendPort,
          onError: onErrors[current].sendPort);
    }
    void scheduleNext() {
      if (_current == tests.length) return;
      run().whenComplete(scheduleNext);
    }

    for (int i = 0; i < parallelism; ++i) {
      scheduleNext();
    }
    await waitUntilDone();
  }

  Future waitUntilDone() async {
    final exitSi = StreamIterator(onExit);
    for (int i = 0; i < tests.length; ++i) {
      await exitSi.moveNext();
    }
    await exitSi.cancel();
    onExit.close();
    onExits.forEach((rp) => rp.close());
    onErrors.forEach((rp) => rp.close());

    if (!errorLog.isEmpty) {
      print('Spawning tests in isolates resulted in the following errors:');
      print('------------------------------------------------------------');
      errorLog.forEach(print);
      print('------------------------------------------------------------');
      print('-> Setting exitCode to 255');
      exitCode = 255;
    }
  }

}

main() async {
  final shards = int.fromEnvironment(
      'shards', defaultValue: 1);
  final shard = int.fromEnvironment(
      'shard', defaultValue: 0);

  final repeat = int.fromEnvironment(
      'repeat', defaultValue: 1);

  final parallelism = int.fromEnvironment(
      'parallelism', defaultValue: 0);

  final filteredTests = <Test>[];
  for (int i = 0; i < tests.length; ++i) {
    if ((i % shards) == shard) {
      final test = tests[i];
      for (int j = 0; j < repeat; ++j) {
        filteredTests.add(test);
      }
    }
  }

  final runner = Runner(filteredTests);
  if (parallelism <= 0) {
    await runner.runWithUnlimitedParallelism();
  } else {
    await runner.runWithParallelism(parallelism);
  }
}
  ''');
  return format(sb.toString());
}

Future<String> format(String generatedSource) async {
  try {
    final result = await Process.start(dart, ['format']);
    result.stdin.writeln(generatedSource);

    final results = await Future.wait([
      result.stdin.close(),
      result.stdout.transform(utf8.decoder).join(''),
      result.stderr.transform(utf8.decoder).join(''),
      result.exitCode
    ]);

    final exitCode = results[3] as int;
    if (exitCode != 0) {
      print('Note: Failed to format source code. Dart format exited non-0.');
      return generatedSource;
    }
    final stdout = results[1] as String;
    final stderr = results[2] as String;
    if (stderr.trim().length != 0) {
      print('Note: Failed to format source code. Dart format had stderr: '
          '$stderr');
      return generatedSource;
    }
    return stdout;
  } catch (e) {
    print('Note: Failed to format source code: $e');
    return generatedSource;
  }
}
