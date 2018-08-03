/*
 * Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */
import "dart:async";
import "package:expect/expect.dart";
import "regress_27201_lib.dart" deferred as p;
import "regress_27201_bad_lib_path.dart" deferred as q;

test_loaded() {
  try {
    p.someFunc();
  } catch (e) {
    Expect.fail("Should not be here");
  }
  try {
    p.someGetter;
  } catch (e) {
    Expect.fail("Should not be here");
  }
  try {
    p.someSetter = 1;
  } catch (e) {
    Expect.fail("Should not be here");
  }
  try {
    p.Func;
  } catch (e) {
    Expect.fail("Should not be here");
  }
  try {
    Expect.isTrue(p.loadLibrary() is Future);
  } catch (e) {
    Expect.fail("Should not be here");
  }
}

main() {
  p.loadLibrary().then((v) {
    test_loaded();
  }, onError: (e) {
    Expect.fail("Should have loaded library!");
  });

  // Ensure bad library import is handled correctly.
  q.loadLibrary().then((v) {
    Expect.fail("Should have failed");
  }, onError: (e) {
    Expect.throws(() => q.x);
  });
}
