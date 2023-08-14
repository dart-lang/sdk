// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mixing in a mixin class outside its library.

import 'package:expect/expect.dart';
import 'mixin_class_lib.dart';

abstract class OutsideA with Class {}

class OutsideAImpl extends OutsideA {}

class OutsideB with Class {}

class OutsideC = Object with Class;

abstract class OutsideD with Class, Mixin {}

class OutsideDImpl extends OutsideD {}

class OutsideE with Class, Mixin {}

class OutsideF with NamedMixinClassApplication {
  // To avoid runtime error with DDC until issue 50489 is fixed.
  int foo = 0;
}

class OutsideG with AbstractMixinClass {}

main() {
  Expect.equals(0, OutsideAImpl().foo);
  Expect.equals(0, OutsideB().foo);
  Expect.equals(0, OutsideC().foo);
  Expect.equals(0, OutsideDImpl().foo);
  Expect.equals(0, OutsideE().foo);
  Expect.equals(0, OutsideF().foo);
  Expect.equals(0, OutsideG().foo);
}
