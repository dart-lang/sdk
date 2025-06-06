// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/environment.dart';
import 'package:compiler/src/ir/constants.dart';
import 'package:compiler/src/ir/visitors.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:front_end/src/api_unstable/dart2js.dart' as ir;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:compiler/src/util/memory_compiler.dart';

const emptyEnv = <String, String>{};

class TestData {
  final String name;

  /// Declarations needed for the [constants].
  final String declarations;

  /// Tested constants.
  final List<ConstantData> constants;

  const TestData(this.name, this.declarations, this.constants);
}

class ConstantData {
  /// Source code for the constant expression.
  final String code;

  /// Constant value as structured text for the empty environment or a map from
  /// environment to either the expected constant value as structured text or
  /// a [ConstantResult].
  final expectedResults;

  /// A [String] containing the code name for the error message expected as the
  /// result of evaluating the constant under the empty environment.
  final String? expectedError;

  const ConstantData(this.code, this.expectedResults, {this.expectedError});
}

const List<TestData> DATA = [
  TestData('simple', '', [
    ConstantData('null', 'NullConstant'),
    ConstantData('false', 'BoolConstant(false)'),
    ConstantData('true', 'BoolConstant(true)'),
    ConstantData('0', 'IntConstant(0)'),
    ConstantData('0.0', 'IntConstant(0)'),
    ConstantData('"foo"', 'StringConstant("foo")'),
    ConstantData('1 + 2', 'IntConstant(3)'),
    ConstantData('-(1)', 'IntConstant(-1)'),
    ConstantData('1 == 2', 'BoolConstant(false)'),
    ConstantData('1 != 2', 'BoolConstant(true)'),
    ConstantData('1 / 0', 'DoubleConstant(Infinity)'),
    ConstantData('0 / 0', 'DoubleConstant(NaN)'),
    ConstantData('1 << 0', 'IntConstant(1)'),
    ConstantData('1 >> 0', 'IntConstant(1)'),
    ConstantData('"foo".length', 'IntConstant(3)'),
    ConstantData('identical(0, 1)', 'BoolConstant(false)'),
    ConstantData('"a" "b"', 'StringConstant("ab")'),
    ConstantData(r'"${null}"', 'StringConstant("null")'),
    ConstantData('identical', 'FunctionConstant(identical)'),
    ConstantData('true ? 0 : 1', 'IntConstant(0)'),
    ConstantData(
      'deprecated',
      'ConstructedConstant(Deprecated(message=StringConstant("next release")))',
    ),
    ConstantData('const [] == null', 'BoolConstant(false)'),
    ConstantData('deprecated == null', 'BoolConstant(false)'),
    ConstantData('deprecated != null', 'BoolConstant(true)'),
    ConstantData('null == deprecated', 'BoolConstant(false)'),
    ConstantData('null != deprecated', 'BoolConstant(true)'),
    ConstantData('true == deprecated', 'BoolConstant(false)'),
    ConstantData('true != deprecated', 'BoolConstant(true)'),
    ConstantData('0 == deprecated', 'BoolConstant(false)'),
    ConstantData('0 != deprecated', 'BoolConstant(true)'),
    ConstantData('0.5 == deprecated', 'BoolConstant(false)'),
    ConstantData('0.5 != deprecated', 'BoolConstant(true)'),
    ConstantData('"" == deprecated', 'BoolConstant(false)'),
    ConstantData('"" != deprecated', 'BoolConstant(true)'),
    ConstantData('Object', 'TypeConstant(Object)'),
    ConstantData('null ?? 0', 'IntConstant(0)'),
    ConstantData(
      'const <int, int>{0: 1, 0: 2}',
      'NonConstant',
      expectedError: 'ConstEvalDuplicateKey',
    ),
    ConstantData(
      'const bool.fromEnvironment("foo", defaultValue: false)',
      <Map<String, String>, String>{
        emptyEnv: 'BoolConstant(false)',
        const {'foo': 'true'}: 'BoolConstant(true)',
      },
    ),
    ConstantData(
      'const int.fromEnvironment("foo", defaultValue: 42)',
      <Map<String, String>, String>{
        emptyEnv: 'IntConstant(42)',
        const {'foo': '87'}: 'IntConstant(87)',
      },
    ),
    ConstantData(
      'const String.fromEnvironment("foo", defaultValue: "bar")',
      <Map<String, String>, String>{
        emptyEnv: 'StringConstant("bar")',
        const {'foo': 'foo'}: 'StringConstant("foo")',
      },
    ),
    ConstantData(
      'const [0, 1]',
      'ListConstant(<int>[IntConstant(0), IntConstant(1)])',
    ),
    ConstantData(
      'const <int>[0, 1]',
      'ListConstant(<int>[IntConstant(0), IntConstant(1)])',
    ),
    ConstantData(
      'const {0, 1}',
      'SetConstant(<int>{IntConstant(0), IntConstant(1)})',
    ),
    ConstantData(
      'const <int>{0, 1}',
      'SetConstant(<int>{IntConstant(0), IntConstant(1)})',
    ),
    ConstantData(
      'const {0: 1, 2: 3}',
      'MapConstant(<int, int>{IntConstant(0): IntConstant(1), '
          'IntConstant(2): IntConstant(3)})',
    ),
    ConstantData(
      'const <int, int>{0: 1, 2: 3}',
      'MapConstant(<int, int>{IntConstant(0): IntConstant(1), '
          'IntConstant(2): IntConstant(3)})',
    ),
  ]),
  TestData(
    'env',
    '''
const a = bool.fromEnvironment("foo", defaultValue: true);
const b = int.fromEnvironment("bar", defaultValue: 42);

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
    [
      ConstantData('const Object()', 'ConstructedConstant(Object())'),
      ConstantData('const A()', 'ConstructedConstant(A())'),
      ConstantData(
        'const B(0)',
        'ConstructedConstant(B(field1=IntConstant(0)))',
      ),
      ConstantData(
        'const B(A())',
        'ConstructedConstant(B(field1=ConstructedConstant(A())))',
      ),
      ConstantData(
        'const C()',
        'ConstructedConstant(C(field1=IntConstant(42),'
            'field2=BoolConstant(false)))',
      ),
      ConstantData(
        'const C(field1: 87)',
        'ConstructedConstant(C(field1=IntConstant(87),'
            'field2=BoolConstant(false)))',
      ),
      ConstantData(
        'const C(field2: true)',
        'ConstructedConstant(C(field1=IntConstant(42),'
            'field2=BoolConstant(true)))',
      ),
      ConstantData(
        'const C.named()',
        'ConstructedConstant(C(field1=BoolConstant(false),'
            'field2=BoolConstant(false)))',
      ),
      ConstantData(
        'const C.named(87)',
        'ConstructedConstant(C(field1=IntConstant(87),'
            'field2=IntConstant(87)))',
      ),
      ConstantData(
        'const C(field1: a, field2: b)',
        <Map<String, String>, String>{
          emptyEnv:
              'ConstructedConstant(C(field1=BoolConstant(true),'
              'field2=IntConstant(42)))',
          const {'foo': 'false', 'bar': '87'}:
              'ConstructedConstant(C(field1=BoolConstant(false),'
              'field2=IntConstant(87)))',
        },
      ),
      ConstantData(
        'const D(42, 87)',
        'ConstructedConstant(D(field1=IntConstant(87),'
            'field2=IntConstant(42),'
            'field3=IntConstant(99)))',
      ),
    ],
  ),
  TestData(
    'redirect',
    '''
class A<T> implements B<Null> {
  final field1;
  const A({this.field1:42});
}
class B<S> implements C<Null> {
  const factory B({field1}) = A<B<S>>;
  const factory B.named() = A<S>;
}
class C<U> {
  const factory C({field1}) = A<B<double>>;
}
''',
    [
      ConstantData(
        'const A()',
        'ConstructedConstant(A<dynamic>(field1=IntConstant(42)))',
      ),
      ConstantData(
        'const A<int>(field1: 87)',
        'ConstructedConstant(A<int>(field1=IntConstant(87)))',
      ),
      ConstantData(
        'const B()',
        'ConstructedConstant(A<B<dynamic>>(field1=IntConstant(42)))',
      ),
      ConstantData(
        'const B<int>()',
        'ConstructedConstant(A<B<int>>(field1=IntConstant(42)))',
      ),
      ConstantData(
        'const B<int>(field1: 87)',
        'ConstructedConstant(A<B<int>>(field1=IntConstant(87)))',
      ),
      ConstantData(
        'const C<int>(field1: 87)',
        'ConstructedConstant(A<B<double>>(field1=IntConstant(87)))',
      ),
      ConstantData(
        'const B<int>.named()',
        'ConstructedConstant(A<int>(field1=IntConstant(42)))',
      ),
    ],
  ),
  TestData(
    'env2',
    '''
const c = int.fromEnvironment("foo", defaultValue: 5);
const d = int.fromEnvironment("bar", defaultValue: 10);

class A {
  final field;
  const A(a, b) : field = a + b;
}

class B extends A {
  const B(a) : super(a, a * 2);
}
''',
    [
      ConstantData('const A(c, d)', <Map<String, String>, String>{
        emptyEnv: 'ConstructedConstant(A(field=IntConstant(15)))',
        const {'foo': '7', 'bar': '11'}:
            'ConstructedConstant(A(field=IntConstant(18)))',
      }),
      ConstantData('const B(d)', <Map<String, String>, String>{
        emptyEnv: 'ConstructedConstant(B(field=IntConstant(30)))',
        const {'bar': '42'}: 'ConstructedConstant(B(field=IntConstant(126)))',
      }),
    ],
  ),
  TestData(
    'construct',
    '''
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
 ''',
    [
      ConstantData(
        'const A.named(99, 100)',
        'ConstructedConstant(A('
            't=IntConstant(100),'
            'u=IntConstant(42),'
            'x=IntConstant(3),'
            'y=IntConstant(499),'
            'z=IntConstant(99)))',
      ),
      ConstantData(
        'const A(99, 100)',
        'ConstructedConstant(A('
            't=IntConstant(100),'
            'u=IntConstant(42),'
            'x=IntConstant(3),'
            'y=IntConstant(499),'
            'z=IntConstant(99)))',
      ),
    ],
  ),
  TestData(
    'errors',
    r'''
 const dynamic null_ = bool.fromEnvironment('x') ? null : null;
 const dynamic zero = bool.fromEnvironment('x') ? null : 0;
 const dynamic minus_one = bool.fromEnvironment('x') ? null : -1;
 const dynamic false_ = bool.fromEnvironment('x') ? null : false;
 const dynamic integer = int.fromEnvironment("foo", defaultValue: 5);
 const dynamic string = String.fromEnvironment("bar", defaultValue: "baz");
 const dynamic boolean = bool.fromEnvironment("baz", defaultValue: false);
 const dynamic not_string =
    bool.fromEnvironment("not_string", defaultValue: false) ? '' : 0;
 class Class1 {
    final field;
    const Class1() : field = not_string.length;
 }
 class Class2 implements Class3 {
    const Class2() : assert(false_);
    const Class2.redirect() : this();
 }
 class Class3 {
    const Class3() : assert(false_, "Message");
    const factory Class3.fact() = Class2;
 }
 class Class4 extends Class2 {
    const Class4();
 }
 class Class5 {
    const Class5(a) : assert(a > 0, "$a <= 0");
 }
 class Class6 extends Class5 {
    const Class6(a) : super(a - 1);
 }
 class Class7 {
    const Class7();

    bool operator ==(Object other) => true;
 }
 class Class8 {
    final field;
    const Class8(this.field);
 }
 class Class9 {
    final field = null_;
    const Class9();
 }
 class Class10 {
    final int field = string;
    const Class10();
 }
 ''',
    [
      ConstantData(
        r'"$integer $string $boolean"',
        'StringConstant("5 baz false")',
      ),
      ConstantData(
        'integer ? true : false',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        r'"${deprecated}"',
        'NonConstant',
        expectedError: 'ConstEvalInvalidStringInterpolationOperand',
      ),
      ConstantData(
        '0 + string',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'string + 0',
        'NonConstant',
        expectedError: 'ConstEvalInvalidBinaryOperandType',
      ),
      ConstantData(
        'boolean + string',
        'NonConstant',
        expectedError: 'ConstEvalInvalidMethodInvocation',
      ),
      ConstantData(
        'boolean + false',
        'NonConstant',
        expectedError: 'ConstEvalInvalidMethodInvocation',
      ),
      ConstantData(
        '0 * string',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        '0 % string',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        '0 << string',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        '1 ~/ zero',
        'NonConstant',
        expectedError: 'ConstEvalZeroDivisor',
      ),
      ConstantData(
        '1 % zero',
        'NonConstant',
        expectedError: 'ConstEvalZeroDivisor',
      ),
      ConstantData(
        '1 << minus_one',
        'NonConstant',
        expectedError: 'ConstEvalNegativeShift',
      ),
      ConstantData(
        '1 >> minus_one',
        'NonConstant',
        expectedError: 'ConstEvalNegativeShift',
      ),
      ConstantData(
        'const bool.fromEnvironment(integer)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'const bool.fromEnvironment("baz", defaultValue: integer)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'const int.fromEnvironment(integer)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'const int.fromEnvironment("baz", defaultValue: string)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'const String.fromEnvironment(integer)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'const String.fromEnvironment("baz", defaultValue: integer)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'false || integer',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'integer || true',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'integer && true',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        '!integer',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        '!string',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        '-(string)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidMethodInvocation',
      ),
      ConstantData(
        'not_string.length',
        'NonConstant',
        expectedError: 'ConstEvalInvalidPropertyGet',
      ),
      ConstantData(
        'const Class1()',
        'NonConstant',
        expectedError: 'ConstEvalInvalidPropertyGet',
      ),
      ConstantData(
        'const Class2()',
        'NonConstant',
        expectedError: 'ConstEvalFailedAssertion',
      ),
      ConstantData(
        'const Class2.redirect()',
        'NonConstant',
        expectedError: 'ConstEvalFailedAssertion',
      ),
      ConstantData(
        'const Class3()',
        'NonConstant',
        expectedError: 'ConstEvalFailedAssertionWithMessage',
      ),
      ConstantData(
        'const Class3.fact()',
        'NonConstant',
        expectedError: 'ConstEvalFailedAssertion',
      ),
      ConstantData(
        'const Class4()',
        'NonConstant',
        expectedError: 'ConstEvalFailedAssertion',
      ),
      ConstantData(
        'const Class5(0)',
        'NonConstant',
        expectedError: 'ConstEvalFailedAssertionWithMessage',
      ),
      ConstantData('const Class5(1)', 'ConstructedConstant(Class5())'),
      ConstantData(
        'const Class6(1)',
        'NonConstant',
        expectedError: 'ConstEvalFailedAssertionWithMessage',
      ),
      ConstantData('const Class6(2)', 'ConstructedConstant(Class6())'),
      ConstantData('const Class7()', 'ConstructedConstant(Class7())'),
      ConstantData(
        'const Class7() == const Class7()',
        'NonConstant',
        expectedError: 'ConstEvalEqualsOperandNotPrimitiveEquality',
      ),
      ConstantData(
        'const Class7() != const Class7()',
        'NonConstant',
        expectedError: 'ConstEvalEqualsOperandNotPrimitiveEquality',
      ),
      ConstantData(
        'const Class8(not_string.length)',
        'NonConstant',
        expectedError: 'ConstEvalInvalidPropertyGet',
      ),
      ConstantData(
        'const Class9()',
        'ConstructedConstant(Class9(field=NullConstant))',
      ),
      ConstantData(
        'const Class10()',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
    ],
  ),
  TestData(
    'assert',
    '''
    const true_ = bool.fromEnvironment('x') ? null : true;
    class A {
      const A() : assert(true);
    }
    class B {
      const B() : assert(true, "Message");
    }
    class C {
      final a;
      const C(this.a);
    }
    class D extends C {
      final b;
      const D(c) : b = c + 2, super(c + 1);
    }
  ''',
    [
      ConstantData(r'const A()', 'ConstructedConstant(A())'),
      ConstantData(r'const B()', 'ConstructedConstant(B())'),
      ConstantData(
        r'const D(0)',
        'ConstructedConstant(D(a=IntConstant(1),b=IntConstant(2)))',
      ),
    ],
  ),
  TestData(
    'instantiations',
    '''
T identity<T>(T t) => t;
class C<T> {
  final T defaultValue;
  final T Function(T t) identityFunction;

  const C(this.defaultValue, this.identityFunction);
}
  ''',
    [
      ConstantData('identity', 'FunctionConstant(identity)'),
      ConstantData(
        'const C<int>(0, identity)',
        'ConstructedConstant(C<int>(defaultValue=IntConstant(0),'
            'identityFunction=InstantiationConstant([int],'
            'FunctionConstant(identity))))',
      ),
      ConstantData(
        'const C<double>(0.5, identity)',
        'ConstructedConstant(C<double>(defaultValue=DoubleConstant(0.5),'
            'identityFunction=InstantiationConstant([double],'
            'FunctionConstant(identity))))',
      ),
    ],
  ),
  TestData(
    'generic class',
    '''
class C<T> {
  const C.generative();
  const C.redirect() : this.generative();
}
  ''',
    <ConstantData>[
      ConstantData(
        'const C<int>.generative()',
        'ConstructedConstant(C<int>())',
      ),
      ConstantData('const C<int>.redirect()', 'ConstructedConstant(C<int>())'),
    ],
  ),
  TestData(
    'instance',
    '''
const dynamic zero_ = bool.fromEnvironment("x") ? null : 0;
class Class9 {
  final field = zero_;
  const Class9();
}
''',
    <ConstantData>[
      ConstantData(
        'const Class9()',
        'ConstructedConstant(Class9(field=IntConstant(0)))',
      ),
    ],
  ),
  TestData(
    'type-variables',
    '''
class A {
  const A();
}

class C1<T> {
  final T a;
  const C1(dynamic t) : a = t; // adds implicit cast `as T`
}

T id<T>(T t) => t;

class C2<T> {
  final T Function(T) a;
  const C2(dynamic t) : a = id; // implicit partial instantiation
}
''',
    <ConstantData>[
      ConstantData(
        'const C1<A>(A())',
        'ConstructedConstant(C1<A>(a=ConstructedConstant(A())))',
      ),
      ConstantData(
        'const C2<A>(id)',
        'ConstructedConstant(C2<A>(a='
            'InstantiationConstant([A],FunctionConstant(id))))',
      ),
    ],
  ),
  TestData(
    'unused-arguments',
    '''
class A {
  const A();

  A operator -() => this;
}
class B implements A {
  const B();

  B operator -() => this;
}
class C implements A {
  const C();

  C operator -() => this;
}
class Class<T extends A> {
  const Class(T t);
  const Class.redirect(dynamic t) : this(t);
  const Class.method(T t) : this(-t);
}
class Subclass<T extends A> extends Class<T> {
  const Subclass(dynamic t) : super(t);
}
''',
    [
      ConstantData(
        'const Class<B>.redirect(C())',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData(
        'const Class<A>.method(A())',
        'NonConstant',
        expectedError:
            'The argument type \'A\' can\'t be '
            'assigned to the parameter type \'T\'.',
      ),
      ConstantData(
        'const Subclass<B>(C())',
        'NonConstant',
        expectedError: 'ConstEvalInvalidType',
      ),
      ConstantData('const Class<A>(A())', 'ConstructedConstant(Class<A>())'),
      ConstantData(
        'const Class<B>.redirect(B())',
        'ConstructedConstant(Class<B>())',
      ),
      ConstantData(
        'const Subclass<A>(A())',
        'ConstructedConstant(Subclass<A>())',
      ),
      ConstantData(
        'const Subclass<B>(B())',
        'ConstructedConstant(Subclass<B>())',
      ),
    ],
  ),
  TestData(
    'Nested Unevaluated',
    '''
class Foo {
  const Foo(
    int Function(String)? a1,
    int Function(String)? a2,
    int Function(String)? a3,
    int Function(String)? a4,
  ) : _foo = a1 ??
            a2 ??
            a3 ??
            a4 ??
            bar;
  final int Function(String) _foo;
}

int bar(String o) => int.parse(o);
 ''',
    [
      ConstantData(
        '''Foo(
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
  )''',
        <Map<String, String>, String>{
          emptyEnv: 'ConstructedConstant(Foo(_foo=FunctionConstant(bar)))',
          const {'baz': 'true'}:
              'ConstructedConstant(Foo(_foo=FunctionConstant(int.parse)))',
        },
      ),
      ConstantData(
        '''String.fromEnvironment(String.fromEnvironment(String.fromEnvironment("foo")))''',
        <Map<String, String>, String>{
          emptyEnv: 'StringConstant("")',
          const {'foo': 'bar', 'bar': 'baz'}: 'StringConstant("")',
          const {'foo': 'bar', 'bar': 'baz', 'baz': 'hello'}:
              'StringConstant("hello")',
          const {'foo': 'bar', 'bar': 'baz', 'baz': 'world'}:
              'StringConstant("world")',
        },
      ),
    ],
  ),
];

Future testData(TestData data) async {
  // Group tests by environment and then by expected error so that we can
  // distinguish which constant triggered which errors in the CFE. There
  // are too many constants to compile each individually, this test would
  // timeout.
  Map<Map<String, String>, Map<String?, List<(ConstantData, String)>>>
  constants = {};
  data.constants.forEach((ConstantData constantData) {
    final expectedResult = constantData.expectedResults;
    if (expectedResult is String) {
      ((constants[emptyEnv] ??= {})[constantData.expectedError] ??= []).add((
        constantData,
        expectedResult,
      ));
    } else if (expectedResult is Map<Map<String, String>, String>) {
      expectedResult.forEach((env, expectedString) {
        ((constants[env] ??= {})[constantData.expectedError] ??= []).add((
          constantData,
          expectedString,
        ));
      });
    }
  });

  for (final env in constants.keys) {
    final expectations = constants[env]!;
    for (final errorString in expectations.keys) {
      StringBuffer sb = StringBuffer();
      sb.writeln('${data.declarations}');
      final constantEntries = expectations[errorString]!;
      final envData = <(String, (ConstantData, String))>[];
      for (final constantEntry in constantEntries) {
        final name = 'c${envData.length}';
        final code = constantEntry.$1.code;
        envData.add((name, constantEntry));
        // Encode the constants as part of a from-environment conditional to
        // force CFE to create unevaluated constants.
        sb.writeln('const $name = bool.fromEnvironment("x") ? null : $code;');
      }
      sb.writeln('main() {');
      for (final (name, _) in envData) {
        sb.writeln('  print($name);');
      }
      sb.writeln('}');
      String source = sb.toString();
      print(
        "--source '${data.name}'-------------------------------------------",
      );
      print("Compiling with env: $env");
      print(source);
      await runEnvTest(env, source, envData, errorString);
    }
  }
}

Future<void> runEnvTest(
  Map<String, String> env,
  String source,
  List<(String, (ConstantData, String))> envData,
  String? expectedError,
) async {
  final diagnosticCollector = DiagnosticCollector();
  CompilationResult result = await runCompiler(
    memorySourceFiles: {'main.dart': source},
    options: [Flags.enableAsserts, Flags.testMode],
    environment: {...env},
    diagnosticHandler: diagnosticCollector,
  );
  Compiler compiler = result.compiler!;
  KernelFrontendStrategy frontEndStrategy = compiler.frontendStrategy;
  KernelToElementMap elementMap = frontEndStrategy.elementMap;
  DartTypes dartTypes = elementMap.types;
  ir.TypeEnvironment typeEnvironment = elementMap.typeEnvironment;
  KElementEnvironment elementEnvironment =
      compiler.frontendStrategy.elementEnvironment;
  ConstantValuefier constantValuefier = ConstantValuefier(elementMap);
  LibraryEntity library = elementEnvironment.mainLibrary!;
  for (final (name, (data, expectedText)) in envData) {
    final field = elementEnvironment.lookupLibraryMember(library, name)!;
    compiler.reporter.withCurrentElement(field, () {
      final node = elementMap.getMemberNode(field) as ir.Field;
      print('-- testing $field = ${data.code} --');
      Dart2jsConstantEvaluator evaluator = Dart2jsConstantEvaluator(
        elementMap.env.mainComponent,
        elementMap.typeEnvironment,
        (ir.LocatedMessage message, List<ir.LocatedMessage>? context) {
          // Constants should be fully evaluated by this point so there should be
          // no new messages.
          throw StateError('There should be no unevaluated errors in the AST.');
        },
        environment: Environment(env),
        supportReevaluationForTesting: true,
      );
      ir.Constant evaluatedConstant = evaluator.evaluate(
        ir.StaticTypeContext(node, typeEnvironment),
        node.initializer!,
      );

      ConstantValue? value = evaluatedConstant is! ir.UnevaluatedConstant
          ? constantValuefier.visitConstant(evaluatedConstant)
          : null;

      String valueText = value?.toStructuredText(dartTypes) ?? 'NonConstant';
      Expect.equals(
        expectedText,
        valueText,
        "Unexpected value '${valueText}' for field $field = "
        "`${data.code}` in env $env, "
        "expected '${expectedText}'.",
      );

      final errors = diagnosticCollector.contexts.map((e) => e.text).toList();
      if (expectedError != null) {
        if (node.initializer is ir.InvalidExpression) {
          Expect.isTrue(
            diagnosticCollector.errors.any(
              (e) => e.text.contains(expectedError),
            ),
            "Error mismatch for `$field = ${data.code}`:\n"
            "Expected to contain: ${expectedError},\n"
            "Found: ${diagnosticCollector.errors.map((e) => e.text)}.",
          );
        } else {
          // There should be 2 errors per constant in this test group, 1 for the
          // declaration and another for the print.
          Expect.equals(envData.length * 2, errors.length);
          Expect.isTrue(
            errors.every((e) => e == expectedError),
            "Error mismatch for `$field = ${data.code}`:\n"
            "Expected: ${expectedError},\n"
            "Found: ${errors}.",
          );
        }
      } else {
        Expect.isTrue(
          diagnosticCollector.contexts.isEmpty,
          "Unexpected errors for `$field = ${data.code}`:\n"
          "Found: ${errors}.",
        );
      }
    });
  }
}

const int totalShards = 2;

void testShard(List<String> args, int shard) {
  if (shard >= totalShards) throw ArgumentError('Shard number invalid: $shard');
  asyncTest(() async {
    int i = 0;
    for (TestData data in DATA) {
      i++;
      if (i % totalShards != shard) continue;
      if (args.isNotEmpty && !args.contains(data.name)) continue;
      await testData(data);
    }
  });
}
