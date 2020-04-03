// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

test() {
  Object x;
  Function f;
  x();
  x(3);
  f(5, 2);
  x.call();
  f.call;
  f.call(5, 2);
}

main() {}
