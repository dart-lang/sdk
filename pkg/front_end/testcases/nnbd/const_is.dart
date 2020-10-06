// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests derived from co19/Language/Types/Function_Types/subtype_named_args_t04
// and language/nnbd/subtyping/function_type_required_params_test

bool inStrongMode = <int?>[] is! List<int>;

int f({required int i}) {
  return i + 1;
}

int g({int i = 1}) {
  return i + 1;
}

typedef int fType({required int i});
typedef int gType({int i});
typedef int bigType(
    {required int i1,
    required int i2,
    required int i3,
    required int i4,
    required int i5,
    required int i6,
    required int i7,
    required int i8,
    required int i9,
    required int i10,
    required int i11,
    required int i12,
    required int i13,
    required int i14,
    required int i15,
    required int i16,
    required int i17,
    required int i18,
    required int i19,
    required int i20,
    required int i21,
    required int i22,
    required int i23,
    required int i24,
    required int i25,
    required int i26,
    required int i27,
    required int i28,
    required int i29,
    required int i30,
    required int i31,
    required int i32,
    required int i33,
    required int i34,
    required int i35,
    required int i36,
    required int i37,
    required int i38,
    required int i39,
    required int i40,
    required int i41,
    required int i42,
    required int i43,
    required int i44,
    required int i45,
    required int i46,
    required int i47,
    required int i48,
    required int i49,
    required int i50,
    required int i51,
    required int i52,
    required int i53,
    required int i54,
    required int i55,
    required int i56,
    required int i57,
    required int i58,
    required int i59,
    required int i60,
    required int i61,
    required int i62,
    required int i63,
    required int i64,
    required int i65,
    required int i66,
    required int i67,
    required int i68,
    required int i69,
    required int i70});

class A {}

class A1 {}

class A2 {}

class B implements A, A1, A2 {}

class C implements B {}

class D implements C {}

typedef B func(Object o);
typedef B t1(int i, B b, Map<int, num> m, var x,
    {required var ox,
    required B ob,
    required List<num> ol,
    required bool obool});

B f1(int i, B b, Map<int, num> m, var x,
        {required extraParam,
        required bool obool,
        required var ox,
        required D ob,
        required List<num>? ol}) =>
    new B();
D f2(int i, D b, Map<int, int> m, func x,
        {required func ox,
        required D ob,
        required List<int> ol,
        required bool obool}) =>
    new D();
C f3(num i, A b, Map<Object, Object> m, var x,
        {required var ox,
        required extraParam,
        required A2 ob,
        required List ol,
        required Object obool}) =>
    new C();
C f4(num i, A b, Map<Object, Object> m, var x,
        {required var ox,
        required A2 ob,
        required List ol,
        required bool obool,
        required A xx,
        required B yy}) =>
    new C();
C f5(int i, A b, Map<Object, Object> m, var x,
        {required ox, required B ob, required List ol, required obool}) =>
    new C();

const f_is_fType = f is fType;
const f_is_gType = f is gType;
const g_is_fType = g is fType;
const g_is_gType = g is gType;
const f_is_bigType = f is bigType;

const f1_is_t1 = f1 is t1;
const f2_is_t1 = f2 is t1;
const f3_is_t1 = f3 is t1;
const f4_is_t1 = f4 is t1;
const f5_is_t1 = f5 is t1;

main() {
  expect(true, f_is_fType);
  expect(f is fType, f_is_fType);
  expect(!inStrongMode, f_is_gType);
  expect(f is gType, f_is_gType);
  expect(true, g_is_fType);
  expect(g is fType, g_is_fType);
  expect(true, g_is_gType);
  expect(g is gType, g_is_gType);
  expect(false, f_is_bigType);
  expect(f is bigType, f_is_bigType);

  expect(false, f1_is_t1);
  expect(f1 is t1, f1_is_t1);
  expect(false, f2_is_t1);
  expect(f2 is t1, f2_is_t1);
  expect(!inStrongMode, f3_is_t1);
  expect(f3 is t1, f3_is_t1);
  expect(!inStrongMode, f4_is_t1);
  expect(f4 is t1, f4_is_t1);
  expect(true, f5_is_t1);
  expect(f5 is t1, f5_is_t1);
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}
