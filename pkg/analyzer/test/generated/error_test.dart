// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:front_end/src/scanner/errors.dart';
import 'package:source_span/src/span.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisErrorTest);
  });
}

@reflectiveTest
class AnalysisErrorTest {
  void test_location() {
    String text = '''
line one
line two
line three
line four
''';
    String path = '/source.dart';
    Source source = new StringSource(text, path);
    int offset = text.indexOf('thr');
    int length = 3;
    ErrorCode errorCode = ScannerErrorCode.UNTERMINATED_STRING_LITERAL;
    AnalysisError error = new AnalysisError(source, offset, length, errorCode);
    SourceSpan span = error.span;
    expect(span.start.line, 2);
    expect(span.start.column, 5);
    expect(span.start.offset, offset);
    expect(span.end.line, 2);
    expect(span.end.column, 8);
    expect(span.end.offset, offset + length);
    expect(span.text, 'thr');
    expect(span.sourceUrl, new Uri.file(path));
  }
}
