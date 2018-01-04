// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:classNeedsRti,explicit=[A<int>]*/
class A<T> {}

/*element: B.:classNeedsRti*/
class B<T> extends A<T> {}

/*element: main:*/
main() {
  new B<int>() is A<int>;
}
