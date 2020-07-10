// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:explicit=[B<A*>*]*/
class A {}

/*class: B:deps=[closure],explicit=[B<A*>*],needsArgs*/
class B<T> {}

main() {
  /*needsArgs,selectors=[Selector(call, call, arity=0, types=1)]*/
  closure<T>() => new B<T>();

  closure<A>() is B<A>;
}
