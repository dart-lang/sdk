// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on
// tests/language/nonfunction_type_aliases/usage_type_variable_error_test.dart

// Introduce an aliased type.

class A {
  A();
  A.named();
  static void staticMethod<X>() {}
}

typedef T<X extends A> = X;

// Use the aliased type.

class C {
  final T v12;

  C() : v12 = T(); // Error
}
