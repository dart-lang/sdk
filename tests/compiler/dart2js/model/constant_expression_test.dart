// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constant_expression_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/elements/entities.dart';
import '../memory_compiler.dart';
import 'constant_expression_evaluate_test.dart' show MemoryEnvironment;

class TestData {
  /// Declarations needed for the [constants].
  final String declarations;

  /// Tested constants.
  final List<ConstantData> constants;

  final bool strongModeOnly;

  const TestData(this.declarations, this.constants,
      {this.strongModeOnly: false});
}

class ConstantData {
  /// Source code for the constant expression.
  final String code;

  /// The expected constant expression kind.
  final ConstantExpressionKind kind;

  /// ConstantExpression.getText() result if different from [code].
  final String text;

  /// ConstantExpression.getText() result if different from [code].
  final String strongText;

  /// The expected instance type for ConstructedConstantExpression.
  final String type;

  /// The expected instance fields for ConstructedConstantExpression.
  final Map<String, String> fields;

  const ConstantData(String code, this.kind,
      {String text, String strongText, this.type, this.fields})
      : this.code = code,
        this.text = text ?? code,
        this.strongText = strongText ?? text ?? code;
}

const List<TestData> DATA = const [
  const TestData('''
class Class<T, S> {
  final a;
  final b;
  final c;
  const Class(this.a, {this.b, this.c: true});
  const Class.named([this.a, this.b = 0, this.c = 2]);

  static const staticConstant = 0;
  static staticFunction() {}
}
const t = true;
const f = false;
const toplevelConstant = 0;
toplevelFunction() {}
''', const [
    const ConstantData('null', ConstantExpressionKind.NULL),
    const ConstantData('false', ConstantExpressionKind.BOOL),
    const ConstantData('true', ConstantExpressionKind.BOOL),
    const ConstantData('0', ConstantExpressionKind.INT),
    const ConstantData('0.0', ConstantExpressionKind.DOUBLE),
    const ConstantData('"foo"', ConstantExpressionKind.STRING),
    const ConstantData('1 + 2', ConstantExpressionKind.BINARY),
    const ConstantData('1 == 2', ConstantExpressionKind.BINARY),
    const ConstantData('1 != 2', ConstantExpressionKind.UNARY,
        // a != b is encoded as !(a == b) by CFE.
        text: '!(1 == 2)'),
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
    const ConstantData('const []', ConstantExpressionKind.LIST),
    const ConstantData('const [0, 1]', ConstantExpressionKind.LIST,
        strongText: 'const <int>[0, 1]'),
    const ConstantData('const <int>[0, 1]', ConstantExpressionKind.LIST),
    const ConstantData('const <dynamic>[0, 1]', ConstantExpressionKind.LIST,
        text: 'const [0, 1]'),
    const ConstantData('const {}', ConstantExpressionKind.MAP),
    const ConstantData('const {0: 1, 2: 3}', ConstantExpressionKind.MAP,
        strongText: 'const <int, int>{0: 1, 2: 3}'),
    const ConstantData(
        'const <int, int>{0: 1, 2: 3}', ConstantExpressionKind.MAP),
    const ConstantData(
        'const <String, int>{"0": 1, "2": 3}', ConstantExpressionKind.MAP),
    const ConstantData(
        'const <String, dynamic>{"0": 1, "2": 3}', ConstantExpressionKind.MAP),
    const ConstantData(
        'const <dynamic, dynamic>{"0": 1, "2": 3}', ConstantExpressionKind.MAP,
        text: 'const {"0": 1, "2": 3}'),
    const ConstantData('const bool.fromEnvironment("foo", defaultValue: false)',
        ConstantExpressionKind.BOOL_FROM_ENVIRONMENT),
    const ConstantData('const int.fromEnvironment("foo", defaultValue: 42)',
        ConstantExpressionKind.INT_FROM_ENVIRONMENT),
    const ConstantData(
        'const String.fromEnvironment("foo", defaultValue: "bar")',
        ConstantExpressionKind.STRING_FROM_ENVIRONMENT),
    const ConstantData('const Class(0)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class(0, b: 1)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class(0, c: 2)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class(0, b: 3, c: 4)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class.named()', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class.named(0)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class.named(0, 1)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class.named(0, 1, 2)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class<String, int>(0)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class<String, dynamic>(0)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class<dynamic, String>(0)', ConstantExpressionKind.CONSTRUCTED),
    const ConstantData(
        'const Class<dynamic, dynamic>(0)', ConstantExpressionKind.CONSTRUCTED,
        text: 'const Class(0)'),
    const ConstantData('toplevelConstant', ConstantExpressionKind.FIELD),
    const ConstantData('toplevelFunction', ConstantExpressionKind.FUNCTION),
    const ConstantData('Class.staticConstant', ConstantExpressionKind.FIELD),
    const ConstantData('Class.staticFunction', ConstantExpressionKind.FUNCTION),
    const ConstantData('1 + 2', ConstantExpressionKind.BINARY),
    const ConstantData('1 + 2 + 3', ConstantExpressionKind.BINARY),
    const ConstantData('1 + -2', ConstantExpressionKind.BINARY),
    const ConstantData('-1 + 2', ConstantExpressionKind.BINARY),
    const ConstantData('(1 + 2) + 3', ConstantExpressionKind.BINARY,
        text: '1 + 2 + 3'),
    const ConstantData('1 + (2 + 3)', ConstantExpressionKind.BINARY,
        text: '1 + 2 + 3'),
    const ConstantData('1 * 2', ConstantExpressionKind.BINARY),
    const ConstantData('1 * 2 + 3', ConstantExpressionKind.BINARY),
    const ConstantData('1 * (2 + 3)', ConstantExpressionKind.BINARY),
    const ConstantData('1 + 2 * 3', ConstantExpressionKind.BINARY),
    const ConstantData('(1 + 2) * 3', ConstantExpressionKind.BINARY),
    const ConstantData(
        'false || identical(0, 1)', ConstantExpressionKind.BINARY),
    const ConstantData('!identical(0, 1)', ConstantExpressionKind.UNARY),
    const ConstantData(
        '!identical(0, 1) || false', ConstantExpressionKind.BINARY),
    const ConstantData(
        '!(identical(0, 1) || false)', ConstantExpressionKind.UNARY),
    const ConstantData('identical(0, 1) ? 3 * 4 + 5 : 6 + 7 * 8',
        ConstantExpressionKind.CONDITIONAL),
    const ConstantData('t ? f ? 0 : 1 : 2', ConstantExpressionKind.CONDITIONAL),
    const ConstantData(
        '(t ? t : f) ? f ? 0 : 1 : 2', ConstantExpressionKind.CONDITIONAL),
    const ConstantData(
        't ? t : f ? f ? 0 : 1 : 2', ConstantExpressionKind.CONDITIONAL),
    const ConstantData(
        't ? t ? t : t : t ? t : t', ConstantExpressionKind.CONDITIONAL),
    const ConstantData(
        't ? (t ? t : t) : (t ? t : t)', ConstantExpressionKind.CONDITIONAL,
        text: 't ? t ? t : t : t ? t : t'),
    const ConstantData(
        'const [const <dynamic, dynamic>{0: true, "1": "c" "d"}, '
        'const Class(const Class<dynamic, dynamic>(toplevelConstant))]',
        ConstantExpressionKind.LIST,
        text: 'const [const {0: true, "1": "cd"}, '
            'const Class(const Class(toplevelConstant))]',
        strongText: 'const <Object>[const {0: true, "1": "cd"}, '
            'const Class(const Class(toplevelConstant))]'),
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
        },
        // Redirecting factories are replaced by their effective targets by CFE.
        text: 'const A<B<dynamic>>()'),
    const ConstantData('const B<int>()', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<B<int>>',
        fields: const {
          'field(A#field1)': '42',
        },
        // Redirecting factories are replaced by their effective targets by CFE.
        text: 'const A<B<int>>()'),
    const ConstantData(
        'const B<int>(field1: 87)', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<B<int>>',
        fields: const {
          'field(A#field1)': '87',
        },
        // Redirecting factories are replaced by their effective targets by CFE.
        text: 'const A<B<int>>(field1: 87)'),
    const ConstantData(
        'const C<int>(field1: 87)', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<B<double>>',
        fields: const {
          'field(A#field1)': '87',
        },
        // Redirecting factories are replaced by their effective targets by CFE.
        text: 'const A<B<double>>(field1: 87)'),
    const ConstantData(
        'const B<int>.named()', ConstantExpressionKind.CONSTRUCTED,
        type: 'A<int>',
        fields: const {
          'field(A#field1)': '42',
        },
        // Redirecting factories are replaced by their effective targets by CFE.
        text: 'const A<int>()'),
  ]),
  const TestData('''
T identity<T>(T t) => t;
class C<T> {
  final T defaultValue;
  final T Function(T t) identityFunction;

  const C(this.defaultValue, this.identityFunction);
}
  ''', const <ConstantData>[
    const ConstantData('identity', ConstantExpressionKind.FUNCTION),
    const ConstantData(
        'const C<int>(0, identity)', ConstantExpressionKind.CONSTRUCTED,
        type: 'C<int>', strongText: 'const C<int>(0, <int>(identity))'),
    const ConstantData(
        'const C<double>(0.5, identity)', ConstantExpressionKind.CONSTRUCTED,
        type: 'C<double>',
        strongText: 'const C<double>(0.5, <double>(identity))'),
  ], strongModeOnly: true)
];

main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest(strongMode: false);
    print('--test from kernel (strong)---------------------------------------');
    await runTest(strongMode: true);
  });
}

Future runTest({bool strongMode}) async {
  for (TestData data in DATA) {
    await testData(data, strongMode: strongMode);
  }
}

Future testData(TestData data, {bool strongMode}) async {
  if (data.strongModeOnly && !strongMode) return;

  StringBuffer sb = new StringBuffer();
  sb.writeln('${data.declarations}');
  Map<String, ConstantData> constants = {};
  List<String> names = <String>[];
  data.constants.forEach((ConstantData constantData) {
    String name = 'c${constants.length}';
    names.add(name);
    sb.writeln('const $name = ${constantData.code};');
    constants[name] = constantData;
  });
  sb.writeln('main() {');
  for (String name in names) {
    sb.writeln('  print($name);');
  }
  sb.writeln('}');
  String source = sb.toString();
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': source},
      options: strongMode ? [Flags.strongMode] : []);
  Compiler compiler = result.compiler;
  var elementEnvironment = compiler.frontendStrategy.elementEnvironment;

  MemoryEnvironment environment = new MemoryEnvironment(
      new KernelEvaluationEnvironment(
          (compiler.frontendStrategy as dynamic).elementMap,
          compiler.environment,
          null));
  dynamic library = elementEnvironment.mainLibrary;
  constants.forEach((String name, ConstantData data) {
    FieldEntity field = elementEnvironment.lookupLibraryMember(library, name);
    dynamic constant = elementEnvironment.getFieldConstant(field);
    Expect.equals(
        data.kind,
        constant.kind,
        "Unexpected kind '${constant.kind}' for constant "
        "`${constant.toDartText()}`, expected '${data.kind}'.");
    String text = strongMode ? data.strongText : data.text;
    Expect.equals(
        text,
        constant.toDartText(),
        "Unexpected text '${constant.toDartText()}' for constant, "
        "expected '${text}'.");
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
      Map instanceFields = constant.computeInstanceData(environment).fieldMap;
      Expect.equals(
          data.fields.length,
          instanceFields.length,
          "Unexpected field count ${instanceFields.length} for constant "
          "`${constant.toDartText()}`, expected '${data.fields.length}'.");
      instanceFields.forEach((field, expression) {
        String name = '$field';
        Expect.isTrue(name.startsWith('k:'));
        name = name.substring(2).replaceAll('.', "#");
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
