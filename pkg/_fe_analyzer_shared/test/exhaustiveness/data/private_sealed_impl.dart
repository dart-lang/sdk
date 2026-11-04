// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}

sealed class B implements A {}

abstract final class C implements B {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl1 extends B implements C {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl2 extends B implements C {}

exhaustive0(A a) => /*
 checkingOrder={A,B,C,_CImpl1,_CImpl2},
 expandedSubtypes={C,_CImpl1,_CImpl2},
 subtypes={B},
 type=A
*/ switch (a) {
  _CImpl1() /*space=_CImpl1*/ => 0,
  _CImpl2() /*space=_CImpl2*/ => 1,
  C() /*space=C*/ => 2,
};

exhaustive1(A a) => /*
 checkingOrder={A,B,C,_CImpl1,_CImpl2},
 expandedSubtypes={C,_CImpl1,_CImpl2},
 subtypes={B},
 type=A
*/ switch (a) {
  C() /*space=C*/ => 0,
};

nonExhaustive0(A a) => /*
 checkingOrder={A,B,C,_CImpl1,_CImpl2},
 error=non-exhaustive:C(),
 expandedSubtypes={C,_CImpl1,_CImpl2},
 subtypes={B},
 type=A
*/ switch (a) {
  _CImpl1() /*space=_CImpl1*/ => 0,
  _CImpl2() /*space=_CImpl2*/ => 1,
};

nonExhaustive1(A a) => /*
 checkingOrder={A,B,C,_CImpl1,_CImpl2},
 error=non-exhaustive:C();_CImpl1();_CImpl2(),
 expandedSubtypes={C,_CImpl1,_CImpl2},
 reduced=non-exhaustive:C(),
 subtypes={B},
 type=A
*/
    switch (a) {};
