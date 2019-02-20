// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.text_serializer_test;

import 'package:kernel/ast.dart';
import 'package:kernel/text/serializer_combinators.dart';
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
  Expression result = expressionSerializer.readFrom(
      stream, new DeserializationState(null, new CanonicalName.root()));
  if (stream.moveNext()) {
    throw StateError("extra cruft in basic literal");
  }
  return result;
}

String writeExpression(Expression expression) {
  StringBuffer buffer = new StringBuffer();
  expressionSerializer.writeTo(
      buffer, expression, new SerializationState(null));
  return buffer.toString();
}

void test() {
  List<String> failures = [];
  List<String> tests = [
    "(get-prop (int 0) (public \"hashCode\"))",
    "(get-super (public \"hashCode\"))",
    "(invoke-method (int 0) (public \"foo\") () ((int 1) (int 2)) ())",
    "(invoke-method (int 0) (public \"foo\") ((dynamic) (void)) "
        "((int 1) (int 2)) (\"others\" (list (dynamic) ((int 3) (int 4)))))",
    "(let (var \"x^0\" (dynamic) (int 0) ()) (null))",
    "(let (var \"x^0\" (dynamic) _ ()) (null))",
    "(let (const \"x^0\" (dynamic) (int 0) ()) (null))",
    "(let (const \"x^0\" (dynamic) _ ()) (null))",
    "(let (final \"x^0\" (dynamic) (int 0) ()) (null))",
    "(let (final \"x^0\" (dynamic) _ ()) (null))",
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
    "(concat ((string \"The opposite of \") (int 3) "
        "(string \" is \") (int 7)))",
    "(symbol \"unquote-splicing\")",
    "(this)",
    "(rethrow)",
    "(throw (string \"error\"))",
    "(await (null))",
    "(cond (bool true) (dynamic) (int 0) (int 1))",
    "(is (bool true) (invalid))",
    "(as (bool true) (void))",
    "(type (bottom))",
    "(list (dynamic) ((null) (null) (null)))",
    "(const-list (dynamic) ((int 0) (int 1) (int 2)))",
    "(set (dynamic) ((bool true) (bool false) (int 0)))",
    "(const-set (dynamic) ((int 0) (int 1) (int 2)))",
    "(map (dynamic) (void) ((int 0) (null) (int 1) (null) (int 2) (null)))",
    "(const-map (dynamic) (void) ((int 0) (null) (int 1) (null) "
        "(int 2) (null)))",
    "(type (-> () () () ((dynamic)) () () (dynamic)))",
    "(type (-> () () () () ((dynamic)) () (dynamic)))",
    "(type (-> () () () ((dynamic) (dynamic)) () () (dynamic)))",
    "(type (-> () () () () () () (dynamic)))",
    "(type (-> () () () ((-> () () () ((dynamic)) () () (dynamic))) () () "
        "(dynamic)))",
    "(type (-> (\"T^0\") ((dynamic)) ((dynamic)) () () () (dynamic)))",
    "(type (-> (\"T^0\") ((dynamic)) ((dynamic)) ((par \"T^0\" _)) () () "
        "(par \"T^0\" _)))",
    "(type (-> (\"T^0\" \"S^1\") ((par \"S^1\" _) (par \"T^0\" _)) ((dynamic) "
        "(dynamic)) () () () (dynamic)))",
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
