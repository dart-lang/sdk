// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class Mixin1<T> {}

abstract class Mixin2<T> {}

class A {
  A(foo);
}

class B<K, V> extends A with Mixin1<K>, Mixin2<V> {
  B(foo) : super(foo);
}

main() {
  var b = new B<num, String>(null);
  Expect.isTrue(b is Mixin1<num>);
  Expect.isTrue(b is! Mixin1<String>);
  Expect.isTrue(b is Mixin2<String>);
  Expect.isTrue(b is! Mixin2<num>);
}
