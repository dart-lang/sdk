// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

abstract class Base {
  void f(int i);
  void g([int i]);
  void h({int i});
}

abstract class Mixin implements Base {}

class Derived extends Object with Mixin {
  // Type `(int) -> void` should be inherited from `Base`
  f(i) {}

  // Type `([int]) -> void` should be inherited from `Base`
  g([i = -1]) {}

  // Type `({h: int}) -> void` should be inherited from `Base`
  h({i = -1}) {}
}

main() {
  var d = new Derived();






}
