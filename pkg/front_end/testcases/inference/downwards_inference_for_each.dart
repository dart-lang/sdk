// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => null;
}

Future main() async {
  for (int x in /*@typeArgs=int*/ [1, 2, 3]) {}
  await for (int x in new /*@typeArgs=int*/ MyStream()) {}
}
