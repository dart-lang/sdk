// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Test1 {
  int prop;

  static void test(Test1 t) {
    var /*@ type=int* */ v1 = /*@ type=Test1* */  t
        ?. /*@target=Test1.prop*/ prop = getInt();

    var /*@ type=num* */ v2 = /*@ type=Test1* */  t
        ?. /*@target=Test1.prop*/ prop = getNum();

    var /*@ type=int* */ v4 =  t?.
            /*@target=Test1.prop*/ /*@target=Test1.prop*/ prop
         ??= getInt();

    var /*@ type=num* */ v5 =  t?.
            /*@target=Test1.prop*/ /*@target=Test1.prop*/ prop
         ??= getNum();

    var /*@ type=int* */ v7 =  t?.
            /*@target=Test1.prop*/ /*@target=Test1.prop*/ prop
        /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =  t?.
            /*@target=Test1.prop*/ /*@target=Test1.prop*/ prop
        /*@target=num.+*/ += getNum();

    var /*@ type=int* */ v10 = /*@target=num.+*/ ++
         t?.
            /*@target=Test1.prop*/ /*@target=Test1.prop*/ prop;

    var /*@ type=int* */ v11 =  t?.
            /*@target=Test1.prop*/ /*@target=Test1.prop*/ prop
        /*@target=num.+*/ ++;
  }
}

class Test2 {
  num prop;

  static void test(Test2 t) {
    var /*@ type=int* */ v1 = /*@ type=Test2* */  t
        ?. /*@target=Test2.prop*/ prop = getInt();

    var /*@ type=num* */ v2 = /*@ type=Test2* */  t
        ?. /*@target=Test2.prop*/ prop = getNum();

    var /*@ type=double* */ v3 = /*@ type=Test2* */  t
        ?. /*@target=Test2.prop*/ prop = getDouble();

    var /*@ type=num* */ v4 =  t?.
            /*@target=Test2.prop*/ /*@target=Test2.prop*/ prop
         ??= getInt();

    var /*@ type=num* */ v5 =  t?.
            /*@target=Test2.prop*/ /*@target=Test2.prop*/ prop
         ??= getNum();

    var /*@ type=num* */ v6 =  t?.
            /*@target=Test2.prop*/ /*@target=Test2.prop*/ prop
         ??= getDouble();

    var /*@ type=num* */ v7 =  t?.
            /*@target=Test2.prop*/ /*@target=Test2.prop*/ prop
        /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =  t?.
            /*@target=Test2.prop*/ /*@target=Test2.prop*/ prop
        /*@target=num.+*/ += getNum();

    var /*@ type=num* */ v9 =  t?.
        /*@target=Test2.prop*/ /*@target=Test2.prop*/
        prop /*@target=num.+*/ += getDouble();

    var /*@ type=num* */ v10 = /*@target=num.+*/ ++ 
        t?. /*@target=Test2.prop*/ /*@target=Test2.prop*/ prop;

    var /*@ type=num* */ v11 = 
        t?. /*@target=Test2.prop*/ /*@target=Test2.prop*/ prop
        /*@target=num.+*/ ++;
  }
}

class Test3 {
  double prop;

  static void test3(Test3 t) {
    var /*@ type=num* */ v2 = /*@ type=Test3* */  t
        ?. /*@target=Test3.prop*/ prop = getNum();

    var /*@ type=double* */ v3 = /*@ type=Test3* */  t
        ?. /*@target=Test3.prop*/ prop = getDouble();

    var /*@ type=num* */ v5 =  t?.
            /*@target=Test3.prop*/ /*@target=Test3.prop*/ prop
         ??= getNum();

    var /*@ type=double* */ v6 =
         t?.
                /*@target=Test3.prop*/ /*@target=Test3.prop*/ prop
             ??= getDouble();

    var /*@ type=double* */ v7 =  t?.
            /*@target=Test3.prop*/ /*@target=Test3.prop*/ prop
        /*@target=double.+*/ += getInt();

    var /*@ type=double* */ v8 =  t?.
            /*@target=Test3.prop*/ /*@target=Test3.prop*/ prop
        /*@target=double.+*/ += getNum();

    var /*@ type=double* */ v9 =
         t?.
                /*@target=Test3.prop*/ /*@target=Test3.prop*/ prop
            /*@target=double.+*/ += getDouble();

    var /*@ type=double* */ v10 = /*@target=double.+*/ ++
         t?.
            /*@target=Test3.prop*/ /*@target=Test3.prop*/ prop;

    var /*@ type=double* */ v11 = 
        t?. /*@target=Test3.prop*/ /*@target=Test3.prop*/ prop
        /*@target=double.+*/ ++;
  }
}

main() {}
