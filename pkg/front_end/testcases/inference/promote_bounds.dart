// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class B {
  void foo();
}

abstract class C extends B {
  void bar();
}

void f<T extends B>(T a) {
  if (a is String) {
    // Not promoted; we can still call foo.
    a. /*@target=B::foo*/ foo();
  }
  if (a is C) {
    // Promoted; we can now call bar.
    /*@promotedType=f::T extends C*/ a. /*@target=C::bar*/ bar();
  }
}

main() {}
