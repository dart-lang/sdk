// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests elimination of type casts.

class A<T> {}

class B<T> extends A<T> {
  testT1(x) => x as T;
  testT2negative(x) => x as T;
  testAOfT1(x) => x as A<T>;
  testAOfT2negative(x) => x as A<T>;
}

testInt1(x) => x as int;
testInt2(x) => x as int;
testDynamic(x) => x as dynamic;
testObject(x) => x as Object;
testBOfInt(x) => x as B<int>;
testAOfInt(x) => x as A<int>;
testAOfNum(x) => x as A<num>;
testAOfAOfB1(x) => x as A<A<B>>;
testAOfAOfB2negative(x) => x as A<A<B>>;

void main() {
  testInt1(42);
  testInt2(null);
  testDynamic('hi');
  testObject('bye');
  testBOfInt(new B<int>());
  testAOfInt(new B<int>());
  testAOfNum(new B<int>());
  testAOfAOfB1(new A<A<B>>());
  testAOfAOfB2negative(new A<A<A>>());
  new B<int>().testT1(42);
  new B<A<int>>().testT2negative(new A<String>());
  new B<A<int>>().testAOfT1(new A<A<int>>());
  new B<A<int>>().testAOfT2negative(new A<A<num>>());
}
