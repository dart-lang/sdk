// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*element: method1a:*/
T method1a<T>() => null;

/*element: method1b:*/
T method1b<T>() => null;

/*strong.element: method2:direct,explicit=[method2.T],needsArgs*/
/*omit.element: method2:*/
T method2<T>(T t, String s) => t;

/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*strong.element: Class.:*/
  /*omit.element: Class.:*/
  Class();
}

/*strong.element: main:*/
/*omit.element: main:*/
main() {
  Expect.isTrue(method1a.runtimeType == method1b.runtimeType);
  Expect.isFalse(method1a.runtimeType == method2.runtimeType);
  new Class<int>();
}
