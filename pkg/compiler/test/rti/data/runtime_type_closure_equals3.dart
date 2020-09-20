// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

String method() => null;

/*spec.class: Class1:direct,explicit=[Class1.T*],needsArgs*/
/*prod.class: Class1:needsArgs*/
class Class1<T> {
  Class1();

  method() {
    /*needsSignature*/
    T local1a() => null;

    /*needsSignature*/
    T local1b() => null;

    /*needsSignature*/
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
  new Class1<int>().method();
  new Class2<int>();
}
