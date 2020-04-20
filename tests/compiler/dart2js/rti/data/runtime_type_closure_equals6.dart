// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*strong.member: method1a:*/
/*omit.member: method1a:*/
method1a() => null;

/*strong.member: method1b:*/
/*omit.member: method1b:*/
method1b() => null;

/*strong.member: method2:*/
/*omit.member: method2:*/
method2(t, s) => t;

/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*strong.member: Class.:*/
  /*omit.member: Class.:*/
  Class();
}

/*strong.member: main:*/
/*omit.member: main:*/
main() {
  Expect.isTrue(method1a.runtimeType == method1b.runtimeType);
  Expect.isFalse(method1a.runtimeType == method2.runtimeType);
  new Class<int>();
}
