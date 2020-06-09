// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: Class:*/
class Class<T> {
  /*member: Class.:*/
  Class();
}

/*member: method1:*/
method1<T>() {}

/*member: method2:*/
method2<T>(t, s) => t;

/*member: main:*/
main() {
  print('${method1.runtimeType}');
  method2(0, '');
  new Class();
}
