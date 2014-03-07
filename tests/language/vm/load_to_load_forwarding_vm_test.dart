// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.

// VMOptions=--optimization-counter-threshold=10

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
    return arr.length;  // Immutable length load.
  }

  if (arr.length < 2) {  // Mutable length load, should not be forwarded.
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

testPhiConvertions(f, arr) {
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
    arr[0] = a;  // Escape.
    arr[0] = b;
  }

  return c * c;  // Deopt point.
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
    obj = obj.next;  // This load should not be forwarded.
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
    obj = obj.next;  // This load should be forwarded.
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

  var result = new List(9);
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

  Expect.listEquals([-0.1, 0.1, 0.0,
                     0.0, -0.1, 0.1,
                     0.1, 0.0, -0.1], result);
}


class C {
  C(this.box, this.parent);
  final box;
  final C parent;
}

testPhiForwarding5(C c) {
  var s = 0;
  var tmp = c;
  var a = c.parent;
  if (a.box + tmp.box != 1) throw "failed";
  do {
    s += tmp.box + a.box;
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
    sum += v.x + v.y;
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

testIndexedAliasedStore(a, b) {
  a[0] = 1;
  a[1] = 2;
  if (a == b) {
    b[0] = 3;
  }
  return a[0] + a[1];
}

testIndexedAliasedStore1(a, b) {
  a[0] = 1;
  a[1] = 2;
  if (a == b) {
    b[0] = 3;
  }
  return a[0] + a[1];
}

testIndexedAliasedStore2(a, b, i) {
  a[0] = 1;
  a[1] = 2;
  if (a == b) {
    b[i] = 3;
  }
  return a[0] + a[1];
}
var indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

class Z {
  var x = 42;
}

var global_array = new List<Z>(1);

side_effect() {
  global_array[0].x++;
}

testAliasingStoreIndexed(array) {
  var z = new Z();
  array[0] = z;
  side_effect();
  return z.x;
}

main() {
  final fixed = new List(10);
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
  }

  Expect.equals(1, testImmutableVMFields([], false));
  Expect.equals(2, testImmutableVMFields([1], false));
  Expect.equals(2, testImmutableVMFields([1, 2], false));
  Expect.equals(3, testImmutableVMFields([1, 2, 3], false));

  final u32List = new Uint32List(3);
  u32List[0] = 0;
  u32List[1] = 0x3FFFFFFF;
  u32List[2] = 0x7FFFFFFF;

  for (var i = 0; i < 20; i++) {
    testPhiConvertions(true, u32List);
    testPhiConvertions(false, u32List);
  }

  for (var i = 0; i < 20; i++) {
    Expect.equals(0.0, testPhiMultipleRepresentations(true, f64List));
    Expect.equals(0, testPhiMultipleRepresentations(false, const [1,2]));
  }

  final escape = new List(1);
  for (var i = 0; i < 20; i++) {
    fakeAliasing(escape);
  }

  final array = new List(3);
  for (var i = 0; i < 20; i++) {
    Expect.equals(3, testIndexedNoAlias(array));
  }
  for (var i = 0; i < 20; i++) {
    Expect.equals(5, testIndexedAliasedStore1(array, array));
  }
  for (var i = 0; i < 20; i++) {
    Expect.equals(4, testIndexedAliasedStore2(array, array, indices[1]));
  }

  var test_array = new List(1);
  for (var i = 0; i < 20; i++) {
    Expect.equals(43, testAliasingStoreIndexed(global_array));
  }
}
