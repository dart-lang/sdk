// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.text_serializer_from_kernel_nodes_test;

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
  Expression result = expressionSerializer.readFrom(stream, null);
  if (stream.moveNext()) {
    throw StateError("extra cruft in basic literal");
  }
  return result;
}

String writeExpression(Expression expression) {
  StringBuffer buffer = new StringBuffer();
  expressionSerializer.writeTo(buffer, expression, null);
  return buffer.toString();
}

class TestCase {
  final String name;
  final Node node;
  final String expectation;

  TestCase({this.name, this.node, this.expectation});
}

void test() {
  List<String> failures = [];
  List<TestCase> tests = <TestCase>[
    new TestCase(
        name: "let dynamic x = 42 in x",
        node: () {
          VariableDeclaration x = new VariableDeclaration("x",
              type: const DynamicType(), initializer: new IntLiteral(42));
          return new Let(x, new VariableGet(x));
        }(),
        expectation:
            "(let (var \"x^0\" (dynamic) (int 42) ()) (get-var \"x^0\" _))"),
    new TestCase(
        name: "let dynamic x = 42 in let Bottom x^0 = null in x",
        node: () {
          VariableDeclaration outterLetVar = new VariableDeclaration("x",
              type: const DynamicType(), initializer: new IntLiteral(42));
          VariableDeclaration innerLetVar = new VariableDeclaration("x",
              type: const BottomType(), initializer: new NullLiteral());
          return new Let(outterLetVar,
              new Let(innerLetVar, new VariableGet(outterLetVar)));
        }(),
        expectation: ""
            "(let (var \"x^0\" (dynamic) (int 42) ())"
            " (let (var \"x^1\" (bottom) (null) ())"
            " (get-var \"x^0\" _)))"),
    new TestCase(
        name: "let dynamic x = 42 in let Bottom x^0 = null in x^0",
        node: () {
          VariableDeclaration outterLetVar = new VariableDeclaration("x",
              type: const DynamicType(), initializer: new IntLiteral(42));
          VariableDeclaration innerLetVar = new VariableDeclaration("x",
              type: const BottomType(), initializer: new NullLiteral());
          return new Let(
              outterLetVar, new Let(innerLetVar, new VariableGet(innerLetVar)));
        }(),
        expectation: ""
            "(let (var \"x^0\" (dynamic) (int 42) ())"
            " (let (var \"x^1\" (bottom) (null) ())"
            " (get-var \"x^1\" _)))"),
  ];
  for (TestCase testCase in tests) {
    String roundTripInput = writeExpression(testCase.node);
    if (roundTripInput != testCase.expectation) {
      failures.add(''
          '* initial serialization for test "${testCase.name}"'
          ' gave output "${roundTripInput}"');
    }

    TreeNode deserialized = readExpression(roundTripInput);
    String roundTripOutput = writeExpression(deserialized);
    if (roundTripOutput != roundTripInput) {
      failures.add(''
          '* input "${testCase.name}" gave output "${roundTripOutput}"');
    }
  }
  if (failures.isNotEmpty) {
    print('Round trip failures:');
    failures.forEach(print);
    throw StateError('Round trip failures');
  }
}
