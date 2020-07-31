// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo {
  int foo(int x) => x;
}

test() {
  dynamic d = new Foo();
  var /*@ type=int* */ get_hashCode = d. /*@target=Object.hashCode*/ hashCode;
  var /*@ type=dynamic */ call_hashCode =
      d. /*@target=Object.hashCode*/ hashCode();
  var /*@ type=String* */ call_toString =
      d. /*@target=Object.toString*/ toString();
  var /*@ type=dynamic */ call_toStringArg = d.toString(color: "pink");
  var /*@ type=dynamic */ call_foo0 = d.foo();
  var /*@ type=dynamic */ call_foo1 = d.foo(1);
  var /*@ type=dynamic */ call_foo2 = d.foo(1, 2);
  var /*@ type=dynamic */ call_nsm0 = d.noSuchMethod();
  var /*@ type=dynamic */ call_nsm1 =
      d. /*@target=Object.noSuchMethod*/ noSuchMethod(null);
  var /*@ type=dynamic */ call_nsm2 = d.noSuchMethod(null, null);
  var /*@ type=bool* */ equals_self = d /*@target=Object.==*/ == d;
  var /*@ type=bool* */ equals_null = d /*@target=Object.==*/ == null;
  var /*@ type=bool* */ null_equals = null /*@target=Object.==*/ == d;
  var /*@ type=bool* */ not_equals_self = d /*@target=Object.==*/ != d;
  var /*@ type=bool* */ not_equals_null = d /*@target=Object.==*/ != null;
  var /*@ type=bool* */ null_not_equals = null /*@target=Object.==*/ != d;
}

main() {}
