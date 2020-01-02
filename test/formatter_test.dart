// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/formatter.dart';
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

      var source = MockSource()..fullName = '/foo/bar/baz.dart';

      var error = AnalysisError(source, 10, 3, code);

      var info = AnalysisErrorInfoImpl([error], lineInfo);

      var out = CollectingSink();

      var reporter =
          SimpleFormatter([info], null, out, fileCount: 1, elapsedMs: 13)
            ..write();

      test('count', () {
        expect(reporter.errorCount, 1);
      });

      test('write', () {
        expect(out.buffer.toString().trim(), '''/foo/bar/baz.dart 3:2 [test] MSG

1 file analyzed, 1 issue found, in 13 ms.''');
      });

      test('stats', () {
        out.buffer.clear();
        SimpleFormatter([info], null, out,
            fileCount: 1, showStatistics: true, elapsedMs: 13)
          ..write();
        expect(out.buffer.toString(),
            startsWith('''/foo/bar/baz.dart 3:2 [test] MSG

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

      var source = MockSource()..fullName = '/foo/bar/baz.dart';

      var error = AnalysisError(source, 12, 13, code);

      var info = AnalysisErrorInfoImpl([error], lineInfo);

      var out = CollectingSink();

      group('filtered', () {
        var reporter = SimpleFormatter([info], _RejectingFilter(), out,
            fileCount: 1, elapsedMs: 13)
          ..write();

        test('error count', () {
          expect(reporter.errorCount, 0);
        });

        test('filter count', () {
          expect(reporter.filteredLintCount, 1);
        });

        test('write', () {
          expect(out.buffer.toString().trim(),
              '1 file analyzed, 0 issues found (1 filtered), in 13 ms.');
        });
      });

      group('machine-output', () {
        test('write', () {
          out.buffer.clear();
          SimpleFormatter([info], null, out,
              fileCount: 1, machineOutput: true, elapsedMs: 13)
            ..write();

          expect(out.buffer.toString().trim(),
              '''MockErrorSeverity|MockErrorType|MockError|/foo/bar/baz.dart|3|4|13|MSG

1 file analyzed, 1 issue found, in 13 ms.''');
        });
      });
    });
  });
}

class _RejectingFilter extends LintFilter {
  @override
  bool filter(AnalysisError lint) => true;
}
