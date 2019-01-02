// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.text_serializer_test;

import 'package:kernel/ast.dart';
import 'package:kernel/text/text_reader.dart';
import 'package:kernel/text/text_serializer.dart';

void main() {
  initializeSerializers();
  test();
}

// Wrappers for testing.
Expression readExpression(String input) {
  TextIterator stream = new TextIterator(input, 0);
  stream.moveNext();
  Expression result = expressionSerializer.readFrom(stream);
  if (stream.moveNext()) {
    throw StateError("extra cruft in basic literal");
  }
  return result;
}

String writeExpression(Expression expression) {
  StringBuffer buffer = new StringBuffer();
  expressionSerializer.writeTo(buffer, expression);
  return buffer.toString();
}

void test() {
  List<String> failures = [];
  List<String> tests = [
    "(let (var \"x\" (dynamic) (int 0) 0) (null))",
    "(let (var \"x\" (dynamic) _ 0) (null))",
    "(let (const \"x\" (dynamic) (int 0) 0) (null))",
    "(let (const \"x\" (dynamic) _ 0) (null))",
    "(let (final \"x\" (dynamic) (int 0) 0) (null))",
    "(let (final \"x\" (dynamic) _ 0) (null))",
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
    "(invalid \"You can't touch this\")",
    "(not (bool true))",
    "(&& (bool true) (bool false))",
    "(|| (&& (bool true) (not (bool true))) (bool true))",
    "(concat 4 (string \"The opposite of \") (int 3) "
        "(string \" is \") (int 7))",
    "(symbol \"unquote-splicing\")",
    "(this)",
    "(rethrow)",
    "(throw (string \"error\"))",
    "(await (null))",
    "(cond (bool true) (dynamic) (int 0) (int 1))",
    "(is (bool true) (invalid))",
    "(as (bool true) (void))",
    "(type (bottom))",
    "(list (dynamic) 3 (null) (null) (null))",
    "(const-list (dynamic) 3 (int 0) (int 1) (int 2))",
    "(set (dynamic) 3 (bool true) (bool false) (int 0))",
    "(const-set (dynamic) 3 (int 0) (int 1) (int 2))",
    "(map (dynamic) (void) 6 (int 0) (null) (int 1) (null) (int 2) (null))",
    "(const-map (dynamic) (void) 6 (int 0) (null) (int 1) (null) "
        "(int 2) (null))",
  ];
  for (var test in tests) {
    var literal = readExpression(test);
    var output = writeExpression(literal);
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
