// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test optimized [] on strings.

var a = "abc";
var b = "øbc";
var c = new String.fromCharCodes([123, 456, 789]);

test_charat(s, i) {
  return s[i];
}

test_const_str(i) {
  return "abc"[i];
}

test_const_index(s) {
  return s[0];
}

test_const_index2(s) {
  return s[3];
}

main() {
  Expect.equals("a", test_charat(a, 0));
  for (var i = 0; i < 20; i++) test_charat(a, 0);
  Expect.equals("a", test_charat(a, 0));
  Expect.equals("b", test_charat(a, 1));
  Expect.equals("c", test_charat(a, 2));
  Expect.throws(() => test_charat(a, 3));

  Expect.equals("a", test_const_str(0));
  for (var i = 0; i < 20; i++) test_const_str(0);
  Expect.equals("a", test_const_str(0));
  Expect.equals("b", test_const_str(1));
  Expect.equals("c", test_const_str(2));
  Expect.throws(() => test_const_str(3));

  Expect.equals("a", test_const_index(a));
  for (var i = 0; i < 20; i++) test_const_index(a);
  Expect.equals("a", test_const_index(a));
  Expect.equals("ø", test_const_index(b));
  Expect.equals(new String.fromCharCodes([123]), test_const_index(c));
  Expect.throws(() => test_const_index2(a));

  Expect.equals("ø", test_charat(b, 0));
  for (var i = 0; i < 20; i++) test_charat(b, 0);
  Expect.equals("ø", test_charat(b, 0));
  Expect.equals("b", test_charat(b, 1));
  Expect.equals("c", test_charat(b, 2));
  Expect.throws(() => test_charat(b, 3));

  Expect.equals(new String.fromCharCodes([123]), test_charat(c, 0));
  for (var i = 0; i < 20; i++) test_charat(c, 0);
  Expect.equals(new String.fromCharCodes([123]), test_charat(c, 0));
  Expect.equals(new String.fromCharCodes([456]), test_charat(c, 1));
  Expect.equals(new String.fromCharCodes([789]), test_charat(c, 2));
  Expect.throws(() => test_charat(c, 3));
}
