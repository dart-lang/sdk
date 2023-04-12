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

import 'package:compiler/src/util/testing.dart';

/*class: A:*/
class A {}

/*class: B:checks=[]*/
class B implements A {}

/*class: C:checks=[],indirectInstance*/
class C = Object with B;

/*class: D:checks=[],instance*/
class D extends C {}

@pragma('dart2js:noInline')
test(o) => o is A;

testSingleInstantatiedSubtype() {
  makeLive(test(new D()));
  makeLive(test(null));
}

/*class: A2:checkedInstance*/
class A2 {}

/*class: B2:checks=[]*/
class B2 implements A2 {}

/*class: C2:checks=[$isA2],indirectInstance*/
class C2 = Object with B2;

/*class: D2:checks=[],instance*/
class D2 extends C2 {}

// Second instantiated class that implements A2.
/*class: E2:checks=[$isA2],instance*/
class E2 implements A2 {}

@pragma('dart2js:noInline')
testA2(o) => o is A2;

testMultipleInstantatiedSubtypes() {
  makeLive(testA2(D2()));
  makeLive(testA2(E2()));
  makeLive(testA2(null));
}

main() {
  testSingleInstantatiedSubtype();
  testMultipleInstantatiedSubtypes();
}
