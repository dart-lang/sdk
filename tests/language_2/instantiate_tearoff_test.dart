// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

T f<T>(T x) => x;

int intToInt(int x) => x;
String stringToString(String x) => x;

main() {
  int Function(int) intFunc = f;
  dynamic intFuncDynamic = intFunc;
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
  String Function(String) stringFunc = f;
  dynamic stringFuncDynamic = stringFunc;
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
  dynamic Function(dynamic) dynamicFunc = f;
  dynamic dynamicFuncDynamic = dynamicFunc;
  Expect.throwsNoSuchMethodError(() {
    dynamicFuncDynamic<int>(1);
  });
}
