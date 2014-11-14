// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-use-osr

import "package:expect/expect.dart";

class X {
  operator * (other) => "NaNNaNNaNNaNBatman";
}

foo(x) => (x * 1.0) is double;

bar(x) {
  try {
    int i = (x * 1);
    return true;
  } catch (e) {
    return false;
  }
}

baz(x) => (x * 1) == x;

main() {
  for (var i = 0; i < 100; i++) {
    Expect.isTrue(foo(1.0));
    assert(() {
      Expect.isTrue(bar(-1 << 63));
      return true;
    });
    Expect.isTrue(baz(-1 << 63));
  }
  Expect.isFalse(foo(new X()));
  assert(() {
    Expect.isFalse(bar(new X()));
    return true;
  });
  Expect.isFalse(baz(new X()));
}

