// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constant_expression_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/compile_time_constants.dart';
import 'package:compiler/src/elements/elements.dart';
import 'memory_compiler.dart';
import 'constant_expression_evaluate_test.dart' show MemoryEnvironment;

class TestData {
  /// Declarations needed for the [constants].
  final String declarations;

  /// Tested constants.
  final List constants;

  const TestData(this.declarations, this.constants);
}

class ConstantData {
  /// Source code for the constant expression.
  final String code;

  /// The expected constant expression kind.
  final ConstantExpressionKind kind;

  /// ConstantExpression.getText() result if different from [code].
  final String text;

  /// The expected instance type for ConstructedConstantExpression.
  final String type;

  /// The expected instance fields for ConstructedConstantExpression.
  final Map<String, String> fields;

  const ConstantData(String code, this.kind,
      {String text, this.type, this.fields})
      : this.code = code,
        this.text = text != null ? text : code;
}

const List<TestData> DATA = const [
  const TestData('', const [
    const ConstantData('null', ConstantExpressionKind.NULL),
    const ConstantData('false', ConstantExpressionKind.BOOL),
    const ConstantData('true', ConstantExpressionKind.BOOL),
    const ConstantData('0', ConstantExpressionKind.INT),
    const ConstantData('0.0', ConstantExpressionKind.DOUBLE),
    const ConstantData('"foo"', ConstantExpressionKind.STRING),
    const ConstantData('1 + 2', ConstantExpressionKind.BINARY),
    const ConstantData('1 == 2', ConstantExpressionKind.BINARY),
    const ConstantData('1 != 2', ConstantExpressionKind.BINARY),
    const ConstantData('1 ?? 2', ConstantExpressionKind.BINARY),
    const ConstantData('-(1)', ConstantExpressionKind.UNARY, text: '-1'),
    const ConstantData('"foo".length', ConstantExpressionKind.STRING_LENGTH),
    const ConstantData('identical(0, 1)', ConstantExpressionKind.IDENTICAL),
    const ConstantData('"a" "b"', ConstantExpressionKind.CONCATENATE,
        text: '"ab"'),
    const ConstantData('identical', ConstantExpressionKind.FUNCTION),
    const ConstantData('true ? 0 : 1', ConstantExpressionKind.CONDITIONAL),
    const ConstantData('proxy', ConstantExpressionKind.FIELD),
    const ConstantData('Object', ConstantExpressionKind.TYPE),
    const ConstantData('#name', ConstantExpressionKind.SYMBOL),
    const ConstantData('const [0, 1]', ConstantExpressionKind.LIST),
    const ConstantData('const <int>[0, 1]', ConstantExpressionKind.LIST),
    const ConstantData('const {0: 1, 2: 3}', ConstantExpressionKind.MAP),
    const ConstantData(
        'const <int, int>{0: 1, 2: 3}', ConstantExpressionKind.MAP),
    const ConstantData('const bool.fromEnvironment("foo", defaultValue: false)',
        ConstantExpressionKind.BOOL_FROM_ENVIRONMENT),
    const ConstantData('const int.fromEnvironment("foo", defaultValue: 42)',
        ConstantExpressionKind.INT_FROM_ENVIRONMENT),
    const ConstantData(
        'const String.fromEnvironment("foo", defaultValue: "bar")',
        ConstantExpressionKind.STRING_FROM_ENVIRONMENT),
  ]),
  const TestData('''
class A {
  const A();
}
class B {
  final field1;
  const B(this.field1);
}
class C extends B {
  final field2;
  const C({field1: 42, this.field2: false}) : super(field1);
  const C.named([field = false]) : this(field1: field, field2: field);
}
''', const [
    const ConstantData('const Object()', ConstantExpressionKind.CONSTRUCTED,
        type: 'Object', fields: const {}),
    const ConstantData('const A()', ConstantExpressionKind.CONSTRUCTED,
        type: 'A', fields: const {}),
    const ConstantData('const B(0)', ConstantExpressionKind.CONSTRUCTED,
        type: 'B', fields: const {'field(B#field1)': '0'}),
    const ConstantData('const B(const A())', ConstantExpressionKind.CONSTRUCTED,
        type: 'B', fields: const {'field(B#field1)': 'const A()'}),
    const ConstantData('const C()', ConstantExpressionKind.CONSTRUCTED,
        type: 'C',
        fields: const {
          'field(B#field1)': '42',
          'field(C#field2)': 'false',
        }),
    const ConstantData(
        'const C(field1: 87)', ConstantExpressionKind.CONSTRUCTED,
        type: 'C',
        fields: const {
          'field(B#field1)': '87',
          'field(C#field2)': 'false',
        }),
    const ConstantData(
        'const C(field2: true)', ConstantExpressionKind.CONSTRUCTED,
        type: 'C',
        fields: const {
          'field(B#field1)': '42',
          'field(C#field2)': 'true',
        }),
    const ConstantData('const C.named()', ConstantExpressionKind.CONSTRUCTED,
        type: 'C',
        fields: const {
          'field(B#field1)': 'false',
          'field(C#field2)': 'false',
        }),
    const ConstantData('const C.named(87)', ConstantExpressionKind.CONSTRUCTED,
        type: 'C',
        fields: const {
          'field(B#field1)': '87',
          'field(C#field2)': '87',
        }),
  ]),
  const TestData('''
class A<T> implements B {
  final field1;
  const A({this.field1:42});
}
class B<S> implements C {
  const factory B({field1}) = A<B<S>>;
  const factory B.named() = A<S>;
}
class C<U> {
  const factory C({field1}) = A<B<double>>;
}
''', const [
    const ConstantData('const A()', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<dynamic>', fields: const {'field(A#field1)': '42'}),
    const ConstantData(
        'const A<int>(field1: 87)', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<int>', fields: const {'field(A#field1)': '87'}),
    const ConstantData('const B()', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<B<dynamic>>',
        fields: const {
          'field(A#field1)': '42',
        }),
    const ConstantData('const B<int>()', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<B<int>>',
        fields: const {
          'field(A#field1)': '42',
        }),
    const ConstantData(
        'const B<int>(field1: 87)', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<B<int>>',
        fields: const {
          'field(A#field1)': '87',
        }),
    const ConstantData(
        'const C<int>(field1: 87)', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<B<double>>',
        fields: const {
          'field(A#field1)': '87',
        }),
    const ConstantData(
        'const B<int>.named()', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<int>',
        fields: const {
          'field(A#field1)': '42',
        }),
  ]),
];

main() {
  asyncTest(() => Future.forEach(DATA, testData));
}

Future testData(TestData data) async {
  StringBuffer sb = new StringBuffer();
  sb.write('${data.declarations}\n');
  Map constants = {};
  data.constants.forEach((ConstantData constantData) {
    String name = 'c${constants.length}';
    sb.write('const $name = ${constantData.code};\n');
    constants[name] = constantData;
  });
  sb.write('main() {}\n');
  String source = sb.toString();
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': source}, options: ['--analyze-all']);
  Compiler compiler = result.compiler;
  MemoryEnvironment environment =
      new MemoryEnvironment(new AstEvaluationEnvironment(compiler));
  dynamic library = compiler.frontendStrategy.elementEnvironment.mainLibrary;
  constants.forEach((String name, ConstantData data) {
    FieldElement field = library.localLookup(name);
    dynamic constant = field.constant;
    Expect.equals(
        data.kind,
        constant.kind,
        "Unexpected kind '${constant.kind}' for constant "
        "`${constant.toDartText()}`, expected '${data.kind}'.");
    Expect.equals(
        data.text,
        constant.toDartText(),
        "Unexpected text '${constant.toDartText()}' for constant, "
        "expected '${data.text}'.");
    if (data.type != null) {
      String instanceType =
          constant.computeInstanceType(environment).toString();
      Expect.equals(
          data.type,
          instanceType,
          "Unexpected type '$instanceType' for constant "
          "`${constant.toDartText()}`, expected '${data.type}'.");
    }
    if (data.fields != null) {
      Map instanceFields = constant.computeInstanceFields(environment);
      Expect.equals(
          data.fields.length,
          instanceFields.length,
          "Unexpected field count ${instanceFields.length} for constant "
          "`${constant.toDartText()}`, expected '${data.fields.length}'.");
      instanceFields.forEach((field, expression) {
        String name = '$field';
        String expression = instanceFields[field].toDartText();
        String expected = data.fields[name];
        Expect.equals(
            expected,
            expression,
            "Unexpected field expression ${expression} for field '$name' in "
            "constant `${constant.toDartText()}`, expected '${expected}'.");
      });
    }
  });
}
