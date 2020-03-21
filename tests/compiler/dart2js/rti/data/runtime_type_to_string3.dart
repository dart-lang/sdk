// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*strong.class: Class1:needsArgs*/
/*omit.class: Class1:*/
class Class1<T> {
  /*strong.member: Class1.:*/
  /*omit.member: Class1.:*/
  Class1();
}

/*strong.class: Class2:*/
/*omit.class: Class2:*/
class Class2<T> {
  /*strong.member: Class2.:*/
  /*omit.member: Class2.:*/
  Class2();
}

/*strong.member: main:*/
/*omit.member: main:*/
main() {
  Class1<int> cls1 = new Class1<int>();
  print(cls1.runtimeType?.toString());
  new Class2<int>();
}
