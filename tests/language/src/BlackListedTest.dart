// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test checking that static/instance field shadowing do not conflict.

// Test that certain interfaces/classes are blacklisted from being
// implemented or extended.

// bool.
class MyBool implements bool {}                 /// 01: compile-time error
interface MyBoolInterface extends bool {}       /// 02: compile-time error

// num.
class MyNum implements num {}                   /// 03: compile-time error
interface MyNumInterface extends num {}         /// 04: compile-time error

// int.
class MyInt implements int {}                   /// 05: compile-time error
interface MyIntInterface extends int {}         /// 06: compile-time error

// double.
class MyDouble implements double {}            /// 07: compile-time error
interface MyDoubleInterface extends double {}  /// 08: compile-time error

// String.
class MyString implements String {}            /// 09: compile-time error
interface MyStringInterface extends String {}  /// 10: compile-time error

// Function.
class MyFunction implements Function {}        /// 11: compile-time error
interface MyFunctionInterface extends Function {}  /// 12: compile-time error

main() {
}