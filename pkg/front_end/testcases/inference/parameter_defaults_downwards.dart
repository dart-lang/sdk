// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void optional_toplevel([List<int> x = /*@typeArgs=int*/ const []]) {}

void named_toplevel({List<int> x: /*@typeArgs=int*/ const []}) {}

main() {
  void optional_local([List<int> x = /*@typeArgs=int*/ const []]) {}
  void named_local({List<int> x: /*@typeArgs=int*/ const []}) {}
  var /*@type=([List<int>]) -> Null*/ optional_closure = /*@returnType=Null*/ (
      [List<int> x = /*@typeArgs=int*/ const []]) {};
  var /*@type=({x: List<int>}) -> Null*/ name_closure = /*@returnType=Null*/ (
      {List<int> x: /*@typeArgs=int*/ const []}) {};
}
