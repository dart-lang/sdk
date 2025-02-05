// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

abstract class Base {
  void f(int i);
  void g([int i]);
  void h({int i});
}

mixin Mixin implements Base {}

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
  d.f.expectStaticType<Exactly<void Function(int)>>();
  d.g.expectStaticType<Exactly<void Function([int])>>();
  d.h.expectStaticType<Exactly<void Function({int i})>>();
}
