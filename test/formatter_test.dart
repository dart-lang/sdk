// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/formatter.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

main() {
  defineTests();
}

defineTests() {
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
      var info = new MockAnalysisErrorInfo();
      var error = new MockAnalysisError();
      var lineInfo = new MockLineInfo();
      var location = new MockLineInfo_Location();
      when(location.columnNumber).thenReturn(3);
      when(location.lineNumber).thenReturn(3);

      when(lineInfo.getLocation(any)).thenReturn(location);
      var code = new MockErrorCode();
      when(code.name).thenReturn('mock_code');
      when(error.errorCode).thenReturn(code);
      var type = new MockErrorType();
      when(type.displayName).thenReturn('test');
      when(code.type).thenReturn(type);
      when(error.message).thenReturn('MSG');
      var source = new MockSource();
      when(source.fullName).thenReturn('/foo/bar/baz.dart');
      when(error.source).thenReturn(source);

      when(info.lineInfo).thenReturn(lineInfo);

      when(info.errors).thenReturn([error]);
      var out = new CollectingSink();

      var reporter =
          new SimpleFormatter([info], null, out, fileCount: 1, elapsedMs: 13)
            ..write();

      test('count', () {
        expect(reporter.errorCount, 1);
      });

      test('write', () {
        expect(out.buffer.toString().trim(), '''/foo/bar/baz.dart 3:3 [test] MSG

1 file analyzed, 1 issue found, in 13 ms.''');
      });

      test('stats', () {
        out.buffer.clear();
        new SimpleFormatter([info], null, out,
            fileCount: 1, showStatistics: true, elapsedMs: 13)
          ..write();
        expect(out.buffer.toString(),
            startsWith('''/foo/bar/baz.dart 3:3 [test] MSG

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
      var info = new MockAnalysisErrorInfo();
      var error = new MockAnalysisError();
      var lineInfo = new MockLineInfo();
      var location = new MockLineInfo_Location();
      when(location.columnNumber).thenReturn(3);
      when(location.lineNumber).thenReturn(3);

      when(lineInfo.getLocation(any)).thenReturn(location);
      var code = new MockErrorCode();
      when(code.errorSeverity).thenReturn(new MockErrorSeverity());
      when(code.name).thenReturn('MockError');
      when(error.errorCode).thenReturn(code);
      var type = new MockErrorType();
      when(type.displayName).thenReturn('test');
      when(code.type).thenReturn(type);
      when(error.message).thenReturn('MSG');
      var source = new MockSource();
      when(source.fullName).thenReturn('/foo/bar/baz.dart');
      when(error.source).thenReturn(source);
      when(error.length).thenReturn(13);
      when(error.source).thenReturn(source);

      when(info.lineInfo).thenReturn(lineInfo);

      when(info.errors).thenReturn([error]);
      var out = new CollectingSink();

      group('filtered', () {
        var reporter = new SimpleFormatter([info], new _RejectingFilter(), out,
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

      group('machine-ouptut', () {
        test('write', () {
          out.buffer.clear();
          new SimpleFormatter([info], null, out,
              fileCount: 1, machineOutput: true, elapsedMs: 13)
            ..write();

          expect(out.buffer.toString().trim(),
              '''MockErrorSeverity|MockErrorType|MockError|/foo/bar/baz.dart|3|3|13|MSG

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
