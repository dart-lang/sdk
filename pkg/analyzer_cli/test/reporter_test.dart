// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.formatter;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart' hide ErrorFormatter;

import 'mocks.dart';

main() {
  group('reporter', () {
    var out = new StringBuffer();

    tearDown(() => out.clear());

    // Options
    var options = new MockCommandLineOptions();
    when(options.enableTypeChecks).thenReturn(false);
    when(options.hintsAreFatal).thenReturn(false);
    when(options.machineFormat).thenReturn(false);

    var reporter = new ErrorFormatter(out, options);

    test('error', () {
      var error = mockError(ErrorType.SYNTACTIC_ERROR, ErrorSeverity.ERROR);
      reporter.formatErrors([error]);

      expect(
          out.toString(),
          '''[error] MSG (/foo/bar/baz.dart, line 3, col 3)
1 error found.
''');
    });

    test('hint', () {
      var error = mockError(ErrorType.HINT, ErrorSeverity.INFO);
      reporter.formatErrors([error]);

      expect(
          out.toString(),
          '''[hint] MSG (/foo/bar/baz.dart, line 3, col 3)
1 hint found.
''');
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
  var source = new MockSource();
  when(source.fullName).thenReturn('/foo/bar/baz.dart');
  when(error.source).thenReturn(source);
  when(info.errors).thenReturn([error]);

  return info;
}
