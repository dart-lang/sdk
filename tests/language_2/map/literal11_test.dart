// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use type arguments on constant maps.

library map_literal11_test;

import "package:expect/expect.dart";

void foo(Map m) {
  m[23] = 23; //# none: runtime error
}

void main() {
  Map<String, dynamic> map = {};
  foo(map);
}
