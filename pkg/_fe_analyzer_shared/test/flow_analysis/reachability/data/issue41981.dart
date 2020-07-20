// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test(Null n) {
  0;
  if (n != null)
    /*stmt: unreachable*/ 1;
  2;
}
