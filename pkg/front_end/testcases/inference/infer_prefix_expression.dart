// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=bool*/ a_not = !true;
var /*@topType=int*/ a_complement = /*@target=int::~*/ ~1;
var /*@topType=int*/ a_negate = /*@target=int::unary-*/ -1;

main() {
  a_not;
  a_complement;
  a_negate;
}
