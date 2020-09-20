// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:expect/expect.dart';

/*class: global#Future:typeArgument*/

/*class: A:checkedInstance,checks=[],instance*/
class A<T> {}

/*class: B:checkedTypeArgument,typeArgument*/
class B {}

/*class: C:typeArgument*/
class C {}

@pragma('dart2js:noInline')
test(o) => o is A<FutureOr<B>>;

main() {
  Expect.isTrue(test(new A<B>()));
  Expect.isTrue(test(new A<Future<B>>()));
  Expect.isFalse(test(new A<C>()));
  Expect.isFalse(test(new A<Future<C>>()));
}
