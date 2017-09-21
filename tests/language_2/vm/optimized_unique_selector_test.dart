// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  _uniqueSelector() {}
  final uniqueField = 10;
}

test1(obj) {
  var res = 0;
  for (var i = 0; i < 2; i++) {
    obj._uniqueSelector();
    res += obj.uniqueField; // This load must not be hoisted out of the loop.
  }
  return res;
}

test2(obj) {
  final objAlias = obj;
  closure() => objAlias;
  var res = 0;
  for (var i = 0; i < 2; i++) {
    obj._uniqueSelector();
    res +=
        objAlias.uniqueField; // This load must not be hoisted out of the loop.
  }
  return res;
}

var foofoo_ = test1;

main() {
  Expect.equals(20, foofoo_(new A()));
  Expect.throws(() => foofoo_(0));

  foofoo_ = test2;

  Expect.equals(20, foofoo_(new A()));
  Expect.throws(() => foofoo_(0));
}
