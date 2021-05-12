// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class Class1 {
  Class1();
}

class Class2<T> implements Class1 {
  Class2();
}

main() {
  Class1 cls1 = new Class1();
  Class1 cls2a = new Class2<int>();
  Class1 cls2b = new Class2<int>();
  Class1 cls2c = new Class2<String>();
  var r1 = cls1.runtimeType;
  var r2a = cls2a.runtimeType;
  var r2b = cls2b.runtimeType;
  var r2c = cls2c.runtimeType;
  Expect.equals(r1, r1);
  Expect.notEquals(r1, r2a);
  Expect.notEquals(r1, r2b);
  Expect.notEquals(r1, r2c);
  Expect.equals(r2a, r2a);
  Expect.equals(r2a, r2b);
  Expect.notEquals(r2a, r2c);
  Expect.equals(r2b, r2b);
  Expect.notEquals(r2b, r2c);
  Expect.equals(r2c, r2c);
}
