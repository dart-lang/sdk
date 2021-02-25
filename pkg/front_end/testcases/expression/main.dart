// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library main;

import 'dart:io' show File, Process, exit;

List<String> listOfStrings = ["hello"];

int doitstat(int x) => x + 1;
int _privateToplevel(int x) => x + 1;

int globalVar = 6;
int _globalPrivate = 7;

const ConstClass const42 = ConstClass(42);

class ConstClass {
  static const ConstClass classConst42 = ConstClass(42);
  final int x;
  const ConstClass(this.x);
}

class A<T> {
  const A();
  static int doit(int x) => x + 1;
  static int staticVar = 3;
  int doit_with_this(int x) => x + 1;

  final int _priv = 0;
  void _privMethod() {}
}

T id<T>(T x) => x;

class B extends A<Object> {
  int x;
  final int y = 7;
  int _priv;
  String get z {
    return "";
  }

  void set z(_) {}
  void _privMethod() {}
}

class Bound {}

class HasPrivate {
  int _priv = 0;
}

class C<T extends Bound> extends HasPrivate {}

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
