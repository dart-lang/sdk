// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

getNonArray() => new A();

class A {
  operator [](index) => index;
}

main() {
  Expect.equals(42, () {
    var res;
    do {
      var a = getNonArray();
      res = a[42];
    } while (false);
    return res;
  }());
}
