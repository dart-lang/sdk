// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:explicit=[B<A>]*/
class A {}

/*ast.class: B:needsArgs,deps=[closure],explicit=[B<A>]*/
/*kernel.class: B:needsArgs,deps=[closure],explicit=[B<A>],required*/
class B<T> {}

main() {
  /*kernel.needsArgs*/ closure<T>() => new B<T>();

  closure<A>() is B<A>;
}
