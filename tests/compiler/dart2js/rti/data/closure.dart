// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:needsArgs*/
class A<T> {
  m() {
    return /*needsSignature*/ (T t) {};
  }

  /*element: A.f:*/
  f() {
    return /**/ (int t) {};
  }
}

main() {
  new A<int>().m() is void Function(int);
  new A<int>().f() is void Function(int);
}
