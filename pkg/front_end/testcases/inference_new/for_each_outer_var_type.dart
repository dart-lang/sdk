// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

T f<T>() => null;

class A {}

class B extends A {}

test() async {
  Iterable<A> iterable;
  Stream<A> stream;
  A a;
  B b;
  int i;
  for (a in iterable) {}
  await for (a in stream) {}
  for (b in iterable) {}
  await for (b in stream) {}
  for (i in iterable) {}
  await for (i in stream) {}
  for (a in /*@ typeArgs=Iterable<A*>* */ f()) {}
  await for (a in /*@ typeArgs=Stream<A*>* */ f()) {}
}

main() {}
