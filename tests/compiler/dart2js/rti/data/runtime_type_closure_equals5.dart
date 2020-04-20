// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*omit.class: Class1:needsArgs*/
/*strong.class: Class1:direct,explicit=[Class1.T],needsArgs*/
class Class1<T> {
  /*strong.member: Class1.:*/
  /*omit.member: Class1.:*/
  Class1();

  /*strong.member: Class1.method1a:needsSignature*/
  /*omit.member: Class1.method1a:needsSignature*/
  T method1a() => null;

  /*strong.member: Class1.method1b:needsSignature*/
  /*omit.member: Class1.method1b:needsSignature*/
  T method1b() => null;

  /*strong.member: Class1.method2:needsSignature*/
  /*omit.member: Class1.method2:needsSignature*/
  T method2(T t, String s) => t;
}

/*strong.class: Class2:*/
/*omit.class: Class2:*/
class Class2<T> {
  /*strong.member: Class2.:*/
  /*omit.member: Class2.:*/
  Class2();
}

/*strong.member: main:*/
/*omit.member: main:*/
main() {
  var c = new Class1<int>();

  Expect.isTrue(c.method1a.runtimeType == c.method1b.runtimeType);
  Expect.isFalse(c.method1a.runtimeType == c.method2.runtimeType);
  new Class2<int>();
}
