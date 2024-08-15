// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/generic/instantiate_type_variable_test.dart

// Test that you cannot instantiate a type variable.

class Foo<T> {
  Foo() {}
  dynamic make() {
    return new T(); // Error
  }
}
