// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A1 {}

sealed class B1 implements A1 {}

abstract final class C1 implements B1 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl1 extends B1 implements C1 {}

nonExhaustive1(A1 a) => /*
 checkingOrder={A1,B1,C1,_CImpl1},
 error=non-exhaustive:C1();_CImpl1(),
 expandedSubtypes={C1,_CImpl1},
 reduced=non-exhaustive:C1(),
 subtypes={B1},
 type=A1
*/
    switch (a) {};

sealed class A2 {}

sealed class B2 implements A2 {}

abstract final class C2 implements B2 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl2a extends B2 implements C2 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl2b extends B2 implements C2 {}

nonExhaustive2(A2 a) => /*
 checkingOrder={A2,B2,C2,_CImpl2a,_CImpl2b},
 error=non-exhaustive:C2();_CImpl2a();_CImpl2b(),
 expandedSubtypes={C2,_CImpl2a,_CImpl2b},
 reduced=non-exhaustive:C2(),
 subtypes={B2},
 type=A2
*/
    switch (a) {};

sealed class A3 {}

sealed class B3 implements A3 {}

abstract final class C3 implements B3 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl3 extends B3 implements C3 {}

abstract final class D3 implements B3 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _DImpl3 extends B3 implements D3 {}

nonExhaustive3(A3 a) => /*
 checkingOrder={A3,B3,C3,_CImpl3,D3,_DImpl3},
 error=non-exhaustive:C3();_CImpl3();D3();_DImpl3(),
 expandedSubtypes={C3,_CImpl3,D3,_DImpl3},
 reduced=non-exhaustive:C3();D3(),
 subtypes={B3},
 type=A3
*/
    switch (a) {};

sealed class A4 {}

sealed class B4 implements A4 {}

abstract final class C4 implements B4 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl4a extends B4 implements C4 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl4b extends B4 implements C4 {}

abstract final class D4 implements B4 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _DImpl4a extends B4 implements D4 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _DImpl4b extends B4 implements D4 {}

nonExhaustive4(A4 a) => /*
 checkingOrder={A4,B4,C4,_CImpl4a,_CImpl4b,D4,_DImpl4a,_DImpl4b},
 error=non-exhaustive:C4();_CImpl4a();_CImpl4b();D4();_DImpl4a();_DImpl4b(),
 expandedSubtypes={C4,_CImpl4a,_CImpl4b,D4,_DImpl4a,_DImpl4b},
 reduced=non-exhaustive:C4();D4(),
 subtypes={B4},
 type=A4
*/
    switch (a) {};

sealed class A5 {}

sealed class B5 implements A5 {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _CImpl5 extends B5 implements C5 {}

abstract final class C5 implements B5 {}

nonExhaustive5(A5 a) => /*
 checkingOrder={A5,B5,_CImpl5,C5},
 error=non-exhaustive:_CImpl5();C5(),
 expandedSubtypes={_CImpl5,C5},
 reduced=non-exhaustive:C5(),
 subtypes={B5},
 type=A5
*/
    switch (a) {};
