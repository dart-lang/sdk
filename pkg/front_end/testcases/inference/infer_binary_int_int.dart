// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=bool*/ a_equal = 1 /*@target=num::==*/ == 2;
var /*@topType=bool*/ a_notEqual = 1 /*@target=num::==*/ != 2;
var /*@topType=int*/ a_bitXor = 1 /*@target=int::^*/ ^ 2;
var /*@topType=int*/ a_bitAnd = 1 /*@target=int::&*/ & 2;
var /*@topType=int*/ a_bitOr = 1 /*@target=int::|*/ | 2;
var /*@topType=int*/ a_bitShiftRight = 1 /*@target=int::>>*/ >> 2;
var /*@topType=int*/ a_bitShiftLeft = 1 /*@target=int::<<*/ << 2;
var /*@topType=int*/ a_add = 1 /*@target=num::+*/ + 2;
var /*@topType=int*/ a_subtract = 1 /*@target=num::-*/ - 2;
var /*@topType=int*/ a_multiply = 1 /*@target=num::**/ * 2;
var /*@topType=num*/ a_divide = 1 /*@target=num::/ */ / 2;
var /*@topType=int*/ a_floorDivide = 1 /*@target=num::~/ */ ~/ 2;
var /*@topType=bool*/ a_greater = 1 /*@target=num::>*/ > 2;
var /*@topType=bool*/ a_less = 1 /*@target=num::<*/ < 2;
var /*@topType=bool*/ a_greaterEqual = 1 /*@target=num::>=*/ >= 2;
var /*@topType=bool*/ a_lessEqual = 1 /*@target=num::<=*/ <= 2;
var /*@topType=int*/ a_modulo = 1 /*@target=num::%*/ % 2;
