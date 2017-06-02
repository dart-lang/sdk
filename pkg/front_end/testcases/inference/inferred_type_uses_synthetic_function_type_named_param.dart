// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int f({int x}) => null;
String g({int x}) => null;
var /*@topType=List<({x: int}) -> Object>*/ v = /*@typeArgs=({x: int}) -> Object*/ [
  f,
  g
];

main() {
  v;
}
