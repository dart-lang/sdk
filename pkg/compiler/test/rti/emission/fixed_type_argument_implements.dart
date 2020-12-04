// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that we emit the relation between B and A even when B is only live
// as a type argument through the supertype of D.

/*spec.class: A:checkedTypeArgument,typeArgument*/
class A {}

/*class: B:typeArgument*/
class B implements A {}

/*spec.class: C:checkedInstance*/
class C<T> {}

/*spec.class: D:checks=[$isC],instance*/
/*prod.class: D:checks=[],instance*/
class D implements C<B> {}

main() {
  C<A> c = new D();
  test(c);
}

@pragma('dart2js:noInline')
void test(Object o) => test1(o);

@pragma('dart2js:noInline')
void test1(C<A> c) {}
