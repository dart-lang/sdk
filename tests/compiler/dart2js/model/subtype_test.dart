// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library subtype_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart' show ClassEntity;
import 'package:compiler/src/elements/types.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

void main() {
  asyncTest(() async {
    await runTests();
  });
}

Future runTests() async {
  await testCallableSubtype();
  await testInterfaceSubtype();
  await testFunctionSubtyping();
  await testTypedefSubtyping();
  await testFunctionSubtypingOptional();
  await testTypedefSubtypingOptional();
  await testFunctionSubtypingNamed();
  await testTypedefSubtypingNamed();
  await testTypeVariableSubtype();
  await testStrongModeSubtyping();
}

void testTypes(TypeEnvironment env, DartType subtype, DartType supertype,
    bool expectSubtype) {
  Expect.equals(expectSubtype, env.isSubtype(subtype, supertype),
      '$subtype <: $supertype');
  if (expectSubtype) {
    Expect.isTrue(env.isPotentialSubtype(subtype, supertype),
        '$subtype <: $supertype (potential)');
  }
}

void testElementTypes(
    TypeEnvironment env, String subname, String supername, bool expectSubtype) {
  DartType subtype = env.getElementType(subname);
  DartType supertype = env.getElementType(supername);
  testTypes(env, subtype, supertype, expectSubtype);
}

Future testInterfaceSubtype() async {
  await TypeEnvironment.create(r"""
      class A<T> {}
      class B<T1, T2> extends A<T1> {}
      // TODO(johnniwinther): Inheritance with different type arguments is
      // currently not supported by the implementation.
      class C<T1, T2> extends B<T2, T1> /*implements A<A<T1>>*/ {}

      main() {
        new C();
      }
      """, options: [Flags.noSoundNullSafety], expectNoErrors: true)
      .then((env) {
    void expect(bool expectSubtype, DartType T, DartType S) {
      testTypes(env, T, S, expectSubtype);
    }

    var types = env.types;

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
    expect(true, dynamic_, void_);
    expect(true, void_, Object_);
    expect(true, Object_, void_);
    expect(true, Null_, void_);

    expect(true, Object_, Object_);
    expect(true, num_, Object_);
    expect(true, int_, Object_);
    expect(true, String_, Object_);
    expect(true, dynamic_, Object_);
    expect(true, Null_, Object_);

    expect(false, Object_, num_);
    expect(true, num_, num_);
    expect(true, int_, num_);
    expect(false, String_, num_);
    expect(false, dynamic_, num_);
    expect(true, Null_, num_);

    expect(false, Object_, int_);
    expect(false, num_, int_);
    expect(true, int_, int_);
    expect(false, String_, int_);
    expect(false, dynamic_, int_);
    expect(true, Null_, int_);

    expect(false, Object_, String_);
    expect(false, num_, String_);
    expect(false, int_, String_);
    expect(true, String_, String_);
    expect(false, dynamic_, String_);
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
    expect(false, dynamic_, Null_);
    expect(true, Null_, Null_);

    DartType A_Object = instantiate(types, A, [Object_]);
    DartType A_num = instantiate(types, A, [num_]);
    DartType A_int = instantiate(types, A, [int_]);
    DartType A_String = instantiate(types, A, [String_]);
    DartType A_dynamic = instantiate(types, A, [dynamic_]);
    DartType A_Null = instantiate(types, A, [Null_]);

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
    expect(true, A_dynamic, A_Object);
    expect(true, A_Null, A_Object);

    expect(false, A_Object, A_num);
    expect(true, A_num, A_num);
    expect(true, A_int, A_num);
    expect(false, A_String, A_num);
    expect(false, A_dynamic, A_num);
    expect(true, A_Null, A_num);

    expect(false, A_Object, A_int);
    expect(false, A_num, A_int);
    expect(true, A_int, A_int);
    expect(false, A_String, A_int);
    expect(false, A_dynamic, A_int);
    expect(true, A_Null, A_int);

    expect(false, A_Object, A_String);
    expect(false, A_num, A_String);
    expect(false, A_int, A_String);
    expect(true, A_String, A_String);
    expect(false, A_dynamic, A_String);
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
    expect(false, A_dynamic, A_Null);
    expect(true, A_Null, A_Null);

    DartType B_Object_Object = instantiate(types, B, [Object_, Object_]);
    DartType B_num_num = instantiate(types, B, [num_, num_]);
    DartType B_int_num = instantiate(types, B, [int_, num_]);
    DartType B_dynamic_dynamic = instantiate(types, B, [dynamic_, dynamic_]);
    DartType B_String_dynamic = instantiate(types, B, [String_, dynamic_]);

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
    expect(true, B_dynamic_dynamic, A_Object);
    expect(false, B_dynamic_dynamic, A_num);
    expect(false, B_dynamic_dynamic, A_int);
    expect(false, B_dynamic_dynamic, A_String);
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
    expect(true, B_dynamic_dynamic, B_Object_Object);
    expect(true, B_String_dynamic, B_Object_Object);

    expect(false, B_Object_Object, B_num_num);
    expect(true, B_num_num, B_num_num);
    expect(true, B_int_num, B_num_num);
    expect(false, B_dynamic_dynamic, B_num_num);
    expect(false, B_String_dynamic, B_num_num);

    expect(false, B_Object_Object, B_int_num);
    expect(false, B_num_num, B_int_num);
    expect(true, B_int_num, B_int_num);
    expect(false, B_dynamic_dynamic, B_int_num);
    expect(false, B_String_dynamic, B_int_num);

    expect(true, B_Object_Object, B_dynamic_dynamic);
    expect(true, B_num_num, B_dynamic_dynamic);
    expect(true, B_int_num, B_dynamic_dynamic);
    expect(true, B_dynamic_dynamic, B_dynamic_dynamic);
    expect(true, B_String_dynamic, B_dynamic_dynamic);

    expect(false, B_Object_Object, B_String_dynamic);
    expect(false, B_num_num, B_String_dynamic);
    expect(false, B_int_num, B_String_dynamic);
    expect(false, B_dynamic_dynamic, B_String_dynamic);
    expect(true, B_String_dynamic, B_String_dynamic);

    DartType C_Object_Object = instantiate(types, C, [Object_, Object_]);
    DartType C_num_num = instantiate(types, C, [num_, num_]);
    DartType C_int_String = instantiate(types, C, [int_, String_]);
    DartType C_dynamic_dynamic = instantiate(types, C, [dynamic_, dynamic_]);

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

    expect(true, C_dynamic_dynamic, B_Object_Object);
    expect(false, C_dynamic_dynamic, B_num_num);
    expect(false, C_dynamic_dynamic, B_int_num);
    expect(true, C_dynamic_dynamic, B_dynamic_dynamic);
    expect(false, C_dynamic_dynamic, B_String_dynamic);

    expect(false, C_int_String, A_int);
    expect(true, C_int_String, A_String);
    // TODO(johnniwinther): Inheritance with different type arguments is
    // currently not supported by the implementation.
    //expect(true, C_int_String, instantiate(A, [A_int]));
    expect(false, C_int_String, instantiate(types, A, [A_String]));
  });
}

Future testCallableSubtype() async {
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

      main() {
        new W();
        var a = new A();
        a.call(null, null);
        a.m1(null, null);
        a.m2(null, null);
        a.m3(null, null);
        a.m4(null, null);
        a.m5(null, null);
      }
      """, options: [Flags.noSoundNullSafety], expectNoErrors: true)
      .then((env) {
    void expect(bool expectSubtype, DartType T, DartType S) {
      testTypes(env, T, S, expectSubtype);
    }

    ClassEntity classA = env.getClass('A');
    DartType A = env.elementEnvironment.getRawType(classA);
    DartType function = env['Function'];
    DartType call = env.getMemberType('call', classA);
    DartType m1 = env.getMemberType('m1', classA);
    DartType m2 = env.getMemberType('m2', classA);
    DartType m3 = env.getMemberType('m3', classA);
    DartType m4 = env.getMemberType('m4', classA);
    DartType m5 = env.getMemberType('m5', classA);

    expect(false, A, function);
    expect(false, A, call);
    expect(false, call, m1);
    expect(false, A, m1);
    expect(false, A, m2);
    expect(false, A, m3);
    expect(false, A, m4);
    expect(false, A, m5);
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

Future testFunctionSubtyping() async {
  await TypeEnvironment.create(
          createMethods(functionTypesData, additionalData: """
  main() {
    ${createUses(functionTypesData)}
  }
  """),
          options: [Flags.noSoundNullSafety],
          expectNoErrors: true)
      .then(functionSubtypingHelper);
}

Future testTypedefSubtyping() async {
  await TypeEnvironment.create(
          createTypedefs(functionTypesData, additionalData: """
  main() {
    ${createUses(functionTypesData)}
  }
  """),
          options: [Flags.noSoundNullSafety],
          expectNoErrors: true)
      .then(functionSubtypingHelper);
}

functionSubtypingHelper(TypeEnvironment env) {
  void expect(bool expectSubtype, String sub, String sup) {
    testElementTypes(env, sub, sup, expectSubtype);
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
  expect(true, 'void_', '_');

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
  expect(true, 'int__Object', 'Object__int');
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

Future testFunctionSubtypingOptional() async {
  await TypeEnvironment.create(
          createMethods(optionalFunctionTypesData, additionalData: """
  main() {
    ${createUses(optionalFunctionTypesData)}
  }
  """),
          options: [Flags.noSoundNullSafety],
          expectNoErrors: true)
      .then((env) => functionSubtypingOptionalHelper(env));
}

Future testTypedefSubtypingOptional() async {
  await TypeEnvironment.create(
          createTypedefs(optionalFunctionTypesData, additionalData: """
  main() {
    ${createUses(optionalFunctionTypesData)}
  }
  """),
          options: [Flags.noSoundNullSafety],
          expectNoErrors: true)
      .then((env) => functionSubtypingOptionalHelper(env));
}

functionSubtypingOptionalHelper(TypeEnvironment env) {
  void expect(bool expectSubtype, String sub, String sup) {
    testElementTypes(env, sub, sup, expectSubtype);
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
  expect(true, 'void___Object', 'void___int');
  // Test ([int])->void <: ([Object])->void.
  expect(false, 'void___int', 'void___Object');
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
  expect(true, 'void___Object_int', 'void___int');
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

Future testFunctionSubtypingNamed() async {
  await TypeEnvironment.create(
          createMethods(namedFunctionTypesData, additionalData: """
  main() {
    ${createUses(namedFunctionTypesData)}
  }
  """),
          options: [Flags.noSoundNullSafety],
          expectNoErrors: true)
      .then((env) => functionSubtypingNamedHelper(env));
}

Future testTypedefSubtypingNamed() async {
  await TypeEnvironment.create(
          createTypedefs(namedFunctionTypesData, additionalData: """
  main() {
    ${createUses(namedFunctionTypesData)}
  }
  """),
          options: [Flags.noSoundNullSafety],
          expectNoErrors: true)
      .then((env) => functionSubtypingNamedHelper(env));
}

functionSubtypingNamedHelper(TypeEnvironment env) {
  expect(bool expectSubtype, String sub, String sup) {
    testElementTypes(env, sub, sup, expectSubtype);
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
  expect(true, 'void___a_Object', 'void___a_int');
  // Test ({int a})->void <: ({Object a})->void.
  expect(false, 'void___a_int', 'void___a_Object');
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

Future testTypeVariableSubtype() async {
  await TypeEnvironment.create(r"""
      class A<T> {}
      class B<T extends Object> {}
      class C<T extends num> {}
      class D<T extends int> {}
      class E<T extends S, S extends num> {}
      class F<T extends num, S extends T> {}

      main() {
        new A();
        new B();
        new C();
        new D();
        new E<int, num>();
        new F();
      }
      """, options: [Flags.noSoundNullSafety], expectNoErrors: true)
      .then((env) {
    void expect(bool expectSubtype, DartType T, DartType S) {
      testTypes(env, T, S, expectSubtype);
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
  });
}

Future testStrongModeSubtyping() async {
  await TypeEnvironment.create(r"""
      class ClassWithCall {
        void call() {}
      }
      num returnNum() => null;
      int returnInt() => null;
      void returnVoid() => null;
      Object returnObject() => null;

      takeNum(num o) => null;
      takeInt(int o) => null;
      takeVoid(void o) => null;
      takeObject(Object o) => null;
      
      main() {
        new ClassWithCall().call;
        returnNum();
        returnInt();
        returnVoid();
        returnObject();
        
        takeNum(null);
        takeInt(null);
        takeVoid(null);
        takeObject(null);
      }
      """, options: [Flags.noSoundNullSafety], expectNoErrors: true)
      .then((env) {
    void expect(bool expectSubtype, DartType T, DartType S) {
      Expect.equals(expectSubtype, env.isSubtype(T, S), '$T <: $S');
      if (expectSubtype) {
        Expect.isTrue(env.isPotentialSubtype(T, S), '$T <: $S (potential)');
      }
    }

    InterfaceType ClassWithCall = env['ClassWithCall'];
    DartType Object_ = env['Object'];
    DartType dynamic_ = env['dynamic'];
    DartType void_ = env['void'];
    DartType Null_ = env['Null'];
    DartType Function_ = env['Function'];
    DartType ClassWithCallType =
        env.getMemberType('call', ClassWithCall.element);

    InterfaceType List_Object = env.commonElements.listType(Object_);
    InterfaceType List_dynamic = env.commonElements.listType(dynamic_);
    InterfaceType List_void = env.commonElements.listType(void_);
    InterfaceType List_Null = env.commonElements.listType(Null_);
    InterfaceType List_Function = env.commonElements.listType(Function_);

    DartType returnNum = env.getMemberType('returnNum');
    DartType returnInt = env.getMemberType('returnInt');
    DartType returnVoid = env.getMemberType('returnVoid');
    DartType returnObject = env.getMemberType('returnObject');

    DartType takeNum = env.getMemberType('takeNum');
    DartType takeInt = env.getMemberType('takeInt');
    DartType takeVoid = env.getMemberType('takeVoid');
    DartType takeObject = env.getMemberType('takeObject');

    // Classes with call methods are no longer subtypes of Function.
    expect(false, ClassWithCall, Function_);
    // Classes with call methods are no longer subtype the function type of the
    // call method.
    expect(false, ClassWithCall, ClassWithCallType);

    // At runtime `Object`, `dynamic` and `void` are the same and are therefore
    // subtypes and supertypes of each other.
    //
    // `dynamic` is no longer a bottom type but `Null` is.

    expect(true, Object_, Object_);
    expect(true, Object_, void_);
    expect(true, Object_, dynamic_);
    expect(false, Object_, Null_);
    expect(false, Object_, Function_);

    expect(true, dynamic_, Object_);
    expect(true, dynamic_, void_);
    expect(true, dynamic_, dynamic_);
    expect(false, dynamic_, Null_);
    expect(false, dynamic_, Function_);

    expect(true, void_, Object_);
    expect(true, void_, void_);
    expect(true, void_, dynamic_);
    expect(false, void_, Null_);
    expect(false, void_, Function_);

    expect(true, Null_, Object_);
    expect(true, Null_, void_);
    expect(true, Null_, dynamic_);
    expect(true, Null_, Null_);
    expect(true, Null_, Function_);

    expect(true, Function_, Object_);
    expect(true, Function_, void_);
    expect(true, Function_, dynamic_);
    expect(false, Function_, Null_);
    expect(true, Function_, Function_);

    expect(true, List_Object, List_Object);
    expect(true, List_Object, List_void);
    expect(true, List_Object, List_dynamic);
    expect(false, List_Object, List_Null);
    expect(false, List_Object, List_Function);

    expect(true, List_dynamic, List_Object);
    expect(true, List_dynamic, List_void);
    expect(true, List_dynamic, List_dynamic);
    expect(false, List_dynamic, List_Null);
    expect(false, List_dynamic, List_Function);

    expect(true, List_void, List_Object);
    expect(true, List_void, List_void);
    expect(true, List_void, List_dynamic);
    expect(false, List_void, List_Null);
    expect(false, List_void, List_Function);

    expect(true, List_Null, List_Object);
    expect(true, List_Null, List_void);
    expect(true, List_Null, List_dynamic);
    expect(true, List_Null, List_Null);
    expect(true, List_Null, List_Function);

    expect(true, List_Function, List_Object);
    expect(true, List_Function, List_void);
    expect(true, List_Function, List_dynamic);
    expect(false, List_Function, List_Null);
    expect(true, List_Function, List_Function);

    // Return type are now covariant.
    expect(true, returnNum, returnNum);
    expect(false, returnNum, returnInt);
    expect(true, returnNum, returnVoid);
    expect(true, returnNum, returnObject);

    expect(true, returnInt, returnNum);
    expect(true, returnInt, returnInt);
    expect(true, returnInt, returnVoid);
    expect(true, returnInt, returnObject);

    expect(false, returnVoid, returnNum);
    expect(false, returnVoid, returnInt);
    expect(true, returnVoid, returnVoid);
    expect(true, returnVoid, returnObject);

    expect(false, returnObject, returnNum);
    expect(false, returnObject, returnInt);
    expect(true, returnObject, returnVoid);
    expect(true, returnObject, returnObject);

    // Arguments types are now contravariant.
    expect(true, takeNum, takeNum);
    expect(true, takeNum, takeInt);
    expect(false, takeNum, takeVoid);
    expect(false, takeNum, takeObject);

    expect(false, takeInt, takeNum);
    expect(true, takeInt, takeInt);
    expect(false, takeInt, takeVoid);
    expect(false, takeInt, takeObject);

    expect(true, takeVoid, takeNum);
    expect(true, takeVoid, takeInt);
    expect(true, takeVoid, takeVoid);
    expect(true, takeVoid, takeObject);

    expect(true, takeObject, takeNum);
    expect(true, takeObject, takeInt);
    expect(true, takeObject, takeVoid);
    expect(true, takeObject, takeObject);
  });
}
