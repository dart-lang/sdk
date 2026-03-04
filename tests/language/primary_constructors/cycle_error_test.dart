// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=primary-constructors

// Tests cycle errors for primary constructors.

class A() extends C {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'A' is a supertype of itself.

class B() extends A {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'B' is a supertype of itself.

class C() extends B {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'C' is a supertype of itself.


class SuperA(super.x) extends SuperC {}
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'SuperA' is a supertype of itself.
//                 ^
// [analyzer] COMPILE_TIME_ERROR.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL
// [cfe] The super constructor has no corresponding positional parameter.

class SuperB(super.x) extends SuperA {}
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'SuperB' is a supertype of itself.
//                 ^
// [analyzer] COMPILE_TIME_ERROR.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL
// [cfe] The super constructor has no corresponding positional parameter.

class SuperC(super.x) extends SuperB {}
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'SuperC' is a supertype of itself.
//                 ^
// [analyzer] COMPILE_TIME_ERROR.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL
// [cfe] The super constructor has no corresponding positional parameter.
