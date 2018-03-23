// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:test/test.dart' hide ErrorFormatter;

import 'mocks.dart';

main() {
  group('reporter', () {
    StringBuffer out;
    AnalysisStats stats;
    MockCommandLineOptions options;
    ErrorFormatter reporter;

    setUp(() {
      ansi.runningTests = true;

      out = new StringBuffer();
      stats = new AnalysisStats();

      options = new MockCommandLineOptions();
      options.enableTypeChecks = false;
      options.infosAreFatal = false;
      options.machineFormat = false;
      options.verbose = false;
      options.color = false;

      reporter = new HumanErrorFormatter(out, options, stats);
    });

    tearDown(() {
      ansi.runningTests = false;
    });

    test('error', () {
      AnalysisErrorInfo error =
          mockError(ErrorType.SYNTACTIC_ERROR, ErrorSeverity.ERROR);
      reporter.formatErrors([error]);
      reporter.flush();

      expect(out.toString().trim(),
          'error • MSG at /foo/bar/baz.dart:3:3 • mock_code');
    });

    test('hint', () {
      AnalysisErrorInfo error = mockError(ErrorType.HINT, ErrorSeverity.INFO);
      reporter.formatErrors([error]);
      reporter.flush();

      expect(out.toString().trim(),
          'hint • MSG at /foo/bar/baz.dart:3:3 • mock_code');
    });

    test('stats', () {
      AnalysisErrorInfo error = mockError(ErrorType.HINT, ErrorSeverity.INFO);
      reporter.formatErrors([error]);
      reporter.flush();
      stats.print(out);
      expect(
          out.toString().trim(),
          'hint • MSG at /foo/bar/baz.dart:3:3 • mock_code\n'
          '1 hint found.');
    });
  });
}

MockAnalysisErrorInfo mockError(ErrorType type, ErrorSeverity severity) {
  // ErrorInfo
  var location = new MockLineInfo_Location(3, 3);
  var lineInfo = new MockLineInfo(defaultLocation: location);

  // Details
  var code = new MockErrorCode(type, severity, 'mock_code');
  var source = new MockSource('/foo/bar/baz.dart');
  var error = new MockAnalysisError(source, code, 20, 'MSG');

  return new MockAnalysisErrorInfo(lineInfo, [error]);
}
