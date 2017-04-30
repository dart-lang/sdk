// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

main() {
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
  f8() => /*error:REFERENCED_BEFORE_DECLARATION*/ f9();
  f9() => f5();
}
