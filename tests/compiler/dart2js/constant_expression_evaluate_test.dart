// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.expressions.evaluate_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/compile_time_constants.dart';
import 'package:compiler/src/constants/constructors.dart';
import 'package:compiler/src/constants/evaluation.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/constant_system_dart.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'memory_compiler.dart';

class TestData {
  final String name;

  /// Declarations needed for the [constants].
  final String declarations;

  /// Tested constants.
  final List constants;

  const TestData(this.name, this.declarations, this.constants);
}

class ConstantData {
  /// Source code for the constant expression.
  final String code;

  /// Constant value as structured text for the empty environment or a map from
  /// environment to either the expected constant value as structured text or
  /// a [ConstantResult].
  final expectedResults;

  /// A [MessageKind] or a list of [MessageKind]s containing the error messages
  /// expected as the result of evaluating the constant under the empty
  /// environment.
  final expectedErrors;

  const ConstantData(this.code, this.expectedResults, [this.expectedErrors]);
}

class EvaluationError {
  final MessageKind kind;
  final Map arguments;

  EvaluationError(this.kind, this.arguments);
}

class MemoryEnvironment implements EvaluationEnvironment {
  final EvaluationEnvironment _environment;
  final Map<String, String> env;
  final List<EvaluationError> errors = <EvaluationError>[];

  MemoryEnvironment(this._environment, [this.env = const <String, String>{}]);

  @override
  String readFromEnvironment(String name) => env[name];

  @override
  InterfaceType substByContext(InterfaceType base, InterfaceType target) {
    return _environment.substByContext(base, target);
  }

  @override
  ConstantConstructor getConstructorConstant(ConstructorEntity constructor) {
    return _environment.getConstructorConstant(constructor);
  }

  @override
  ConstantExpression getFieldConstant(FieldEntity field) {
    return _environment.getFieldConstant(field);
  }

  @override
  ConstantExpression getLocalConstant(Local local) {
    return _environment.getLocalConstant(local);
  }

  @override
  CommonElements get commonElements => _environment.commonElements;

  void reportWarning(
      ConstantExpression expression, MessageKind kind, Map arguments) {
    errors.add(new EvaluationError(kind, arguments));
    _environment.reportWarning(expression, kind, arguments);
  }

  void reportError(
      ConstantExpression expression, MessageKind kind, Map arguments) {
    errors.add(new EvaluationError(kind, arguments));
    _environment.reportError(expression, kind, arguments);
  }

  ConstantValue evaluateConstructor(
      ConstructorEntity constructor, ConstantValue evaluate()) {
    return _environment.evaluateConstructor(constructor, evaluate);
  }

  ConstantValue evaluateField(FieldEntity field, ConstantValue evaluate()) {
    return _environment.evaluateField(field, evaluate);
  }
}

const List<TestData> DATA = const [
  const TestData('simple', '', const [
    const ConstantData('null', 'NullConstant'),
    const ConstantData('false', 'BoolConstant(false)'),
    const ConstantData('true', 'BoolConstant(true)'),
    const ConstantData('0', 'IntConstant(0)'),
    const ConstantData('0.0', 'DoubleConstant(0.0)'),
    const ConstantData('"foo"', 'StringConstant("foo")'),
    const ConstantData('1 + 2', 'IntConstant(3)'),
    const ConstantData('-(1)', 'IntConstant(-1)'),
    const ConstantData('1 == 2', 'BoolConstant(false)'),
    const ConstantData('1 != 2', 'BoolConstant(true)'),
    const ConstantData('"foo".length', 'IntConstant(3)'),
    const ConstantData('identical(0, 1)', 'BoolConstant(false)'),
    const ConstantData('"a" "b"', 'StringConstant("ab")'),
    const ConstantData(r'"${null}"', 'StringConstant("null")'),
    const ConstantData('identical', 'FunctionConstant(identical)'),
    const ConstantData('true ? 0 : 1', 'IntConstant(0)'),
    const ConstantData('proxy', 'ConstructedConstant(_Proxy())'),
    const ConstantData('Object', 'TypeConstant(Object)'),
    const ConstantData('null ?? 0', 'IntConstant(0)'),
    const ConstantData(
        'const [0, 1]', 'ListConstant([IntConstant(0), IntConstant(1)])'),
    const ConstantData('const <int>[0, 1]',
        'ListConstant(<int>[IntConstant(0), IntConstant(1)])'),
    const ConstantData(
        'const {0: 1, 2: 3}',
        'MapConstant({IntConstant(0): IntConstant(1), '
        'IntConstant(2): IntConstant(3)})'),
    const ConstantData(
        'const <int, int>{0: 1, 2: 3}',
        'MapConstant(<int, int>{IntConstant(0): IntConstant(1), '
        'IntConstant(2): IntConstant(3)})'),
    const ConstantData(
        'const <int, int>{0: 1, 0: 2}',
        'MapConstant(<int, int>{IntConstant(0): IntConstant(2)})',
        MessageKind.EQUAL_MAP_ENTRY_KEY),
    const ConstantData(
        'const bool.fromEnvironment("foo", defaultValue: false)', const {
      const {}: 'BoolConstant(false)',
      const {'foo': 'true'}: 'BoolConstant(true)'
    }),
    const ConstantData(
        'const int.fromEnvironment("foo", defaultValue: 42)', const {
      const {}: 'IntConstant(42)',
      const {'foo': '87'}: 'IntConstant(87)'
    }),
    const ConstantData(
        'const String.fromEnvironment("foo", defaultValue: "bar")', const {
      const {}: 'StringConstant("bar")',
      const {'foo': 'foo'}: 'StringConstant("foo")'
    }),
  ]),
  const TestData('env', '''
const a = const bool.fromEnvironment("foo", defaultValue: true);
const b = const int.fromEnvironment("bar", defaultValue: 42);

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
class D extends C {
  final field3 = 99;
  const D(a, b) : super(field2: a, field1: b);
}
''', const [
    const ConstantData('const Object()', 'ConstructedConstant(Object())'),
    const ConstantData('const A()', 'ConstructedConstant(A())'),
    const ConstantData(
        'const B(0)', 'ConstructedConstant(B(field1=IntConstant(0)))'),
    const ConstantData('const B(const A())',
        'ConstructedConstant(B(field1=ConstructedConstant(A())))'),
    const ConstantData(
        'const C()',
        'ConstructedConstant(C(field1=IntConstant(42),'
        'field2=BoolConstant(false)))'),
    const ConstantData(
        'const C(field1: 87)',
        'ConstructedConstant(C(field1=IntConstant(87),'
        'field2=BoolConstant(false)))'),
    const ConstantData(
        'const C(field2: true)',
        'ConstructedConstant(C(field1=IntConstant(42),'
        'field2=BoolConstant(true)))'),
    const ConstantData(
        'const C.named()',
        'ConstructedConstant(C(field1=BoolConstant(false),'
        'field2=BoolConstant(false)))'),
    const ConstantData(
        'const C.named(87)',
        'ConstructedConstant(C(field1=IntConstant(87),'
        'field2=IntConstant(87)))'),
    const ConstantData('const C(field1: a, field2: b)', const {
      const {}: 'ConstructedConstant(C(field1=BoolConstant(true),'
          'field2=IntConstant(42)))',
      const {'foo': 'false', 'bar': '87'}:
          'ConstructedConstant(C(field1=BoolConstant(false),'
          'field2=IntConstant(87)))',
    }),
    const ConstantData(
        'const D(42, 87)',
        'ConstructedConstant(D(field1=IntConstant(87),'
        'field2=IntConstant(42),'
        'field3=IntConstant(99)))'),
  ]),
  const TestData('redirect', '''
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
    const ConstantData(
        'const A()', 'ConstructedConstant(A<dynamic>(field1=IntConstant(42)))'),
    const ConstantData('const A<int>(field1: 87)',
        'ConstructedConstant(A<int>(field1=IntConstant(87)))'),
    const ConstantData('const B()',
        'ConstructedConstant(A<B<dynamic>>(field1=IntConstant(42)))'),
    const ConstantData('const B<int>()',
        'ConstructedConstant(A<B<int>>(field1=IntConstant(42)))'),
    const ConstantData('const B<int>(field1: 87)',
        'ConstructedConstant(A<B<int>>(field1=IntConstant(87)))'),
    const ConstantData('const C<int>(field1: 87)',
        'ConstructedConstant(A<B<double>>(field1=IntConstant(87)))'),
    const ConstantData('const B<int>.named()',
        'ConstructedConstant(A<int>(field1=IntConstant(42)))'),
  ]),
  const TestData('env2', '''
const c = const int.fromEnvironment("foo", defaultValue: 5);
const d = const int.fromEnvironment("bar", defaultValue: 10);

class A {
  final field;
  const A(a, b) : field = a + b;
}

class B extends A {
  const B(a) : super(a, a * 2);
}
''', const [
    const ConstantData('const A(c, d)', const {
      const {}: 'ConstructedConstant(A(field=IntConstant(15)))',
      const {'foo': '7', 'bar': '11'}:
          'ConstructedConstant(A(field=IntConstant(18)))',
    }),
    const ConstantData('const B(d)', const {
      const {}: 'ConstructedConstant(B(field=IntConstant(30)))',
      const {'bar': '42'}: 'ConstructedConstant(B(field=IntConstant(126)))',
    }),
  ]),
  const TestData('construct', '''
 class A {
   final x;
   final y;
   final z;
   final t;
   final u = 42;
   const A(this.z, tt) : y = 499, t = tt, x = 3;
   const A.named(z, this.t) : y = 400 + z, this.z = z, x = 3;
   const A.named2(t, z, y, x) : x = t, y = z, z = y, t = x;
 }
 ''', const [
    const ConstantData(
        'const A.named(99, 100)',
        'ConstructedConstant(A('
        't=IntConstant(100),'
        'u=IntConstant(42),'
        'x=IntConstant(3),'
        'y=IntConstant(499),'
        'z=IntConstant(99)))'),
    const ConstantData(
        'const A(99, 100)',
        'ConstructedConstant(A('
        't=IntConstant(100),'
        'u=IntConstant(42),'
        'x=IntConstant(3),'
        'y=IntConstant(499),'
        'z=IntConstant(99)))'),
  ]),
  const TestData('errors', '''
 const integer = const int.fromEnvironment("foo", defaultValue: 5);
 const string = const String.fromEnvironment("bar", defaultValue: "baz");
 const boolean = const bool.fromEnvironment("baz", defaultValue: false);
 const not_string =
    const bool.fromEnvironment("not_string", defaultValue: false) ? '' : 0;
 class Class1 {
    final field;
    const Class1() : field = not_string.length;
 }
 ''', const [
    const ConstantData(
        r'"$integer $string $boolean"', 'StringConstant("5 baz false")'),
    const ConstantData('0 ? true : false', 'NonConstant',
        MessageKind.INVALID_CONSTANT_CONDITIONAL_TYPE),
    const ConstantData('integer ? true : false', 'NonConstant',
        MessageKind.INVALID_CONSTANT_CONDITIONAL_TYPE),
    const ConstantData(r'"${const []}"', 'NonConstant',
        MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE),
    const ConstantData(r'"${proxy}"', 'NonConstant',
        MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE),
    const ConstantData(r'"${proxy}${const []}"', 'NonConstant', const [
      MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE,
      MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE
    ]),
    const ConstantData(r'"${"${proxy}"}${const []}"', 'NonConstant', const [
      MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE,
      MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE
    ]),
    const ConstantData(
        '0 + ""', 'NonConstant', MessageKind.INVALID_CONSTANT_NUM_ADD_TYPE),
    const ConstantData(
        '0 + string', 'NonConstant', MessageKind.INVALID_CONSTANT_NUM_ADD_TYPE),
    const ConstantData(
        '"" + 0', 'NonConstant', MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE),
    const ConstantData('string + 0', 'NonConstant',
        MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE),
    const ConstantData('true + ""', 'NonConstant',
        MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE),
    const ConstantData('boolean + string', 'NonConstant',
        MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE),
    const ConstantData(
        'true + false', 'NonConstant', MessageKind.INVALID_CONSTANT_ADD_TYPES),
    const ConstantData('boolean + false', 'NonConstant',
        MessageKind.INVALID_CONSTANT_ADD_TYPES),
    const ConstantData('const [] == null', 'NonConstant',
        MessageKind.INVALID_CONSTANT_BINARY_PRIMITIVE_TYPE),
    const ConstantData('proxy == null', 'NonConstant',
        MessageKind.INVALID_CONSTANT_BINARY_PRIMITIVE_TYPE),
    const ConstantData(
        '0 * ""', 'NonConstant', MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE),
    const ConstantData('0 * string', 'NonConstant',
        MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE),
    const ConstantData(
        '0 % ""', 'NonConstant', MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE),
    const ConstantData('0 % string', 'NonConstant',
        MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE),
    const ConstantData(
        '0 << ""', 'NonConstant', MessageKind.INVALID_CONSTANT_BINARY_INT_TYPE),
    const ConstantData('0 << string', 'NonConstant',
        MessageKind.INVALID_CONSTANT_BINARY_INT_TYPE),
    const ConstantData(
        'null[0]', 'NonConstant', MessageKind.INVALID_CONSTANT_INDEX),
    const ConstantData('const bool.fromEnvironment(0)', 'NonConstant',
        MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE),
    const ConstantData('const bool.fromEnvironment(integer)', 'NonConstant',
        MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE),
    const ConstantData(
        'const bool.fromEnvironment("baz", defaultValue: 0)',
        'NonConstant',
        MessageKind.INVALID_BOOL_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE),
    const ConstantData(
        'const bool.fromEnvironment("baz", defaultValue: integer)',
        'NonConstant',
        MessageKind.INVALID_BOOL_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE),
    const ConstantData('const int.fromEnvironment(0)', 'NonConstant',
        MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE),
    const ConstantData('const int.fromEnvironment(integer)', 'NonConstant',
        MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE),
    const ConstantData(
        'const int.fromEnvironment("baz", defaultValue: "")',
        'NonConstant',
        MessageKind.INVALID_INT_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE),
    const ConstantData(
        'const int.fromEnvironment("baz", defaultValue: string)',
        'NonConstant',
        MessageKind.INVALID_INT_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE),
    const ConstantData('const String.fromEnvironment(0)', 'NonConstant',
        MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE),
    const ConstantData('const String.fromEnvironment(integer)', 'NonConstant',
        MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE),
    const ConstantData(
        'const String.fromEnvironment("baz", defaultValue: 0)',
        'NonConstant',
        MessageKind.INVALID_STRING_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE),
    const ConstantData(
        'const String.fromEnvironment("baz", defaultValue: integer)',
        'NonConstant',
        MessageKind.INVALID_STRING_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE),
    const ConstantData('true || 0', 'NonConstant',
        MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE),
    const ConstantData('0 || true', 'NonConstant',
        MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE),
    const ConstantData('true || integer', 'NonConstant',
        MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE),
    const ConstantData('integer || true', 'NonConstant',
        MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE),
    const ConstantData('true && 0', 'NonConstant',
        MessageKind.INVALID_LOGICAL_AND_OPERAND_TYPE),
    const ConstantData('0 && true', 'NonConstant',
        MessageKind.INVALID_LOGICAL_AND_OPERAND_TYPE),
    const ConstantData('integer && true', 'NonConstant',
        MessageKind.INVALID_LOGICAL_AND_OPERAND_TYPE),
    const ConstantData(
        '!0', 'NonConstant', MessageKind.INVALID_CONSTANT_NOT_TYPE),
    const ConstantData(
        '!string', 'NonConstant', MessageKind.INVALID_CONSTANT_NOT_TYPE),
    const ConstantData(
        '-("")', 'NonConstant', MessageKind.INVALID_CONSTANT_NEGATE_TYPE),
    const ConstantData(
        '-(string)', 'NonConstant', MessageKind.INVALID_CONSTANT_NEGATE_TYPE),
    const ConstantData('not_string.length', 'NonConstant',
        MessageKind.INVALID_CONSTANT_STRING_LENGTH_TYPE),
    const ConstantData('const Class1()', 'NonConstant',
        MessageKind.INVALID_CONSTANT_STRING_LENGTH_TYPE),
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
  print("--source '${data.name}'---------------------------------------------");
  print(source);

  Future runTest(
      List<String> options,
      EvaluationEnvironment getEnvironment(
          Compiler compiler, FieldEntity field)) async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': source}, options: options);
    Compiler compiler = result.compiler;
    ElementEnvironment elementEnvironment =
        compiler.frontendStrategy.elementEnvironment;
    LibraryEntity library = elementEnvironment.mainLibrary;
    constants.forEach((String name, ConstantData data) {
      FieldEntity field = elementEnvironment.lookupLibraryMember(library, name);
      compiler.reporter.withCurrentElement(field, () {
        ConstantExpression constant =
            elementEnvironment.getFieldConstant(field);

        var expectedResults = data.expectedResults;
        if (expectedResults is String) {
          expectedResults = {const <String, String>{}: expectedResults};
        }
        expectedResults.forEach((Map<String, String> env, String expectedText) {
          MemoryEnvironment environment =
              new MemoryEnvironment(getEnvironment(compiler, field), env);
          ConstantValue value =
              constant.evaluate(environment, DART_CONSTANT_SYSTEM);

          Expect.isNotNull(
              value,
              "Expected non-null value from evaluation of "
              "`${constant.toStructuredText()}`.");

          String valueText = value.toStructuredText();
          Expect.equals(
              expectedText,
              valueText,
              "Unexpected value '${valueText}' for field $field = "
              "`${constant.toDartText()}`, expected '${expectedText}'.");

          List<MessageKind> errors =
              environment.errors.map((m) => m.kind).toList();
          var expectedErrors = data.expectedErrors;
          if (expectedErrors != null) {
            if (expectedErrors is! List) {
              expectedErrors = [expectedErrors];
            }
            Expect.listEquals(
                expectedErrors,
                errors,
                "Error mismatch for `$field = ${constant.toDartText()}`:\n"
                "Expected: ${data.expectedErrors},\n"
                "Found: ${errors}.");
          } else {
            Expect.isTrue(
                errors.isEmpty,
                "Unexpected errors for `$field = ${constant.toDartText()}`:\n"
                "Found: ${errors}.");
          }
        });
      });
    });
  }

  const skipAstList = const [
    // The old front end reports errors through the compile time constant
    // evaluator which results in different constant expressions for errorneous
    // constants.
    'errors',
  ];
  const skipKernelList = const [
    // TODO(johnniwinther): Investigate why some types of the constructed
    // objects don't match.
    'redirect',
  ];

  if (!skipAstList.contains(data.name)) {
    print(
        '--test ast----------------------------------------------------------');
    await runTest(
        [Flags.analyzeAll],
        (Compiler compiler, FieldEntity field) => new AstEvaluationEnvironment(
            compiler,
            constantRequired: field.isConst));
  }
  if (!skipKernelList.contains(data.name)) {
    print(
        '--test kernel-------------------------------------------------------');
    await runTest([Flags.useKernel, Flags.analyzeOnly],
        (Compiler compiler, FieldEntity field) {
      KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
      KernelToElementMap elementMap = frontendStrategy.elementMap;
      return new KernelEvaluationEnvironment(elementMap, null, field,
          constantRequired: field.isConst);
    });
  }
}
