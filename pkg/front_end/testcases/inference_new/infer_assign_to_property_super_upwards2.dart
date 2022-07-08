// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Base {
  int intProp = 0;
  int? intProp2;
  num numProp = 0;
  num? numProp2;
  double doubleProp = 0;
  double? doubleProp2;
}

class Test1 extends Base {
  void test() {
    var /*@type=int*/ v1 = super.intProp = getInt();

    var /*@type=int*/ v4 =
        super. /*@target=Base.intProp2*/ intProp2 ??= getInt();

    var /*@type=int*/ v7 =
        super. /*@target=Base.intProp*/ intProp /*@target=num.+*/ += getInt();

    var /*@type=int*/ v10 = /*@target=num.+*/ ++super
        . /*@target=Base.intProp*/ intProp;

    var /*@type=int*/ v11 = super
        . /*@type=int*/ /*@target=Base.intProp*/
        /*@type=int*/ intProp /*@target=num.+*/ ++;
  }
}

class Test2 extends Base {
  void test() {
    var /*@type=int*/ v1 = super.numProp = getInt();

    var /*@type=num*/ v2 = super.numProp = getNum();

    var /*@type=double*/ v3 = super.numProp = getDouble();

    var /*@type=num*/ v4 =
        super. /*@target=Base.numProp2*/ numProp2 ??= getInt();

    var /*@type=num*/ v5 =
        super. /*@target=Base.numProp2*/ numProp2 ??= getNum();

    var /*@type=num*/ v6 =
        super. /*@target=Base.numProp2*/ numProp2 ??= getDouble();

    var /*@type=num*/ v7 =
        super. /*@target=Base.numProp*/ numProp /*@target=num.+*/ += getInt();

    var /*@type=num*/ v8 =
        super. /*@target=Base.numProp*/ numProp /*@target=num.+*/ += getNum();

    var /*@type=double*/ v9 = super
        . /*@target=Base.numProp*/ numProp /*@target=num.+*/ += getDouble();

    var /*@type=num*/ v10 = /*@target=num.+*/ ++super
        . /*@target=Base.numProp*/ numProp;

    var /*@type=num*/ v11 = super
        . /*@type=num*/ /*@target=Base.numProp*/
        /*@type=num*/ numProp /*@target=num.+*/ ++;
  }
}

class Test3 extends Base {
  void test3() {
    var /*@type=double*/ v3 = super.doubleProp = getDouble();

    var /*@type=double*/ v6 =
        super. /*@target=Base.doubleProp2*/ doubleProp2 ??= getDouble();

    var /*@type=double*/ v7 = super
        . /*@target=Base.doubleProp*/
        doubleProp /*@target=double.+*/ += getInt();

    var /*@type=double*/ v8 = super
        . /*@target=Base.doubleProp*/
        doubleProp /*@target=double.+*/ += getNum();

    var /*@type=double*/ v9 = super
        . /*@target=Base.doubleProp*/
        doubleProp /*@target=double.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=double.+*/ ++super
        . /*@target=Base.doubleProp*/
        doubleProp;

    var /*@type=double*/ v11 = super
        . /*@type=double*/ /*@target=Base.doubleProp*/
        /*@type=double*/ doubleProp /*@target=double.+*/ ++;
  }
}

main() {}
