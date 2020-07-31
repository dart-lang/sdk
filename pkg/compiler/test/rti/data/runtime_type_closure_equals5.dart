// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*spec.class: Class1:direct,explicit=[Class1.T*],needsArgs*/
/*prod.class: Class1:needsArgs*/
class Class1<T> {
  Class1();

  /*member: Class1.method1a:needsSignature*/
  T method1a() => null;

  /*member: Class1.method1b:needsSignature*/
  T method1b() => null;

  /*member: Class1.method2:needsSignature*/
  T method2(T t, String s) => t;
}

class Class2<T> {
  Class2();
}

main() {
  var c = new Class1<int>();

  Expect.isTrue(c.method1a.runtimeType == c.method1b.runtimeType);
  Expect.isFalse(c.method1a.runtimeType == c.method2.runtimeType);
  new Class2<int>();
}
