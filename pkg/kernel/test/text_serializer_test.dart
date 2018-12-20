// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.text_serializer_test;

import 'package:kernel/ast.dart';
import 'package:kernel/text/text_reader.dart';
import 'package:kernel/text/text_serializer.dart';

void main() {
  test();
}

// Wrappers for testing.
BasicLiteral readBasicLiteral(String input) {
  TextIterator stream = new TextIterator(input, 0);
  stream.moveNext();
  BasicLiteral result = basicLiteralSerializer.readFrom(stream);
  if (stream.moveNext()) {
    throw StateError("extra cruft in basic literal");
  }
  return result;
}

String writeBasicLiteral(BasicLiteral literal) {
  StringBuffer buffer = new StringBuffer();
  basicLiteralSerializer.writeTo(buffer, literal);
  return buffer.toString();
}

void test() {
  List<String> failures = [];
  List<String> tests = [
    "(string \"Hello, 'string'!\")",
    "(string \"Hello, \\\"string\\\"!\")",
    "(string \"Yeah nah yeah, here is\\nthis really long string haiku\\n"
        "blowing in the wind\\n\")",
    "(int 42)",
    "(int 0)",
    "(int -1001)",
    "(double 3.14159)",
    "(bool true)",
    "(bool false)",
    "(null)",
  ];
  for (var test in tests) {
    var literal = readBasicLiteral(test);
    var output = writeBasicLiteral(literal);
    if (output != test) {
      failures.add('* input "${test}" gave output "${output}"');
    }
  }
  if (failures.isNotEmpty) {
    print('Round trip failures:');
    failures.forEach(print);
    throw StateError('Round trip failures');
  }
}
