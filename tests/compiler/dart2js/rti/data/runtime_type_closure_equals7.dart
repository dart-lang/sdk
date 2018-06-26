// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*kernel.element: method1a:needsSignature*/
/*strong.element: method1a:needsArgs*/
/*omit.element: method1a:needsArgs*/
T method1a<T>() => null;

/*kernel.element: method1b:needsSignature*/
/*strong.element: method1b:needsArgs*/
/*omit.element: method1b:needsArgs*/
T method1b<T>() => null;

/*kernel.element: method2:needsSignature*/
/*strong.element: method2:direct,explicit=[method2.T],needsArgs*/
/*omit.element: method2:needsArgs*/
T method2<T>(T t, String s) => t;

/*kernel.class: Class:needsArgs*/
/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*kernel.element: Class.:needsSignature*/
  /*strong.element: Class.:*/
  /*omit.element: Class.:*/
  Class();
}

/*kernel.element: main:needsSignature*/
/*strong.element: main:*/
/*omit.element: main:*/
main() {
  Expect.isTrue(method1a.runtimeType == method1b.runtimeType);
  Expect.isFalse(method1a.runtimeType == method2.runtimeType);
  new Class<int>();
}
