// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From tests/co19/src/Language/Statements/For/syntax_t09.dart

void foo() {
  for (
    var x, // Error
    y in List.filled(10, "")
  ) break;
}
