// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.formatter;

import 'package:linter/src/formatter.dart';
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
      expect(pluralize('issue', 0), equals('issues'));
      expect(pluralize('issue', 1), equals('issue'));
      expect(pluralize('issue', 2), equals('issues'));
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

      var reporter = new ReportFormatter([info], out, fileCount: 1);
      reporter.write();

      test('count', () {
        expect(reporter.errorCount, equals(1));
      });

      test('write', () {
        expect(out.buffer.toString(), equals(
            '''[test] MSG (/foo/bar/baz.dart, line 3, col 3)

1 file analyzed, 1 issues found.
'''));
      });
    });
  });
}

class CollectingSink extends MockIOSink {
  final buffer = new StringBuffer();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  write(obj) {
    buffer.write(obj);
  }

  @override
  writeln([Object obj = ""]) {
    buffer.writeln(obj);
  }
}
