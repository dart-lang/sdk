// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:implicit=[A]*/
class A {}

/*element: B.:needsArgs,test,explicit=[B.T]*/
class B<T> {
  /*element: B.method:*/
  method(T t) => t is T;
}

/*element: main:*/
main() {
  new B<A>().method(new A());
}
