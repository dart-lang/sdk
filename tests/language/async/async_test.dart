// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

topLevelFunction() async {}

Future<int> topLevelWithParameter(int a) async {
  return 7 + a;
}

topLevelWithParameterWrongType(int a) async {
  return 7 + a;
}

var what = 'async getter';
Future<String> get topLevelGetter async {
  return 'I want to be an ${what}';
}

class A {
  static int staticVar = 1;

  static staticMethod(int param) async => staticVar + param;
  static get staticGetter async => staticVar + 3;

  int _x;
  A(this._x);

  operator +(A other) async {
    return new A(_x + other._x);
  }

  get value => _x;
}

class B {
  final _y;
  const B._internal(this._y);

  B() : _y = null;
}

main() {
  Future<Object?> asyncReturn;

  asyncReturn = topLevelFunction();
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.isNull(result);
    asyncEnd();
  });

  asyncReturn = topLevelWithParameter(4);
  Expect.isTrue(asyncReturn is Future);
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.equals(result, 11);
    asyncEnd();
  });

  asyncReturn = topLevelGetter;
  Expect.isTrue(asyncReturn is Future);
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.equals(result, 'I want to be an async getter');
    asyncEnd();
  });

  asyncReturn = A.staticMethod(2);
  Expect.isTrue(asyncReturn is Future);
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.equals(result, 3);
    asyncEnd();
  });

  asyncReturn = A.staticGetter;
  Expect.isTrue(asyncReturn is Future);
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.equals(result, 4);
    asyncEnd();
  });

  A a = new A(13);

  var b = new A(9);
  asyncReturn = a + b;
  Expect.isTrue(asyncReturn is Future);
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.equals((result as A).value, 22);
    asyncEnd();
  });

  var foo = 17;
  bar(int p1, p2) async {
    var z = 8;
    return p2 + z + foo;
  }

  asyncReturn = bar(1, 2);
  Expect.isTrue(asyncReturn is Future);
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.equals(result, 27);
    asyncEnd();
  });

  var moreNesting = (int shadowP1, String p2, num p3) {
    var z = 3;
    aa(int shadowP1) async {
      return foo + z + p3 + shadowP1;
    }

    return aa(6);
  };
  asyncReturn = moreNesting(1, "ignore", 2);
  Expect.isTrue(asyncReturn is Future);
  asyncStart();
  asyncReturn.then((Object? result) {
    Expect.equals(result, 28);
    asyncEnd();
  });

  var checkAsync = (var someFunc) {
    var toTest = someFunc();
    Expect.isTrue(toTest is Future);
    asyncStart();
    toTest.then((int result) {
      Expect.equals(result, 4);
      asyncEnd();
    });
  };
  checkAsync(() async => 4);
}
