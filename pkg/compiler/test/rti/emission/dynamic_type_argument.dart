// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*class: A:checkedInstance,checks=[],instance*/
class A<T> {}

/*class: B:checkedTypeArgument,typeArgument*/
class B {}

/*class: C:checks=[],instance*/
class C {
  @pragma('dart2js:noInline')
  method1<T>() => method2<T>();

  @pragma('dart2js:noInline')
  method2<T>() => new A<T>();
}

/*class: D:typeArgument*/
class D extends B {}

/*class: E:typeArgument*/
class E {}

@pragma('dart2js:noInline')
test(o) => o is A<B>;

main() {
  Expect.isTrue(test(new C().method1<B>()));
  Expect.isTrue(test(new C().method1<D>()));
  Expect.isFalse(test(new C().method1<E>()));
}
