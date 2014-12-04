// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that dart2js produces the expected static type warnings and
// compile-time errors for the provided multitests.

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import 'memory_compiler.dart';

import '../../../tools/testing/dart/multitest.dart'
    show ExtractTestsFromMultitest;
import '../../../tools/testing/dart/path.dart'
    show Path;

void check(List<String> testFiles,
           {List<String> arguments: const <String>[],
            List<String> options: const <String>[]}) {
  bool outcomeMismatch = false;
  bool verbose = arguments.contains('-v');
  var cachedCompiler;
  asyncTest(() => Future.forEach(testFiles, (String testFile) {
    Map<String, String> testSources = {};
    Map<String, Set<String>> testOutcomes = {};
    String fileName = 'tests/$testFile';
    ExtractTestsFromMultitest(new Path(fileName), testSources, testOutcomes);
    return Future.forEach(testSources.keys, (String testName) {
      String testFileName = '$fileName/$testName';
      Set<String> expectedOutcome = testOutcomes[testName];
      DiagnosticCollector collector = new DiagnosticCollector();
      var compiler = compilerFor(
           {testFileName: testSources[testName]},
           diagnosticHandler: collector,
           options: ['--analyze-only']..addAll(options),
           showDiagnostics: verbose,
           cachedCompiler: cachedCompiler);
      return compiler.run(Uri.parse('memory:$testFileName')).then((_) {
        if (expectedOutcome.contains('compile-time error')) {
          if (collector.errors.isEmpty) {
            print('$testFileName: Missing compile-time error.');
            outcomeMismatch = true;
          }
        } else if (expectedOutcome.contains('static type warning')) {
          if (collector.warnings.isEmpty) {
            print('$testFileName: Missing static type warning.');
            outcomeMismatch = true;
          }
        } else {
          // Expect ok.
          if (!collector.errors.isEmpty ||
              !collector.warnings.isEmpty) {
            collector.errors.forEach((message) {
              print('$testFileName: Unexpected error: ${message.message}');
            });
            collector.warnings.forEach((message) {
              print('$testFileName: Unexpected warning: ${message.message}');
            });
            outcomeMismatch = true;
          }
        }
        cachedCompiler = compiler;
      });
    });
  }).then((_) {
    Expect.isFalse(outcomeMismatch, 'Outcome mismatch');
  }));
}
