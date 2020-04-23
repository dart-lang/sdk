// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*strong.class: Class1:*/
/*omit.class: Class1:*/
class Class1<T> {
  /*strong.member: Class1.:*/
  /*omit.member: Class1.:*/
  Class1();

  // TODO(johnniwinther): Currently only methods that use class type variables
  // in their signature are marked as 'needs signature'. Change this to mark
  // all methods that need to support access to their function type at runtime.

  /*strong.member: Class1.method1a:*/
  /*omit.member: Class1.method1a:*/
  method1a() => null;

  /*strong.member: Class1.method1b:*/
  /*omit.member: Class1.method1b:*/
  method1b() => null;

  /*strong.member: Class1.method2:*/
  /*omit.member: Class1.method2:*/
  method2(t, s) => t;
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
