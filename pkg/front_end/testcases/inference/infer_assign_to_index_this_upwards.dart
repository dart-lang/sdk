// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Test1 {
  int operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test1::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = this /*@target=Test1::[]=*/ ['x'] = getNum();
    var /*@type=int*/ v4 = this /*@target=Test1::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = this /*@target=Test1::[]=*/ ['x'] ??= getNum();
    var /*@type=int*/ v7 = this /*@target=Test1::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = this /*@target=Test1::[]=*/ ['x'] += getNum();
    var /*@type=int*/ v10 = ++this /*@target=Test1::[]=*/ ['x'];
    var /*@type=int*/ v11 = this /*@target=Test1::[]=*/ ['x']++;
  }
}

abstract class Test2 {
  int operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test2::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = this /*@target=Test2::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = this /*@target=Test2::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v4 = this /*@target=Test2::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = this /*@target=Test2::[]=*/ ['x'] ??= getNum();
    var /*@type=num*/ v6 = this /*@target=Test2::[]=*/ ['x'] ??= getDouble();
    var /*@type=num*/ v7 = this /*@target=Test2::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = this /*@target=Test2::[]=*/ ['x'] += getNum();
    var /*@type=num*/ v9 = this /*@target=Test2::[]=*/ ['x'] += getDouble();
    var /*@type=num*/ v10 = ++this /*@target=Test2::[]=*/ ['x'];
    var /*@type=num*/ v11 = this /*@target=Test2::[]=*/ ['x']++;
  }
}

abstract class Test3 {
  int operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var /*@type=num*/ v2 = this /*@target=Test3::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = this /*@target=Test3::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v5 = this /*@target=Test3::[]=*/ ['x'] ??= getNum();
    var /*@type=double*/ v6 = this /*@target=Test3::[]=*/ ['x'] ??= getDouble();
    var /*@type=double*/ v7 = this /*@target=Test3::[]=*/ ['x'] += getInt();
    var /*@type=double*/ v8 = this /*@target=Test3::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = this /*@target=Test3::[]=*/ ['x'] += getDouble();
    var /*@type=double*/ v10 = ++this /*@target=Test3::[]=*/ ['x'];
    var /*@type=double*/ v11 = this /*@target=Test3::[]=*/ ['x']++;
  }
}

abstract class Test4 {
  num operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test4::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = this /*@target=Test4::[]=*/ ['x'] = getNum();
    var /*@type=int*/ v4 = this /*@target=Test4::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = this /*@target=Test4::[]=*/ ['x'] ??= getNum();
    var /*@type=int*/ v7 = this /*@target=Test4::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = this /*@target=Test4::[]=*/ ['x'] += getNum();
    var /*@type=int*/ v10 = ++this /*@target=Test4::[]=*/ ['x'];
    var /*@type=int*/ v11 = this /*@target=Test4::[]=*/ ['x']++;
  }
}

abstract class Test5 {
  num operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test5::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = this /*@target=Test5::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = this /*@target=Test5::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v4 = this /*@target=Test5::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = this /*@target=Test5::[]=*/ ['x'] ??= getNum();
    var /*@type=num*/ v6 = this /*@target=Test5::[]=*/ ['x'] ??= getDouble();
    var /*@type=num*/ v7 = this /*@target=Test5::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = this /*@target=Test5::[]=*/ ['x'] += getNum();
    var /*@type=num*/ v9 = this /*@target=Test5::[]=*/ ['x'] += getDouble();
    var /*@type=num*/ v10 = ++this /*@target=Test5::[]=*/ ['x'];
    var /*@type=num*/ v11 = this /*@target=Test5::[]=*/ ['x']++;
  }
}

abstract class Test6 {
  num operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var /*@type=num*/ v2 = this /*@target=Test6::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = this /*@target=Test6::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v5 = this /*@target=Test6::[]=*/ ['x'] ??= getNum();
    var /*@type=double*/ v6 = this /*@target=Test6::[]=*/ ['x'] ??= getDouble();
    var /*@type=double*/ v7 = this /*@target=Test6::[]=*/ ['x'] += getInt();
    var /*@type=double*/ v8 = this /*@target=Test6::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = this /*@target=Test6::[]=*/ ['x'] += getDouble();
    var /*@type=double*/ v10 = ++this /*@target=Test6::[]=*/ ['x'];
    var /*@type=double*/ v11 = this /*@target=Test6::[]=*/ ['x']++;
  }
}

abstract class Test7 {
  double operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test7::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = this /*@target=Test7::[]=*/ ['x'] = getNum();
    var /*@type=int*/ v4 = this /*@target=Test7::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = this /*@target=Test7::[]=*/ ['x'] ??= getNum();
    var /*@type=int*/ v7 = this /*@target=Test7::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = this /*@target=Test7::[]=*/ ['x'] += getNum();
    var /*@type=int*/ v10 = ++this /*@target=Test7::[]=*/ ['x'];
    var /*@type=int*/ v11 = this /*@target=Test7::[]=*/ ['x']++;
  }
}

abstract class Test8 {
  double operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test8::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = this /*@target=Test8::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = this /*@target=Test8::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v4 = this /*@target=Test8::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = this /*@target=Test8::[]=*/ ['x'] ??= getNum();
    var /*@type=num*/ v6 = this /*@target=Test8::[]=*/ ['x'] ??= getDouble();
    var /*@type=num*/ v7 = this /*@target=Test8::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = this /*@target=Test8::[]=*/ ['x'] += getNum();
    var /*@type=num*/ v9 = this /*@target=Test8::[]=*/ ['x'] += getDouble();
    var /*@type=num*/ v10 = ++this /*@target=Test8::[]=*/ ['x'];
    var /*@type=num*/ v11 = this /*@target=Test8::[]=*/ ['x']++;
  }
}

abstract class Test9 {
  double operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var /*@type=num*/ v2 = this /*@target=Test9::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = this /*@target=Test9::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v5 = this /*@target=Test9::[]=*/ ['x'] ??= getNum();
    var /*@type=double*/ v6 = this /*@target=Test9::[]=*/ ['x'] ??= getDouble();
    var /*@type=double*/ v7 = this /*@target=Test9::[]=*/ ['x'] += getInt();
    var /*@type=double*/ v8 = this /*@target=Test9::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = this /*@target=Test9::[]=*/ ['x'] += getDouble();
    var /*@type=double*/ v10 = ++this /*@target=Test9::[]=*/ ['x'];
    var /*@type=double*/ v11 = this /*@target=Test9::[]=*/ ['x']++;
  }
}

main() {}
