// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:explicit=[B<A>]*/
class A {}

/*element: B.:needsArgs,deps=[C],explicit=[B<A>]*/
class B<T> {}

/*element: C.:needsArgs*/
class C<T> {
  /*element: C.method:*/
  method() => new B<T>();
}

/*element: main:*/
main() {
  // TODO(johnniwinther): Avoid the need to instantiate A for testing the use of
  // it.
  new A();
  new C<A>().method() is B<A>;
}
