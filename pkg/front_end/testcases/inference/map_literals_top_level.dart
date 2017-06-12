// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=Map<int, String>*/ x1 = /*@typeArgs=int, String*/ {
  1: 'x',
  2: 'y'
};
test1() {
  x1 /*@target=Map::[]=*/ [3] = 'z';
  x1 /*@target=Map::[]=*/ [/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi'] = 'w';
  x1 /*@target=Map::[]=*/ [/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 4.0] = 'u';
  x1 /*@target=Map::[]=*/ [3] = /*error:INVALID_ASSIGNMENT*/ 42;
  Map<num, String> y = x1;
}

var /*@topType=Map<num, Pattern>*/ x2 = /*@typeArgs=num, Pattern*/ {
  1: 'x',
  2: 'y',
  3.0: new RegExp('.')
};
test2() {
  x2 /*@target=Map::[]=*/ [3] = 'z';
  x2 /*@target=Map::[]=*/ [/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi'] = 'w';
  x2 /*@target=Map::[]=*/ [4.0] = 'u';
  x2 /*@target=Map::[]=*/ [3] = /*error:INVALID_ASSIGNMENT*/ 42;
  Pattern p = null;
  x2 /*@target=Map::[]=*/ [2] = p;
  Map<int, String> y = /*info:ASSIGNMENT_CAST*/ x2;
}

main() {}
