// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

var result;

class A {
  set foo(int a);
  
  noSuchMethod(im) {
    result = 42;
  }
}

class B extends A {
  noSuchMethod(im) {
    result = 87;
  }

  set foo(v) => super.foo = v;
}

main() {
  new B().foo = 0;
  Expect.equals(42, result);
}
