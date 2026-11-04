// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A1 {}

sealed class B1 implements A1 {}

abstract final class C1 implements B1 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _B1Impl extends B1 {}

nonExhaustive1a(A1 a) => /*
 checkingOrder={A1,B1,C1,_B1Impl},
 error=non-exhaustive:C1();_B1Impl(),
 expandedSubtypes={C1,_B1Impl},
 reduced=non-exhaustive:C1();needsDefault,
 subtypes={B1},
 type=A1
*/
    switch (a) {};

nonExhaustive1b(A1 a) => /*
 checkingOrder={A1,B1,C1,_B1Impl},
 error=non-exhaustive:_B1Impl(),
 expandedSubtypes={C1,_B1Impl},
 reduced=non-exhaustive:needsDefault,
 subtypes={B1},
 type=A1
*/ switch (a) {
  C1() /*space=C1*/ => 0,
};

sealed class A2 {}

sealed class B2 implements A2 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _B2Impl extends B2 {}

abstract final class C2 implements B2 {}

nonExhaustive2a(A2 a) => /*
 checkingOrder={A2,B2,_B2Impl,C2},
 error=non-exhaustive:_B2Impl();C2(),
 expandedSubtypes={_B2Impl,C2},
 reduced=non-exhaustive:C2();needsDefault,
 subtypes={B2},
 type=A2
*/
    switch (a) {};

nonExhaustive2b(A2 a) => /*
 checkingOrder={A2,B2,_B2Impl,C2},
 error=non-exhaustive:_B2Impl(),
 expandedSubtypes={_B2Impl,C2},
 reduced=non-exhaustive:needsDefault,
 subtypes={B2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
};
