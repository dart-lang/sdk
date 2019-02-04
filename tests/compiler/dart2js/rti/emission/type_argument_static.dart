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

@noInline
m<T>() => new C<T>();

@noInline
test(o) => o is C<A>;

main() {
  Expect.isTrue(test(m<B>()));
  Expect.isFalse(test(m<D>()));
}
