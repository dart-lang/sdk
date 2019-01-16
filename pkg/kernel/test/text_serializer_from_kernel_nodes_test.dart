// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.text_serializer_from_kernel_nodes_test;

import 'package:kernel/ast.dart';
import 'package:kernel/text/serializer_combinators.dart';
import 'package:kernel/text/text_reader.dart';
import 'package:kernel/text/text_serializer.dart';

void main() {
  initializeSerializers();
  test();
}

// Wrappers for testing.
Expression readExpression(
    String input, DeserializationEnvironment environment) {
  TextIterator stream = new TextIterator(input, 0);
  stream.moveNext();
  Expression result = expressionSerializer.readFrom(stream, environment);
  if (stream.moveNext()) {
    throw StateError("extra cruft in basic literal");
  }
  return result;
}

String writeExpression(
    Expression expression, SerializationEnvironment environment) {
  StringBuffer buffer = new StringBuffer();
  expressionSerializer.writeTo(buffer, expression, environment);
  return buffer.toString();
}

class TestCase {
  final String name;
  final Node node;
  final SerializationEnvironment serializationEnvironment;
  final DeserializationEnvironment deserializationEnvironment;
  final String expectation;

  TestCase(
      {this.name,
      this.node,
      this.expectation,
      this.serializationEnvironment,
      this.deserializationEnvironment});
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
    () {
      VariableDeclaration x =
          new VariableDeclaration("x", type: const DynamicType());
      return new TestCase(
          name: "/* suppose: dynamic x; */ x = 42",
          node: () {
            return new VariableSet(x, new IntLiteral(42));
          }(),
          expectation: "(set-var \"x^0\" (int 42))",
          serializationEnvironment: new SerializationEnvironment(null)
            ..add(x, "x^0"),
          deserializationEnvironment: new DeserializationEnvironment(null)
            ..add("x^0", x));
    }(),
  ];
  for (TestCase testCase in tests) {
    String roundTripInput =
        writeExpression(testCase.node, testCase.serializationEnvironment);
    if (roundTripInput != testCase.expectation) {
      failures.add(''
          '* initial serialization for test "${testCase.name}"'
          ' gave output "${roundTripInput}"');
    }

    TreeNode deserialized =
        readExpression(roundTripInput, testCase.deserializationEnvironment);
    String roundTripOutput =
        writeExpression(deserialized, testCase.serializationEnvironment);
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
