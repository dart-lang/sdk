// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Base {
  int constant1000() => 1000;
}

class Foo extends Base {
  final int base;
  Foo(this.base);

  nestedAdderFunction(a, b, c, d, e) {
    var result = a + b;
    return () {
      var result2 = c + d;
      return () {
        return base + result + result2 + e;
      };
    };
  }

  nestedAdderFunction2(a, b, c, d, e) {
    var result = a + b;
    return () {
      var base = super.constant1000;
      var result2 = c + d;
      return () {
        return base() + result + result2 + e;
      };
    };
  }
}

nestedAdderFunction(a, b, c, d, e) {
  var result = a + b;
  return () {
    var result2 = c + d;
    return () {
      return result + result2 + e;
    };
  };
}

main() {
  Expect.isTrue(nestedAdderFunction(1, 2, 3, 4, 5)()() == 15);

  var foo = new Foo(100);
  Expect.isTrue(foo.nestedAdderFunction(1, 2, 3, 4, 5)()() == 115);
  Expect.isTrue(foo.nestedAdderFunction2(1, 2, 3, 4, 5)()() == 1015);

  var funs = [];
  for (int i = 0; i < 3; i++) {
    funs.add(() => i);
  }
  Expect.isTrue((funs[0]() + funs[1]() + funs[2]()) == 3);

  var funs2 = [];
  for (var i in [0, 1, 2]) {
    funs2.add(() => i);
  }
  Expect.isTrue((funs2[0]() + funs2[1]() + funs2[2]()) == 3);
}
