// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that private names exported via public typedefs may not appear multiple
// times in a super-interface graph.

import "private_name_library.dart";

/// Test that having a private class in the implements and extends class via two
/// different public names is an error.
class A0 extends PublicClass implements AlsoPublicClass {
//    ^
// [cfe] '_PrivateClass' can't be used in both 'extends' and 'implements' clauses.
//                                      ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_SUPER_CLASS
}

/// Test that having a private class in the implements class twice via the same
/// public name is an error.
class A1 implements PublicClass, PublicClass {
//                               ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_REPEATED
// [cfe] unspecified
  noSuchMethod(_) => null;
}

/// Test that having a private class in the implements class twice via two
/// different public names is an error.
class A2 implements PublicClass, AlsoPublicClass {
//                               ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_REPEATED
// [cfe] unspecified
  noSuchMethod(_) => null;
}

/// Helper class for the following test
class A3 extends PublicGenericClassOfInt {}

/// Test that having a private generic class in the super-interface graph
/// twice with two different generic instantiations is an error.
class A4 extends A3 implements PublicGenericClass<String> {
// [error line 42, column 7, length 2]
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
//    ^
// [cfe] 'A4' can't implement both '_PrivateGenericClass<int>' and '_PrivateGenericClass<String>'
}

/// Test that having a private generic class in the super-interface graph
/// twice at the same instantiation is not an error.
class A5 extends A3 implements PublicGenericClass<int> {}

/// Test that having a private generic class in the implements clause twice with
/// two different generic instantiations is an error.
class A6 implements PublicGenericClass<int>, PublicGenericClass<String> {
// [error line 55, column 7, length 2]
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
//    ^
// [cfe] 'A6' can't implement both '_PrivateGenericClass<int>' and '_PrivateGenericClass<String>'
//                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_REPEATED
}

void main() {}
