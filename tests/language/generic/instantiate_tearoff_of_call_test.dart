// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

T f<T>(T x) => x;

void test(T Function<T>(T) f) {
  int Function(int) intFunc = f.call;
  dynamic intFuncDynamic = intFunc;
  Expect.isTrue(intFuncDynamic is int Function(int));
  Expect.isFalse(intFuncDynamic is String Function(String));
  Expect.equals(intFuncDynamic(1), 1);
  Expect.throwsTypeError(() {
    intFuncDynamic('oops');
  });
  String Function(String) stringFunc = f.call;
  dynamic stringFuncDynamic = stringFunc;
  Expect.isTrue(stringFuncDynamic is String Function(String));
  Expect.isFalse(stringFuncDynamic is int Function(int));
  Expect.equals(stringFuncDynamic('hello'), 'hello');
  Expect.throwsTypeError(() {
    stringFuncDynamic(1);
  });
}

main() {
  test(f);
}
