// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// case 2 - const variable must be initialized (variable list).

class A {
  static foo() {
    final Object x = 1, y, z = 3;
  }
}

