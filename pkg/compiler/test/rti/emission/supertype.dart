// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Note: When an interface is implemented by single instantiated class, an `is`
// test on the interface can be compiled to an `is` test on the instantiated
// class and implemented as an `instanceof` test.
// [testSingleInstantatiedSubtype] demonstates that an `$is` property is not
// required when the optimization applies (the empty `checks=[]` data).
// [testMultipleInstantatiedSubtypes] avoids the optimization by adding another
// instantiated class that implements the tested interface so there is true
// multiple inheritance. The `checks=` then contain the required `$is` property.

/*class: B:*/
class B {}

/*class: C:checks=[],instance*/
class C implements B {}

@pragma('dart2js:noInline')
test(o) => o is B;

testSingleInstantatiedSubtype() {
  test(new C());
  test(null);
}

/*class: B2:checkedInstance*/
class B2 {}

/*class: C2:checks=[$isB2],instance*/
class C2 implements B2 {}

/*class: D2:checks=[$isB2],instance*/
class D2 implements B2 {}

@pragma('dart2js:noInline')
testB2(o) => o is B2;

testMultipleInstantatiedSubtypes() {
  testB2(C2());
  testB2(D2());
  testB2(null);
}

void main() {
  testSingleInstantatiedSubtype();
  testMultipleInstantatiedSubtypes();
}
