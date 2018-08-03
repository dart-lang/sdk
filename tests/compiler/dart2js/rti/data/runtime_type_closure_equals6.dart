// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*kernel.element: method1a:needsSignature*/
/*strong.element: method1a:*/
/*omit.element: method1a:*/
method1a() => null;

/*kernel.element: method1b:needsSignature*/
/*strong.element: method1b:*/
/*omit.element: method1b:*/
method1b() => null;

/*kernel.element: method2:needsSignature*/
/*strong.element: method2:*/
/*omit.element: method2:*/
method2(t, s) => t;

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
