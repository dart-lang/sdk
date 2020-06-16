// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class A {}

class B implements A {}

class C<T> {}

class D {}

class E {
  @pragma('dart2js:noInline')
  m<T>() => new C<T>();
}

class F {
  @pragma('dart2js:noInline')
  m<T>() => false;
}

@pragma('dart2js:noInline')
test(o) => o is C<A>;

main() {
  dynamic o =
      new DateTime.now().millisecondsSinceEpoch == 0 ? new F() : new E();
  Expect.isTrue(test(o.m<B>()));
  Expect.isFalse(test(o.m<D>()));
}
