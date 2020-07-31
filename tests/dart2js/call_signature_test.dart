// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test. Crash occurred when trying to create a signature function
// for the non-live 'call' method on the live class 'A'.

import 'package:expect/expect.dart';

class A<T> {
  /// Weird signature to ensure it isn't match by any call selector.
  call(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, {T? t}) {}
}

class B<T> {
  @pragma('dart2js:noInline')
  m(f) => f is Function(T);
}

@pragma('dart2js:noInline')
create() => new B<A<int>>();

main() {
  var o = create();
  new A();
  Expect.isTrue(o.m((A<int> i) => i));
  Expect.isFalse(o.m((A<String> i) => i));
}
