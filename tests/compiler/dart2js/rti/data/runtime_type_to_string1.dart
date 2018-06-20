// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*!omit.class: Class1:*/
/*omit.class: Class1:*/
class Class1 {
  /*kernel.element: Class1.:needsSignature*/
  /*!kernel.element: Class1.:*/
  Class1();
}

/*kernel.class: Class2:needsArgs*/
/*!kernel.class: Class2:*/
class Class2<T> {
  /*kernel.element: Class2.:needsSignature*/
  /*!kernel.element: Class2.:*/
  Class2();
}

/*!omit.class: Class3:needsArgs*/
/*omit.class: Class3:*/
class Class3<T> implements Class1 {
  /*kernel.element: Class3.:needsSignature*/
  /*!kernel.element: Class3.:*/
  Class3();
}

/*kernel.element: main:needsSignature*/
/*!kernel.element: main:*/
main() {
  Class1 cls1 = new Class1();
  print(cls1.runtimeType.toString());
  new Class2<int>();
  Class1 cls3 = new Class3<int>();
  print(cls3.runtimeType.toString());
}
