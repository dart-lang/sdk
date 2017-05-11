// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test1() {
  var /*@type=Map<int, String>*/ x = /*@typeArgs=int, String*/ {1: 'x', 2: 'y'};
  x /*@target=Map::[]=*/ [3] = 'z';
  x /*@target=Map::[]=*/ [
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi'] = 'w';
  x /*@target=Map::[]=*/ [
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 4.0] = 'u';
  x /*@target=Map::[]=*/ [3] = /*error:INVALID_ASSIGNMENT*/ 42;
  Map<num, String> y = x;
}

test2() {
  var /*@type=Map<num, Pattern>*/ x = /*@typeArgs=num, Pattern*/ {
    1: 'x',
    2: 'y',
    3.0: new RegExp('.')
  };
  x /*@target=Map::[]=*/ [3] = 'z';
  x /*@target=Map::[]=*/ [
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi'] = 'w';
  x /*@target=Map::[]=*/ [4.0] = 'u';
  x /*@target=Map::[]=*/ [3] = /*error:INVALID_ASSIGNMENT*/ 42;
  Pattern p = null;
  x /*@target=Map::[]=*/ [2] = p;
  Map<int, String> y = /*info:ASSIGNMENT_CAST*/ x;
}
