// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A<T> {}

class B<T> extends A<T> {}

main() {
  num x;
  var x1 = (x = 1);
  var x2 = (x = 1.0);

  A<int> y;
  var y1 = (y = new A());
  var y2 = (y = new B());
}
