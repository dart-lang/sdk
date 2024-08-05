// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/generic/metadata_test.dart

// @dart=2.12

// Check that annotations cannot use type arguments, but can be raw.

class C<T> {
  const C();
}

@C() // OK
@C<dynamic>() // Error
@C<int>() // Error
void foo() {}