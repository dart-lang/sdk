// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
/*@testedFeatures=inference*/
library test;

test() {
  /*@returnType=invalid-type*/ f() => /*error:REFERENCED_BEFORE_DECLARATION*/ g();

  // Ignore inference for g since Fasta doesn't infer it due to the circularity,
  // and that's ok.
  /*@testedFeatures=none*/
  g() => 0;
  /*@testedFeatures=inference*/

  var /*@type=() ->* invalid-type*/ v = f;
}

main() {}
