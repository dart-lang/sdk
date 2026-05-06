// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:test/test.dart' hide ErrorFormatter;
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(ReporterTest);
}

@reflectiveTest
class ReporterTest extends PubPackageResolutionTest {
  final StringBuffer out = StringBuffer();
  final AnalysisStats stats = AnalysisStats();

  @override
  void setUp() {
    super.setUp();
    ansi.runningTests = true;
  }

  @override
  Future<void> tearDown() async {
    ansi.runningTests = false;
    await super.tearDown();
  }

  Future<void> test_human_error() async {
    var options = CommandLineOptions.parse(resourceProvider, [
      '--dart-sdk=${sdkRoot.path}',
      'test.dart',
    ])!;
    var reporter = HumanErrorFormatter(out, options, stats);

    newFile(testFile.path, r'''
void f() {
  x;
}
''');

    var errorsResult = await _getErrorsResultForFile(testFile);
    await reporter.formatErrors([errorsResult]);
    reporter.flush();

    expect(
      out.toString().trim(),
      "error • Undefined name 'x'. • package:test/test.dart:2:3 • undefined_identifier",
    );
  }

  Future<void> test_human_hint() async {
    var options = CommandLineOptions.parse(resourceProvider, [
      '--dart-sdk=${sdkRoot.path}',
      'test.dart',
    ])!;
    var reporter = HumanErrorFormatter(out, options, stats);

    newFile(testFile.path, r'''
void f() {
  return;
  1;
}
''');

    var errorsResult = await _getErrorsResultForFile(testFile);
    await reporter.formatErrors([errorsResult]);
    reporter.flush();

    expect(
      out.toString().trim(),
      'warning • Dead code. • package:test/test.dart:3:3 • dead_code',
    );
  }

  Future<void> test_human_stats() async {
    var options = CommandLineOptions.parse(resourceProvider, [
      '--dart-sdk=${sdkRoot.path}',
      'test.dart',
    ])!;
    var reporter = HumanErrorFormatter(out, options, stats);

    newFile(testFile.path, r'''
void f() {
  return;
  1;
}
''');

    var errorsResult = await _getErrorsResultForFile(testFile);
    await reporter.formatErrors([errorsResult]);
    reporter.flush();
    stats.print(out);

    expect(
      out.toString().trim(),
      'warning • Dead code. • package:test/test.dart:3:3 • dead_code\n'
      '1 warning found.',
    );
  }

  Future<void> test_json_error() async {
    var options = CommandLineOptions.parse(resourceProvider, [
      '--format=json',
      '--dart-sdk=${sdkRoot.path}',
      'test.dart',
    ])!;
    var reporter = JsonErrorFormatter(out, options, stats);

    newFile(testFile.path, r'''
void f() {
  x;
}
''');

    var errorsResult = await _getErrorsResultForFile(testFile);
    await reporter.formatErrors([errorsResult]);
    reporter.flush();

    var expected = {
      'version': 1,
      'diagnostics': [
        {
          'code': 'undefined_identifier',
          'severity': 'ERROR',
          'type': 'COMPILE_TIME_ERROR',
          'location': {
            'file': testFile.path,
            'range': {
              'start': {'offset': 13, 'line': 2, 'column': 3},
              'end': {'offset': 14, 'line': 2, 'column': 4},
            },
          },
          'problemMessage': "Undefined name 'x'.",
          'correctionMessage':
              'Try correcting the name to one that is defined, or defining the name.',
          'documentation': 'https://dart.dev/diagnostics/undefined_identifier',
        },
      ],
    };
    expect(out.toString().trim(), json.encode(expected));
  }

  Future<ErrorsResult> _getErrorsResultForFile(File file) async {
    var errorsResult = await contextCollection
        .contextFor(file.path)
        .currentSession
        .getErrors(file.path);
    return errorsResult as ErrorsResult;
  }
}
