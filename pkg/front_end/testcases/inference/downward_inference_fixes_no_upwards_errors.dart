// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:math';

// T max<T extends num>(T x, T y);
f(num x, dynamic y) {
  num a = max(x, /*info:DYNAMIC_CAST*/ y);
  Object b = max(x, /*info:DYNAMIC_CAST*/ y);
  dynamic c = max(x, y);
  var d = max(x, y);
}

main() {}
