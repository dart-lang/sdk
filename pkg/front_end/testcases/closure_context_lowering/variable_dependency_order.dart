// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M {
  foo() {
    int x = 0;
    int y = 0;
    int z = y;
    return () => x + z;
  }
}

class A with M {}
