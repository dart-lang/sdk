// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Test1 {
  int t;

  void test() {
    var /*@type=int*/ v1 = /*@target=Test1::t*/ t = getInt();
    var /*@type=int*/ v2 = /*@target=Test1::t*/ t = getNum();
    var /*@type=int*/ v4 = /*@target=Test1::t*/ t ??= getInt();
    var /*@type=int*/ v5 = /*@target=Test1::t*/ t ??= getNum();
    var /*@type=int*/ v7 = /*@target=Test1::t*/ t += getInt();
    var /*@type=num*/ v8 = /*@target=Test1::t*/ t += getNum();
    var /*@type=int*/ v10 = ++ /*@target=Test1::t*/ t;
    var /*@type=int*/ v11 = /*@target=Test1::t*/ t++;
  }
}

class Test2 {
  num t;

  void test() {
    var /*@type=int*/ v1 = /*@target=Test2::t*/ t = getInt();
    var /*@type=num*/ v2 = /*@target=Test2::t*/ t = getNum();
    var /*@type=double*/ v3 = /*@target=Test2::t*/ t = getDouble();
    var /*@type=num*/ v4 = /*@target=Test2::t*/ t ??= getInt();
    var /*@type=num*/ v5 = /*@target=Test2::t*/ t ??= getNum();
    var /*@type=num*/ v6 = /*@target=Test2::t*/ t ??= getDouble();
    var /*@type=num*/ v7 = /*@target=Test2::t*/ t += getInt();
    var /*@type=num*/ v8 = /*@target=Test2::t*/ t += getNum();
    var /*@type=num*/ v9 = /*@target=Test2::t*/ t += getDouble();
    var /*@type=num*/ v10 = ++ /*@target=Test2::t*/ t;
    var /*@type=num*/ v11 = /*@target=Test2::t*/ t++;
  }
}

class Test3 {
  double t;

  void test3() {
    var /*@type=double*/ v2 = /*@target=Test3::t*/ t = getNum();
    var /*@type=double*/ v3 = /*@target=Test3::t*/ t = getDouble();
    var /*@type=double*/ v5 = /*@target=Test3::t*/ t ??= getNum();
    var /*@type=double*/ v6 = /*@target=Test3::t*/ t ??= getDouble();
    var /*@type=double*/ v7 = /*@target=Test3::t*/ t += getInt();
    var /*@type=double*/ v8 = /*@target=Test3::t*/ t += getNum();
    var /*@type=double*/ v9 = /*@target=Test3::t*/ t += getDouble();
    var /*@type=double*/ v10 = ++ /*@target=Test3::t*/ t;
    var /*@type=double*/ v11 = /*@target=Test3::t*/ t++;
  }
}

main() {}
