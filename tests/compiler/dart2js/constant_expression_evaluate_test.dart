// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.expressions.evaluate_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/constants/constructors.dart';
import 'package:compiler/src/constants/evaluation.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/constant_system_dart.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'memory_compiler.dart';

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

  /// Map from environment to expected constant value as structured text.
  final Map<Map<String, String>, String> expectedValues;

  const ConstantData(this.code, this.expectedValues);
}

class MemoryEnvironment implements EvaluationEnvironment {
  final Compiler _compiler;
  final Map<String, String> env;

  MemoryEnvironment(this._compiler, [this.env = const <String, String>{}]);

  @override
  String readFromEnvironment(String name) => env[name];

  @override
  ResolutionInterfaceType substByContext(
      ResolutionInterfaceType base, ResolutionInterfaceType target) {
    return base.substByContext(target);
  }

  @override
  ConstantConstructor getConstructorConstant(ConstructorElement constructor) {
    return constructor.constantConstructor;
  }

  @override
  ConstantExpression getFieldConstant(FieldElement field) {
    return field.constant;
  }

  @override
  ConstantExpression getLocalConstant(LocalVariableElement local) {
    return local.constant;
  }

  @override
  CommonElements get commonElements => _compiler.resolution.commonElements;
}

const List<TestData> DATA = const [
  const TestData('', const [
    const ConstantData('null', const {const {}: 'NullConstant'}),
    const ConstantData('false', const {const {}: 'BoolConstant(false)'}),
    const ConstantData('true', const {const {}: 'BoolConstant(true)'}),
    const ConstantData('0', const {const {}: 'IntConstant(0)'}),
    const ConstantData('0.0', const {const {}: 'DoubleConstant(0.0)'}),
    const ConstantData('"foo"', const {const {}: 'StringConstant("foo")'}),
    const ConstantData('1 + 2', const {const {}: 'IntConstant(3)'}),
    const ConstantData('-(1)', const {const {}: 'IntConstant(-1)'}),
    const ConstantData('1 == 2', const {const {}: 'BoolConstant(false)'}),
    const ConstantData('1 != 2', const {const {}: 'BoolConstant(true)'}),
    const ConstantData('"foo".length', const {const {}: 'IntConstant(3)'}),
    const ConstantData(
        'identical(0, 1)', const {const {}: 'BoolConstant(false)'}),
    const ConstantData('"a" "b"', const {const {}: 'StringConstant("ab")'}),
    const ConstantData(
        r'"${null}"', const {const {}: 'StringConstant("null")'}),
    const ConstantData(
        'identical', const {const {}: 'FunctionConstant(identical)'}),
    const ConstantData('true ? 0 : 1', const {const {}: 'IntConstant(0)'}),
    const ConstantData(
        'proxy', const {const {}: 'ConstructedConstant(_Proxy())'}),
    const ConstantData('Object', const {const {}: 'TypeConstant(Object)'}),
    const ConstantData('const [0, 1]',
        const {const {}: 'ListConstant([IntConstant(0), IntConstant(1)])'}),
    const ConstantData('const <int>[0, 1]', const {
      const {}: 'ListConstant(<int>[IntConstant(0), IntConstant(1)])'
    }),
    const ConstantData('const {0: 1, 2: 3}', const {
      const {}: 'MapConstant({IntConstant(0): IntConstant(1), '
          'IntConstant(2): IntConstant(3)})'
    }),
    const ConstantData('const <int, int>{0: 1, 2: 3}', const {
      const {}: 'MapConstant(<int, int>{IntConstant(0): IntConstant(1), '
          'IntConstant(2): IntConstant(3)})'
    }),
    const ConstantData('const <int, int>{0: 1, 0: 2}', const {
      const {}: 'MapConstant(<int, int>{IntConstant(0): IntConstant(2)})'
    }),
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
  const TestData(
      '''
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
''',
      const [
        const ConstantData('const Object()',
            const {const {}: 'ConstructedConstant(Object())'}),
        const ConstantData(
            'const A()', const {const {}: 'ConstructedConstant(A())'}),
        const ConstantData('const B(0)',
            const {const {}: 'ConstructedConstant(B(field1=IntConstant(0)))'}),
        const ConstantData('const B(const A())', const {
          const {}: 'ConstructedConstant(B(field1=ConstructedConstant(A())))'
        }),
        const ConstantData('const C()', const {
          const {}: 'ConstructedConstant(C(field1=IntConstant(42),'
              'field2=BoolConstant(false)))'
        }),
        const ConstantData('const C(field1: 87)', const {
          const {}: 'ConstructedConstant(C(field1=IntConstant(87),'
              'field2=BoolConstant(false)))'
        }),
        const ConstantData('const C(field2: true)', const {
          const {}: 'ConstructedConstant(C(field1=IntConstant(42),'
              'field2=BoolConstant(true)))'
        }),
        const ConstantData('const C.named()', const {
          const {}: 'ConstructedConstant(C(field1=BoolConstant(false),'
              'field2=BoolConstant(false)))'
        }),
        const ConstantData('const C.named(87)', const {
          const {}: 'ConstructedConstant(C(field1=IntConstant(87),'
              'field2=IntConstant(87)))'
        }),
        const ConstantData('const C(field1: a, field2: b)', const {
          const {}: 'ConstructedConstant(C(field1=BoolConstant(true),'
              'field2=IntConstant(42)))',
          const {'foo': 'false', 'bar': '87'}:
              'ConstructedConstant(C(field1=BoolConstant(false),'
              'field2=IntConstant(87)))',
        }),
        const ConstantData('const D(42, 87)', const {
          const {}: 'ConstructedConstant(D(field1=IntConstant(87),'
              'field2=IntConstant(42),'
              'field3=IntConstant(99)))'
        }),
      ]),
  const TestData(
      '''
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
''',
      const [
        const ConstantData('const A()', const {
          const {}: 'ConstructedConstant(A<dynamic>(field1=IntConstant(42)))'
        }),
        const ConstantData('const A<int>(field1: 87)', const {
          const {}: 'ConstructedConstant(A<int>(field1=IntConstant(87)))'
        }),
        const ConstantData('const B()', const {
          const {}: 'ConstructedConstant(A<B<dynamic>>(field1=IntConstant(42)))'
        }),
        const ConstantData('const B<int>()', const {
          const {}: 'ConstructedConstant(A<B<int>>(field1=IntConstant(42)))'
        }),
        const ConstantData('const B<int>(field1: 87)', const {
          const {}: 'ConstructedConstant(A<B<int>>(field1=IntConstant(87)))'
        }),
        const ConstantData('const C<int>(field1: 87)', const {
          const {}: 'ConstructedConstant(A<B<double>>(field1=IntConstant(87)))'
        }),
        const ConstantData('const B<int>.named()', const {
          const {}: 'ConstructedConstant(A<int>(field1=IntConstant(42)))'
        }),
      ]),
  const TestData(
      '''
const c = const int.fromEnvironment("foo", defaultValue: 5);
const d = const int.fromEnvironment("bar", defaultValue: 10);

class A {
  final field;
  const A(a, b) : field = a + b;
}

class B extends A {
  const B(a) : super(a, a * 2);
}
''',
      const [
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
  var library = compiler.mainApp;
  constants.forEach((String name, ConstantData data) {
    FieldElement field = library.localLookup(name);
    ConstantExpression constant = field.constant;
    data.expectedValues.forEach((Map<String, String> env, String expectedText) {
      EvaluationEnvironment environment = new MemoryEnvironment(compiler, env);
      ConstantValue value =
          constant.evaluate(environment, DART_CONSTANT_SYSTEM);
      String valueText = value.toStructuredText();
      Expect.equals(
          expectedText,
          valueText,
          "Unexpected value '${valueText}' for constant "
          "`${constant.toDartText()}`, expected '${expectedText}'.");
    });
  });
}
