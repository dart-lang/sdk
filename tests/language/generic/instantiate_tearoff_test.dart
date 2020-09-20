// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--lazy-dispatchers
// VMOptions=--no-lazy-dispatchers

import "package:expect/expect.dart";

T f<T>(T x) => x;

int intToInt(int x) => x;
String stringToString(String x) => x;
String stringAndIntToString(String x, int y) => x;

test(intFuncDynamic, stringFuncDynamic, dynamicFuncDynamic) {
  Expect.isTrue(intFuncDynamic is int Function(int));
  Expect.isFalse(intFuncDynamic is String Function(String));
  Expect.equals(intFuncDynamic(1), 1);
  Expect.equals("${intFuncDynamic.runtimeType}", "${intToInt.runtimeType}");
  Expect.throwsTypeError(() {
    intFuncDynamic('oops');
  });
  Expect.throwsNoSuchMethodError(() {
    intFuncDynamic<String>('oops');
  });
  Expect.isTrue(stringFuncDynamic is String Function(String));
  Expect.isFalse(stringFuncDynamic is int Function(int));
  Expect.equals(stringFuncDynamic('hello'), 'hello');
  Expect.equals(
      "${stringFuncDynamic.runtimeType}", "${stringToString.runtimeType}");
  Expect.throwsTypeError(() {
    stringFuncDynamic(1);
  });
  Expect.throwsNoSuchMethodError(() {
    stringFuncDynamic<int>(1);
  });
  Expect.throwsNoSuchMethodError(() {
    dynamicFuncDynamic<int>(1);
  });
}

main() {
  int Function(int) if1 = f;
  String Function(String) sf1 = f;
  dynamic Function(dynamic) df1 = f;
  test(if1, sf1, df1);

  T local<T>(T x) => x;

  int Function(int) if2 = local;
  String Function(String) sf2 = local;
  dynamic Function(dynamic) df2 = local;
  test(if2, sf2, df2);

  dynamic bar<X>() {
    String foo<T>(X x, T t) {
      return "$X, $T";
    }

    String Function(X, int) x = foo;
    return x;
  }

  dynamic fn = bar<String>();
  Expect.equals("${fn.runtimeType}", "${stringAndIntToString.runtimeType}");
  Expect.equals(fn("a", 1), "String, int");
}
