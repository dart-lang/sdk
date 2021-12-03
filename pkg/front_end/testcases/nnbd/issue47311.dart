// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

typedef Baz<T> = T Function(T);

class Foo1<T> {
  void method<S extends T>(Baz<S> x) {}
}

class Bar1 implements Foo1<Object> {
  void method<T extends Object>(Baz<T> x) {}
}

class Foo2<T> {
  void method<V extends S, S extends T>(Baz<S> x, Baz<V> y) {}
}

class Bar2 implements Foo2<Object> {
  void method<V extends T, T extends Object>(Baz<T> x, Baz<V> y) {}
}

class Foo3<T> {
  void method<V extends S, S extends FutureOr<T>>(Baz<S> x, Baz<V> y) {}
}

class Bar3 implements Foo3<Object> {
  void method<V extends T, T extends FutureOr<Object>>(Baz<T> x, Baz<V> y) {}
}

class Foo4<T> {
  void method<V extends FutureOr<S>, S extends T>(Baz<S> x, Baz<V> y) {}
}

class Bar4 implements Foo4<Object> {
  void method<V extends FutureOr<T>, T extends Object>(Baz<T> x, Baz<V> y) {}
}

class Foo5<T> {
  void method<V extends FutureOr<S>, S extends FutureOr<T>>(Baz<S> x, Baz<V> y) {}
}

class Bar5 implements Foo5<Object> {
  void method<V extends FutureOr<T>, T extends FutureOr<Object>>(Baz<T> x, Baz<V> y) {}
}

void main() {}
