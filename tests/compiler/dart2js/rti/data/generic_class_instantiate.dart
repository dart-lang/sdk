// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:explicit=[B<A>]*/
class A {}

/*class: B:needsArgs,deps=[C],explicit=[B<A>]*/
class B<T> {}

/*class: C:needsArgs*/
class C<T> {
  method() => new B<T>();
}

main() {
  new C<A>().method() is B<A>;
}
