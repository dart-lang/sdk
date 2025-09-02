// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/codes.dart'
    show codeCantReadFile, codeMissingMain;
import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/util/memory_compiler.dart';

final EXCEPTION = 'Crash-marker';

final Uri entryPoint = Uri.parse('memory:main.dart');

main() {
  runTests() async {
    test('Empty program', await run());
    test(
      'Crash diagnostics',
      await run(diagnostics: CrashingDiagnostics()),
      expectedLines: [
        'Uncaught exception in diagnostic handler: $EXCEPTION',
        null /* Stack trace*/,
      ],
      expectedExceptions: [EXCEPTION],
    );

    var cantReadFile = codeCantReadFile.withArguments(entryPoint, EXCEPTION);
    List<String> expectedLines = [
      "Error: ${cantReadFile.problemMessage}",
      "Error: ${codeMissingMain.problemMessage}",
    ];
    test(
      'Throw in input provider',
      await run(memorySourceFiles: CrashingMap()),
      expectedLines: expectedLines,
    );
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

void test(
  String title,
  RunResult result, {
  List expectedLines = const [],
  List expectedExceptions = const [],
}) {
  print('--------------------------------------------------------------------');
  print('Running $title');
  print('--------------------------------------------------------------------');
  print('lines:');
  result.lines.forEach(print);
  print('exceptions:');
  result.exceptions.forEach(print);
  Expect.equals(
    expectedLines.length,
    result.lines.length,
    "Unexpected number of calls to print.",
  );
  Expect.equals(
    expectedExceptions.length,
    result.exceptions.length,
    "Unexpected number of exceptions.",
  );
  for (int i = 0; i < expectedLines.length; i++) {
    if (expectedLines[i] != null) {
      Expect.stringEquals(expectedLines[i], result.lines[i]);
    }
  }
}

Future<RunResult> run({
  Map<String, String> memorySourceFiles = const {'main.dart': 'main() {}'},
  api.CompilerDiagnostics? diagnostics,
}) async {
  RunResult result = RunResult();
  await runZoned(
    () async {
      try {
        await runCompiler(
          entryPoint: entryPoint,
          memorySourceFiles: memorySourceFiles,
          diagnosticHandler: diagnostics,
        );
      } catch (e) {
        result.exceptions.add(e);
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        result.lines.add(line);
      },
    ),
  );
  return result;
}

class RunResult {
  List<String> lines = <String>[];
  List exceptions = [];
}

class CrashingDiagnostics extends DiagnosticCollector {
  @override
  void report(
    code,
    Uri? uri,
    int? begin,
    int? end,
    String text,
    api.Diagnostic kind,
  ) {
    throw EXCEPTION;
  }
}

class CrashingMap implements Map<String, String> {
  @override
  operator [](_) => throw EXCEPTION;

  @override
  noSuchMethod(_) => null;
}
