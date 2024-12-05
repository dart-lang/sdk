// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

// Test that unmodifiable typed list assignments on optimized and slow paths
// produce the same error.

@pragma('dart2js:never-inline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void check2(String name, String name1, f1(), String name2, f2()) {
  Error? trap(part, f) {
    try {
      f();
    } on Error catch (e) {
      return e;
    }
    Expect.fail('should throw: $name.$part');
  }

  var e1 = trap(name1, f1);
  var e2 = trap(name2, f2);
  var s1 = '$e1';
  var s2 = '$e2';
  Expect.equals(s1, s2, '\n  $name.$name1: "$s1"\n  $name.$name2: "$s2"\n');
}

void check(String name, f1(), f2(), [f3()?, f4()?]) {
  check2(name, 'f1', f1, 'f2', f2);
  if (f3 != null) check2(name, 'f1', f1, 'f3', f3);
  if (f4 != null) check2(name, 'f1', f1, 'f4', f4);
}

void testUint8List() {
  Uint8List a = Uint8List(100);
  Uint8List b = a.asUnmodifiableView();
  Uint8List c = confuse(true) ? b : a;

  dynamic d = confuse(true) ? b : const [1];

  void f1() {
    d[0] = 0; // dynamic receiver.
  }

  void f2() {
    b[0] = 1; // unmodifiable receiver
  }

  void f3() {
    c[0] = 1; // potentially unmodifiable receiver
  }

  check('Uint8List', f1, f2, f3);
}

void testInt16List() {
  Int16List a = Int16List(100);
  Int16List b = a.asUnmodifiableView();
  Int16List c = confuse(true) ? b : a;

  dynamic d = confuse(true) ? b : const [1];

  void f1() {
    d[0] = 0; // dynamic receiver.
  }

  void f2() {
    b[0] = 1; // unmodifiable receiver
  }

  void f3() {
    c[0] = 1; // potentially unmodifiable receiver
  }

  check('Int16List', f1, f2, f3);
}

void testFloat32List() {
  Float32List a = Float32List(100);
  Float32List b = a.asUnmodifiableView();
  Float32List c = confuse(true) ? b : a;

  dynamic d = confuse(true) ? b : const [1];

  void f1() {
    d[0] = 0; // dynamic receiver.
  }

  void f2() {
    b[0] = 1; // unmodifiable receiver
  }

  void f3() {
    c[0] = 1; // potentially unmodifiable receiver
  }

  check('Float32List', f1, f2, f3);
}

void testFloat64List() {
  Float64List a = Float64List(100);
  Float64List b = a.asUnmodifiableView();
  Float64List c = confuse(true) ? b : a;

  dynamic d = confuse(true) ? b : const [1];

  void f1() {
    d[0] = 0; // dynamic receiver.
  }

  void f2() {
    b[0] = 1; // unmodifiable receiver
  }

  void f3() {
    c[0] = 1; // potentially unmodifiable receiver
  }

  check('Float64List', f1, f2, f3);
}

void testFloat64x2List() {
  Float64x2List a = Float64x2List(100);
  Float64x2List b = a.asUnmodifiableView();
  Float64x2List c = confuse(true) ? b : a;

  dynamic d = confuse(true) ? b : const [1];

  void f1() {
    d[0] = a.last; // dynamic receiver.
  }

  void f2() {
    b[0] = a.last; // unmodifiable receiver
  }

  void f3() {
    c[0] = a.last; // potentially unmodifiable receiver
  }

  check('Float64List', f1, f2, f3);
}

main() {
  testUint8List();
  testInt16List();
  testFloat32List();
  testFloat64List();
  testFloat64x2List();
}
