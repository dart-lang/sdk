// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "mixin_from_dill_lib1.dart" as lib1;
import "mixin_from_dill_lib2.dart" as lib2;

main() {
  lib1.Foo foo1 = new lib1.Foo();
  if (foo1 == null) throw "what?";
  if (!(foo1 == foo1)) throw "what?";
  foo1.x();
  lib2.Foo foo2 = new lib2.Foo();
  if (foo2 == null) throw "what?";
  if (!(foo2 == foo2)) throw "what?";
  foo2.x();
}
