// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A1 {}

sealed class B1 implements A1 {}

final class _C1aImpl extends B1 implements C1 {}

final class _C1bImpl extends B1 implements C1 {}

abstract final class C1 implements B1 {}

exhaustive1(A1 a) => /*
 checkingOrder={A1,B1,_C1aImpl,_C1bImpl,C1},
 error=non-exhaustive:_C1aImpl();_C1bImpl();C1(),
 expandedSubtypes={_C1aImpl,_C1bImpl,C1},
 reduced=non-exhaustive:C1(),
 subtypes={B1},
 type=A1
*/
    switch (a) {};

sealed class A2 {}

sealed class B2 implements A2 {}

final class _C2aImpl extends B2 implements C2 {}

abstract final class C2 implements B2 {}

final class _C2bImpl extends B2 implements C2 {}

exhaustive2(A2 a) => /*
 checkingOrder={A2,B2,_C2aImpl,C2,_C2bImpl},
 error=non-exhaustive:_C2aImpl();C2();_C2bImpl(),
 expandedSubtypes={_C2aImpl,C2,_C2bImpl},
 reduced=non-exhaustive:C2(),
 subtypes={B2},
 type=A2
*/
    switch (a) {};

sealed class A3 {}

sealed class B3 implements A3 {}

abstract final class C3 implements B3 {}

final class _C3aImpl extends B3 implements C3 {}

final class _C3bImpl extends B3 implements C3 {}

exhaustive3(A3 a) => /*
 checkingOrder={A3,B3,C3,_C3aImpl,_C3bImpl},
 error=non-exhaustive:C3();_C3aImpl();_C3bImpl(),
 expandedSubtypes={C3,_C3aImpl,_C3bImpl},
 reduced=non-exhaustive:C3(),
 subtypes={B3},
 type=A3
*/
    switch (a) {};
