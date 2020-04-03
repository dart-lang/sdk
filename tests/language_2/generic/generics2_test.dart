// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program testing generic type allocations and generic type tests.

class A<E> {}

class Pair<P, Q> extends A /* i.e. extends A<dynamic> */ {
  final P fst;
  final Q snd;
  Pair(this.fst, this.snd);
}

main() {
  print(new Pair<int, int>(1, 2));
  print(new Pair<String, int>("1", 2));
}
