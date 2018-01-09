// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart' show ClassEntity;
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:expect/expect.dart';
import 'type_test_helper.dart';

void main() {
  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(CompileMode.memory);
    print('--test from kernel------------------------------------------------');
    await runTests(CompileMode.kernel);
  });
}

Future runTests(CompileMode compileMode) async {
  await testInterfaceSubtype(compileMode);
  await testCallableSubtype(compileMode);
  await testFunctionSubtyping(compileMode);
  await testTypedefSubtyping(compileMode);
  await testFunctionSubtypingOptional(compileMode);
  await testTypedefSubtypingOptional(compileMode);
  await testFunctionSubtypingNamed(compileMode);
  await testTypedefSubtypingNamed(compileMode);
  await testTypeVariableSubtype(compileMode);
}

void testTypes(TypeEnvironment env, DartType subtype, DartType supertype,
    bool expectSubtype, bool expectMoreSpecific) {
  if (expectMoreSpecific == null) expectMoreSpecific = expectSubtype;
  Expect.equals(expectSubtype, env.isSubtype(subtype, supertype),
      '$subtype <: $supertype');
  if (env.types is Types) {
    Expect.equals(expectMoreSpecific, env.isMoreSpecific(subtype, supertype),
        '$subtype << $supertype');
  }
}

void testElementTypes(TypeEnvironment env, String subname, String supername,
    bool expectSubtype, bool expectMoreSpecific) {
  DartType subtype = env.getElementType(subname);
  DartType supertype = env.getElementType(supername);
  testTypes(env, subtype, supertype, expectSubtype, expectMoreSpecific);
}

Future testInterfaceSubtype(CompileMode compileMode) async {
  await TypeEnvironment.create(r"""
      class A<T> {}
      class B<T1, T2> extends A<T1> {}
      // TODO(johnniwinther): Inheritance with different type arguments is
      // currently not supported by the implementation.
      class C<T1, T2> extends B<T2, T1> /*implements A<A<T1>>*/ {}
      """, compileMode: compileMode).then((env) {
    void expect(bool expectSubtype, DartType T, DartType S,
        {bool expectMoreSpecific}) {
      testTypes(env, T, S, expectSubtype, expectMoreSpecific);
    }

    ClassEntity A = env.getClass('A');
    ClassEntity B = env.getClass('B');
    ClassEntity C = env.getClass('C');
    DartType Object_ = env['Object'];
    DartType num_ = env['num'];
    DartType int_ = env['int'];
    DartType String_ = env['String'];
    DartType dynamic_ = env['dynamic'];
    DartType void_ = env['void'];
    DartType Null_ = env['Null'];

    expect(true, void_, void_);
    expect(true, void_, dynamic_);
    // Unsure about the next one, see dartbug.com/14933.
    expect(true, dynamic_, void_, expectMoreSpecific: false);
    expect(false, void_, Object_);
    expect(false, Object_, void_);
    expect(true, Null_, void_);

    expect(true, Object_, Object_);
    expect(true, num_, Object_);
    expect(true, int_, Object_);
    expect(true, String_, Object_);
    expect(true, dynamic_, Object_, expectMoreSpecific: false);
    expect(true, Null_, Object_);

    expect(false, Object_, num_);
    expect(true, num_, num_);
    expect(true, int_, num_);
    expect(false, String_, num_);
    expect(true, dynamic_, num_, expectMoreSpecific: false);
    expect(true, Null_, num_);

    expect(false, Object_, int_);
    expect(false, num_, int_);
    expect(true, int_, int_);
    expect(false, String_, int_);
    expect(true, dynamic_, int_, expectMoreSpecific: false);
    expect(true, Null_, int_);

    expect(false, Object_, String_);
    expect(false, num_, String_);
    expect(false, int_, String_);
    expect(true, String_, String_);
    expect(true, dynamic_, String_, expectMoreSpecific: false);
    expect(true, Null_, String_);

    expect(true, Object_, dynamic_);
    expect(true, num_, dynamic_);
    expect(true, int_, dynamic_);
    expect(true, String_, dynamic_);
    expect(true, dynamic_, dynamic_);
    expect(true, Null_, dynamic_);

    expect(false, Object_, Null_);
    expect(false, num_, Null_);
    expect(false, int_, Null_);
    expect(false, String_, Null_);
    expect(true, dynamic_, Null_, expectMoreSpecific: false);
    expect(true, Null_, Null_);

    DartType A_Object = instantiate(A, [Object_]);
    DartType A_num = instantiate(A, [num_]);
    DartType A_int = instantiate(A, [int_]);
    DartType A_String = instantiate(A, [String_]);
    DartType A_dynamic = instantiate(A, [dynamic_]);
    DartType A_Null = instantiate(A, [Null_]);

    expect(true, A_Object, Object_);
    expect(false, A_Object, num_);
    expect(false, A_Object, int_);
    expect(false, A_Object, String_);
    expect(true, A_Object, dynamic_);
    expect(false, A_Object, Null_);

    expect(true, A_Object, A_Object);
    expect(true, A_num, A_Object);
    expect(true, A_int, A_Object);
    expect(true, A_String, A_Object);
    expect(true, A_dynamic, A_Object, expectMoreSpecific: false);
    expect(true, A_Null, A_Object);

    expect(false, A_Object, A_num);
    expect(true, A_num, A_num);
    expect(true, A_int, A_num);
    expect(false, A_String, A_num);
    expect(true, A_dynamic, A_num, expectMoreSpecific: false);
    expect(true, A_Null, A_num);

    expect(false, A_Object, A_int);
    expect(false, A_num, A_int);
    expect(true, A_int, A_int);
    expect(false, A_String, A_int);
    expect(true, A_dynamic, A_int, expectMoreSpecific: false);
    expect(true, A_Null, A_int);

    expect(false, A_Object, A_String);
    expect(false, A_num, A_String);
    expect(false, A_int, A_String);
    expect(true, A_String, A_String);
    expect(true, A_dynamic, A_String, expectMoreSpecific: false);
    expect(true, A_Null, A_String);

    expect(true, A_Object, A_dynamic);
    expect(true, A_num, A_dynamic);
    expect(true, A_int, A_dynamic);
    expect(true, A_String, A_dynamic);
    expect(true, A_dynamic, A_dynamic);
    expect(true, A_Null, A_dynamic);

    expect(false, A_Object, A_Null);
    expect(false, A_num, A_Null);
    expect(false, A_int, A_Null);
    expect(false, A_String, A_Null);
    expect(true, A_dynamic, A_Null, expectMoreSpecific: false);
    expect(true, A_Null, A_Null);

    DartType B_Object_Object = instantiate(B, [Object_, Object_]);
    DartType B_num_num = instantiate(B, [num_, num_]);
    DartType B_int_num = instantiate(B, [int_, num_]);
    DartType B_dynamic_dynamic = instantiate(B, [dynamic_, dynamic_]);
    DartType B_String_dynamic = instantiate(B, [String_, dynamic_]);

    expect(true, B_Object_Object, Object_);
    expect(true, B_Object_Object, A_Object);
    expect(false, B_Object_Object, A_num);
    expect(false, B_Object_Object, A_int);
    expect(false, B_Object_Object, A_String);
    expect(true, B_Object_Object, A_dynamic);

    expect(true, B_num_num, Object_);
    expect(true, B_num_num, A_Object);
    expect(true, B_num_num, A_num);
    expect(false, B_num_num, A_int);
    expect(false, B_num_num, A_String);
    expect(true, B_num_num, A_dynamic);

    expect(true, B_int_num, Object_);
    expect(true, B_int_num, A_Object);
    expect(true, B_int_num, A_num);
    expect(true, B_int_num, A_int);
    expect(false, B_int_num, A_String);
    expect(true, B_int_num, A_dynamic);

    expect(true, B_dynamic_dynamic, Object_);
    expect(true, B_dynamic_dynamic, A_Object, expectMoreSpecific: false);
    expect(true, B_dynamic_dynamic, A_num, expectMoreSpecific: false);
    expect(true, B_dynamic_dynamic, A_int, expectMoreSpecific: false);
    expect(true, B_dynamic_dynamic, A_String, expectMoreSpecific: false);
    expect(true, B_dynamic_dynamic, A_dynamic);

    expect(true, B_String_dynamic, Object_);
    expect(true, B_String_dynamic, A_Object);
    expect(false, B_String_dynamic, A_num);
    expect(false, B_String_dynamic, A_int);
    expect(true, B_String_dynamic, A_String);
    expect(true, B_String_dynamic, A_dynamic);

    expect(true, B_Object_Object, B_Object_Object);
    expect(true, B_num_num, B_Object_Object);
    expect(true, B_int_num, B_Object_Object);
    expect(true, B_dynamic_dynamic, B_Object_Object, expectMoreSpecific: false);
    expect(true, B_String_dynamic, B_Object_Object, expectMoreSpecific: false);

    expect(false, B_Object_Object, B_num_num);
    expect(true, B_num_num, B_num_num);
    expect(true, B_int_num, B_num_num);
    expect(true, B_dynamic_dynamic, B_num_num, expectMoreSpecific: false);
    expect(false, B_String_dynamic, B_num_num);

    expect(false, B_Object_Object, B_int_num);
    expect(false, B_num_num, B_int_num);
    expect(true, B_int_num, B_int_num);
    expect(true, B_dynamic_dynamic, B_int_num, expectMoreSpecific: false);
    expect(false, B_String_dynamic, B_int_num);

    expect(true, B_Object_Object, B_dynamic_dynamic);
    expect(true, B_num_num, B_dynamic_dynamic);
    expect(true, B_int_num, B_dynamic_dynamic);
    expect(true, B_dynamic_dynamic, B_dynamic_dynamic);
    expect(true, B_String_dynamic, B_dynamic_dynamic);

    expect(false, B_Object_Object, B_String_dynamic);
    expect(false, B_num_num, B_String_dynamic);
    expect(false, B_int_num, B_String_dynamic);
    expect(true, B_dynamic_dynamic, B_String_dynamic,
        expectMoreSpecific: false);
    expect(true, B_String_dynamic, B_String_dynamic);

    DartType C_Object_Object = instantiate(C, [Object_, Object_]);
    DartType C_num_num = instantiate(C, [num_, num_]);
    DartType C_int_String = instantiate(C, [int_, String_]);
    DartType C_dynamic_dynamic = instantiate(C, [dynamic_, dynamic_]);

    expect(true, C_Object_Object, B_Object_Object);
    expect(false, C_Object_Object, B_num_num);
    expect(false, C_Object_Object, B_int_num);
    expect(true, C_Object_Object, B_dynamic_dynamic);
    expect(false, C_Object_Object, B_String_dynamic);

    expect(true, C_num_num, B_Object_Object);
    expect(true, C_num_num, B_num_num);
    expect(false, C_num_num, B_int_num);
    expect(true, C_num_num, B_dynamic_dynamic);
    expect(false, C_num_num, B_String_dynamic);

    expect(true, C_int_String, B_Object_Object);
    expect(false, C_int_String, B_num_num);
    expect(false, C_int_String, B_int_num);
    expect(true, C_int_String, B_dynamic_dynamic);
    expect(true, C_int_String, B_String_dynamic);

    expect(true, C_dynamic_dynamic, B_Object_Object, expectMoreSpecific: false);
    expect(true, C_dynamic_dynamic, B_num_num, expectMoreSpecific: false);
    expect(true, C_dynamic_dynamic, B_int_num, expectMoreSpecific: false);
    expect(true, C_dynamic_dynamic, B_dynamic_dynamic);
    expect(true, C_dynamic_dynamic, B_String_dynamic,
        expectMoreSpecific: false);

    expect(false, C_int_String, A_int);
    expect(true, C_int_String, A_String);
    // TODO(johnniwinther): Inheritance with different type arguments is
    // currently not supported by the implementation.
    //expect(true, C_int_String, instantiate(A, [A_int]));
    expect(false, C_int_String, instantiate(A, [A_String]));
  });
}

Future testCallableSubtype(CompileMode compileMode) async {
  await TypeEnvironment.create(r"""
      class U {}
      class V extends U {}
      class W extends V {}
      class A {
        int call(V v, int i) => null;

        int m1(U u, int i) => null;
        int m2(W w, num n) => null;
        U m3(V v, int i) => null;
        int m4(V v, U u) => null;
        void m5(V v, int i) => null;
      }
      """, compileMode: compileMode).then((env) {
    void expect(bool expectSubtype, DartType T, DartType S,
        {bool expectMoreSpecific}) {
      testTypes(env, T, S, expectSubtype, expectMoreSpecific);
    }

    ClassEntity classA = env.getClass('A');
    DartType A = env.elementEnvironment.getRawType(classA);
    DartType function = env['Function'];
    DartType call = env.getMemberType(classA, 'call');
    DartType m1 = env.getMemberType(classA, 'm1');
    DartType m2 = env.getMemberType(classA, 'm2');
    DartType m3 = env.getMemberType(classA, 'm3');
    DartType m4 = env.getMemberType(classA, 'm4');
    DartType m5 = env.getMemberType(classA, 'm5');

    expect(true, A, function);
    expect(true, A, call);
    expect(true, call, m1);
    expect(true, A, m1);
    expect(true, A, m2, expectMoreSpecific: false);
    expect(false, A, m3);
    expect(false, A, m4);
    expect(true, A, m5);
  });
}

const List<FunctionTypeData> functionTypesData = const <FunctionTypeData>[
  const FunctionTypeData('', '_', '()'),
  const FunctionTypeData('void', 'void_', '()'),
  const FunctionTypeData('void', 'void_2', '()'),
  const FunctionTypeData('int', 'int_', '()'),
  const FunctionTypeData('int', 'int_2', '()'),
  const FunctionTypeData('Object', 'Object_', '()'),
  const FunctionTypeData('double', 'double_', '()'),
  const FunctionTypeData('void', 'void__int', '(int i)'),
  const FunctionTypeData('int', 'int__int', '(int i)'),
  const FunctionTypeData('int', 'int__int2', '(int i)'),
  const FunctionTypeData('int', 'int__Object', '(Object o)'),
  const FunctionTypeData('Object', 'Object__int', '(int i)'),
  const FunctionTypeData('int', 'int__double', '(double d)'),
  const FunctionTypeData('int', 'int__int_int', '(int i1, int i2)'),
  const FunctionTypeData('void', 'inline_void_', '(void Function() f)'),
  const FunctionTypeData(
      'void', 'inline_void__int', '(void Function(int i) f)'),
];

Future testFunctionSubtyping(CompileMode compileMode) async {
  await TypeEnvironment
      .create(createMethods(functionTypesData), compileMode: compileMode)
      .then(functionSubtypingHelper);
}

Future testTypedefSubtyping(CompileMode compileMode) async {
  await TypeEnvironment
      .create(createTypedefs(functionTypesData), compileMode: compileMode)
      .then(functionSubtypingHelper);
}

functionSubtypingHelper(TypeEnvironment env) {
  void expect(bool expectSubtype, String sub, String sup,
      {bool expectMoreSpecific}) {
    testElementTypes(env, sub, sup, expectSubtype, expectMoreSpecific);
  }

  // () -> int <: Function
  expect(true, 'int_', 'Function');
  // Function <: () -> int
  expect(false, 'Function', 'int_');

  // () -> dynamic <: () -> dynamic
  expect(true, '_', '_');
  // () -> dynamic <: () -> void
  expect(true, '_', 'void_');
  // () -> void <: () -> dynamic
  expect(true, 'void_', '_', expectMoreSpecific: false);

  // () -> int <: () -> void
  expect(true, 'int_', 'void_');
  // () -> void <: () -> int
  expect(false, 'void_', 'int_');
  // () -> void <: () -> void
  expect(true, 'void_', 'void_2');
  // () -> int <: () -> int
  expect(true, 'int_', 'int_2');
  // () -> int <: () -> Object
  expect(true, 'int_', 'Object_');
  // () -> int <: () -> double
  expect(false, 'int_', 'double_');
  // () -> int <: (int) -> void
  expect(false, 'int_', 'void__int');
  // () -> void <: (int) -> int
  expect(false, 'void_', 'int__int');
  // () -> void <: (int) -> void
  expect(false, 'void_', 'void__int');
  // (int) -> int <: (int) -> int
  expect(true, 'int__int', 'int__int2');
  // (Object) -> int <: (int) -> Object
  expect(true, 'int__Object', 'Object__int', expectMoreSpecific: false);
  // (int) -> int <: (double) -> int
  expect(false, 'int__int', 'int__double');
  // () -> int <: (int) -> int
  expect(false, 'int_', 'int__int');
  // (int) -> int <: (int,int) -> int
  expect(false, 'int__int', 'int__int_int');
  // (int,int) -> int <: (int) -> int
  expect(false, 'int__int_int', 'int__int');
  // (()->void) -> void <: ((int)->void) -> void
  expect(false, 'inline_void_', 'inline_void__int');
  // ((int)->void) -> void <: (()->void) -> void
  expect(false, 'inline_void__int', 'inline_void_');
}

const List<FunctionTypeData> optionalFunctionTypesData =
    const <FunctionTypeData>[
  const FunctionTypeData('void', 'void_', '()'),
  const FunctionTypeData('void', 'void__int', '(int i)'),
  const FunctionTypeData('void', 'void___int', '([int i])'),
  const FunctionTypeData('void', 'void___int2', '([int i])'),
  const FunctionTypeData('void', 'void___Object', '([Object o])'),
  const FunctionTypeData('void', 'void__int__int', '(int i1, [int i2])'),
  const FunctionTypeData('void', 'void__int__int2', '(int i1, [int i2])'),
  const FunctionTypeData(
      'void', 'void__int__int_int', '(int i1, [int i2, int i3])'),
  const FunctionTypeData('void', 'void___double', '(double d)'),
  const FunctionTypeData('void', 'void___int_int', '([int i1, int i2])'),
  const FunctionTypeData(
      'void', 'void___int_int_int', '([int i1, int i2, int i3])'),
  const FunctionTypeData('void', 'void___Object_int', '([Object o, int i])'),
];

Future testFunctionSubtypingOptional(CompileMode compileMode) async {
  await TypeEnvironment
      .create(createMethods(optionalFunctionTypesData),
          compileMode: compileMode)
      .then(functionSubtypingOptionalHelper);
}

Future testTypedefSubtypingOptional(CompileMode compileMode) async {
  await TypeEnvironment
      .create(createTypedefs(optionalFunctionTypesData),
          compileMode: compileMode)
      .then(functionSubtypingOptionalHelper);
}

functionSubtypingOptionalHelper(TypeEnvironment env) {
  void expect(bool expectSubtype, String sub, String sup,
      {bool expectMoreSpecific}) {
    testElementTypes(env, sub, sup, expectSubtype, expectMoreSpecific);
  }

  // Test ([int])->void <: ()->void.
  expect(true, 'void___int', 'void_');
  // Test ([int])->void <: (int)->void.
  expect(true, 'void___int', 'void__int');
  // Test (int)->void <: ([int])->void.
  expect(false, 'void__int', 'void___int');
  // Test ([int])->void <: ([int])->void.
  expect(true, 'void___int', 'void___int2');
  // Test ([Object])->void <: ([int])->void.
  expect(true, 'void___Object', 'void___int', expectMoreSpecific: false);
  // Test ([int])->void <: ([Object])->void.
  expect(true, 'void___int', 'void___Object');
  // Test (int,[int])->void <: (int)->void.
  expect(true, 'void__int__int', 'void__int');
  // Test (int,[int])->void <: (int,[int])->void.
  expect(true, 'void__int__int', 'void__int__int2');
  // Test (int)->void <: ([int])->void.
  expect(false, 'void__int', 'void___int');
  // Test ([int,int])->void <: (int)->void.
  expect(true, 'void___int_int', 'void__int');
  // Test ([int,int])->void <: (int,[int])->void.
  expect(true, 'void___int_int', 'void__int__int');
  // Test ([int,int])->void <: (int,[int,int])->void.
  expect(false, 'void___int_int', 'void__int__int_int');
  // Test ([int,int,int])->void <: (int,[int,int])->void.
  expect(true, 'void___int_int_int', 'void__int__int_int');
  // Test ([int])->void <: ([double])->void.
  expect(false, 'void___int', 'void___double');
  // Test ([int])->void <: ([int,int])->void.
  expect(false, 'void___int', 'void___int_int');
  // Test ([int,int])->void <: ([int])->void.
  expect(true, 'void___int_int', 'void___int');
  // Test ([Object,int])->void <: ([int])->void.
  expect(true, 'void___Object_int', 'void___int', expectMoreSpecific: false);
}

const List<FunctionTypeData> namedFunctionTypesData = const <FunctionTypeData>[
  const FunctionTypeData('void', 'void_', '()'),
  const FunctionTypeData('void', 'void__int', '(int i)'),
  const FunctionTypeData('void', 'void___a_int', '({int a})'),
  const FunctionTypeData('void', 'void___a_int2', '({int a})'),
  const FunctionTypeData('void', 'void___b_int', '({int b})'),
  const FunctionTypeData('void', 'void___a_Object', '({Object a})'),
  const FunctionTypeData('void', 'void__int__a_int', '(int i1, {int a})'),
  const FunctionTypeData('void', 'void__int__a_int2', '(int i1, {int a})'),
  const FunctionTypeData('void', 'void___a_double', '({double a})'),
  const FunctionTypeData('void', 'void___a_int_b_int', '({int a, int b})'),
  const FunctionTypeData(
      'void', 'void___a_int_b_int_c_int', '({int a, int b, int c})'),
  const FunctionTypeData('void', 'void___a_int_c_int', '({int a, int c})'),
  const FunctionTypeData('void', 'void___b_int_c_int', '({int b, int c})'),
  const FunctionTypeData('void', 'void___c_int', '({int c})'),
];

Future testFunctionSubtypingNamed(CompileMode compileMode) async {
  await TypeEnvironment
      .create(createMethods(namedFunctionTypesData), compileMode: compileMode)
      .then(functionSubtypingNamedHelper);
}

Future testTypedefSubtypingNamed(CompileMode compileMode) async {
  await TypeEnvironment
      .create(createTypedefs(namedFunctionTypesData), compileMode: compileMode)
      .then(functionSubtypingNamedHelper);
}

functionSubtypingNamedHelper(TypeEnvironment env) {
  expect(bool expectSubtype, String sub, String sup,
      {bool expectMoreSpecific}) {
    testElementTypes(env, sub, sup, expectSubtype, expectMoreSpecific);
  }

  // Test ({int a})->void <: ()->void.
  expect(true, 'void___a_int', 'void_');
  // Test ({int a})->void <: (int)->void.
  expect(false, 'void___a_int', 'void__int');
  // Test (int)->void <: ({int a})->void.
  expect(false, 'void__int', 'void___a_int');
  // Test ({int a})->void <: ({int a})->void.
  expect(true, 'void___a_int', 'void___a_int2');
  // Test ({int a})->void <: ({int b})->void.
  expect(false, 'void___a_int', 'void___b_int');
  // Test ({Object a})->void <: ({int a})->void.
  expect(true, 'void___a_Object', 'void___a_int', expectMoreSpecific: false);
  // Test ({int a})->void <: ({Object a})->void.
  expect(true, 'void___a_int', 'void___a_Object');
  // Test (int,{int a})->void <: (int,{int a})->void.
  expect(true, 'void__int__a_int', 'void__int__a_int2');
  // Test ({int a})->void <: ({double a})->void.
  expect(false, 'void___a_int', 'void___a_double');
  // Test ({int a})->void <: ({int a,int b})->void.
  expect(false, 'void___a_int', 'void___a_int_b_int');
  // Test ({int a,int b})->void <: ({int a})->void.
  expect(true, 'void___a_int_b_int', 'void___a_int');
  // Test ({int a,int b,int c})->void <: ({int a,int c})->void.
  expect(true, 'void___a_int_b_int_c_int', 'void___a_int_c_int');
  // Test ({int a,int b,int c})->void <: ({int b,int c})->void.
  expect(true, 'void___a_int_b_int_c_int', 'void___b_int_c_int');
  // Test ({int a,int b,int c})->void <: ({int c})->void.
  expect(true, 'void___a_int_b_int_c_int', 'void___c_int');
}

Future testTypeVariableSubtype(CompileMode compileMode) async {
  await TypeEnvironment.create(r"""
      class A<T> {}
      class B<T extends Object> {}
      class C<T extends num> {}
      class D<T extends int> {}
      class E<T extends S, S extends num> {}
      class F<T extends num, S extends T> {}
      class G<T extends T> {}
      class H<T extends S, S extends T> {}
      class I<T extends S, S extends U, U extends T> {}
      class J<T extends S, S extends U, U extends S> {}
      """, compileMode: compileMode).then((env) {
    void expect(bool expectSubtype, DartType T, DartType S,
        {bool expectMoreSpecific}) {
      testTypes(env, T, S, expectSubtype, expectMoreSpecific);
    }

    TypeVariableType getTypeVariable(ClassEntity cls, int index) {
      return env.elementEnvironment.getThisType(cls).typeArguments[index];
    }

    ClassEntity A = env.getClass('A');
    TypeVariableType A_T = getTypeVariable(A, 0);
    ClassEntity B = env.getClass('B');
    TypeVariableType B_T = getTypeVariable(B, 0);
    ClassEntity C = env.getClass('C');
    TypeVariableType C_T = getTypeVariable(C, 0);
    ClassEntity D = env.getClass('D');
    TypeVariableType D_T = getTypeVariable(D, 0);
    ClassEntity E = env.getClass('E');
    TypeVariableType E_T = getTypeVariable(E, 0);
    TypeVariableType E_S = getTypeVariable(E, 1);
    ClassEntity F = env.getClass('F');
    TypeVariableType F_T = getTypeVariable(F, 0);
    TypeVariableType F_S = getTypeVariable(F, 1);
    ClassEntity G = env.getClass('G');
    TypeVariableType G_T = getTypeVariable(G, 0);
    ClassEntity H = env.getClass('H');
    TypeVariableType H_T = getTypeVariable(H, 0);
    TypeVariableType H_S = getTypeVariable(H, 1);
    ClassEntity I = env.getClass('I');
    TypeVariableType I_T = getTypeVariable(I, 0);
    TypeVariableType I_S = getTypeVariable(I, 1);
    TypeVariableType I_U = getTypeVariable(I, 2);
    ClassEntity J = env.getClass('J');
    TypeVariableType J_T = getTypeVariable(J, 0);
    TypeVariableType J_S = getTypeVariable(J, 1);
    TypeVariableType J_U = getTypeVariable(J, 2);

    DartType Object_ = env['Object'];
    DartType num_ = env['num'];
    DartType int_ = env['int'];
    DartType String_ = env['String'];
    DartType dynamic_ = env['dynamic'];

    // class A<T> {}
    expect(true, A_T, Object_);
    expect(false, A_T, num_);
    expect(false, A_T, int_);
    expect(false, A_T, String_);
    expect(true, A_T, dynamic_);
    expect(true, A_T, A_T);
    expect(false, A_T, B_T);

    // class B<T extends Object> {}
    expect(true, B_T, Object_);
    expect(false, B_T, num_);
    expect(false, B_T, int_);
    expect(false, B_T, String_);
    expect(true, B_T, dynamic_);
    expect(true, B_T, B_T);
    expect(false, B_T, A_T);

    // class C<T extends num> {}
    expect(true, C_T, Object_);
    expect(true, C_T, num_);
    expect(false, C_T, int_);
    expect(false, C_T, String_);
    expect(true, C_T, dynamic_);
    expect(true, C_T, C_T);
    expect(false, C_T, A_T);

    // class D<T extends int> {}
    expect(true, D_T, Object_);
    expect(true, D_T, num_);
    expect(true, D_T, int_);
    expect(false, D_T, String_);
    expect(true, D_T, dynamic_);
    expect(true, D_T, D_T);
    expect(false, D_T, A_T);

    // class E<T extends S, S extends num> {}
    expect(true, E_T, Object_);
    expect(true, E_T, num_);
    expect(false, E_T, int_);
    expect(false, E_T, String_);
    expect(true, E_T, dynamic_);
    expect(true, E_T, E_T);
    expect(true, E_T, E_S);
    expect(false, E_T, A_T);

    expect(true, E_S, Object_);
    expect(true, E_S, num_);
    expect(false, E_S, int_);
    expect(false, E_S, String_);
    expect(true, E_S, dynamic_);
    expect(false, E_S, E_T);
    expect(true, E_S, E_S);
    expect(false, E_S, A_T);

    // class F<T extends num, S extends T> {}
    expect(true, F_T, Object_);
    expect(true, F_T, num_);
    expect(false, F_T, int_);
    expect(false, F_T, String_);
    expect(true, F_T, dynamic_);
    expect(false, F_T, F_S);
    expect(true, F_T, F_T);
    expect(false, F_T, A_T);

    expect(true, F_S, Object_);
    expect(true, F_S, num_);
    expect(false, F_S, int_);
    expect(false, F_S, String_);
    expect(true, F_S, dynamic_);
    expect(true, F_S, F_S);
    expect(true, F_S, F_T);
    expect(false, F_S, A_T);

    // class G<T extends T> {}
    expect(true, G_T, Object_);
    expect(false, G_T, num_);
    expect(false, G_T, int_);
    expect(false, G_T, String_);
    expect(true, G_T, dynamic_);
    expect(true, G_T, G_T);
    expect(false, G_T, A_T);

    // class H<T extends S, S extends T> {}
    expect(true, H_T, Object_);
    expect(false, H_T, num_);
    expect(false, H_T, int_);
    expect(false, H_T, String_);
    expect(true, H_T, dynamic_);
    expect(true, H_T, H_T);
    expect(true, H_T, H_S);
    expect(false, H_T, A_T);

    expect(true, H_S, Object_);
    expect(false, H_S, num_);
    expect(false, H_S, int_);
    expect(false, H_S, String_);
    expect(true, H_S, dynamic_);
    expect(true, H_S, H_T);
    expect(true, H_S, H_S);
    expect(false, H_S, A_T);

    // class I<T extends S, S extends U, U extends T> {}
    expect(true, I_T, Object_);
    expect(false, I_T, num_);
    expect(false, I_T, int_);
    expect(false, I_T, String_);
    expect(true, I_T, dynamic_);
    expect(true, I_T, I_T);
    expect(true, I_T, I_S);
    expect(true, I_T, I_U);
    expect(false, I_T, A_T);

    expect(true, I_S, Object_);
    expect(false, I_S, num_);
    expect(false, I_S, int_);
    expect(false, I_S, String_);
    expect(true, I_S, dynamic_);
    expect(true, I_S, I_T);
    expect(true, I_S, I_S);
    expect(true, I_S, I_U);
    expect(false, I_S, A_T);

    expect(true, I_U, Object_);
    expect(false, I_U, num_);
    expect(false, I_U, int_);
    expect(false, I_U, String_);
    expect(true, I_U, dynamic_);
    expect(true, I_U, I_T);
    expect(true, I_U, I_S);
    expect(true, I_U, I_U);
    expect(false, I_U, A_T);

    // class J<T extends S, S extends U, U extends S> {}
    expect(true, J_T, Object_);
    expect(false, J_T, num_);
    expect(false, J_T, int_);
    expect(false, J_T, String_);
    expect(true, J_T, dynamic_);
    expect(true, J_T, J_T);
    expect(true, J_T, J_S);
    expect(true, J_T, J_U);
    expect(false, J_T, A_T);

    expect(true, J_S, Object_);
    expect(false, J_S, num_);
    expect(false, J_S, int_);
    expect(false, J_S, String_);
    expect(true, J_S, dynamic_);
    expect(false, J_S, J_T);
    expect(true, J_S, J_S);
    expect(true, J_S, J_U);
    expect(false, J_S, A_T);

    expect(true, J_U, Object_);
    expect(false, J_U, num_);
    expect(false, J_U, int_);
    expect(false, J_U, String_);
    expect(true, J_U, dynamic_);
    expect(false, J_U, J_T);
    expect(true, J_U, J_S);
    expect(true, J_U, J_U);
    expect(false, J_U, A_T);
  });
}
