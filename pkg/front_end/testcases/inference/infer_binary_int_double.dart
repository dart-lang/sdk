// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var a_equal = 1 /*@target=num.==*/ == 2.0;
var a_notEqual = 1 /*@target=num.==*/ != 2.0;
var a_add = 1 /*@target=num.+*/ + 2.0;
var a_subtract = 1 /*@target=num.-*/ - 2.0;
var a_multiply = 1 /*@target=num.**/ * 2.0;
var a_divide = 1 /*@target=num./ */ / 2.0;
var a_floorDivide = 1 /*@target=num.~/ */ ~/ 2.0;
var a_greater = 1 /*@target=num.>*/ > 2.0;
var a_less = 1 /*@target=num.<*/ < 2.0;
var a_greaterEqual = 1 /*@target=num.>=*/ >= 2.0;
var a_lessEqual = 1 /*@target=num.<=*/ <= 2.0;
var a_modulo = 1 /*@target=num.%*/ % 2.0;

main() {
  a_equal;
  a_notEqual;
  a_add;
  a_subtract;
  a_multiply;
  a_divide;
  a_floorDivide;
  a_greater;
  a_less;
  a_greaterEqual;
  a_lessEqual;
  a_modulo;
}
