// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*kernel.class: Class1:needsArgs*/
/*!kernel.class: Class1:*/
class Class1<T> {
  /*kernel.element: Class1.:needsSignature*/
  /*!kernel.element: Class1.:*/
  Class1();

  // TODO(johnniwinther): Currently only methods that use class type variables
  // in their signature are marked as 'needs signature'. Change this to mark
  // all methods that need to support access to their function type at runtime.
  /*kernel.element: Class1.method1a:needsSignature*/
  /*!kernel.element: Class1.method1a:*/
  method1a() => null;

  /*kernel.element: Class1.method1b:needsSignature*/
  /*!kernel.element: Class1.method1b:*/
  method1b() => null;

  /*kernel.element: Class1.method2:needsSignature*/
  /*!kernel.element: Class1.method2:*/
  method2(t, s) => t;
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
  var c = new Class1<int>();

  Expect.isTrue(c.method1a.runtimeType == c.method1b.runtimeType);
  Expect.isFalse(c.method1a.runtimeType == c.method2.runtimeType);
  new Class2<int>();
}
