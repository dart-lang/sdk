// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_analysis_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/filenames.dart';
import 'memory_compiler.dart';
import 'serialization_helper.dart';
import 'serialization_test_data.dart';

main(List<String> arguments) {
  asyncTest(() async {
    String serializedData = await serializeDartCore();

    if (arguments.isNotEmpty) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.last));
      await analyze(serializedData, entryPoint, null);
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      for (Test test in TESTS) {
        await analyze(serializedData, entryPoint, test);
      }
    }
  });
}

Future analyze(String serializedData, Uri entryPoint, Test test) async {
  DiagnosticCollector diagnosticCollector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: test != null ? test.sourceFiles : const {},
      options: [Flags.analyzeOnly],
      diagnosticHandler: diagnosticCollector,
      beforeRun: (Compiler compiler) {
        deserialize(compiler, serializedData);
      });
  if (test != null) {
    Expect.equals(test.expectedErrorCount, diagnosticCollector.errors.length,
        "Unexpected error count.");
    Expect.equals(
        test.expectedWarningCount,
        diagnosticCollector.warnings.length,
        "Unexpected warning count.");
    Expect.equals(test.expectedHintCount, diagnosticCollector.hints.length,
        "Unexpected hint count.");
    Expect.equals(test.expectedInfoCount, diagnosticCollector.infos.length,
        "Unexpected info count.");
  }
}

