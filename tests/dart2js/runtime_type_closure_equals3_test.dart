// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

String method() => throw 'unreachable';

class Class1<T> {
  Class1();

  method() {
    T local1a() => throw 'unreachable';

    T local1b() => throw 'unreachable';

    T local2(T t, String s) => t;

    Expect.isTrue(local1a.runtimeType == local1b.runtimeType);
    Expect.isFalse(local1a.runtimeType == local2.runtimeType);
    Expect.isFalse(local1a.runtimeType == method.runtimeType);
  }
}

class Class2<T> {
  Class2();
}

main() {
  Class1<int>().method();
  Class2<int>();
}
