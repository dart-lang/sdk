// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  int get foo;
  noSuchMethod(im) => 42;
}

class B extends A {
  noSuchMethod(im) => 87;

  get foo => super.foo;
}

main() {
  Expect.equals(42, new B().foo);
}
