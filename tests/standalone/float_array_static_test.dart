// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native float arrays.

// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

// Library tag to be able to run in html test framework.
library FloatArrayTest;

import "package:expect/expect.dart";
import 'dart:typed_data';

void testIndexOf32() {
  var list = new Float32List(10);
  for (int i = 0; i < list.length; i++) {
    list[i] = i + 10.0;
  }
  /*@compile-error=unspecified*/ Expect.equals(0, list.indexOf(10));
  /*@compile-error=unspecified*/ Expect.equals(5, list.indexOf(15));
  /*@compile-error=unspecified*/ Expect.equals(9, list.indexOf(19));
  /*@compile-error=unspecified*/ Expect.equals(-1, list.indexOf(20));
}

void testBadValues32() {
  var list = new Float32List(10);
  list[0] = 2.0;
  /*@compile-error=unspecified*/ list[0] = 2;
  /*@compile-error=unspecified*/ list[0] = "hello";
}

void testIndexOf64() {
  var list = new Float64List(10);
  for (int i = 0; i < list.length; i++) {
    list[i] = i + 10.0;
  }
  /*@compile-error=unspecified*/ Expect.equals(0, list.indexOf(10));
  /*@compile-error=unspecified*/ Expect.equals(5, list.indexOf(15));
  /*@compile-error=unspecified*/ Expect.equals(9, list.indexOf(19));
  /*@compile-error=unspecified*/ Expect.equals(-1, list.indexOf(20));
}

void testBadValues64() {
  var list = new Float64List(10);
  list[0] = 2.0;
  /*@compile-error=unspecified*/ list[0] = 2;
  /*@compile-error=unspecified*/ list[0] = "hello";
}

main() {
  testIndexOf32();
  testIndexOf64();
  testBadValues32();
  testBadValues64();
}
