// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

test(Future<int> base) {
  var f = base.then((x) {
    return x == 0;
  });
  var g = base.then((x) => x == 0);
  Future<bool> b = f;
  b = g;
}

main() {}
