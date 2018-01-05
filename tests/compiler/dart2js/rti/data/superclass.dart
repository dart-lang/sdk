// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:*/
class A<T> {}

/*element: B.:needsArgs,explicit=[B<int>]*/
class B<T> extends A<T> {}

/*element: main:*/
main() {
  new B<int>() is B<int>;
}
