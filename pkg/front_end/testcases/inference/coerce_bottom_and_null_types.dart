// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

f() {
  var /*@type=int*/ a = 0;
  var /*@type=dynamic*/ b = null;
  var /*@type=dynamic*/ c = throw 'foo';
  var /*@type=() -> int*/ d = /*@returnType=int*/ () => 0;
  var /*@type=() -> dynamic*/ e = /*@returnType=dynamic*/ () => null;
  var /*@type=() -> <BottomType>*/ f = /*@returnType=<BottomType>*/ () =>
      throw 'foo';
  var /*@type=() -> int*/ g = /*@returnType=int*/ () {
    return 0;
  };
  var /*@type=() -> Null*/ h = /*@returnType=Null*/ () {
    return null;
  };
  var /*@type=() -> <BottomType>*/ i = /*@returnType=<BottomType>*/ () {
    return (throw 'foo');
  };
}

main() {}
