// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class A {
  bool _result;
  A(this._result);
  operator ==(x) { return _result; }
}


opaque(x) => [x,1,'y'][0];  // confuse the optimizers.

class Death {
  operator ==(x) { throw 'Dead!'; }
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
}

main() {
  for (int i = 0; i < 1000; i++) tests();
}
