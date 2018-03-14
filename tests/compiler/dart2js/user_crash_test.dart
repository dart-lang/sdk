// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'memory_compiler.dart';

final EXCEPTION = 'Crash-marker';

main() {
  runTests({bool useKernel}) async {
    test('Empty program', await run(useKernel: useKernel));
    test('Crash diagnostics',
        await run(useKernel: useKernel, diagnostics: new CrashingDiagnostics()),
        expectedLines: [
          'Uncaught exception in diagnostic handler: $EXCEPTION',
          null /* Stack trace*/
        ],
        expectedExceptions: [
          EXCEPTION
        ]);
    test(
        'Throw in package discovery',
        await run(
            useKernel: useKernel,
            packagesDiscoveryProvider: (_) {
              throw EXCEPTION;
            }),
        expectedLines: [
          'Uncaught exception in package discovery: $EXCEPTION',
          null /* Stack trace*/
        ],
        expectedExceptions: [
          EXCEPTION
        ]);
    test(
        'new Future.error in package discovery',
        await run(
            useKernel: useKernel,
            packagesDiscoveryProvider: (_) => new Future.error(EXCEPTION)),
        expectedExceptions: [EXCEPTION]);

    List<String> expectedLines;
    if (useKernel) {
      expectedLines = ['Error: Input file not found: memory:main.dart.'];
    } else {
      expectedLines = [
        'Uncaught exception in input provider: $EXCEPTION',
        null, // Stack trace
        'memory:main.dart:\nError: $EXCEPTION' /* READ_SELF_ERROR */
      ];
    }
    test('Throw in input provider',
        await run(useKernel: useKernel, memorySourceFiles: new CrashingMap()),
        expectedLines: expectedLines);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
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
      Expect.equals(expectedLines[i], result.lines[i]);
    }
  }
}

Future<RunResult> run(
    {Map<String, String> memorySourceFiles: const {'main.dart': 'main() {}'},
    CompilerDiagnostics diagnostics,
    PackagesDiscoveryProvider packagesDiscoveryProvider,
    bool useKernel}) async {
  RunResult result = new RunResult();
  await runZoned(() async {
    try {
      await runCompiler(
          entryPoint: Uri.parse('memory:main.dart'),
          memorySourceFiles: memorySourceFiles,
          diagnosticHandler: diagnostics,
          packagesDiscoveryProvider: packagesDiscoveryProvider,
          options: useKernel ? [] : [Flags.useOldFrontend]);
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
  operator [](_) => throw EXCEPTION;

  noSuchMethod(_) => null;
}
