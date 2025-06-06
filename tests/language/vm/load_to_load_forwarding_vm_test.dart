// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";
import "dart:typed_data";

class A {
  var x, y;
  A(this.x, this.y);
}

foo(a) {
  var value1 = a.x;
  var value2 = a.y;
  for (var j = 1; j < 4; j++) {
    value1 |= a.x << (j * 8);
    a.y += 1;
    a.x += 1;
    value2 |= a.y << (j * 8);
  }
  return [value1, value2];
}

bar(a, mode) {
  var value1 = a.x;
  var value2 = a.y;
  for (var j = 1; j < 4; j++) {
    value1 |= a.x << (j * 8);
    a.y += 1;
    if (mode) a.x += 1;
    a.x += 1;
    value2 |= a.y << (j * 8);
  }
  return [value1, value2];
}

// Verify that immutable and mutable VM fields (array length in this case)
// are not confused by load forwarding even if the access the same offset
// in the object.
testImmutableVMFields(arr, immutable) {
  if (immutable) {
    return arr.length; // Immutable length load.
  }

  if (arr.length < 2) {
    // Mutable length load, should not be forwarded.
    arr.add(null);
  }

  return arr.length;
}

testPhiRepresentation(f, arr) {
  if (f) {
    arr[0] = arr[0] + arr[1];
  } else {
    arr[0] = arr[0] - arr[1];
  }
  return arr[0];
}

testPhiConversions(f, arr) {
  if (f) {
    arr[0] = arr[1];
  } else {
    arr[0] = arr[2];
  }
  return arr[0];
}

class M {
  var x;
  M(this.x);
}

fakeAliasing(arr) {
  var a = new M(10);
  var b = new M(10);
  var c = arr.length;

  if (c * c != c * c) {
    arr[0] = a; // Escape.
    arr[0] = b;
  }

  return c * c; // Deopt point.
}

class X {
  var next;
  X(this.next);
}

testPhiForwarding(obj) {
  if (obj.next == null) {
    return 1;
  }

  var len = 0;
  while (obj != null) {
    len++;
    obj = obj.next; // This load should not be forwarded.
  }

  return len;
}

testPhiForwarding2(obj) {
  if (obj.next == null) {
    return 1;
  }

  var len = 0, next = null;
  while ((obj != null) && len < 2) {
    len++;
    obj = obj.next; // This load should be forwarded.
    next = obj.next;
  }

  return len;
}

class V {
  final f;
  V(this.f);
}

testPhiForwarding3() {
  var a = new V(-0.1);
  var c = new V(0.0);
  var b = new V(0.1);

  for (var i = 0; i < 3; i++) {
    var af = a.f;
    var bf = b.f;
    var cf = c.f;
    a = new V(cf);
    b = new V(af);
    c = new V(bf);
  }

  Expect.equals(-0.1, a.f);
  Expect.equals(0.1, b.f);
  Expect.equals(0.0, c.f);
}

testPhiForwarding4() {
  var a = new V(-0.1);
  var b = new V(0.1);
  var c = new V(0.0);

  var result = new List<dynamic>.filled(9, null);
  for (var i = 0, j = 0; i < 3; i++) {
    result[j++] = a.f;
    result[j++] = b.f;
    result[j++] = c.f;
    var xa = a;
    var xb = b;
    a = c;
    b = xa;
    c = xb;
  }

  Expect.listEquals([-0.1, 0.1, 0.0, 0.0, -0.1, 0.1, 0.1, 0.0, -0.1], result);
}

class C {
  C(this.box, this.parent);
  final box;
  final C? parent;
}

testPhiForwarding5(C c) {
  var s = 0;
  var tmp = c;
  var a = c.parent;
  if (a!.box + tmp.box != 1) throw "failed";
  do {
    s += (tmp.box + a!.box) as int;
    tmp = a;
    a = a.parent;
  } while (a != null);
  return s;
}

class U {
  var x, y;
  U() : x = 0, y = 0;
}

testEqualPhisElimination() {
  var u = new U();
  var v = new U();
  var sum = 0;
  for (var i = 0; i < 3; i++) {
    u.x = i;
    u.y = i;
    if ((i & 1) == 1) {
      v.x = i + 1;
      v.y = i + 1;
    } else {
      v.x = i - 1;
      v.y = i - 1;
    }
    sum += (v.x + v.y) as int;
  }
  Expect.equals(4, sum);
  Expect.equals(2, u.x);
  Expect.equals(2, u.y);
}

testPhiMultipleRepresentations(f, arr) {
  var w;
  if (f) {
    w = arr[0] + arr[1];
  } else {
    w = arr[0] - arr[1];
  }
  var v;
  if (f) {
    v = arr[0];
  } else {
    v = arr[0];
  }
  return v + w;
}

testIndexedNoAlias(a) {
  a[0] = 1;
  a[1] = 2;
  a[2] = 3;
  return a[0] + a[1];
}

//
// Tests for indexed store aliases were autogenerated to have extensive
// coverage for all interesting aliasing combinations within the alias
// lattice (*[*], *[C], X[*], X[C])
//

testIndexedAliasedStore1(i) {
  var a = new List<dynamic>.filled(2, null);
  a[0] = 1; // X[C]
  a[i] = 2; // X[*]
  return a[0];
}

testIndexedAliasedStore2(f, c) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  a[0] = 1; // X[C]
  d[0] = 2; // *[C]
  return a[0];
}

testIndexedAliasedStore3(f, c, i) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  a[0] = 1; // X[C]
  d[i] = 2; // *[*]
  return a[0];
}

testIndexedAliasedStore4(i) {
  var a = new List<dynamic>.filled(2, null);
  a[i] = 1; // X[*]
  a[0] = 2; // X[C]
  return a[i];
}

testIndexedAliasedStore5(i, j) {
  var a = new List<dynamic>.filled(2, null);
  a[i] = 1; // X[*]
  a[j] = 2; // X[*]
  return a[i];
}

testIndexedAliasedStore6(i, f, c) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  a[i] = 1; // X[*]
  d[0] = 2; // *[C]
  return a[i];
}

testIndexedAliasedStore7(i, f, c) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  a[i] = 1; // X[*]
  d[i] = 2; // *[*]
  return a[i];
}

testIndexedAliasedStore8(c, i) {
  c[0] = 1; // *[C]
  c[i] = 2; // *[*]
  return c[0];
}

testIndexedAliasedStore9(c, f) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  c[0] = 1; // *[C]
  d[0] = 2; // *[C]
  return c[0];
}

testIndexedAliasedStore10(c, i) {
  c[i] = 1; // *[*]
  c[0] = 2; // *[C]
  return c[i];
}

testIndexedAliasedStore11(c, i, j) {
  c[i] = 1; // *[*]
  c[j] = 2; // *[*]
  return c[i];
}

testIndexedAliasedStore12(f, c) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  d[0] = 1; // *[C]
  a[0] = 2; // X[C]
  return d[0];
}

testIndexedAliasedStore13(f, c, i) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  d[0] = 1; // *[C]
  a[i] = 2; // X[*]
  return d[0];
}

testIndexedAliasedStore14(f, c, i) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  d[i] = 1; // *[*]
  a[0] = 2; // X[C]
  return d[i];
}

testIndexedAliasedStore15(f, c, i) {
  var a = new List<dynamic>.filled(2, null);
  var d = f ? a : c;
  d[i] = 1; // *[*]
  a[i] = 2; // X[*]
  return d[i];
}

testIndexedAliasedStores() {
  var arr = new List<dynamic>.filled(2, null);

  for (var i = 0; i < 50; i++) {
    Expect.equals(2, testIndexedAliasedStore1(0));
    Expect.equals(1, testIndexedAliasedStore1(1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore2(false, arr));
    Expect.equals(2, testIndexedAliasedStore2(true, arr));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore3(false, arr, 0));
    Expect.equals(1, testIndexedAliasedStore3(false, arr, 1));
    Expect.equals(2, testIndexedAliasedStore3(true, arr, 0));
    Expect.equals(1, testIndexedAliasedStore3(true, arr, 1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(2, testIndexedAliasedStore4(0));
    Expect.equals(1, testIndexedAliasedStore4(1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(2, testIndexedAliasedStore5(0, 0));
    Expect.equals(1, testIndexedAliasedStore5(0, 1));
    Expect.equals(1, testIndexedAliasedStore5(1, 0));
    Expect.equals(2, testIndexedAliasedStore5(1, 1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore6(0, false, arr));
    Expect.equals(2, testIndexedAliasedStore6(0, true, arr));
    Expect.equals(1, testIndexedAliasedStore6(1, false, arr));
    Expect.equals(1, testIndexedAliasedStore6(1, true, arr));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore7(0, false, arr));
    Expect.equals(2, testIndexedAliasedStore7(0, true, arr));
    Expect.equals(1, testIndexedAliasedStore7(1, false, arr));
    Expect.equals(2, testIndexedAliasedStore7(1, true, arr));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(2, testIndexedAliasedStore8(arr, 0));
    Expect.equals(1, testIndexedAliasedStore8(arr, 1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(2, testIndexedAliasedStore9(arr, false));
    Expect.equals(1, testIndexedAliasedStore9(arr, true));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(2, testIndexedAliasedStore10(arr, 0));
    Expect.equals(1, testIndexedAliasedStore10(arr, 1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(2, testIndexedAliasedStore11(arr, 0, 0));
    Expect.equals(1, testIndexedAliasedStore11(arr, 0, 1));
    Expect.equals(1, testIndexedAliasedStore11(arr, 1, 0));
    Expect.equals(2, testIndexedAliasedStore11(arr, 1, 1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore12(false, arr));
    Expect.equals(2, testIndexedAliasedStore12(true, arr));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore13(false, arr, 0));
    Expect.equals(1, testIndexedAliasedStore13(false, arr, 1));
    Expect.equals(2, testIndexedAliasedStore13(true, arr, 0));
    Expect.equals(1, testIndexedAliasedStore13(true, arr, 1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore14(false, arr, 0));
    Expect.equals(1, testIndexedAliasedStore14(false, arr, 1));
    Expect.equals(2, testIndexedAliasedStore14(true, arr, 0));
    Expect.equals(1, testIndexedAliasedStore14(true, arr, 1));
  }

  for (var i = 0; i < 50; i++) {
    Expect.equals(1, testIndexedAliasedStore15(false, arr, 0));
    Expect.equals(1, testIndexedAliasedStore15(false, arr, 1));
    Expect.equals(2, testIndexedAliasedStore15(true, arr, 0));
    Expect.equals(2, testIndexedAliasedStore15(true, arr, 1));
  }
}

var indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

class Z {
  var x = 42;
}

var global_array = new List<Z?>.filled(1, null);

side_effect() {
  global_array[0]!.x++;
}

testAliasingStoreIndexed(array) {
  var z = new Z();
  array[0] = z;
  side_effect();
  return z.x;
}

class ZZ {
  var f;
}

var zz, f0 = 42;

testAliasesRefinement() {
  zz = new ZZ();
  var b = zz;
  if (b.f == null) {
    b.f = f0;
  }
  return b.f;
}

testViewAliasing1() {
  final f64 = new Float64List(1);
  final f32 = new Float32List.view(f64.buffer);
  f64[0] = 1.0; // Should not be forwarded.
  f32[1] = 2.0; // upper 32bits for 2.0f and 2.0 are the same
  return f64[0];
}

testViewAliasing2() {
  final f64 = new Float64List(2);
  final f64v = new Float64List.view(f64.buffer, Float64List.bytesPerElement);
  f64[1] = 1.0; // Should not be forwarded.
  f64v[0] = 2.0;
  return f64[1];
}

testViewAliasing3() {
  final u8 = new Uint8List(Float64List.bytesPerElement * 2);
  final f64 = new Float64List.view(u8.buffer, Float64List.bytesPerElement);
  f64[0] = 1.0; // Should not be forwarded.
  u8[15] = 0x40;
  u8[14] = 0x00;
  return f64[0];
}

testViewAliasing4() {
  final u8 = new Uint8List(Float64List.bytesPerElement * 2);
  final f64 = new Float64List.view(u8.buffer, Float64List.bytesPerElement);
  f64[0] = 2.0; // Not aliased: should be forwarded.
  u8[0] = 0x40;
  u8[1] = 0x00;
  return f64[0];
}

main() {
  final fixed = new List<dynamic>.filled(10, null);
  final growable = [];
  testImmutableVMFields(fixed, true);
  testImmutableVMFields(growable, false);
  testImmutableVMFields(growable, false);

  final f64List = new Float64List(2);
  testPhiRepresentation(true, f64List);
  testPhiRepresentation(false, f64List);

  final obj = new X(new X(new X(null)));

  final cs = new C(0, new C(1, new C(2, null)));

  for (var i = 0; i < 20; i++) {
    Expect.listEquals([0x02010000, 0x03020100], foo(new A(0, 0)));
    Expect.listEquals([0x02010000, 0x03020100], bar(new A(0, 0), false));
    Expect.listEquals([0x04020000, 0x03020100], bar(new A(0, 0), true));
    testImmutableVMFields(fixed, true);
    testPhiRepresentation(true, f64List);
    testPhiForwarding(obj);
    testPhiForwarding2(obj);
    testPhiForwarding3();
    testPhiForwarding4();
    Expect.equals(4, testPhiForwarding5(cs));
    testEqualPhisElimination();
    Expect.equals(f0, testAliasesRefinement());
  }

  Expect.equals(1, testImmutableVMFields(<dynamic>[], false));
  Expect.equals(2, testImmutableVMFields(<int?>[1], false));
  Expect.equals(2, testImmutableVMFields(<int?>[1, 2], false));
  Expect.equals(3, testImmutableVMFields(<int?>[1, 2, 3], false));

  final u32List = new Uint32List(3);
  u32List[0] = 0;
  u32List[1] = 0x3FFFFFFF;
  u32List[2] = 0x7FFFFFFF;

  for (var i = 0; i < 20; i++) {
    testPhiConversions(true, u32List);
    testPhiConversions(false, u32List);
  }

  for (var i = 0; i < 20; i++) {
    Expect.equals(0.0, testPhiMultipleRepresentations(true, f64List));
    Expect.equals(0, testPhiMultipleRepresentations(false, const [1, 2]));
  }

  final escape = new List<dynamic>.filled(1, null);
  for (var i = 0; i < 20; i++) {
    fakeAliasing(escape);
  }

  final array = new List<dynamic>.filled(3, null);
  for (var i = 0; i < 20; i++) {
    Expect.equals(3, testIndexedNoAlias(array));
  }

  testIndexedAliasedStores();

  var test_array = new List<dynamic>.filled(1, null);
  for (var i = 0; i < 20; i++) {
    Expect.equals(43, testAliasingStoreIndexed(global_array));
  }

  for (var i = 0; i < 20; i++) {
    Expect.equals(2.0, testViewAliasing1());
    Expect.equals(2.0, testViewAliasing2());
    Expect.equals(2.0, testViewAliasing3());
    Expect.equals(2.0, testViewAliasing4());
  }
}
