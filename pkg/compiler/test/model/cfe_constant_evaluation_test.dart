// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library dart2js.constants.expressions.evaluate_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/indexed.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/ir/constants.dart';
import 'package:compiler/src/ir/visitors.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;
import 'package:front_end/src/api_unstable/dart2js.dart' as ir;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import '../helpers/memory_compiler.dart';

class TestData {
  final String name;

  /// Declarations needed for the [constants].
  final String declarations;

  /// Tested constants.
  final List<ConstantData> constantsCommon;
  final List<ConstantData> constantsPreNnbd;
  final List<ConstantData> constantsNnbdWeak;
  List<ConstantData> get constants =>
      constantsCommon +
      (isDart2jsNnbd && constantsNnbdWeak.isNotEmpty
          ? constantsNnbdWeak
          : constantsPreNnbd);

  const TestData(this.name, this.declarations,
      {this.constantsCommon: const [],
      this.constantsPreNnbd: const [],
      this.constantsNnbdWeak: const []});
}

class ConstantData {
  /// Source code for the constant expression.
  final String code;

  /// Constant value as structured text for the empty environment or a map from
  /// environment to either the expected constant value as structured text or
  /// a [ConstantResult].
  final expectedResults;

  /// A [String] or a list of [String]s containing the code names for the error
  /// messages expected as the result of evaluating the constant under the empty
  /// environment.
  final expectedErrors;

  const ConstantData(this.code, this.expectedResults, {this.expectedErrors});
}

const List<TestData> DATA = const [
  const TestData('simple', '', constantsCommon: const [
    const ConstantData('null', 'NullConstant'),
    const ConstantData('false', 'BoolConstant(false)'),
    const ConstantData('true', 'BoolConstant(true)'),
    const ConstantData('0', 'IntConstant(0)'),
    const ConstantData('0.0', 'IntConstant(0)'),
    const ConstantData('"foo"', 'StringConstant("foo")'),
    const ConstantData('1 + 2', 'IntConstant(3)'),
    const ConstantData('-(1)', 'IntConstant(-1)'),
    const ConstantData('1 == 2', 'BoolConstant(false)'),
    const ConstantData('1 != 2', 'BoolConstant(true)'),
    const ConstantData('1 / 0', 'DoubleConstant(Infinity)'),
    const ConstantData('0 / 0', 'DoubleConstant(NaN)'),
    const ConstantData('1 << 0', 'IntConstant(1)'),
    const ConstantData('1 >> 0', 'IntConstant(1)'),
    const ConstantData('"foo".length', 'IntConstant(3)'),
    const ConstantData('identical(0, 1)', 'BoolConstant(false)'),
    const ConstantData('"a" "b"', 'StringConstant("ab")'),
    const ConstantData(r'"${null}"', 'StringConstant("null")'),
    const ConstantData('identical', 'FunctionConstant(identical)'),
    const ConstantData('true ? 0 : 1', 'IntConstant(0)'),
    const ConstantData('proxy', 'ConstructedConstant(_Proxy())'),
    const ConstantData('const [] == null', 'BoolConstant(false)'),
    const ConstantData('proxy == null', 'BoolConstant(false)'),
    const ConstantData('proxy != null', 'BoolConstant(true)'),
    const ConstantData('null == proxy', 'BoolConstant(false)'),
    const ConstantData('null != proxy', 'BoolConstant(true)'),
    const ConstantData('true == proxy', 'BoolConstant(false)'),
    const ConstantData('true != proxy', 'BoolConstant(true)'),
    const ConstantData('0 == proxy', 'BoolConstant(false)'),
    const ConstantData('0 != proxy', 'BoolConstant(true)'),
    const ConstantData('0.5 == proxy', 'BoolConstant(false)'),
    const ConstantData('0.5 != proxy', 'BoolConstant(true)'),
    const ConstantData('"" == proxy', 'BoolConstant(false)'),
    const ConstantData('"" != proxy', 'BoolConstant(true)'),
    const ConstantData('Object', 'TypeConstant(Object)'),
    const ConstantData('null ?? 0', 'IntConstant(0)'),
    const ConstantData('const <int, int>{0: 1, 0: 2}', 'NonConstant',
        expectedErrors: 'ConstEvalDuplicateKey'),
    const ConstantData(
        'const bool.fromEnvironment("foo", defaultValue: false)',
        const <Map<String, String>, String>{
          const {}: 'BoolConstant(false)',
          const {'foo': 'true'}: 'BoolConstant(true)'
        }),
    const ConstantData(
        'const int.fromEnvironment("foo", defaultValue: 42)',
        const <Map<String, String>, String>{
          const {}: 'IntConstant(42)',
          const {'foo': '87'}: 'IntConstant(87)'
        }),
    const ConstantData(
        'const String.fromEnvironment("foo", defaultValue: "bar")',
        const <Map<String, String>, String>{
          const {}: 'StringConstant("bar")',
          const {'foo': 'foo'}: 'StringConstant("foo")'
        }),
  ], constantsPreNnbd: const [
    const ConstantData(
        'const [0, 1]', 'ListConstant(<int>[IntConstant(0), IntConstant(1)])'),
    const ConstantData('const <int>[0, 1]',
        'ListConstant(<int>[IntConstant(0), IntConstant(1)])'),
    const ConstantData(
        'const {0, 1}', 'SetConstant(<int>{IntConstant(0), IntConstant(1)})'),
    const ConstantData('const <int>{0, 1}',
        'SetConstant(<int>{IntConstant(0), IntConstant(1)})'),
    const ConstantData(
        'const {0: 1, 2: 3}',
        'MapConstant(<int, int>{IntConstant(0): IntConstant(1), '
            'IntConstant(2): IntConstant(3)})'),
    const ConstantData(
        'const <int, int>{0: 1, 2: 3}',
        'MapConstant(<int, int>{IntConstant(0): IntConstant(1), '
            'IntConstant(2): IntConstant(3)})'),
  ], constantsNnbdWeak: const [
    const ConstantData(
        'const [0, 1]', 'ListConstant(<int*>[IntConstant(0), IntConstant(1)])'),
    const ConstantData('const <int>[0, 1]',
        'ListConstant(<int*>[IntConstant(0), IntConstant(1)])'),
    const ConstantData(
        'const {0, 1}', 'SetConstant(<int*>{IntConstant(0), IntConstant(1)})'),
    const ConstantData('const <int>{0, 1}',
        'SetConstant(<int*>{IntConstant(0), IntConstant(1)})'),
    const ConstantData(
        'const {0: 1, 2: 3}',
        'MapConstant(<int*, int*>{IntConstant(0): IntConstant(1), '
            'IntConstant(2): IntConstant(3)})'),
    const ConstantData(
        'const <int, int>{0: 1, 2: 3}',
        'MapConstant(<int*, int*>{IntConstant(0): IntConstant(1), '
            'IntConstant(2): IntConstant(3)})'),
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
''', constantsCommon: const [
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
    const ConstantData(
        'const C(field1: a, field2: b)', const <Map<String, String>, String>{
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
''', constantsCommon: const [
    const ConstantData(
        'const A()', 'ConstructedConstant(A<dynamic>(field1=IntConstant(42)))'),
  ], constantsPreNnbd: const [
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
  ], constantsNnbdWeak: const [
    const ConstantData('const A<int>(field1: 87)',
        'ConstructedConstant(A<int*>(field1=IntConstant(87)))'),
    const ConstantData('const B()',
        'ConstructedConstant(A<B<dynamic>*>(field1=IntConstant(42)))'),
    const ConstantData('const B<int>()',
        'ConstructedConstant(A<B<int*>*>(field1=IntConstant(42)))'),
    const ConstantData('const B<int>(field1: 87)',
        'ConstructedConstant(A<B<int*>*>(field1=IntConstant(87)))'),
    const ConstantData('const C<int>(field1: 87)',
        'ConstructedConstant(A<B<double*>*>(field1=IntConstant(87)))'),
    const ConstantData('const B<int>.named()',
        'ConstructedConstant(A<int*>(field1=IntConstant(42)))'),
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
''', constantsCommon: const [
    const ConstantData('const A(c, d)', const <Map<String, String>, String>{
      const {}: 'ConstructedConstant(A(field=IntConstant(15)))',
      const {'foo': '7', 'bar': '11'}:
          'ConstructedConstant(A(field=IntConstant(18)))',
    }),
    const ConstantData('const B(d)', const <Map<String, String>, String>{
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
 ''', constantsCommon: const [
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
  const TestData('errors', r'''
 const dynamic null_ = const bool.fromEnvironment('x') ? null : null;
 const dynamic zero = const bool.fromEnvironment('x') ? null : 0;
 const dynamic minus_one = const bool.fromEnvironment('x') ? null : -1;
 const dynamic false_ = const bool.fromEnvironment('x') ? null : false;
 const dynamic integer = const int.fromEnvironment("foo", defaultValue: 5);
 const dynamic string = const String.fromEnvironment("bar", defaultValue: "baz");
 const dynamic boolean = const bool.fromEnvironment("baz", defaultValue: false);
 const dynamic not_string =
    const bool.fromEnvironment("not_string", defaultValue: false) ? '' : 0;
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
 ''', constantsCommon: const [
    const ConstantData(
        r'"$integer $string $boolean"', 'StringConstant("5 baz false")'),
    const ConstantData('integer ? true : false', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData(r'"${proxy}"', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidStringInterpolationOperand'),
    const ConstantData('0 + string', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('string + 0', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidBinaryOperandType'),
    const ConstantData('boolean + string', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidMethodInvocation'),
    const ConstantData('boolean + false', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidMethodInvocation'),
    const ConstantData('0 * string', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('0 % string', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('0 << string', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('1 ~/ zero', 'NonConstant',
        expectedErrors: 'ConstEvalZeroDivisor'),
    const ConstantData('1 % zero', 'NonConstant',
        expectedErrors: 'ConstEvalZeroDivisor'),
    const ConstantData('1 << minus_one', 'NonConstant',
        expectedErrors: 'ConstEvalNegativeShift'),
    const ConstantData('1 >> minus_one', 'NonConstant',
        expectedErrors: 'ConstEvalNegativeShift'),
    const ConstantData('const bool.fromEnvironment(integer)', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData(
        'const bool.fromEnvironment("baz", defaultValue: integer)',
        'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('const int.fromEnvironment(integer)', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData(
        'const int.fromEnvironment("baz", defaultValue: string)', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('const String.fromEnvironment(integer)', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData(
        'const String.fromEnvironment("baz", defaultValue: integer)',
        'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('false || integer', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('integer || true', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('integer && true', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('!integer', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('!string', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('-(string)', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidMethodInvocation'),
    const ConstantData('not_string.length', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidPropertyGet'),
    const ConstantData('const Class1()', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidPropertyGet'),
    const ConstantData('const Class2()', 'NonConstant',
        expectedErrors: 'ConstEvalFailedAssertion'),
    const ConstantData('const Class2.redirect()', 'NonConstant',
        expectedErrors: 'ConstEvalFailedAssertion'),
    const ConstantData('const Class3()', 'NonConstant',
        expectedErrors: 'ConstEvalFailedAssertionWithMessage'),
    const ConstantData('const Class3.fact()', 'NonConstant',
        expectedErrors: 'ConstEvalFailedAssertion'),
    const ConstantData('const Class4()', 'NonConstant',
        expectedErrors: 'ConstEvalFailedAssertion'),
    const ConstantData('const Class5(0)', 'NonConstant',
        expectedErrors: 'ConstEvalFailedAssertionWithMessage'),
    const ConstantData('const Class5(1)', 'ConstructedConstant(Class5())'),
    const ConstantData('const Class6(1)', 'NonConstant',
        expectedErrors: 'ConstEvalFailedAssertionWithMessage'),
    const ConstantData('const Class6(2)', 'ConstructedConstant(Class6())'),
    const ConstantData('const Class7()', 'ConstructedConstant(Class7())'),
    const ConstantData('const Class7() == const Class7()', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidEqualsOperandType'),
    const ConstantData('const Class7() != const Class7()', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidEqualsOperandType'),
    const ConstantData('const Class8(not_string.length)', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidPropertyGet'),
    const ConstantData(
        'const Class9()', 'ConstructedConstant(Class9(field=NullConstant))'),
    const ConstantData('const Class10()', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
  ]),
  const TestData('assert', '''
    const true_ = const bool.fromEnvironment('x') ? null : true;
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
    class E {
      const E() : assert(true_);
    }
  ''', constantsCommon: const [
    const ConstantData(r'const A()', 'ConstructedConstant(A())'),
    const ConstantData(r'const B()', 'ConstructedConstant(B())'),
    const ConstantData(r'const D(0)',
        'ConstructedConstant(D(a=IntConstant(1),b=IntConstant(2)))'),
    const ConstantData(r'const E()', 'ConstructedConstant(E())'),
  ]),
  const TestData('instantiations', '''
T identity<T>(T t) => t;
class C<T> {
  final T defaultValue;
  final T Function(T t) identityFunction;

  const C(this.defaultValue, this.identityFunction);
}
  ''', constantsCommon: [
    const ConstantData('identity', 'FunctionConstant(identity)'),
  ], constantsPreNnbd: const <ConstantData>[
    const ConstantData(
        'const C<int>(0, identity)',
        'ConstructedConstant(C<int>(defaultValue=IntConstant(0),'
            'identityFunction=InstantiationConstant([int],'
            'FunctionConstant(identity))))'),
    const ConstantData(
        'const C<double>(0.5, identity)',
        'ConstructedConstant(C<double>(defaultValue=DoubleConstant(0.5),'
            'identityFunction=InstantiationConstant([double],'
            'FunctionConstant(identity))))'),
  ], constantsNnbdWeak: const <ConstantData>[
    const ConstantData(
        'const C<int>(0, identity)',
        'ConstructedConstant(C<int*>(defaultValue=IntConstant(0),'
            'identityFunction=InstantiationConstant([int*],'
            'FunctionConstant(identity))))'),
    const ConstantData(
        'const C<double>(0.5, identity)',
        'ConstructedConstant(C<double*>(defaultValue=DoubleConstant(0.5),'
            'identityFunction=InstantiationConstant([double*],'
            'FunctionConstant(identity))))'),
  ]),
  const TestData('generic class', '''
class C<T> {
  const C.generative();
  const C.redirect() : this.generative();
}
  ''', constantsPreNnbd: const <ConstantData>[
    const ConstantData(
        'const C<int>.generative()', 'ConstructedConstant(C<int>())'),
    const ConstantData(
        'const C<int>.redirect()', 'ConstructedConstant(C<int>())'),
  ], constantsNnbdWeak: const <ConstantData>[
    const ConstantData(
        'const C<int>.generative()', 'ConstructedConstant(C<int*>())'),
    const ConstantData(
        'const C<int>.redirect()', 'ConstructedConstant(C<int*>())'),
  ]),
  const TestData('instance', '''
const dynamic zero_ = const bool.fromEnvironment("x") ? null : 0;
class Class9 {
  final field = zero_;
  const Class9();
}
''', constantsCommon: const <ConstantData>[
    const ConstantData(
        'const Class9()', 'ConstructedConstant(Class9(field=IntConstant(0)))'),
  ]),
  const TestData('type-variables', '''
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
''', constantsPreNnbd: const <ConstantData>[
    const ConstantData('const C1<A>(const A())',
        'ConstructedConstant(C1<A>(a=ConstructedConstant(A())))'),
    const ConstantData(
        'const C2<A>(id)',
        'ConstructedConstant(C2<A>(a='
            'InstantiationConstant([A],FunctionConstant(id))))'),
  ], constantsNnbdWeak: const <ConstantData>[
    const ConstantData('const C1<A>(const A())',
        'ConstructedConstant(C1<A*>(a=ConstructedConstant(A())))'),
    const ConstantData(
        'const C2<A>(id)',
        'ConstructedConstant(C2<A*>(a='
            'InstantiationConstant([A*],FunctionConstant(id))))'),
  ]),
  const TestData('unused-arguments', '''
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
''', constantsCommon: [
    const ConstantData('const Class<B>.redirect(const C())', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
    const ConstantData('const Class<A>.method(const A())', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidMethodInvocation'),
    const ConstantData('const Subclass<B>(const C())', 'NonConstant',
        expectedErrors: 'ConstEvalInvalidType'),
  ], constantsPreNnbd: const <ConstantData>[
    const ConstantData(
        'const Class<A>(const A())', 'ConstructedConstant(Class<A>())'),
    const ConstantData('const Class<B>.redirect(const B())',
        'ConstructedConstant(Class<B>())'),
    const ConstantData(
        'const Subclass<A>(const A())', 'ConstructedConstant(Subclass<A>())'),
    const ConstantData(
        'const Subclass<B>(const B())', 'ConstructedConstant(Subclass<B>())'),
  ], constantsNnbdWeak: const <ConstantData>[
    const ConstantData(
        'const Class<A>(const A())', 'ConstructedConstant(Class<A*>())'),
    const ConstantData('const Class<B>.redirect(const B())',
        'ConstructedConstant(Class<B*>())'),
    const ConstantData(
        'const Subclass<A>(const A())', 'ConstructedConstant(Subclass<A*>())'),
    const ConstantData(
        'const Subclass<B>(const B())', 'ConstructedConstant(Subclass<B*>())'),
  ]),
];

main(List<String> args) {
  asyncTest(() async {
    for (TestData data in DATA) {
      if (args.isNotEmpty && !args.contains(data.name)) continue;
      await testData(data);
    }
  });
}

Future testData(TestData data) async {
  StringBuffer sb = new StringBuffer();
  sb.writeln('${data.declarations}');
  Map<String, ConstantData> constants = {};
  List<String> names = <String>[];
  data.constants.forEach((ConstantData constantData) {
    String name = 'c${constants.length}';
    names.add(name);
    // Encode the constants as part of a from-environment conditional to force
    // CFE to create unevaluated constants.
    sb.writeln('const $name = const bool.fromEnvironment("x") ? '
        'null : ${constantData.code};');
    constants[name] = constantData;
  });
  sb.writeln('main() {');
  for (String name in names) {
    sb.writeln('  print($name);');
  }
  sb.writeln('}');
  String source = sb.toString();
  print("--source '${data.name}'---------------------------------------------");
  print(source);

  Future runTest() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': source},
        options: [Flags.enableAsserts]);
    Compiler compiler = result.compiler;
    KernelFrontendStrategy frontEndStrategy = compiler.frontendStrategy;
    KernelToElementMapImpl elementMap = frontEndStrategy.elementMap;
    DartTypes dartTypes = elementMap.types;
    ir.TypeEnvironment typeEnvironment = elementMap.typeEnvironment;
    KElementEnvironment elementEnvironment =
        compiler.frontendStrategy.elementEnvironment;
    ConstantValuefier constantValuefier = new ConstantValuefier(elementMap);
    LibraryEntity library = elementEnvironment.mainLibrary;
    constants.forEach((String name, ConstantData data) {
      IndexedField field =
          elementEnvironment.lookupLibraryMember(library, name);
      compiler.reporter.withCurrentElement(field, () {
        var expectedResults = data.expectedResults;
        if (expectedResults is String) {
          expectedResults = <Map<String, String>, String>{
            const <String, String>{}: expectedResults
          };
        }
        ir.Field node = elementMap.getMemberNode(field);
        ir.ConstantExpression initializer = node.initializer;
        print('-- testing $field = ${data.code} --');
        expectedResults
            .forEach((Map<String, String> environment, String expectedText) {
          List<String> errors = [];
          Dart2jsConstantEvaluator evaluator =
              new Dart2jsConstantEvaluator(elementMap.typeEnvironment,
                  (ir.LocatedMessage message, List<ir.LocatedMessage> context) {
            // TODO(johnniwinther): Assert that `message.uri != null`. Currently
            // all unevaluated constants have no uri.
            // The actual message is a "constant errors starts here" message,
            // the "real error message" is the first in the context.
            errors.add(context.first.code.name);
            reportLocatedMessage(elementMap.reporter, message, context);
          },
                  environment: environment,
                  supportReevaluationForTesting: true,
                  evaluationMode: compiler.options.useLegacySubtyping
                      ? ir.EvaluationMode.weak
                      : ir.EvaluationMode.strong);
          ir.Constant evaluatedConstant = evaluator.evaluate(
              new ir.StaticTypeContext(node, typeEnvironment), initializer);

          ConstantValue value = evaluatedConstant is! ir.UnevaluatedConstant
              ? constantValuefier.visitConstant(evaluatedConstant)
              : new NonConstantValue();

          Expect.isNotNull(
              value,
              "Expected non-null value from evaluation of "
              "`${data.code}`.");

          String valueText = value.toStructuredText(dartTypes);
          Expect.equals(
              expectedText,
              valueText,
              "Unexpected value '${valueText}' for field $field = "
              "`${data.code}` in env $environment, "
              "expected '${expectedText}'.");

          var expectedErrors = data.expectedErrors;
          if (expectedErrors != null) {
            if (expectedErrors is! List) {
              expectedErrors = [expectedErrors];
            }
            Expect.listEquals(
                expectedErrors,
                errors,
                "Error mismatch for `$field = ${data.code}`:\n"
                "Expected: ${data.expectedErrors},\n"
                "Found: ${errors}.");
          } else {
            Expect.isTrue(
                errors.isEmpty,
                "Unexpected errors for `$field = ${data.code}`:\n"
                "Found: ${errors}.");
          }
        });
      });
    });
  }

  await runTest();
}
