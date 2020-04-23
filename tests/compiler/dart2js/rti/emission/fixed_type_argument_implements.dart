// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that we emit the relation between B and A even when B is only live
// as a type argument through the supertype of D.

/*strong|dart2js:nnbd.class: A:checkedTypeArgument,checks=[],typeArgument*/
class A {}

/*strong|dart2js:nnbd.class: B:checks=[$isA],typeArgument*/
/*omit.class: B:checks=[],typeArgument*/
class B implements A {}

/*strong|dart2js:nnbd.class: C:checkedInstance*/
/*omit.class: C:*/
class C<T> {}

/*strong|dart2js:nnbd.class: D:checks=[$isC],instance*/
/*omit.class: D:checks=[],instance*/
class D implements C<B> {}

main() {
  C<A> c = new D();
  test(c);
}

@pragma('dart2js:noInline')
void test(Object o) => test1(o);

@pragma('dart2js:noInline')
void test1(C<A> c) {}
