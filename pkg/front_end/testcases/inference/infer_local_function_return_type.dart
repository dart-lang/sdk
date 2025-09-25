// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

test() {
  f0() => 42;
  f1() async => 42;

  f2() {
    return 42;
  }

  f3() async {
    return 42;
  }

  f4() sync* {
    yield 42;
  }

  f5() async* {
    yield 42;
  }

  num f6() => 42;

  f7() => f7();
  f8() => f5();

  var v0 = f0;
  var v1 = f1;
  var v2 = f2;
  var v3 = f3;
  var v4 = f4;
  var v5 = f5;
  var v6 = f6;
  var v7 = f7;
  var v8 = f8;
}

main() {}
