// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo<X, Y>(X x, String y) {
  if (x is Y) {
    var v = x ?? y;
  }
}
