// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test1() {
  var /*@type=List<Null>*/ x = /*@typeArgs=Null*/ [null];
  x. /*@target=List::add*/ add(/*error:INVALID_CAST_LITERAL*/ 42);
}

main() {
  test1();
}
