// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

T f<T>() => throw '';

class A {}

class B extends A {}

test(Iterable<B> iterable, Stream<B> stream, A a, B b, int i) async {
  for (a in iterable) {}
  await for (a in stream) {}
  for (b in iterable) {}
  await for (b in stream) {}
  for (i in iterable) {}
  await for (i in stream) {}
  for (a in f()) {}
  await for (a in f()) {}
}

main() {}
