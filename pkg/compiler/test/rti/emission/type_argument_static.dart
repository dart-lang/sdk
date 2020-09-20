// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*class: A:checkedTypeArgument,typeArgument*/
class A {}

/*class: B:typeArgument*/
class B implements A {}

/*class: C:checkedInstance,checks=[],instance*/
class C<T> {}

/*class: D:typeArgument*/
class D {}

@pragma('dart2js:noInline')
m<T>() => new C<T>();

@pragma('dart2js:noInline')
test(o) => o is C<A>;

main() {
  Expect.isTrue(test(m<B>()));
  Expect.isFalse(test(m<D>()));
}
