// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*strong.class: Class1:needsArgs*/
/*omit.class: Class1:*/
class Class1<T> {
  /*strong.element: Class1.:*/
  /*omit.element: Class1.:*/
  Class1();
}

/*strong.class: Class2:needsArgs*/
/*omit.class: Class2:*/
class Class2<T> {
  /*strong.element: Class2.:*/
  /*omit.element: Class2.:*/
  Class2();
}

/*strong.element: main:*/
/*omit.element: main:*/
main() {
  dynamic cls1 = new Class1<int>();
  print('${cls1.runtimeType}');
  new Class2<int>();
  cls1 = null;
}
