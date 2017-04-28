// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

main() {
  Future<int> f;
  Future<List<int>>
      b = /*info:ASSIGNMENT_CAST should be pass*/ /*@promotedType=none*/ f
          .then(
              /*@returnType=List<dynamic>*/ (/*@type=int*/ x) => /*@typeArgs=dynamic*/ [])
          .whenComplete(/*@returnType=Null*/ () {});
  b = /*@promotedType=none*/ f.then(
      /*@returnType=List<int>*/ (/*@type=int*/ x) => /*@typeArgs=int*/ []);
}
