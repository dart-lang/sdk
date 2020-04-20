// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B {
  void f(int x, int y) {}
}

abstract class I<T> {
  void f(T x, int y);
}

class C extends B implements I<int> {}

void main() {}
