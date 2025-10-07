// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

void add(int x) {}
add2(int y) {}
test(Future<int> f) {
  var a = f.then(add);
  var b = f.then(add2);
}

main() {}
