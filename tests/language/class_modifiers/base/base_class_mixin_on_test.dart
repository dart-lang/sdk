// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow a base type to appear in the "on" clause of a mixin declaration in
// another library.

import 'package:expect/expect.dart';
import 'base_class_mixin_on_lib.dart';

mixin MA on BaseClass {}
mixin MB on BaseClass {}

class ConcreteA extends A with MA, MB {
  int foo = 0;
}

mixin MC on BaseClass, BaseMixin {}

class ConcreteC extends C with MC {
  int foo = 0;
}

mixin MCSingular on BaseMixin {}

class ConcreteD extends D with MCSingular {
  int foo = 0;
}

main() {
  Expect.equals(0, ConcreteA().foo);
  Expect.equals(0, ConcreteC().foo);
  Expect.equals(0, ConcreteD().foo);
}
