// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

main() {
  var /*@type=() -> Null*/ a = /*@returnType=Null*/ () {};
  var /*@type=() -> Null*/ b = /*@returnType=Null*/ () {
    return;
  };
  var /*@type=() -> Null*/ c = /*@returnType=Null*/ () {
    return null;
  };
  var /*@type=() -> int*/ d = /*@returnType=int*/ () {
    return 0;
  };
  var /*@type=(bool) -> Null*/ e = /*@returnType=Null*/ (bool b) {
    if (b) {
      return;
    } else {
      return;
    }
  };
  var /*@type=(bool) -> Null*/ f = /*@returnType=Null*/ (bool b) {
    if (b) {
      return;
    } else {
      return null;
    }
  };
  var /*@type=(bool) -> int*/ g = /*@returnType=int*/ (bool b) {
    if (b) {
      return;
    } else {
      return 0;
    }
  };
  var /*@type=(bool) -> Null*/ h = /*@returnType=Null*/ (bool b) {
    if (b) {
      return null;
    } else {
      return;
    }
  };
  var /*@type=(bool) -> Null*/ i = /*@returnType=Null*/ (bool b) {
    if (b) {
      return null;
    } else {
      return null;
    }
  };
  var /*@type=(bool) -> int*/ j = /*@returnType=int*/ (bool b) {
    if (b) {
      return null;
    } else {
      return 0;
    }
  };
  var /*@type=(bool) -> int*/ k = /*@returnType=int*/ (bool b) {
    if (b) {
      return 0;
    } else {
      return;
    }
  };
  var /*@type=(bool) -> int*/ l = /*@returnType=int*/ (bool b) {
    if (b) {
      return 0;
    } else {
      return null;
    }
  };
  var /*@type=(bool) -> int*/ m = /*@returnType=int*/ (bool b) {
    if (b) {
      return 0;
    } else {
      return 0;
    }
  };
}
