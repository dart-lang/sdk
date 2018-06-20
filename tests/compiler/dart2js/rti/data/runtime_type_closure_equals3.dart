// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

String method() => null;

/*!strong.class: Class1:needsArgs*/
/*strong.class: Class1:direct,explicit=[Class1.T],needsArgs*/
class Class1<T> {
  /*kernel.element: Class1.:needsSignature*/
  /*!kernel.element: Class1.:*/
  Class1();

  /*kernel.element: Class1.method:needsSignature*/
  /*!kernel.element: Class1.method:*/
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

/*kernel.class: Class2:needsArgs*/
/*!kernel.class: Class2:*/
class Class2<T> {
  /*kernel.element: Class2.:needsSignature*/
  /*!kernel.element: Class2.:*/
  Class2();
}

/*kernel.element: main:needsSignature*/
/*!kernel.element: main:*/
main() {
  new Class1<int>().method();
  new Class2<int>();
}
