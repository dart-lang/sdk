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
Expression readExpression(String input, DeserializationState state) {
  TextIterator stream = new TextIterator(input, 0);
  stream.moveNext();
  Expression result = expressionSerializer.readFrom(stream, state);
  if (stream.moveNext()) {
    throw StateError("extra cruft in basic literal");
  }
  return result;
}

String writeExpression(Expression expression, SerializationState state) {
  StringBuffer buffer = new StringBuffer();
  expressionSerializer.writeTo(buffer, expression, state);
  return buffer.toString();
}

class TestCase {
  final String name;
  final Node node;
  final SerializationState serializationState;
  final DeserializationState deserializationState;
  final String expectation;

  TestCase(
      {this.name,
      this.node,
      this.expectation,
      SerializationState serializationState,
      DeserializationState deserializationState})
      : this.serializationState =
            serializationState ?? new SerializationState(null),
        this.deserializationState = deserializationState ??
            new DeserializationState(null, new CanonicalName.root());
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
          node: new VariableSet(x, new IntLiteral(42)),
          expectation: "(set-var \"x^0\" (int 42))",
          serializationState: new SerializationState(
            new SerializationEnvironment(null)..add(x, "x^0"),
          ),
          deserializationState: new DeserializationState(
              new DeserializationEnvironment(null)..add("x^0", x),
              new CanonicalName.root()));
    }(),
    () {
      Field field = new Field(new Name("field"), type: const DynamicType());
      Library library = new Library(
          new Uri(scheme: "package", path: "foo/bar.dart"),
          fields: <Field>[field]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase(
          name: "/* suppose top-level: dynamic field; */ field",
          node: new StaticGet(field),
          expectation: "(get-static \"package:foo/bar.dart::@fields::field\")",
          serializationState: new SerializationState(null),
          deserializationState: new DeserializationState(null, component.root));
    }(),
  ];
  for (TestCase testCase in tests) {
    String roundTripInput =
        writeExpression(testCase.node, testCase.serializationState);
    if (roundTripInput != testCase.expectation) {
      failures.add(''
          '* initial serialization for test "${testCase.name}"'
          ' gave output "${roundTripInput}"');
    }

    TreeNode deserialized =
        readExpression(roundTripInput, testCase.deserializationState);
    String roundTripOutput =
        writeExpression(deserialized, testCase.serializationState);
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
