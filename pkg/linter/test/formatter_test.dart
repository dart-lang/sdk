// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/test_utilities/analysis_error_info.dart';
import 'package:linter/src/test_utilities/formatter.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  defineTests();
}

void defineTests() {
  group('formatter', () {
    test('shorten', () {
      expect(shorten('/foo/bar', '/foo/bar/baz'), '/baz');
    });

    test('pluralize', () {
      expect(pluralize('issue', 0), '0 issues');
      expect(pluralize('issue', 1), '1 issue');
      expect(pluralize('issue', 2), '2 issues');
    });

    group('reporter', () {
      var lineInfo = LineInfo([3, 6, 9]);

      var type = MockErrorType()..displayName = 'test';

      var code = TestErrorCode('mock_code', 'MSG')..type = type;

      var source = MockSource('/foo/bar/baz.dart');

      var error = AnalysisError.tmp(
          source: source, offset: 10, length: 3, errorCode: code);

      var info = AnalysisErrorInfo([error], lineInfo);

      var out = StringBuffer();

      var reporter = SimpleFormatter([info], out, fileCount: 1, elapsedMs: 13)
        ..write();

      test('count', () {
        expect(reporter.errorCount, 1);
      });

      test('write', () {
        expect(out.toString().trim(), '''/foo/bar/baz.dart 3:2 [test] MSG

1 file analyzed, 1 issue found, in 13 ms.''');
      });

      test('stats', () {
        out.clear();
        SimpleFormatter([info], out,
                fileCount: 1, showStatistics: true, elapsedMs: 13)
            .write();
        expect(out.toString(), startsWith('''/foo/bar/baz.dart 3:2 [test] MSG

1 file analyzed, 1 issue found, in 13 ms.

-----------------------------------------
Counts
-----------------------------------------
mock_code                               1
-----------------------------------------
'''));
      });
    });

    group('reporter', () {
      var lineInfo = LineInfo([3, 6, 9]);

      var type = MockErrorType()..displayName = 'test';

      var code = TestErrorCode('MockError', 'MSG')
        ..errorSeverity = ErrorSeverity('MockErrorSeverity', 0, '', '')
        ..type = type;

      var source = MockSource('/foo/bar/baz.dart');

      var error = AnalysisError.tmp(
          source: source, offset: 12, length: 13, errorCode: code);

      var info = AnalysisErrorInfo([error], lineInfo);

      var out = StringBuffer();

      group('machine-output', () {
        test('write', () {
          out.clear();
          SimpleFormatter([info], out,
                  fileCount: 1, machineOutput: true, elapsedMs: 13)
              .write();

          expect(out.toString().trim(),
              '''MockErrorSeverity|MockErrorType|MockError|/foo/bar/baz.dart|3|4|13|MSG

1 file analyzed, 1 issue found, in 13 ms.''');
        });
      });
    });
  });
}
