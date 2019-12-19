// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if an optional parameter (named or otherwise) with
// no default value has a potentially non-nullable type.
main() {}

// Non-nullable types
void f01({int a = 0}) {}
void f02({int a}) {} //# 01: compile-time error
void f03({required int a}) {}
void f04([int a = 0]) {}
void f05([int a]) {} //# 02: compile-time error
void f06(int a) {}

// Nullable types
void f07({int? a = 0}) {}
void f08({int? a}) {}
void f09({required int? a}) {}
void f10([int? a = 0]) {}
void f11([int? a]) {}
void f12(int? a) {}

class A {
  var f;
  A(void this.f({String s})) {}
}
typedef void f13({String s});
void printToLog(void f({String s})) {}
void Function({String s})? f14;

class B<T extends Object?> {
  // Potentially non-nullable types
  void f15({T a = null}) {} //# 03: compile-time error
  void f16({T a}) {} //# 04: compile-time error
  void f17({required T a}) {}
  void f18([T a = null]) {} //# 05: compile-time error
  void f19([T a]) {} //# 06: compile-time error
  void f20(T a) {}

  // Nullable types
  void f21({T? a = null}) {}
  void f22({T? a}) {}
  void f23({required T? a}) {}
  void f24([T? a = null]) {}
  void f25([T? a]) {}
  void f26(T? a) {}
}

class C<T extends Object> {
  // Non-nullable types
  void f27({T a = null}) {} //# 07: compile-time error
  void f28({T a}) {} //# 08: compile-time error
  void f29({required T a}) {}
  void f30([T a = null]) {} //# 09: compile-time error
  void f31([T a]) {} //# 10: compile-time error
  void f32(T a) {}

  // Nullable types
  void f33({T? a = null}) {}
  void f34({T? a}) {}
  void f35({required T? a}) {}
  void f36([T? a = null]) {}
  void f37([T? a]) {}
  void f38(T? a) {}
}
