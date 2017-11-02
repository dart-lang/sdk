// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Base {
  int intProp;
  num numProp;
  double doubleProp;
}

class Test1 extends Base {
  void test() {
    var /*@type=int*/ v1 = super. /*@target=Base::intProp*/ intProp = getInt();
    var /*@type=int*/ v4 =
        super. /*@target=Base::intProp*/ intProp ??= getInt();
    var /*@type=int*/ v7 = super. /*@target=Base::intProp*/ intProp += getInt();
    var /*@type=num*/ v8 = super. /*@target=Base::intProp*/ intProp += getNum();
    var /*@type=int*/ v10 = ++super. /*@target=Base::intProp*/ intProp;
    var /*@type=int*/ v11 = super. /*@target=Base::intProp*/ intProp++;
  }
}

class Test2 extends Base {
  void test() {
    var /*@type=int*/ v1 = super. /*@target=Base::numProp*/ numProp = getInt();
    var /*@type=num*/ v2 = super. /*@target=Base::numProp*/ numProp = getNum();
    var /*@type=double*/ v3 =
        super. /*@target=Base::numProp*/ numProp = getDouble();
    var /*@type=num*/ v4 =
        super. /*@target=Base::numProp*/ numProp ??= getInt();
    var /*@type=num*/ v5 =
        super. /*@target=Base::numProp*/ numProp ??= getNum();
    var /*@type=num*/ v6 =
        super. /*@target=Base::numProp*/ numProp ??= getDouble();
    var /*@type=num*/ v7 = super. /*@target=Base::numProp*/ numProp += getInt();
    var /*@type=num*/ v8 = super. /*@target=Base::numProp*/ numProp += getNum();
    var /*@type=num*/ v9 =
        super. /*@target=Base::numProp*/ numProp += getDouble();
    var /*@type=num*/ v10 = ++super. /*@target=Base::numProp*/ numProp;
    var /*@type=num*/ v11 = super. /*@target=Base::numProp*/ numProp++;
  }
}

class Test3 extends Base {
  void test3() {
    var /*@type=double*/ v3 =
        super. /*@target=Base::doubleProp*/ doubleProp = getDouble();
    var /*@type=double*/ v6 =
        super. /*@target=Base::doubleProp*/ doubleProp ??= getDouble();
    var /*@type=double*/ v7 =
        super. /*@target=Base::doubleProp*/ doubleProp += getInt();
    var /*@type=double*/ v8 =
        super. /*@target=Base::doubleProp*/ doubleProp += getNum();
    var /*@type=double*/ v9 =
        super. /*@target=Base::doubleProp*/ doubleProp += getDouble();
    var /*@type=double*/ v10 = ++super. /*@target=Base::doubleProp*/ doubleProp;
    var /*@type=double*/ v11 = super. /*@target=Base::doubleProp*/ doubleProp++;
  }
}

main() {}
