// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow a final type to appear in the "on" clause of a mixin declaration.

import 'package:expect/expect.dart';

final class FinalClass {}

abstract final class A extends FinalClass {}

final class B extends FinalClass {}

final mixin FinalMixin {}

final class C extends FinalClass with FinalMixin {}

final class D with FinalMixin {}

final mixin MA on FinalClass {}
final mixin MB on FinalClass {}

final class ConcreteA extends A with MA, MB {
  int foo = 0;
}

final mixin MC on FinalClass, FinalMixin {}

final class ConcreteC extends C with MC {
  int foo = 0;
}

final mixin MCSingular on FinalMixin {}

final class ConcreteD extends D with MCSingular {
  int foo = 0;
}

main() {
  Expect.equals(0, ConcreteA().foo);
  Expect.equals(0, ConcreteC().foo);
  Expect.equals(0, ConcreteD().foo);
}
