// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/fasta/messages.dart'
    show templateCantReadFile, messageMissingMain;
import 'package:compiler/compiler_new.dart';
import '../helpers/memory_compiler.dart';

final EXCEPTION = 'Crash-marker';

final Uri entryPoint = Uri.parse('memory:main.dart');

main() {
  runTests() async {
    test('Empty program', await run());
    test('Crash diagnostics', await run(diagnostics: new CrashingDiagnostics()),
        expectedLines: [
          'Uncaught exception in diagnostic handler: $EXCEPTION',
          null /* Stack trace*/
        ],
        expectedExceptions: [
          EXCEPTION
        ]);

    var cantReadFile =
        templateCantReadFile.withArguments(entryPoint, EXCEPTION);
    List<String> expectedLines = [
      "Error: ${cantReadFile.message}",
      "Error: ${messageMissingMain.message}",
    ];
    test('Throw in input provider',
        await run(memorySourceFiles: new CrashingMap()),
        expectedLines: expectedLines);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

void test(String title, RunResult result,
    {List expectedLines: const [], List expectedExceptions: const []}) {
  print('--------------------------------------------------------------------');
  print('Running $title');
  print('--------------------------------------------------------------------');
  print('lines:');
  result.lines.forEach(print);
  print('exceptions:');
  result.exceptions.forEach(print);
  Expect.equals(expectedLines.length, result.lines.length,
      "Unexpected number of calls to print.");
  Expect.equals(expectedExceptions.length, result.exceptions.length,
      "Unexpected number of exceptions.");
  for (int i = 0; i < expectedLines.length; i++) {
    if (expectedLines[i] != null) {
      Expect.stringEquals(expectedLines[i], result.lines[i]);
    }
  }
}

Future<RunResult> run(
    {Map<String, String> memorySourceFiles: const {'main.dart': 'main() {}'},
    CompilerDiagnostics diagnostics}) async {
  RunResult result = new RunResult();
  await runZoned(() async {
    try {
      await runCompiler(
          entryPoint: entryPoint,
          memorySourceFiles: memorySourceFiles,
          diagnosticHandler: diagnostics,
          unsafeToTouchSourceFiles: true);
    } catch (e) {
      result.exceptions.add(e);
    }
  }, zoneSpecification: new ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
    result.lines.add(line);
  }));
  return result;
}

class RunResult {
  List<String> lines = <String>[];
  List exceptions = [];
}

class CrashingDiagnostics extends DiagnosticCollector {
  @override
  void report(code, Uri uri, int begin, int end, String text, Diagnostic kind) {
    throw EXCEPTION;
  }
}

class CrashingMap implements Map<String, String> {
  @override
  operator [](_) => throw EXCEPTION;

  @override
  noSuchMethod(_) => null;
}
