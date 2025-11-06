// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var v1 = super.intProp = getInt();

    var v4 = super.intProp2 ??= getInt();

    var v7 = super.intProp += getInt();

    var v10 = ++super.intProp;

    var v11 = super.intProp++;
  }
}

class Test2 extends Base {
  void test() {
    var v1 = super.numProp = getInt();

    var v2 = super.numProp = getNum();

    var v3 = super.numProp = getDouble();

    var v4 = super.numProp2 ??= getInt();

    var v5 = super.numProp2 ??= getNum();

    var v6 = super.numProp2 ??= getDouble();

    var v7 = super.numProp += getInt();

    var v8 = super.numProp += getNum();

    var v9 = super.numProp += getDouble();

    var v10 = ++super.numProp;

    var v11 = super.numProp++;
  }
}

class Test3 extends Base {
  void test3() {
    var v3 = super.doubleProp = getDouble();

    var v6 = super.doubleProp2 ??= getDouble();

    var v7 = super.doubleProp += getInt();

    var v8 = super.doubleProp += getNum();

    var v9 = super.doubleProp += getDouble();

    var v10 = ++super.doubleProp;

    var v11 = super.doubleProp++;
  }
}

main() {}
