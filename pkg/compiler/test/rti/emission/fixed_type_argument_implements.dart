// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we emit the relation between B and A even when B is only live
// as a type argument through the supertype of D.

/*class: A:checkedTypeArgument,typeArgument*/
class A {}

/*class: B:typeArgument*/
class B implements A {}

/*class: C:checkedInstance*/
class C<T> {}

/*class: D:checks=[$isC],instance*/
class D implements C<B> {}

main() {
  C<A> c = D();
  test(c);
}

@pragma('dart2js:noInline')
void test(Object o) => test1(o as C<A>);

@pragma('dart2js:noInline')
void test1(C<A> c) {}
