// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

mixin class A {
  int foo();

  noSuchMethod(im) => 42;
}

class B extends Object with A {}

main() {
  Expect.equals(42, A().foo());
  Expect.equals(42, B().foo());
}
