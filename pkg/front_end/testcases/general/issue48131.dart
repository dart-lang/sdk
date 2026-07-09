// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<X> {
  void foo<Y extends X>() {}
}

class B<Z> extends A<Z> {}

void main() {
  new B<Object>().foo<int>();
}
