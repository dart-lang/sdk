// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Test1 {
  int t;
  int? t2;

  Test1(this.t, this.t2);

  void test() {
    var v1 = t = getInt();

    var v4 = t2 ??= getInt();

    var v7 = t += getInt();

    var v10 = ++t;

    var v11 = t++;
  }
}

class Test2 {
  num t;
  num? t2;

  Test2(this.t, this.t2);

  void test() {
    var v1 = t = getInt();

    var v2 = t = getNum();

    var v3 = t = getDouble();

    var v4 = t2 ??= getInt();

    var v5 = t2 ??= getNum();

    var v6 = t2 ??= getDouble();

    var v7 = t += getInt();

    var v8 = t += getNum();

    var v9 = t += getDouble();

    var v10 = ++t;

    var v11 = t++;
  }
}

class Test3 {
  double t;
  double? t2;

  Test3(this.t, this.t2);

  void test3() {
    var v3 = t = getDouble();

    var v6 = t2 ??= getDouble();

    var v7 = t += getInt();

    var v8 = t += getNum();

    var v9 = t += getDouble();

    var v10 = ++t;

    var v11 = t++;
  }
}

main() {}
