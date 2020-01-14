// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<T> {
  bar<V>(T t, int u, V v) => t.toString() + u.toString() + v.toString();
  foo<U>(bar<V>(T t, U u, V v)) => bar<int>(1 as T, 2 as U, 3);
}

main() {
  var c = new C<int>();
  Expect.equals("123", c.foo<int>(c.bar));
}
