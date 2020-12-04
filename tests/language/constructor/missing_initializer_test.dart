// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that it is an error for a class with no generative constructors to
// have a final instance variable without an initializing expression, except
// if it is `abstract` or `external`. The latter also holds in a class with
// generative constructors.

// Has factory, hence no default, hence no generative constructors.
abstract class A {
  final dynamic n;
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED
  // [cfe] Final field 'n' is not initialized.

  // Uninitialized, but no errors.
  abstract final int x1;
  abstract final int? x2;
  external final String x3;
  external final String? x4;

  factory A() = B;
}

class B implements A {
  dynamic get n => 1;
  int get x1 => 1;
  int? get x2 => null;
  String get x3 => "";
  String? get x4 => null;
}

class C = Object with A;
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
  // [cfe] The non-abstract class 'C' is missing implementations for these members:

// Has a generative constructor: default.
abstract class D {
  // Uninitialized, but no errors.
  abstract final int x1;
  abstract final int? x2;
  external final String x3;
  external final String? x4;
}

void main() {
  A();
  C();
  var _ = D;
}
