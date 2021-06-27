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
final dartfmt = 'tools/sdks/dart-sdk/bin/dartfmt';

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
  sb.writeln('final List<dynamic Function(dynamic)> wrappers = [');
  for (int i = 0; i < testFiles.length; ++i) {
    final testFile = testFiles[i];
    sb.writeln('  wrapper$i,');
  }
  sb.writeln('];');
  sb.writeln('final List<String> wrapperNames = [');
  for (int i = 0; i < testFiles.length; ++i) {
    final testFile = testFiles[i];
    sb.writeln('  "$testFile",');
  }
  sb.writeln('];');
  sb.writeln('');
  sb.writeln('''
class Runner {
  static const progressEvery = 100;

  final List<String> testNames;
  final List<dynamic Function(dynamic)> tests;
  late final ReceivePort onExit;
  late final List<ReceivePort> onExits;
  late final List<ReceivePort> onErrors;

  Runner(this.testNames, this.tests) {
    onExit = ReceivePort();
    onExits = List<ReceivePort>.generate(tests.length, (int i) {
      return ReceivePort()..listen((_) {
        print('[\${testNames[i]}] finished');
        onExit.sendPort.send(null);
      });
    });
    onErrors = List<ReceivePort>.generate(tests.length, (int i) {
      return ReceivePort()..listen((error) {
        print('[\${testNames[i]}] error: \$error');
      });
    });
  }

  Future runWithUnlimitedParallelism() async {
    for (int i = 0; i < tests.length; ++i) {
      await Isolate.spawn(
          tests[i],
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
          tests[current],
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
  }

}

main() async {
  const int parallelism = const int.fromEnvironment(
      'parallelism', defaultValue: 0);

  final runner = Runner(wrapperNames, wrappers);
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
    final result = await Process.start(dartfmt, []);
    result.stdin.writeln(generatedSource);

    final results = await Future.wait([
      result.stdin.close(),
      result.stdout.transform(utf8.decoder).join(''),
      result.stderr.transform(utf8.decoder).join(''),
      result.exitCode
    ]);

    final exitCode = results[3] as int;
    if (exitCode != 0) {
      print('Note: Failed to format source code. Dartfmt exited non-0.');
      return generatedSource;
    }
    final stdout = results[1] as String;
    final stderr = results[2] as String;
    if (stderr.trim().length != 0) {
      print('Note: Failed to format source code. Dartfmt had stderr: $stderr');
      return generatedSource;
    }
    return stdout;
  } catch (e) {
    print('Note: Failed to format source code: $e');
    return generatedSource;
  }
}
