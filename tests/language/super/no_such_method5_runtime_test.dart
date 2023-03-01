// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

import 'package:expect/expect.dart';

class A {
  int foo();

  noSuchMethod(im) => 42;
}

class B extends Object with A {

}

main() {
  Expect.equals(42, new B().foo());
}
