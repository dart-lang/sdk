// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S {
  int s1;
  int s2;
  S([this.s1 = 1, this.s2 = 2]);
}

class C extends S {
  int c1;
  C(this.c1, [int super.s1, int x = 0, int super.s2]);
}

main() {}
