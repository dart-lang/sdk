// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';

/*class: global#Future:typeArgument*/

/*class: A:checkedInstance,checks=[],instance*/
class A<T> {}

/*class: B:checkedTypeArgument,typeArgument*/
class B {}

/*class: C:typeArgument*/
class C {}

@pragma('dart2js:noInline')
test(o) => o as A<FutureOr<B>>;

main() {
  test(new A<B>());
  test(new A<Future<B>>());
  test(new A<C>());
  test(new A<Future<C>>());
}
