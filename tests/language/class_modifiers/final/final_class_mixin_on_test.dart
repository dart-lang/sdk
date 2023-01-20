// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow a final type to appear in the "on" clause of a mixin declaration in
// another library.

import 'package:expect/expect.dart';
import 'final_class_mixin_on_lib.dart';

mixin MA on FinalClass {}
mixin MB on FinalClass {}

class ConcreteA extends A with MA, MB {
  int foo = 0;
}

mixin MC on FinalClass, FinalMixin {}

class ConcreteC extends C with MC {
  int foo = 0;
}

mixin MCSingular on FinalMixin {}

class ConcreteD extends D with MCSingular {
  int foo = 0;
}

main() {
  Expect.equals(0, ConcreteA().foo);
  Expect.equals(0, ConcreteC().foo);
  Expect.equals(0, ConcreteD().foo);
}
