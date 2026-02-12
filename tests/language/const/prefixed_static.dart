// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that static members can be used as constant expressions when
// prefixed with the library prefix.

import '' as self;

class A {
  static const int c = 0;
  static int let(int v) => v;
}

void f() {
  const _ = self.A.c;
  const _ = self.A.let;
  const _ = self.A.new;
}
