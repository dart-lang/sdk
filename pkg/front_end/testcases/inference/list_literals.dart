// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test1() {
  var /*@type=List<int>*/ x = /*@typeArgs=int*/ [1, 2, 3];
  x. /*@target=List::add*/ add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi');
  x. /*@target=List::add*/ add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 4.0);
  x. /*@target=List::add*/ add(4);
  List<num> y = x;
}

test2() {
  var /*@type=List<num>*/ x = /*@typeArgs=num*/ [1, 2.0, 3];
  x. /*@target=List::add*/ add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi');
  x. /*@target=List::add*/ add(4.0);
  List<int> y = /*info:ASSIGNMENT_CAST*/ x;
}

main() {
  test1();
  test2();
}
