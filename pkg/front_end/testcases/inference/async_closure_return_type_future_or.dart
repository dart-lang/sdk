// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

FutureOr<int> futureOrInt = null;
var /*@topType=() -> FutureOr<int>*/ f = /*@returnType=FutureOr<int>*/ () =>
    futureOrInt;
var /*@topType=() -> Future<int>*/ g = /*@returnType=Future<int>*/ () async =>
    futureOrInt;

main() {
  f;
  g;
}
