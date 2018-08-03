// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

var /*@topType=bool*/ x = /*@typeArgs=bool*/ f() || /*@typeArgs=bool*/ f();
var /*@topType=bool*/ y = /*@typeArgs=bool*/ f() && /*@typeArgs=bool*/ f();

void test() {
  var /*@type=bool*/ x = /*@typeArgs=bool*/ f() || /*@typeArgs=bool*/ f();
  var /*@type=bool*/ y = /*@typeArgs=bool*/ f() && /*@typeArgs=bool*/ f();
}

main() {}
