// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Class1<T> {
  Class1();

  T method1a() => throw 'unreachable';

  T method1b() => throw 'unreachable';

  T method2(T t, String s) => t;
}

class Class2<T> {
  Class2();
}

main() {
  var c = Class1<int>();

  Expect.isTrue(c.method1a.runtimeType == c.method1b.runtimeType);
  Expect.isFalse(c.method1a.runtimeType == c.method2.runtimeType);
  Class2<int>();
}
