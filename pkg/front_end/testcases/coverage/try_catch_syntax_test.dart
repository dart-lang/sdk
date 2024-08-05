// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/exception/try_catch_syntax_test.dart

testIllegalRethrow() {
  try {
    rethrow; // Error
  } catch (e) {}

  try {} catch (e) {
  } finally {
    rethrow; // Error
  }
}
