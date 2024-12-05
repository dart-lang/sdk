// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/corelib/symbol_reserved_word_test.dart

void foo() {
  var x;

  // 'void' is allowed as a symbol name.
  x = const Symbol('void');
  x = #void;
  x = new Symbol('void');
}
