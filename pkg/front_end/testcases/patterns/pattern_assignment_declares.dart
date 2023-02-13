// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  dynamic field1;
  dynamic field2;
}

method(x, y, z) {
  var a;
  (a, int b, final int c) = x;
  [a, final d] = y;
  Class(field1: a, field2: [[var e, _], [1, var f]]) = z;
}
