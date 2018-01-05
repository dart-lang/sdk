// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:classNeedsRti*/
class A<T> {
  /*element: A.m:methodNeedsRti*/
  void m(T t) {}
}

/*element: main:*/
main() {
  new A<int>().m is void Function(int);
}
