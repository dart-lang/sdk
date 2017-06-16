// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_analysis_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/filenames.dart';
import '../memory_compiler.dart';
import 'helper.dart';
import 'test_data.dart';

/// Number of tests that are not part of the automatic test grouping.
int SKIP_COUNT = 0;

/// Number of groups that the [TESTS] are split into.
int SPLIT_COUNT = 5;

main(List<String> args) {
  asyncTest(() async {
    Arguments arguments = new Arguments.from(args);
    SerializedData serializedData =
        await serializeDartCore(arguments: arguments);
    if (arguments.filename != null) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.filename));
      await analyze(entryPoint,
          resolutionInputs: serializedData.toUris(),
          sourceFiles: serializedData.toMemorySourceFiles());
    } else {
      await arguments.forEachTest(serializedData, TESTS, analyze);
    }
    printMeasurementResults();
  });
}

Future analyze(Uri entryPoint,
    {Map<String, String> sourceFiles: const <String, String>{},
    List<Uri> resolutionInputs,
    int index,
    Test test,
    bool verbose: false}) async {
  String testDescription = test != null ? test.name : '${entryPoint}';
  String id = index != null ? '$index: ' : '';
  String title = '${id}${testDescription}';
  await measure(title, 'analyze', () async {
    DiagnosticCollector diagnosticCollector = new DiagnosticCollector();
    await runCompiler(
        entryPoint: entryPoint,
        resolutionInputs: resolutionInputs,
        memorySourceFiles: sourceFiles,
        options: [Flags.analyzeOnly],
        diagnosticHandler: diagnosticCollector);
    if (test != null) {
      Expect.equals(test.expectedErrorCount, diagnosticCollector.errors.length,
          "Unexpected error count.");
      Expect.equals(test.expectedWarningCount,
          diagnosticCollector.warnings.length, "Unexpected warning count.");
      Expect.equals(test.expectedHintCount, diagnosticCollector.hints.length,
          "Unexpected hint count.");
      Expect.equals(test.expectedInfoCount, diagnosticCollector.infos.length,
          "Unexpected info count.");
    }
  });
}
