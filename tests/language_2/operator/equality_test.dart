// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

class A {
  bool _result;
  A(this._result);
  operator ==(x) {
    return _result;
  }
}

opaque(x) => [x, 1, 'y'][0]; // confuse the optimizers.

class Death {
  operator ==(x) {
    throw 'Dead!';
  }
}

death() => opaque(new Death());
nullFn() => opaque(null);

tests() {
  var alwaysTrue = new A(true);
  var alwaysFalse = new A(false);
  Expect.isFalse(alwaysFalse == alwaysFalse);
  Expect.isTrue(alwaysFalse != alwaysFalse);
  Expect.isTrue(alwaysTrue == alwaysTrue);
  Expect.isTrue(alwaysTrue == 5);
  Expect.isFalse(alwaysTrue == null);
  Expect.isFalse(null == alwaysTrue);
  Expect.isTrue(alwaysTrue != null);
  Expect.isTrue(null != alwaysTrue);
  Expect.isTrue(null == null);
  Expect.isFalse(null != null);

  Expect.throws(() => death() == 5);
  Expect.isFalse(death() == nullFn());
  Expect.isFalse(nullFn() == death());
  Expect.isTrue(nullFn() == nullFn());
  Expect.isTrue(death() != nullFn());
  Expect.isTrue(nullFn() != death());
  Expect.isFalse(nullFn() != nullFn());

  if (death() == nullFn()) {
    throw "failed";
  }
  if (death() != nullFn()) {} else {
    throw "failed";
  }
}

boolEqualityPositiveA(a) => a == true;
boolEqualityNegativeA(a) => a != true;

boolEqualityPositiveB(a) => true == a;
boolEqualityNegativeB(a) => true != a;

main() {
  for (int i = 0; i < 20; i++) {
    tests();
    // Do not inline calls to prevent constant folding.
    Expect.isTrue(boolEqualityPositiveA(true));
    Expect.isFalse(boolEqualityPositiveA(false));
    Expect.isFalse(boolEqualityNegativeA(true));
    Expect.isTrue(boolEqualityNegativeA(false));

    Expect.isTrue(boolEqualityPositiveB(true));
    Expect.isFalse(boolEqualityPositiveB(false));
    Expect.isFalse(boolEqualityNegativeB(true));
    Expect.isTrue(boolEqualityNegativeB(false));
  }

  // Deoptimize.
  Expect.isFalse(boolEqualityPositiveA(1));
  Expect.isTrue(boolEqualityNegativeA("hi"));
  Expect.isFalse(boolEqualityPositiveB(2.0));
  Expect.isTrue(boolEqualityNegativeB([]));
}
