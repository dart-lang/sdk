// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A1 {}

sealed class B1 implements A1 {}

abstract final class C1 implements B1 {}

// Pretend that this is accessible for testing 'reduced'.
final class C1Impl extends B1 implements C1 {}

test1(A1 a) => /*
 checkingOrder={A1,B1,C1,C1Impl},
 error=non-exhaustive:C1();C1Impl(),
 expandedSubtypes={C1,C1Impl},
 subtypes={B1},
 type=A1
*/
    switch (a) {};

test2(A1 a) => /*
 checkingOrder={A1,B1,C1,C1Impl},
 expandedSubtypes={C1,C1Impl},
 subtypes={B1},
 type=A1
*/ switch (a) {
  B1() /*space=B1*/ => 0,
};

test3(A1 a) => /*
 checkingOrder={A1,B1,C1,C1Impl},
 expandedSubtypes={C1,C1Impl},
 subtypes={B1},
 type=A1
*/ switch (a) {
  C1() /*space=C1*/ => 0,
};

sealed class A2;
sealed class B2 extends A2;
class C2 extends A2;
class D2 extends B2;
class E2 extends B2;
class F2 extends B2;

exhaustive(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
  D2() /*space=D2*/ => 1,
  E2() /*space=E2*/ => 2,
  F2() /*space=F2*/ => 3,
};

nonExhaustive3a(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
  D2() /*space=D2*/ => 1,
  E2() /*space=E2*/ => 2,
};

nonExhaustive3b(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:E2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
  D2() /*space=D2*/ => 1,
  F2() /*space=F2*/ => 2,
};

nonExhaustive3c(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:D2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
  E2() /*space=E2*/ => 1,
  F2() /*space=F2*/ => 2,
};

nonExhaustive3d(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  D2() /*space=D2*/ => 0,
  E2() /*space=E2*/ => 1,
  F2() /*space=F2*/ => 2,
};

nonExhaustive2a(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:E2();F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
  D2() /*space=D2*/ => 1,
};

nonExhaustive2b(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:D2();F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
  E2() /*space=E2*/ => 1,
};

nonExhaustive2c(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:D2();E2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
  F2() /*space=F2*/ => 1,
};

nonExhaustive2d(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2();F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  D2() /*space=D2*/ => 0,
  E2() /*space=E2*/ => 1,
};

nonExhaustive2e(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2();E2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  D2() /*space=D2*/ => 0,
  F2() /*space=F2*/ => 1,
};

nonExhaustive2f(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2();D2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  E2() /*space=E2*/ => 0,
  F2() /*space=F2*/ => 1,
};

nonExhaustive1a(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:D2();E2();F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  C2() /*space=C2*/ => 0,
};

nonExhaustive1b(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2();E2();F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  D2() /*space=D2*/ => 0,
};

nonExhaustive1c(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2();D2();F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  E2() /*space=E2*/ => 0,
};

nonExhaustive1d(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2();D2();E2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/ switch (a) {
  F2() /*space=F2*/ => 0,
};

nonExhaustive0(A2 a) => /*
 checkingOrder={A2,B2,C2,D2,E2,F2},
 error=non-exhaustive:C2();D2();E2();F2(),
 expandedSubtypes={D2,E2,F2,C2},
 subtypes={B2,C2},
 type=A2
*/
    switch (a) {};
