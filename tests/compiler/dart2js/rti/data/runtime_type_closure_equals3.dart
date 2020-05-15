// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

String method() => null;

/*prod:nnbd-off|prod:nnbd-sdk.class: Class1:needsArgs*/
/*spec:nnbd-off.class: Class1:direct,explicit=[Class1.T],needsArgs*/
/*spec:nnbd-sdk.class: Class1:direct,explicit=[Class1.T*],needsArgs*/
class Class1<T> {
  /*spec:nnbd-off|prod:nnbd-off.member: Class1.:*/
  Class1();

  /*spec:nnbd-off|prod:nnbd-off.member: Class1.method:*/
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

/*spec:nnbd-off|prod:nnbd-off.class: Class2:*/
class Class2<T> {
  /*spec:nnbd-off|prod:nnbd-off.member: Class2.:*/
  Class2();
}

/*spec:nnbd-off|prod:nnbd-off.member: main:*/
main() {
  new Class1<int>().method();
  new Class2<int>();
}
