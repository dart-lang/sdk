// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/co19/src/Language/Expressions/Instance_Creation/Const/syntax_t04.dart

class A {
  const A.name();
}

void foo() {
  const A.(); // Error
}
