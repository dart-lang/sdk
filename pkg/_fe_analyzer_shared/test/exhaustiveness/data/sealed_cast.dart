// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class M {}

class A extends M {}

class B extends M {}

class C extends M {}

class D implements A, B {}

method(M m) => /*
 checkingOrder={M,A,B,C},
 error=non-exhaustive:C(),
 subtypes={A,B,C},
 type=M
*/
    switch (m) {
      A() as B /*space=A?*/ => 0,
      B() /*space=B*/ => 1,
    };

main() {
  method(B());
  method(D());
}
