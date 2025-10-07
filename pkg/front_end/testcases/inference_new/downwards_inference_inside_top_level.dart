// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A {
  B<int> b = throw '';
}

class B<T> {
  B(T x);
}

var t3 = [new B(3)];

main() {}
