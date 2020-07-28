// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

typedef G<T> = dynamic Function<S extends T>(S);
typedef H<T> = dynamic Function<S extends FutureOr<T>>(S, FutureOr<T>);
// TODO(johnniwinther): Enable and use these when #41951 is fixed to test that
//  updating self referencing type parameters works.
//typedef I<T> = void Function<S extends FutureOr<S>>(S, T);
//typedef J<T> = void Function<S extends FutureOr<S>?>(S, T);
//typedef K<T> = void Function<S extends FutureOr<S?>>(S, T);

class C<T> {
  G<T> field1;
  H<T> field2;

  C(this.field1, this.field2);
}

test1(C<num> c) {
  var f1 = c.field1 = <S extends num>(S s) {
    return s + 1; // ok
  };
  var f2 = c.field2 = <S extends FutureOr<num>>(S s, FutureOr<num> t) async {
    return (await t) + 1; // ok
  };
}

test2(C<num?> c) {
  var f1 = c.field1 = <S extends num?>(S s) {
    return s + 1; // error
  };
  var f2 = c.field2 = <S extends FutureOr<num?>>(S s, FutureOr<num?> t) async {
    return (await t) + 1; // error
  };
}

test3<S extends num?>(S s) => s + 1; // error

main() {}
