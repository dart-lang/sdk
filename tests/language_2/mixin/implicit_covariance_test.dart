// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class A<T> {
  foo(T x);
}

abstract class B<T> implements A<T> {}

class C {
  foo(num x) {
    if (x is! num) {
      throw "Soundness issue: expected x to be num, got ${x.runtimeType}.";
    }
  }
}

class D<T extends num> extends C with B<T> {}

class E<T extends num> = C with B<T>;

test(B<dynamic> b) {
  b.foo("bar");
}

main() {
  Expect.throws<TypeError>(() => test(new D<int>()));
  Expect.throws<TypeError>(() => test(new E<int>()));
}
