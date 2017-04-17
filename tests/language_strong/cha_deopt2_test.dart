// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=100

// Test lazy deoptimization at type checks with deferred loading.

import "package:expect/expect.dart";
import "cha_deopt2_lib.dart";
import "cha_deopt2_deferred_lib.dart" deferred as d;

var loaded = false;

main() {
  for (var i = 0; i < 2000; i++) bla();
  Expect.equals(1, bla());
  d.loadLibrary().then((_) {
    loaded = true;
    Expect.equals(1, bla());
  });
}

make_array() {
  try {
    if (loaded) {
      return [new A(), new B(), new C(), new D(), new E(), d.make_u()];
    } else {
      return [new A(), new B(), new C(), new D(), new E(), new T()];
    }
  } catch (e) {}
}

bla() {
  var count = 0;
  for (var x in make_array()) {
    if (x is T) count++;
  }
  return count;
}
