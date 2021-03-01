// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Random;
import 'dart:typed_data';
import 'package:expect/expect.dart';

void main() {
  var r = Random();
  int genInt() => r.nextInt(256);
  double genDbl() => r.nextDouble();
  Int32x4 genIx4() => Int32x4(genInt(), genInt(), genInt(), genInt());
  Float32x4 genFx4() => Float32x4(genDbl(), genDbl(), genDbl(), genDbl());
  Float64x2 genDx2() => Float64x2(genDbl(), genDbl());

  test("Uint8List", (n) => Uint8List(n)..fill(genInt));
  test("Uint16List", (n) => Uint16List(n)..fill(genInt));
  test("Uint32List", (n) => Uint32List(n)..fill(genInt));
  test("Int8List", (n) => Int8List(n)..fill(genInt));
  test("Int16List", (n) => Int16List(n)..fill(genInt));
  test("Int32List", (n) => Int32List(n)..fill(genInt));
  test("Uint8ClampedList", (n) => Uint8ClampedList(n)..fill(genInt));
  test("Float32List", (n) => Float32List(n)..fill(genDbl));
  test("Float64List", (n) => Float64List(n)..fill(genDbl));
  test("Int32x4List", (n) => Int32x4List(n)..fill(genIx4));
  test("Float32x4List", (n) => Float32x4List(n)..fill(genFx4));
  test("Float64x2List", (n) => Float64x2List(n)..fill(genDx2));
}

void test<T>(String name, List<T> create(int n)) {
  var l1 = create(17);
  var l2 = create(13);
  List<T> l3;
  try {
    // Shouldn't throw:
    l3 = l1 + l2;
  } catch (e) {
    // Until we change Expect.fail to return Never.
    Expect.fail("$name: $e") as Never;
  }
  Expect.equals(30, l3.length);
  if (0 is T || 0.0 is T) {
    // Int32x4 etc. do not support `==`.
    Expect.listEquals(l1, l3.sublist(0, 17), "$name first");
    Expect.listEquals(l2, l3.sublist(17), "$name second");
  }
  // Result is growable, shouldn't throw.
  try {
    l3.add(l3.first);
  } catch (e) {
    Expect.fail("$name: $e");
  }
}

// Fill a list with (random) generated values.
extension<T> on List<T> {
  void fill(T gen()) {
    for (var i = 0; i < length; i++) {
      this[i] = gen();
    }
  }
}
