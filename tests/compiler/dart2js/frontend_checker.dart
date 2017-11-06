// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that dart2js produces the expected static type warnings and
// compile-time errors for the provided multitests.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/util/uri_extras.dart' show relativize;
import 'memory_compiler.dart';

import '../../../tools/testing/dart/multitest.dart'
    show ExtractTestsFromMultitest;
import '../../../tools/testing/dart/path.dart' show Path;

/// Check the analysis of the multitests in [testFiles] to result in the
/// expected static warnings and compile-time errors.
///
/// [testFiles] is a map of the test files to be checked together with their
/// associated white listing.
///
/// For instance if [testFiles] contain the mapping
///     'language/async_await_syntax_test.dart': const ['a03b', 'a04b']
/// the multitests in 'language/async_await_syntax_test.dart' are checked but
/// the subtests 'a03b' and 'a04c' are expected to fail.
void check(Map<String, List<String>> testFiles,
    {List<String> arguments: const <String>[],
    List<String> options: const <String>[]}) {
  bool outcomeMismatch = false;
  bool verbose = arguments.contains('-v');
  var cachedCompiler;
  asyncTest(() => Future.forEach(testFiles.keys, (String testFile) {
        Map<String, String> testSources = {};
        Map<String, Set<String>> testOutcomes = {};
        String fileName = 'tests/$testFile';
        ExtractTestsFromMultitest(
            new Path(fileName), testSources, testOutcomes);
        return Future.forEach(testSources.keys, (String testName) async {
          String testFileName = '$fileName/$testName';
          Set<String> expectedOutcome = testOutcomes[testName];
          bool expectFailure = testFiles[testFile].contains(testName);
          DiagnosticCollector collector = new DiagnosticCollector();
          CompilationResult result = await runCompiler(
              entryPoint: Uri.parse('memory:$testFileName'),
              memorySourceFiles: {testFileName: testSources[testName]},
              diagnosticHandler: collector,
              options: [Flags.analyzeOnly]..addAll(options),
              showDiagnostics: verbose,
              cachedCompiler: cachedCompiler);
          var compiler = result.compiler;
          bool unexpectedResult = false;
          if (expectedOutcome.contains('compile-time error') ||
              expectedOutcome.contains('syntax error')) {
            if (collector.errors.isEmpty) {
              print('$testFileName: Missing compile-time error.');
              unexpectedResult = true;
            }
          } else if (expectedOutcome.contains('static type warning')) {
            if (collector.warnings.isEmpty) {
              print('$testFileName: Missing static type warning.');
              unexpectedResult = true;
            }
          } else {
            // Expect ok.
            if (!collector.errors.isEmpty || !collector.warnings.isEmpty) {
              collector.errors.forEach((message) {
                print('$testFileName: Unexpected error: ${message.message}');
              });
              collector.warnings.forEach((message) {
                print('$testFileName: Unexpected warning: ${message.message}');
              });
              unexpectedResult = true;
            }
          }
          if (expectFailure) {
            if (unexpectedResult) {
              unexpectedResult = false;
            } else {
              print('$testFileName: The test is white-listed '
                  'and therefore expected to fail.');
              unexpectedResult = true;
            }
          }
          if (unexpectedResult) {
            outcomeMismatch = true;
          }
          cachedCompiler = compiler;
        });
      }).then((_) {
        if (outcomeMismatch) {
          String testFileName =
              relativize(Uri.base, Platform.script, Platform.isWindows);
          print('''

===
=== ERROR: Unexpected result of analysis.
===
=== Please update the white-listing in $testFileName
===

''');
          exit(1);
        }
      }));
}
