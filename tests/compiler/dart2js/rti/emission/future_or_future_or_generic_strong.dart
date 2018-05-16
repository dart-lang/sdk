// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

/*class: global#Future:checkedInstance*/

/*class: A:checks=[],instance*/
class A<T> {
  @NoInline()
  m(o) => o is FutureOr<B<T>>;
}

/*class: B:checkedInstance,checkedTypeArgument,checks=[],instance,typeArgument*/
class B<T> {}

/*class: C:checkedInstance,checkedTypeArgument,checks=[],typeArgument*/
class C {}

/*class: D:checkedInstance,checkedTypeArgument,checks=[],typeArgument*/
class D {}

main() {
  Expect.isTrue(new A<FutureOr<C>>().m(new B<C>()));
  Expect.isFalse(new A<FutureOr<D>>().m(new B<C>()));
}
