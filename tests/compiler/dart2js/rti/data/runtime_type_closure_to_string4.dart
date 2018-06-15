// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Class1:*/
class Class1 {
  /*kernel.element: Class1.:needsSignature*/
  /*!kernel.element: Class1.:*/
  Class1();

  /*kernel.element: Class1.method:needsSignature*/
  /*strong.element: Class1.method:needsArgs*/
  /*omit.element: Class1.method:*/
  T method<T>() => null;
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
  Class1 cls1 = new Class1();
  print(cls1.method.runtimeType.toString());
  new Class2<int>();
}
