// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library main;

import 'dart:io' show File, Process, exit;

int doitstat(int x) => x + 1;

int globalVar = 6;

class A<T> {
  const A();
  static int doit(int x) => x + 1;
  static int staticVar = 3;
  int doit_with_this(int x) => x + 1;
}

T id<T>(T x) => x;

class B {
  int x;
  final int y = 7;
  String get z {
    return "";
  }

  void set z(int _) {}
}

class Bound {}

class C<T extends Bound> {}

void hasBound<T extends Bound>() {}

Object k;

class D<T> {
  Y id<Y>(Y x) => x;
  m(List<T> l) {
    assert(l is List<T>);
  }

  foo() {
    List<T> s;
  }
}

abstract class Built<V extends Built<V, B>, B extends Builder<V, B>> {}

abstract class Builder<V extends Built<V, B>, B extends Builder<V, B>> {}

class MiddlewareApi<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>> {}

main() {
  exit(0);
}
