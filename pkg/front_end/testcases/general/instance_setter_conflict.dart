// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int v = 0;
}

class C extends A {
  static int n = 0;
  static get v {
    return n;
  }
}

main() {}
