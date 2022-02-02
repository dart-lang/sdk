// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

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
  makeLive(test(new C().method1<B>()));
  makeLive(test(new C().method1<D>()));
  makeLive(test(new C().method1<E>()));
}
