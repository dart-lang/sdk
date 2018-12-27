// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  foo<Y extends X>() {}
}

class B extends A<dynamic> {}

bar(B b) {
  b.foo();
}

main() {}
