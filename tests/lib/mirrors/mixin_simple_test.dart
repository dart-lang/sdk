// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.mixin;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Super {}

class Mixin {}

class Mixin2 {}

class Class extends Super with Mixin {}

class MultipleMixins extends Class with Mixin2 {}

main() {
  Expect.equals(reflectClass(Class), reflectClass(Class).mixin);
  Expect.equals(reflectClass(Mixin), reflectClass(Class).superclass.mixin);
  Expect.equals(
      reflectClass(Super), reflectClass(Class).superclass.superclass.mixin);

  Expect.equals(
      reflectClass(MultipleMixins), reflectClass(MultipleMixins).mixin);
  Expect.equals(
      reflectClass(Mixin2), reflectClass(MultipleMixins).superclass.mixin);
  Expect.equals(reflectClass(Class),
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
