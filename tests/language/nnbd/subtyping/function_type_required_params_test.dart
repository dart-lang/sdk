// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
import 'package:expect/expect.dart';

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

main() {
  Expect.equals(f.runtimeType, f.runtimeType);
  Expect.notEquals(f.runtimeType, g.runtimeType);
  Expect.equals(g.runtimeType, g.runtimeType);
  Expect.notEquals(f.runtimeType, bigType);

  Expect.isTrue(f is fType);
  Expect.isFalse(f is gType);
  Expect.isTrue(g is fType);
  Expect.isTrue(g is gType);
  Expect.isFalse(f is bigType);
}
