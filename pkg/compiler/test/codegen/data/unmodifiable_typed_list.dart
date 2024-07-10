// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show ArrayFlags, HArrayFlagsSet;

import 'dart:typed_data';

@pragma('dart2js:never-inline')
/*member: returnUnmodifiable:function() {
  var a = new Int8Array(10);
  a.$flags = 3;
  return a;
}*/
returnUnmodifiable() {
  final a = Int8List(10);
  Int8List b = HArrayFlagsSet(a, ArrayFlags.unmodifiable);
  return b;
}

// Two writes, neither checked.
@pragma('dart2js:never-inline')
/*member: return200:function() {
  var a = new Uint8Array(10);
  a[0] = 200;
  a[1] = 201;
  return a;
}*/
return200() {
  final a = Uint8List(10);
  a[0] = 200;
  a[1] = 201;
  return a;
}

@pragma('dart2js:never-inline')
/*member: guaranteedFail:function() {
  var a = new Uint8Array(10);
  a.$flags = 3;
  A.throwUnsupportedOperation(a);
  a[0] = 200;
  a[1] = 201;
  return a;
}*/
guaranteedFail() {
  final a = Uint8List(10);
  Uint8List b = HArrayFlagsSet(a, ArrayFlags.unmodifiable);
  b[0] = 200;
  b[1] = 201;
  return b;
}

@pragma('dart2js:never-inline')
/*member: multipleWrites:function() {
  var a = A.maybeUnmodifiable();
  a.$flags & 2 && A.throwUnsupportedOperation(a);
  if (5 >= a.length)
    return A.ioore(a, 5);
  a[5] = 100;
  a[1] = 200;
  return a;
}*/
multipleWrites() {
  final a = maybeUnmodifiable();
  a[5] = 100;
  a[1] = 200; // there should only be one write check.
  return a;
}

@pragma('dart2js:never-inline')
/*member: hoistedLoad:function(a) {
  var t1, t2, i;
  for (t1 = a.length, t2 = a.$flags | 0, i = 0; i < t1; ++i) {
    t2 & 2 && A.throwUnsupportedOperation(a);
    a[i] = 100;
  }
  return a;
}*/
Uint8List hoistedLoad(Uint8List a) {
  // The load of the flags is hoisted, but the check is not.
  for (int i = 0; i < a.length; i++) {
    a[i] = 100;
  }
  return a;
}

@pragma('dart2js:never-inline')
/*member: hoistedCheck2:function(a) {
  var t2, i,
    t1 = a.length;
  if (t1 > 0)
    for (t2 = a.$flags | 0, i = 0; i < t1; ++i) {
      t2 & 2 && A.throwUnsupportedOperation(a);
      a[i] = 100;
    }
  return a;
}*/
Uint8List hoistedCheck2(Uint8List a) {
  if (a.length > 0) {
    // We should be able to do better here - the loop has a non-zero minimum
    // trip count.
    for (int i = 0; i < a.length; i++) {
      a[i] = 100;
    }
  }
  return a;
}

@pragma('dart2js:never-inline')
/*spec|canary.member: hoistedCheck3:function(a) {
  var t2, i,
    t1 = a.length;
  if (t1 > 0) {
    a.$flags & 2 && A.throwUnsupportedOperation(a);
    a[0] = 100;
    for (t2 = a.$flags | 0, i = 1; i < t1; ++i) {
      t2 & 2 && A.throwUnsupportedOperation(a);
      a[i] = 100;
    }
  }
  return a;
}*/
/*prod.member: hoistedCheck3:function(a) {
  var i,
    t1 = a.length;
  if (t1 > 0) {
    a.$flags & 2 && A.throwUnsupportedOperation(a);
    a[0] = 100;
    for (i = 1; i < t1; ++i)
      a[i] = 100;
  }
  return a;
}*/
Uint8List hoistedCheck3(Uint8List a) {
  if (a.length > 0) {
    a[0] = 100;
    // Checks in the loop are removed via simple dominance.
    for (int i = 1; i < a.length; i++) {
      a[i] = 100;
    }
  }
  return a;
}

@pragma('dart2js:never-inline')
/*spec|canary.member: list1:function(a) {
  B.JSArray_methods.$indexSet(a, 1, 100);
  B.JSArray_methods.$indexSet(a, 2, 200);
  return a;
}*/
/*prod.member: list1:function(a) {
  var t1;
  a.$flags & 2 && A.throwUnsupportedOperation(a);
  t1 = a.length;
  if (1 >= t1)
    return A.ioore(a, 1);
  a[1] = 100;
  if (2 >= t1)
    return A.ioore(a, 2);
  a[2] = 200;
  return a;
}*/
List<int> list1(List<int> a) {
  a[1] = 100;
  a[2] = 200;
  return a;
}

@pragma('dart2js:never-inline')
/*member: maybeUnmodifiable:ignore*/
Uint8List maybeUnmodifiable() {
  var d = Uint8List(10);
  if (DateTime.now().millisecondsSinceEpoch == 42) d = d.asUnmodifiableView();
  return d;
}

@pragma('dart2js:never-inline')
/*member: maybeUnmodifiableList:ignore*/
List<int> maybeUnmodifiableList() {
  var d = List<int>.filled(10, 0);
  if (DateTime.now().millisecondsSinceEpoch == 42) d = List.unmodifiable(d);
  return d;
}

/*member: main:ignore*/
main() {
  print(returnUnmodifiable());
  print(return200());
  print(guaranteedFail);
  print(multipleWrites());
  print(hoistedLoad(maybeUnmodifiable()));
  print(hoistedCheck2(maybeUnmodifiable()));
  print(hoistedCheck3(maybeUnmodifiable()));

  print(list1(maybeUnmodifiableList()));
}
