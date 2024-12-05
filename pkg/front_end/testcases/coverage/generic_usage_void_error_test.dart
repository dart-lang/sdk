// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on
// tests/language/nonfunction_type_aliases/generic_usage_void_error_test.dart

// Introduce an aliased type.

typedef T<X> = void;

// Use the aliased type.

abstract class C {
  final T<Null> v7;

  C(): v7 = T(); // Error
}
