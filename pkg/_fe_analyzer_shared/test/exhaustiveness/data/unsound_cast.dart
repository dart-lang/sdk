// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This exercises unsound code in version <= 3.2.

sealed class S {}

class A extends S {}

class B extends S {}

class C extends S {}

class X extends A {}

class Y extends B {}

class Z implements A, B {}

method(S s) => /*
 checkingOrder={S,A,B,C},
 error=non-exhaustive:A();B();C(),
 subtypes={A,B,C},
 type=S
*/
    switch (s) {
      X() as A /*space=X?*/ => 0,
      Y() as B /*space=Y?*/ => 1,
    };

test() {
  method(Z());
}
