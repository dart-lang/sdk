// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of invocations.

import 'package:expect/expect.dart';

test0(x) {
  Expect.isTrue(x == 'argument0');
  return 'return0';
}

class C0 {
  static test1(x) {
    Expect.isTrue(x == 'argument1');
    return 'return1';
  }
}

class C1 {
  test2(x) {
    Expect.isTrue(x == 'argument2');
    return 'return2';
  }
}

class C2 {
  C2.test3(x) {
    Expect.isTrue(x == 'argument3');
  }
}

main() {
  Expect.isTrue(test0('argument0') == 'return0');
  Expect.isTrue(C0.test1('argument1') == 'return1');
  Expect.isTrue(new C1().test2('argument2') == 'return2');
  var c = new C2.test3('argument3');
  Expect.isTrue(c is C2);
}
