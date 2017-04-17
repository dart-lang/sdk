// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.mixin;

@MirrorsUsed(targets: "test.mixin")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class Super {}

class Mixin {}

class Mixin2 {}

class Mixin3 {}

class MixinApplication = Super with Mixin;

class Class extends Super with Mixin {}

class MultipleMixins extends Super with Mixin, Mixin2, Mixin3 {}

main() {
  Expect.equals(reflectClass(Mixin), reflectClass(MixinApplication).mixin);
  Expect.equals(
      reflectClass(Super), reflectClass(MixinApplication).superclass.mixin);

  Expect.equals(reflectClass(Class), reflectClass(Class).mixin);
  Expect.equals(reflectClass(Mixin), reflectClass(Class).superclass.mixin);
  Expect.equals(
      reflectClass(Super), reflectClass(Class).superclass.superclass.mixin);

  Expect.equals(
      reflectClass(MultipleMixins), reflectClass(MultipleMixins).mixin);
  Expect.equals(
      reflectClass(Mixin3), reflectClass(MultipleMixins).superclass.mixin);
  Expect.equals(reflectClass(Mixin2),
      reflectClass(MultipleMixins).superclass.superclass.mixin);
  Expect.equals(reflectClass(Mixin),
      reflectClass(MultipleMixins).superclass.superclass.superclass.mixin);
  Expect.equals(
      reflectClass(Super),
      reflectClass(MultipleMixins)
          .superclass
          .superclass
          .superclass
          .superclass
          .mixin);
}
