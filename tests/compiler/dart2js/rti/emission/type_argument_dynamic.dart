// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

/*class: A:checkedTypeArgument,checks=[],typeArgument*/
class A {}

/*class: B:checks=[$isA],typeArgument*/
class B implements A {}

/*class: C:checkedInstance,checks=[],instance*/
class C<T> {}

/*class: D:checks=[],typeArgument*/
class D {}

/*class: E:checks=[],instance*/
class E {
  @noInline
  m<T>() => new C<T>();
}

/*class: F:checks=[],instance*/
class F {
  @noInline
  m<T>() => false;
}

@noInline
test(o) => o is C<A>;

main() {
  dynamic o =
      new DateTime.now().millisecondsSinceEpoch == 0 ? new F() : new E();
  Expect.isTrue(test(o.m<B>()));
  Expect.isFalse(test(o.m<D>()));
}
