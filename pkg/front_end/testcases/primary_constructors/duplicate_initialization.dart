// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0 {
  int x;
  int y = 0;
  int z = 2;
  C0(this.x, this.z) : y = 1;
}

class C1(var int x, this.z) {
  int y = 0;
  int z = 2;
  this : y = 1;
}
