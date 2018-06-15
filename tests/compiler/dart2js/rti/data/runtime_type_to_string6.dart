// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*!omit.class: Class1:needsArgs*/
/*omit.class: Class1:*/
class Class1<T> {
  /*kernel.element: Class1.:needsSignature*/
  /*!kernel.element: Class1.:*/
  Class1();
}

/*!omit.class: Class2:needsArgs*/
/*omit.class: Class2:*/
class Class2<T> {
  /*kernel.element: Class2.:needsSignature*/
  /*!kernel.element: Class2.:*/
  Class2();
}

/*kernel.element: main:needsSignature*/
/*!kernel.element: main:*/
main() {
  dynamic cls1 = new Class1<int>();
  print('${cls1.runtimeType}');
  new Class2<int>();
}
