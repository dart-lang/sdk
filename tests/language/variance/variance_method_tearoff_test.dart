// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests reified types of torn-off methods with type parameters that have
// explicit variance modifiers.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

class Contravariant<in T> {
  int method(T x) { return -1; }
}

class Invariant<inout T> {
  T method(T x) { return x; }
}

class LegacyCovariant<T> {
  int method(T x) { return -1; }
}

class NoSuchMethod<inout T> implements Invariant<T> {
  noSuchMethod(_) => 3;
}

main() {
  Contravariant<int> contraDiff = new Contravariant<num>();
  Expect.notType<int Function(Object)>(contraDiff.method);
  Expect.type<int Function(num)>(contraDiff.method);

  Contravariant<num> contraSame = new Contravariant<num>();
  Expect.notType<int Function(Object)>(contraSame.method);
  Expect.type<int Function(num)>(contraSame.method);

  Invariant<num> invSame = new Invariant<num>();
  Expect.notType<num Function(Object)>(invSame.method);
  Expect.type<num Function(num)>(invSame.method);

  LegacyCovariant<num> legacyDiff = new LegacyCovariant<int>();
  Expect.type<int Function(Object)>(legacyDiff.method);
  Expect.type<int Function(num)>(legacyDiff.method);

  LegacyCovariant<num> legacySame = new LegacyCovariant<num>();
  Expect.type<int Function(Object)>(legacySame.method);
  Expect.type<int Function(num)>(legacySame.method);

  NoSuchMethod<num> nsm = new NoSuchMethod<num>();
  Expect.notType<num Function(Object)>(nsm.method);
  Expect.type<num Function(num)>(nsm.method);
}
