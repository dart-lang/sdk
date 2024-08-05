// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/set_literals/invalid_set_literal_test.dart

void foo() {
  var x = <int>{1}; // OK
  var y = <int>{1: 1}; // Error
}