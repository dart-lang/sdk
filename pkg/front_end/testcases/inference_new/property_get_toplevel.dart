// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  int field = 0;
  int get getter => 0;
  int function() => 0;
}

C c = new C();
var field_ref = c. /*@target=C.field*/ field;
var getter_ref = c. /*@target=C.getter*/ getter;
var function_ref = c. /*@target=C.function*/ function;
var field_ref_list = /*@ typeArgs=int* */ [c. /*@target=C.field*/ field];
var getter_ref_list = /*@ typeArgs=int* */ [c. /*@target=C.getter*/ getter];
var function_ref_list = /*@ typeArgs=() ->* int* */ [
  c. /*@target=C.function*/ function
];

main() {}
