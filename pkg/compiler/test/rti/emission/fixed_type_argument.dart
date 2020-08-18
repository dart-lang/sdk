// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: A:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: A:checkedTypeArgument,typeArgument*/
class A {}

/*spec.class: B:checkedInstance,typeArgument*/
/*prod.class: B:typeArgument*/
class B implements A {}

/*class: C:checks=[],indirectInstance*/
class C<T> {
  @pragma('dart2js:noInline')
  method(void Function(T) f) {}
}

/*class: D:checks=[],instance*/
class D extends C<B> {}

main() {
  C<A> c = new D();
  c.method(
      /*spec.checks=[$signature],instance*/
      /*prod.checks=[],instance*/
      (A a) {});
}
