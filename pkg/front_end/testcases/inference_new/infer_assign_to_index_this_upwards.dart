// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Test1a {
  int operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test1a.[]=*/ ['x'] = getInt();

    var /*@type=int*/ v7 = this /*@target=Test1a.[]*/ /*@target=Test1a.[]=*/ [
        'x'] /*@target=num.+*/ += getInt();

    var /*@type=int*/ v10 = /*@target=num.+*/ ++this /*@target=Test1a.[]*/ /*@target=Test1a.[]=*/ [
        'x'];

    var /*@type=int*/ v11 = this /*@target=Test1a.[]*/ /*@target=Test1a.[]=*/ [
        'x'] /*@target=num.+*/ ++;
  }
}

abstract class Test1b {
  int? operator [](String s);
  void operator []=(String s, int? v);

  void test() {
    var /*@type=int*/ v4 =
        this /*@target=Test1b.[]*/ /*@target=Test1b.[]=*/ ['x'] ??= getInt();
  }
}

abstract class Test2a {
  int operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test2a.[]=*/ ['x'] = getInt();

    var /*@type=num*/ v2 = this /*@target=Test2a.[]=*/ ['x'] = getNum();

    var /*@type=double*/ v3 = this /*@target=Test2a.[]=*/ ['x'] = getDouble();

    var /*@type=int*/ v7 = this /*@target=Test2a.[]*/ /*@target=Test2a.[]=*/ [
        'x'] /*@target=num.+*/ += getInt();

    var /*@type=num*/ v8 = this /*@target=Test2a.[]*/ /*@target=Test2a.[]=*/ [
        'x'] /*@target=num.+*/ += getNum();

    var /*@type=double*/ v9 =
        this /*@target=Test2a.[]*/ /*@target=Test2a.[]=*/ [
            'x'] /*@target=num.+*/ += getDouble();

    var /*@type=int*/ v10 = /*@target=num.+*/ ++this /*@target=Test2a.[]*/ /*@target=Test2a.[]=*/ [
        'x'];

    var /*@type=int*/ v11 = this /*@target=Test2a.[]*/ /*@target=Test2a.[]=*/ [
        'x'] /*@target=num.+*/ ++;
  }
}

abstract class Test2b {
  int? operator [](String s);
  void operator []=(String s, num? v);

  void test() {
    var /*@type=int*/ v4 =
        this /*@target=Test2b.[]*/ /*@target=Test2b.[]=*/ ['x'] ??= getInt();

    var /*@type=num*/ v5 =
        this /*@target=Test2b.[]*/ /*@target=Test2b.[]=*/ ['x'] ??= getNum();

    var /*@type=num*/ v6 =
        this /*@target=Test2b.[]*/ /*@target=Test2b.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test3a {
  int operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var /*@type=double*/ v3 = this /*@target=Test3a.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v9 =
        this /*@target=Test3a.[]*/ /*@target=Test3a.[]=*/ [
            'x'] /*@target=num.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=num.+*/ ++this /*@target=Test3a.[]*/ /*@target=Test3a.[]=*/ [
        'x'];

    var /*@type=int*/ v11 = this /*@target=Test3a.[]*/ /*@target=Test3a.[]=*/ [
        'x'] /*@target=num.+*/ ++;
  }
}

abstract class Test3b {
  int? operator [](String s);
  void operator []=(String s, double? v);

  void test() {
    var /*@type=num*/ v6 =
        this /*@target=Test3b.[]*/ /*@target=Test3b.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test4a {
  num operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test4a.[]=*/ ['x'] = getInt();
  }
}

abstract class Test4b {
  num? operator [](String s);
  void operator []=(String s, int? v);

  void test() {
    var /*@type=num*/ v4 =
        this /*@target=Test4b.[]*/ /*@target=Test4b.[]=*/ ['x'] ??= getInt();
  }
}

abstract class Test5a {
  num operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test5a.[]=*/ ['x'] = getInt();

    var /*@type=num*/ v2 = this /*@target=Test5a.[]=*/ ['x'] = getNum();

    var /*@type=double*/ v3 = this /*@target=Test5a.[]=*/ ['x'] = getDouble();

    var /*@type=num*/ v7 = this /*@target=Test5a.[]*/ /*@target=Test5a.[]=*/ [
        'x'] /*@target=num.+*/ += getInt();

    var /*@type=num*/ v8 = this /*@target=Test5a.[]*/ /*@target=Test5a.[]=*/ [
        'x'] /*@target=num.+*/ += getNum();

    var /*@type=double*/ v9 =
        this /*@target=Test5a.[]*/ /*@target=Test5a.[]=*/ [
            'x'] /*@target=num.+*/ += getDouble();

    var /*@type=num*/ v10 = /*@target=num.+*/ ++this /*@target=Test5a.[]*/ /*@target=Test5a.[]=*/ [
        'x'];

    var /*@type=num*/ v11 = this /*@target=Test5a.[]*/ /*@target=Test5a.[]=*/ [
        'x'] /*@target=num.+*/ ++;
  }
}

abstract class Test5b {
  num? operator [](String s);
  void operator []=(String s, num? v);

  void test() {
    var /*@type=num*/ v4 =
        this /*@target=Test5b.[]*/ /*@target=Test5b.[]=*/ ['x'] ??= getInt();

    var /*@type=num*/ v5 =
        this /*@target=Test5b.[]*/ /*@target=Test5b.[]=*/ ['x'] ??= getNum();

    var /*@type=num*/ v6 =
        this /*@target=Test5b.[]*/ /*@target=Test5b.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test6a {
  num operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var /*@type=double*/ v3 = this /*@target=Test6a.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v9 =
        this /*@target=Test6a.[]*/ /*@target=Test6a.[]=*/ [
            'x'] /*@target=num.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=num.+*/ ++this /*@target=Test6a.[]*/ /*@target=Test6a.[]=*/ [
        'x'];

    var /*@type=num*/ v11 = this /*@target=Test6a.[]*/ /*@target=Test6a.[]=*/ [
        'x'] /*@target=num.+*/ ++;
  }
}

abstract class Test6b {
  num? operator [](String s);
  void operator []=(String s, double? v);

  void test() {
    var /*@type=num*/ v6 =
        this /*@target=Test6b.[]*/ /*@target=Test6b.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test7a {
  double operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test7a.[]=*/ ['x'] = getInt();
  }
}

abstract class Test7b {
  double? operator [](String s);
  void operator []=(String s, int? v);

  void test() {
    var /*@type=num*/ v4 =
        this /*@target=Test7b.[]*/ /*@target=Test7b.[]=*/ ['x'] ??= getInt();
  }
}

abstract class Test8a {
  double operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var /*@type=int*/ v1 = this /*@target=Test8a.[]=*/ ['x'] = getInt();

    var /*@type=num*/ v2 = this /*@target=Test8a.[]=*/ ['x'] = getNum();

    var /*@type=double*/ v3 = this /*@target=Test8a.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v7 =
        this /*@target=Test8a.[]*/ /*@target=Test8a.[]=*/ [
            'x'] /*@target=double.+*/ += getInt();

    var /*@type=double*/ v8 =
        this /*@target=Test8a.[]*/ /*@target=Test8a.[]=*/ [
            'x'] /*@target=double.+*/ += getNum();

    var /*@type=double*/ v9 =
        this /*@target=Test8a.[]*/ /*@target=Test8a.[]=*/ [
            'x'] /*@target=double.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=double.+*/ ++this /*@target=Test8a.[]*/ /*@target=Test8a.[]=*/ [
        'x'];

    var /*@type=double*/ v11 =
        this /*@target=Test8a.[]*/ /*@target=Test8a.[]=*/ [
            'x'] /*@target=double.+*/ ++;
  }
}

abstract class Test8b {
  double? operator [](String s);
  void operator []=(String s, num? v);

  void test() {
    var /*@type=num*/ v4 =
        this /*@target=Test8b.[]*/ /*@target=Test8b.[]=*/ ['x'] ??= getInt();

    var /*@type=num*/ v5 =
        this /*@target=Test8b.[]*/ /*@target=Test8b.[]=*/ ['x'] ??= getNum();

    var /*@type=double*/ v6 =
        this /*@target=Test8b.[]*/ /*@target=Test8b.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test9a {
  double operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var /*@type=double*/ v3 = this /*@target=Test9a.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v7 =
        this /*@target=Test9a.[]*/ /*@target=Test9a.[]=*/ [
            'x'] /*@target=double.+*/ += getInt();

    var /*@type=double*/ v8 =
        this /*@target=Test9a.[]*/ /*@target=Test9a.[]=*/ [
            'x'] /*@target=double.+*/ += getNum();

    var /*@type=double*/ v9 =
        this /*@target=Test9a.[]*/ /*@target=Test9a.[]=*/ [
            'x'] /*@target=double.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=double.+*/ ++this /*@target=Test9a.[]*/ /*@target=Test9a.[]=*/ [
        'x'];

    var /*@type=double*/ v11 =
        this /*@target=Test9a.[]*/ /*@target=Test9a.[]=*/ [
            'x'] /*@target=double.+*/ ++;
  }
}

abstract class Test9b {
  double? operator [](String s);
  void operator []=(String s, double? v);

  void test() {
    var /*@type=double*/ v6 =
        this /*@target=Test9b.[]*/ /*@target=Test9b.[]=*/ ['x'] ??= getDouble();
  }
}

main() {}
