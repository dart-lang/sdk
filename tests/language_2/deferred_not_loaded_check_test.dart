// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import "deferred_not_loaded_check_lib.dart" deferred as lib;

// Test that we give appropriate errors when accessing an element that is not
// yet loaded.

var c;

expectSideEffect(test) {
  c = 0;
  test();
  Expect.isTrue(c == 1);
}

expectNoSideEffect(test) {
  c = 0;
  test();
  Expect.isTrue(c == 0);
}

expectThrowsNotLoaded(test) {
  Expect.throws(test, (e) => e is Error);
}

int sideEffect() {
  c = 1;
  return 10;
}

void main() {
  expectSideEffect(() {
    expectThrowsNotLoaded(() {
      lib.foo(sideEffect());
    });
  });
  expectNoSideEffect(() {
    expectThrowsNotLoaded(() {
      lib.C.foo(sideEffect());
    });
  });
  expectSideEffect(() {
    expectThrowsNotLoaded(() {
      new lib.C(sideEffect());
    });
  });
  expectThrowsNotLoaded(() {
    lib.a;
  });
  expectSideEffect(() {
    expectThrowsNotLoaded(() {
      lib.a = sideEffect();
    });
  });
  expectThrowsNotLoaded(() {
    lib.getter;
  });
  expectSideEffect(() {
    expectThrowsNotLoaded(() {
      lib.setter = sideEffect();
    });
  });
  expectNoSideEffect(() {
    expectThrowsNotLoaded(() {
      lib.list[sideEffect()] = sideEffect();
    });
  });
  expectSideEffect(() {
    expectThrowsNotLoaded(() {
      lib.closure(sideEffect());
    });
  });
}
