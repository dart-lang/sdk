// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*strong.member: Class.:*/
  /*omit.member: Class.:*/
  Class();
}

/*strong.member: method1:*/
/*omit.member: method1:*/
method1() {}

/*strong.member: method2:*/
/*omit.member: method2:*/
method2(int i, String s) => i;

/*strong.member: main:*/
/*omit.member: main:*/
main() {
  print('${method1.runtimeType}');
  method2(0, '');
  new Class();
}
