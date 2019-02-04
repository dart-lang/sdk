// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Thing {}

class SubThing extends Thing {
  void sub() {}
}

class A {
  Thing get thing => new Thing();
}

abstract class B implements A {
  @override
  SubThing get thing;
}

class C extends A //
    with //# mixin: compile-time error
        B //# mixin: continued
{}

main() {
  new C()
          .thing //
          .sub() //# mixin: continued
      ;
}
