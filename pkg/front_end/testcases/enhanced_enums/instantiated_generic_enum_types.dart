// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E<X> {
  one(1),
  two("2");

  final X field;

  const E(this.field);
}

test() {
  foo(E.one, E.two); // Ok.
}

foo(E<int> ei, E<String> es) {
  bar(ei, es); // Ok.
  bar(E.one, E.two); // Ok.
  bar(es, ei); // Error.
  bar(E.two, E.one); // Error.
}

bar(E<int> ei, E<String> es) {
  baz(ei, es); // Ok.
}

baz(E<Object> ei, E<Object> es) {
  boz(ei, es); // Error.
  boz(E.one, E.two); // Error.
}

boz(E<Never> ei, E<Never> es) {}

checkIsType<T>(x) {
  if (x is! T) {
    throw "Expected value of type ${x.runtimeType} to also be of type ${T}.";
  }
}

checkIsNotType<T>(x) {
  if (x is T) {
    throw "Expected value of type ${x.runtimeType} to not be of type ${T}.";
  }
}

main() {
  checkIsType<E<dynamic>>(E.one);
  checkIsType<E<dynamic>>(E.two);
  checkIsType<E<int>>(E.one);
  checkIsType<E<String>>(E.two);

  checkIsNotType<E<Never>>(E.one);
  checkIsNotType<E<Never>>(E.two);
  checkIsNotType<E<String>>(E.one);
  checkIsNotType<E<int>>(E.two);
}
