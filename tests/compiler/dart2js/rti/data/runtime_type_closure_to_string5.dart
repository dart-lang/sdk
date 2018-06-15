// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*kernel.class: Class:needsArgs*/
/*!kernel.class: Class:*/
class Class<T> {
  /*kernel.element: Class.:needsSignature*/
  /*!kernel.element: Class.:*/
  Class();
}

/*kernel.element: method1:needsSignature*/
/*!kernel.element: method1:*/
method1() {}

/*kernel.element: method2:needsSignature*/
/*!kernel.element: method2:*/
method2(int i, String s) => i;

/*kernel.element: main:needsSignature*/
/*!kernel.element: main:*/
main() {
  print('${method1.runtimeType}');
  method2(0, '');
  new Class();
}
