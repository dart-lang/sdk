// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Class:*/
class Class<T> {
  /*element: Class.:*/
  Class();
}

/*element: method1:*/
method1<T>() {}

/*element: method2:*/
method2<T>(t, s) => t;

/*element: main:*/
main() {
  print('${method1.runtimeType}');
  method2(0, '');
  new Class();
}
