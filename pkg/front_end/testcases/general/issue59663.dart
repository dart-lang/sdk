// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  Function<Y extends X>(Y) foo;
  A(this.foo);
}

bar<T extends num>(T t) {}

main() {
  new A(bar);
}
