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
  TestRunner testRunner = new TestRunner();
  testRunner.run();
  if (testRunner.failures.isNotEmpty) {
    print('Round trip failures:');
    testRunner.failures.forEach(print);
    throw StateError('Round trip failures');
  }
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

class TestRunner {
  final List<String> failures = [];

  void run() {
    test('(get-prop (int 0) (public "hashCode"))');
    test('(get-super (public "hashCode"))');
    test('(invoke-method (int 0) (public "foo") () ((int 1) (int 2)) ())');
    test('(invoke-method (int 0) (public "foo") ((dynamic) (void)) '
        '((int 1) (int 2)) ("others" (list (dynamic) ((int 3) (int 4)))))');
    test('(let "x^0" () (dynamic) (int 0) () (null))');
    test('(let "x^0" () (dynamic) _ () (null))');
    test('(let "x^0" ((const)) (dynamic) (int 0) () (null))');
    test('(let "x^0" ((const)) (dynamic) _ () (null))');
    test('(let "x^0" ((final)) (dynamic) (int 0) () (null))');
    test('(let "x^0" ((final)) (dynamic) _ () (null))');
    test(r'''(string "Hello, 'string'!")''');
    test(r'''(string "Hello, \"string\"!")''');
    test(r'''(string "Yeah nah yeah, here is\nthis really long string haiku\n'''
        r'''blowing in the wind\n")''');
    test('(int 42)');
    test('(int 0)');
    test('(int -1001)');
    test('(double 3.14159)');
    test('(bool true)');
    test('(bool false)');
    test('(null)');
    test(r'''(invalid "You can't touch this")''');
    test('(not (bool true))');
    test('(&& (bool true) (bool false))');
    test('(|| (&& (bool true) (not (bool true))) (bool true))');
    test('(concat ((string "The opposite of ") (int 3) '
        '(string " is ") (int 7)))');
    test('(symbol "unquote-splicing")');
    test('(this)');
    test('(rethrow)');
    test('(throw (string "error"))');
    test('(await (null))');
    test('(cond (bool true) (dynamic) (int 0) (int 1))');
    test('(is (bool true) (invalid))');
    test('(as (bool true) (void))');
    test('(type (bottom))');
    test('(list (dynamic) ((null) (null) (null)))');
    test('(const-list (dynamic) ((int 0) (int 1) (int 2)))');
    test('(set (dynamic) ((bool true) (bool false) (int 0)))');
    test('(const-set (dynamic) ((int 0) (int 1) (int 2)))');
    test('(map (dynamic) (void)'
        ' ((int 0) (null) (int 1) (null) (int 2) (null)))');
    test('(const-map (dynamic) (void) ((int 0) (null) (int 1) (null) '
        '(int 2) (null)))');
    test('(type (-> () () () ((dynamic)) () () (dynamic)))');
    test('(type (-> () () () () ((dynamic)) () (dynamic)))');
    test('(type (-> () () () ((dynamic) (dynamic)) () () (dynamic)))');
    test('(type (-> () () () () () () (dynamic)))');
    test('(type (-> () () () ((-> () () () ((dynamic)) () () (dynamic))) () () '
        '(dynamic)))');
    test('(type (-> ("T^0") ((dynamic)) ((dynamic)) () () () (dynamic)))');
    test('(type (-> ("T^0") ((dynamic)) ((dynamic)) ((par "T^0" _)) () () '
        '(par "T^0" _)))');
    test('(type (-> ("T^0" "S^1") ((par "S^1" _) (par "T^0" _)) ((dynamic) '
        '(dynamic)) () () () (dynamic)))');
  }

  void test(String input) {
    var kernelAst = readExpression(input);
    var output = writeExpression(kernelAst);
    if (output != input) {
      failures.add('* input "${input}" gave output "${output}"');
    }
  }
}
