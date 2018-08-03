// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'package:expect/expect.dart';

test1(String a, String b) {
  return a == b;
}

var LEN = 500;

var ITER = 100000 / LEN;

measure(fn, a, b) {
  for (var i = 0; i < ITER; i++) {
    Expect.equals(true, fn(a, b));
  }
}

main() {
  var n = LEN;
  StringBuffer s = new StringBuffer();
  for (var i = 0; i < n; ++i) s.write("A");
  String t = s.toString();
  String u = s.toString();
  String v = s.toString() + "\u1234";
  String w = s.toString() + "\u1234";
  for (var i = 0; i < 10; i++) measure(test1, t, u);
  for (var i = 0; i < 10; i++) measure(test1, v, w);
}
