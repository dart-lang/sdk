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
    var /*@ type=int* */ v1 = /*@target=Test1.t*/ t = getInt();

    var /*@ type=num* */ v2 = /*@target=Test1.t*/ t = getNum();

    var /*@ type=int* */ v4 = /*@target=Test1.t*/ /*@target=Test1.t*/ t
        /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 = /*@target=Test1.t*/ /*@target=Test1.t*/ t
        /*@target=num.==*/ ??= getNum();

    var /*@ type=int* */ v7 = /*@target=Test1.t*/ /*@target=Test1.t*/ t
        /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 = /*@target=Test1.t*/ /*@target=Test1.t*/ t
        /*@target=num.+*/ += getNum();

    var /*@ type=int* */ v10 = /*@target=num.+*/ ++
        /*@target=Test1.t*/ /*@target=Test1.t*/ t;

    var /*@ type=int* */ v11 =
        /*@ type=int* */ /*@target=Test1.t*/ /*@target=Test1.t*/
        /*@ type=int* */ t /*@target=num.+*/ ++;
  }
}

class Test2 {
  num t;

  void test() {
    var /*@ type=int* */ v1 = /*@target=Test2.t*/ t = getInt();

    var /*@ type=num* */ v2 = /*@target=Test2.t*/ t = getNum();

    var /*@ type=double* */ v3 = /*@target=Test2.t*/ t = getDouble();

    var /*@ type=num* */ v4 = /*@target=Test2.t*/ /*@target=Test2.t*/ t
        /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 = /*@target=Test2.t*/ /*@target=Test2.t*/ t
        /*@target=num.==*/ ??= getNum();

    var /*@ type=num* */ v6 = /*@target=Test2.t*/ /*@target=Test2.t*/ t
        /*@target=num.==*/ ??= getDouble();

    var /*@ type=num* */ v7 = /*@target=Test2.t*/ /*@target=Test2.t*/ t
        /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 = /*@target=Test2.t*/ /*@target=Test2.t*/ t
        /*@target=num.+*/ += getNum();

    var /*@ type=num* */ v9 = /*@target=Test2.t*/ /*@target=Test2.t*/ t
        /*@target=num.+*/ += getDouble();

    var /*@ type=num* */ v10 = /*@target=num.+*/ ++
        /*@target=Test2.t*/ /*@target=Test2.t*/ t;

    var /*@ type=num* */ v11 =
        /*@ type=num* */ /*@target=Test2.t*/ /*@target=Test2.t*/
        /*@ type=num* */ t /*@target=num.+*/ ++;
  }
}

class Test3 {
  double t;

  void test3() {
    var /*@ type=num* */ v2 = /*@target=Test3.t*/ t = getNum();

    var /*@ type=double* */ v3 = /*@target=Test3.t*/ t = getDouble();

    var /*@ type=num* */ v5 = /*@target=Test3.t*/ /*@target=Test3.t*/ t
        /*@target=num.==*/ ??= getNum();

    var /*@ type=double* */ v6 = /*@target=Test3.t*/ /*@target=Test3.t*/ t
        /*@target=num.==*/ ??= getDouble();

    var /*@ type=double* */ v7 = /*@target=Test3.t*/ /*@target=Test3.t*/ t
        /*@target=double.+*/ += getInt();

    var /*@ type=double* */ v8 = /*@target=Test3.t*/ /*@target=Test3.t*/ t
        /*@target=double.+*/ += getNum();

    var /*@ type=double* */ v9 = /*@target=Test3.t*/ /*@target=Test3.t*/ t
        /*@target=double.+*/ += getDouble();

    var /*@ type=double* */ v10 =
        /*@target=double.+*/ ++ /*@target=Test3.t*/ /*@target=Test3.t*/ t;

    var /*@ type=double* */ v11 =
        /*@ type=double* */ /*@target=Test3.t*/ /*@target=Test3.t*/
        /*@ type=double* */ t /*@target=double.+*/ ++;
  }
}

main() {}
