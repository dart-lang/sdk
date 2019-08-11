// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

Future<T> func1<T extends A>(T t) async {
  // TODO(37439): We should infer 'T' instead of '<bottom>'.
  return /*invoke: <bottom>*/ func2/*<<bottom>>*/(/*as: <bottom>*/ /*T*/ t);
}

T func2<T extends A>(T t) => /*T*/ t;

main() async {
  /*B*/ await /*invoke: Future<B>*/ func1/*<B>*/(/*B*/ B());
}
