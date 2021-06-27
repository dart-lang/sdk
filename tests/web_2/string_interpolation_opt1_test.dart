// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";
import 'dart:math';

// Test that String interpolation works in some optimized cases.

bool get inscrutableFalse => new Random().nextDouble() > 2;

returnsNullOrString(x) {
  if (inscrutableFalse) return 'hi';
  if (inscrutableFalse) return null;
  return x;
}

returnsNullOrInt(x) {
  if (inscrutableFalse) return 123;
  if (inscrutableFalse) return null;
  return x;
}

spoil(a) {
  a[3] = 123;
  a[4] = 'ddd';
}

void testString() {
  var a = new List(100); // 'null' values in here are JavaScript undefined.
  spoil(a);
  var s = returnsNullOrString('hi');
  var x = a[2];
  if (x == null) {
    s = returnsNullOrString(x);
  }

  Expect.equals('s: null', 's: $s');
}

void testInt() {
  var a = new List(100); // 'null' values in here are JavaScript undefined.
  spoil(a);
  var s = returnsNullOrInt(123);
  var x = a[2];
  if (x == null) {
    s = returnsNullOrInt(x);
  }

  Expect.equals('s: null', 's: $s');
}

void main() {
  testInt();
  testString();
}
