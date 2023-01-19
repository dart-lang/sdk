// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow an interface type to appear in the "on" clause of a mixin declaration
// in another library.

import 'package:expect/expect.dart';
import 'interface_class_mixin_on_lib.dart';

mixin MA on InterfaceClass {}
mixin MB on InterfaceClass {}

class ConcreteA extends A with MA, MB {
  int foo = 0;
}

mixin MC on InterfaceClass, InterfaceMixin {}

class ConcreteC extends C with MC {
  int foo = 0;
}

mixin MCSingular on InterfaceMixin {}

class ConcreteD extends D with MCSingular {
  int foo = 0;
}

main() {
  Expect.equals(0, ConcreteA().foo);
  Expect.equals(0, ConcreteC().foo);
  Expect.equals(0, ConcreteD().foo);
}
