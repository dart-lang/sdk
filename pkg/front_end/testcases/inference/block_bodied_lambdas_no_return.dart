// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test1() {
  List<int> o;
  var /*@type=Iterable<Null>*/ y =
      o. /*@typeArgs=Null*/ /*@target=Iterable::map*/ map(
          /*@returnType=Null*/ (/*@type=int*/ x) {});
  Iterable<int> z = y;
}

main() {}
