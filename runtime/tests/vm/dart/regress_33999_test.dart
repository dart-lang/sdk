// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test checking that canonicalization rules for AssertAssignable IL
// instructions take into account that these instructions can be
// on unreachable code paths.

// Class with two type parameters.
class A<U, T> {
  T? field1;
  List<T>? field2;
  T Function(T)? field3;
}

// Class with a single type parameter
class B<T> {
  T? field1;
  List<T>? field2;
  T Function(T)? field3;
}

var TRUE = true;

void foo(bool f) {
  dynamic x = f ? new B<int>() : new A<String, int>();
  if (f == TRUE) {
    // Prevent constant folding by accessing a global
    x.field1 = 10;
    x.field2 = <int>[];
    x.field3 = (int i) => ++i;
  } else {
    x.field1 = 10;
    x.field2 = <int>[];
    x.field3 = (int i) => ++i;
  }
}

void bar() {
  // When foo() is inlined into bar() a graph where
  // allocation of B will flow into code-path that
  // expects A will arise. On that code-path (which
  // is dynamically unreachable because it is guarded
  // by CheckClass) there will be an assert assignable
  // against A.T.
  // Canonicalization rule should not crash when it tries
  // to instantiate this type.
  foo(true);
}

void main() {
  // Execute both paths to populate ICData.
  foo(true);
  foo(false);

  // Force optimization of bar().
  for (var i = 0; i < 100000; i++) bar();
}
