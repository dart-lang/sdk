// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*kernel.class: Class:needsArgs*/
/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*kernel.element: Class.:needsSignature*/
  /*strong.element: Class.:*/
  /*omit.element: Class.:*/
  Class();
}

/*kernel.element: method1:needsSignature*/
/*strong.element: method1:*/
/*omit.element: method1:*/
method1() {}

/*kernel.element: method2:needsSignature*/
/*strong.element: method2:*/
/*omit.element: method2:*/
method2(int i, String s) => i;

/*kernel.element: main:needsSignature*/
/*strong.element: main:*/
/*omit.element: main:*/
main() {
  print('${method1.runtimeType}');
  method2(0, '');
  new Class();
}
