// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.formatter;

import 'package:analyzer/src/generated/error.dart';
import 'package:linter/src/formatter.dart';
import 'package:linter/src/linter.dart';
import 'package:mockito/mockito.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  groupSep = ' | ';

  defineTests();
}

defineTests() {
  group('formatter', () {
    test('shorten', () {
      expect(shorten('/foo/bar', '/foo/bar/baz'), equals('/baz'));
    });

    test('pluralize', () {
      expect(pluralize('issue', 0), equals('0 issues'));
      expect(pluralize('issue', 1), equals('1 issue'));
      expect(pluralize('issue', 2), equals('2 issues'));
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

      var reporter = new SimpleFormatter([info], null, out, fileCount: 1);
      reporter.write();

      test('count', () {
        expect(reporter.errorCount, equals(1));
      });

      test('write', () {
        expect(out.buffer.toString(), equals('''/foo/bar/baz.dart 3:3 [test] MSG

1 file analyzed, 1 issue found.
'''));
      });
    });

    group('reporter (filtered)', () {
      var info = new MockAnalysisErrorInfo();
      var error = new MockAnalysisError();
      var lineInfo = new MockLineInfo();
      var location = new MockLineInfo_Location();
      when(location.columnNumber).thenReturn(3);
      when(location.lineNumber).thenReturn(3);

      when(lineInfo.getLocation(any)).thenReturn(location);
      var code = new MockErrorCode();
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

      var reporter = new SimpleFormatter([info], new _RejectingFilter(), out,
          fileCount: 1);
      reporter.write();

      test('error count', () {
        expect(reporter.errorCount, equals(0));
      });

      test('filter count', () {
        expect(reporter.filteredLintCount, equals(1));
      });

      test('write', () {
        expect(out.buffer.toString(), equals('''

1 file analyzed, 0 issues found (1 filtered).
'''));
      });
    });
  });
}

class _RejectingFilter extends LintFilter {
  @override
  bool filter(AnalysisError lint) => true;
}
