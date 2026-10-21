// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A1 {}

sealed class B1 implements A1 {}

final class _C1Impl extends B1 implements C1 {}

final class _B1Impl extends B1 {}

abstract final class C1 implements B1 {}

exhaustive1(A1 a) => /*
 checkingOrder={A1,B1,_C1Impl,_B1Impl,C1},
 error=non-exhaustive:_C1Impl();_B1Impl();C1(),
 expandedSubtypes={_C1Impl,_B1Impl,C1},
 reduced=non-exhaustive:C1();needsDefault,
 subtypes={B1},
 type=A1
*/
    switch (a) {};

sealed class A2 {}

sealed class B2 implements A2 {}

final class _C2Impl extends B2 implements C2 {}

abstract final class C2 implements B2 {}

final class _B2Impl extends B2 {}

exhaustive2(A2 a) => /*
 checkingOrder={A2,B2,_C2Impl,C2,_B2Impl},
 error=non-exhaustive:_C2Impl();C2();_B2Impl(),
 expandedSubtypes={_C2Impl,C2,_B2Impl},
 reduced=non-exhaustive:C2();needsDefault,
 subtypes={B2},
 type=A2
*/
    switch (a) {};

sealed class A3 {}

sealed class B3 implements A3 {}

abstract final class C3 implements B3 {}

final class _C3Impl extends B3 implements C3 {}

final class _B3Impl extends B3 {}

exhaustive3(A3 a) => /*
 checkingOrder={A3,B3,C3,_C3Impl,_B3Impl},
 error=non-exhaustive:C3();_C3Impl();_B3Impl(),
 expandedSubtypes={C3,_C3Impl,_B3Impl},
 reduced=non-exhaustive:C3();needsDefault,
 subtypes={B3},
 type=A3
*/
    switch (a) {};

sealed class A4 {}

sealed class B4 implements A4 {}

final class _B4Impl extends B4 {}

final class _C4Impl extends B4 implements C4 {}

abstract final class C4 implements B4 {}

exhaustive4(A4 a) => /*
 checkingOrder={A4,B4,_B4Impl,_C4Impl,C4},
 error=non-exhaustive:_B4Impl();_C4Impl();C4(),
 expandedSubtypes={_B4Impl,_C4Impl,C4},
 reduced=non-exhaustive:C4();needsDefault,
 subtypes={B4},
 type=A4
*/
    switch (a) {};

sealed class A5 {}

sealed class B5 implements A5 {}

final class _B5Impl extends B5 {}

abstract final class C5 implements B5 {}

final class _C5Impl extends B5 implements C5 {}

exhaustive5(A5 a) => /*
 checkingOrder={A5,B5,_B5Impl,C5,_C5Impl},
 error=non-exhaustive:_B5Impl();C5();_C5Impl(),
 expandedSubtypes={_B5Impl,C5,_C5Impl},
 reduced=non-exhaustive:C5();needsDefault,
 subtypes={B5},
 type=A5
*/
    switch (a) {};

sealed class A6 {}

sealed class B6 implements A6 {}

abstract final class C6 implements B6 {}

final class _B6Impl extends B6 {}

final class _C6Impl extends B6 implements C6 {}

exhaustive6(A6 a) => /*
 checkingOrder={A6,B6,C6,_B6Impl,_C6Impl},
 error=non-exhaustive:C6();_B6Impl();_C6Impl(),
 expandedSubtypes={C6,_B6Impl,_C6Impl},
 reduced=non-exhaustive:C6();needsDefault,
 subtypes={B6},
 type=A6
*/
    switch (a) {};
