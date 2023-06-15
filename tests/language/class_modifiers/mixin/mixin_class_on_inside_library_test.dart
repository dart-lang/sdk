// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure mixin classes can be used in an on clause for another mixin inside
// of its library.

import 'package:expect/expect.dart';

mixin class Class {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}

mixin MA on Class {}
mixin MB on Class {}

abstract class A extends Class {}

class ConcreteA extends A with MA, MB {
  int foo = 0;
}

mixin MC on Class, Mixin {}

class B extends Class with Mixin {}

class ConcreteB extends B with MC {
  int foo = 0;
}

class C with Mixin {}

mixin MCSingular on Mixin {}

class ConcreteC extends C with MCSingular {
  int foo = 0;
}

main() {
  Expect.equals(0, ConcreteA().foo);
  Expect.equals(0, ConcreteB().foo);
  Expect.equals(0, ConcreteC().foo);
}
