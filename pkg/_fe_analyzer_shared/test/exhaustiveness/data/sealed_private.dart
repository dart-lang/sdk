// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class S1 {}

// Pretend that this is inaccessible for testing 'reduced'.
sealed class _S1Impl extends S1 {}

sealed class A1 implements S1 {}

sealed class B1 implements S1 {}

// Pretend that this is inaccessible for testing 'reduced'.
class _A1Impl extends _S1Impl implements A1 {}

// Pretend that this is inaccessible for testing 'reduced'.
class _B1Impl extends _S1Impl implements B1 {}

nonExhaustive1(S1 x) => /*
 checkingOrder={S1,_S1Impl,A1,B1,_A1Impl,_B1Impl,_A1Impl,_B1Impl},
 error=non-exhaustive:_A1Impl();_B1Impl();_A1Impl();_B1Impl(),
 expandedSubtypes={_A1Impl,_B1Impl,_A1Impl,_B1Impl},
 reduced=non-exhaustive:A1();B1(),
 subtypes={_S1Impl,A1,B1},
 type=S1
*/
    switch (x) {};

sealed class S2 {}

sealed class A2 implements S2 {}

sealed class B2 implements S2 {}

// Pretend that this is inaccessible for testing 'reduced'.
sealed class _S2Impl extends S2 {}

// Pretend that this is inaccessible for testing 'reduced'.
class _A2Impl extends _S2Impl implements A2 {}

// Pretend that this is inaccessible for testing 'reduced'.
class _B2Impl extends _S2Impl implements B2 {}

nonExhaustive2(S2 x) => /*
 checkingOrder={S2,A2,B2,_S2Impl,_A2Impl,_B2Impl,_A2Impl,_B2Impl},
 error=non-exhaustive:_A2Impl();_B2Impl();_A2Impl();_B2Impl(),
 expandedSubtypes={_A2Impl,_B2Impl,_A2Impl,_B2Impl},
 reduced=non-exhaustive:A2();B2(),
 subtypes={A2,B2,_S2Impl},
 type=S2
*/
    switch (x) {};

sealed class S3 {}

// Pretend that this is inaccessible for testing 'reduced'.
sealed class _S3Impl extends S3 {}

sealed class A3 implements S3 {}

// Pretend that this is inaccessible for testing 'reduced'.
class _A3Impl extends _S3Impl implements A3 {}

nonExhaustive3(S3 x) => /*
 checkingOrder={S3,_S3Impl,A3,_A3Impl,_A3Impl},
 error=non-exhaustive:_A3Impl();_A3Impl(),
 expandedSubtypes={_A3Impl,_A3Impl},
 reduced=non-exhaustive:A3(),
 subtypes={_S3Impl,A3},
 type=S3
*/
    switch (x) {};

sealed class S4 {}

sealed class A4 implements S4 {}

// Pretend that this is inaccessible for testing 'reduced'.
sealed class _S4Impl extends S4 {}

// Pretend that this is inaccessible for testing 'reduced'.
class _A4Impl extends _S4Impl implements A4 {}

nonExhaustive4(S4 x) => /*
 checkingOrder={S4,A4,_S4Impl,_A4Impl,_A4Impl},
 error=non-exhaustive:_A4Impl();_A4Impl(),
 expandedSubtypes={_A4Impl,_A4Impl},
 reduced=non-exhaustive:A4(),
 subtypes={A4,_S4Impl},
 type=S4
*/
    switch (x) {};
