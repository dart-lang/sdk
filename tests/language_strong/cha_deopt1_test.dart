// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=100

// Test lazy deoptimization at field guards with deferred loading.

import "package:expect/expect.dart";
import "cha_deopt1_lib.dart";
import "cha_deopt1_deferred_lib.dart" deferred as d;

var loaded = false;

main() {
  for (var i = 0; i < 2000; i++) bla();
  Expect.equals(42, bla());
  d.loadLibrary().then((_) {
    loaded = true;
    Expect.equals("good horse", bla());
  });
}

make_t() {
  try {
    if (loaded) {
      return d.make_u();
    } else {
      return new T();
    }
  } catch (e) {}
}

bla() {
  var x = new X();
  x.test(make_t());
  return x.fld.m();
}

class X {
  T fld = new T();

  test(T t) {
    if (t != null) {
      T tmp = t;
      fld = tmp;
    }
  }
}
