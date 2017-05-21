// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

Future<int> futureInt = null;
var /*@topType=() -> Future<int>*/ f = /*@returnType=Future<int>*/ () =>
    futureInt;
var /*@topType=() -> Future<int>*/ g = /*@returnType=Future<int>*/ () async =>
    futureInt;

main() {
  f;
  g;
}
