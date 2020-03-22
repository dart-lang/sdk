// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:test/test.dart' hide ErrorFormatter;

import 'mocks.dart';

void main() {
  group('reporter', () {
    StringBuffer out;
    AnalysisStats stats;
    MockCommandLineOptions options;
    ErrorFormatter reporter;

    setUp(() {
      ansi.runningTests = true;

      out = StringBuffer();
      stats = AnalysisStats();

      options = MockCommandLineOptions();
      options.enableTypeChecks = false;
      options.infosAreFatal = false;
      options.machineFormat = false;
      options.verbose = false;
      options.color = false;

      reporter = HumanErrorFormatter(out, options, stats);
    });

    tearDown(() {
      ansi.runningTests = false;
    });

    test('error', () {
      var error = mockResult(ErrorType.SYNTACTIC_ERROR, ErrorSeverity.ERROR);
      reporter.formatErrors([error]);
      reporter.flush();

      expect(out.toString().trim(),
          'error • MSG • /foo/bar/baz.dart:3:3 • mock_code');
    });

    test('hint', () {
      var error = mockResult(ErrorType.HINT, ErrorSeverity.INFO);
      reporter.formatErrors([error]);
      reporter.flush();

      expect(out.toString().trim(),
          'hint • MSG • /foo/bar/baz.dart:3:3 • mock_code');
    });

    test('stats', () {
      var error = mockResult(ErrorType.HINT, ErrorSeverity.INFO);
      reporter.formatErrors([error]);
      reporter.flush();
      stats.print(out);
      expect(
          out.toString().trim(),
          'hint • MSG • /foo/bar/baz.dart:3:3 • mock_code\n'
          '1 hint found.');
    });
  });
}

ErrorsResultImpl mockResult(ErrorType type, ErrorSeverity severity) {
  // ErrorInfo
  var location = CharacterLocation(3, 3);
  var lineInfo = MockLineInfo(defaultLocation: location);

  // Details
  var code = MockErrorCode(type, severity, 'mock_code');
  var source = MockSource('/foo/bar/baz.dart');
  var error = MockAnalysisError(source, code, 20, 'MSG');

  return ErrorsResultImpl(
      null, source.fullName, null, lineInfo, false, [error]);
}
