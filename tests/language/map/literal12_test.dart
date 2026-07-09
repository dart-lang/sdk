// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test relative order of key and value evaluation.

library map_literal12_test;

import "package:expect/expect.dart";

int x = 0;
void main() {
  var map1 = {++x: ++x};
  Expect.equals('{1: 2}', map1.toString());

  var map2 = {++x: ++x, ++x: ++x};
  Expect.equals('{3: 4, 5: 6}', map2.toString());
}
