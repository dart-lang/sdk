// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.formatter;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:test/test.dart' hide ErrorFormatter;
import 'package:typed_mock/typed_mock.dart';

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
      when(options.enableTypeChecks).thenReturn(false);
      when(options.infosAreFatal).thenReturn(false);
      when(options.machineFormat).thenReturn(false);
      when(options.verbose).thenReturn(false);
      when(options.color).thenReturn(false);

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
  var info = new MockAnalysisErrorInfo();
  var error = new MockAnalysisError();
  var lineInfo = new MockLineInfo();
  var location = new MockLineInfo_Location();
  when(location.columnNumber).thenReturn(3);
  when(location.lineNumber).thenReturn(3);
  when(lineInfo.getLocation(anyObject)).thenReturn(location);
  when(info.lineInfo).thenReturn(lineInfo);

  // Details
  var code = new MockErrorCode();
  when(code.type).thenReturn(type);
  when(code.errorSeverity).thenReturn(severity);
  when(code.name).thenReturn('mock_code');
  when(error.errorCode).thenReturn(code);
  when(error.message).thenReturn('MSG');
  when(error.offset).thenReturn(20);
  var source = new MockSource();
  when(source.fullName).thenReturn('/foo/bar/baz.dart');
  when(error.source).thenReturn(source);
  when(info.errors).thenReturn([error]);

  return info;
}
