// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T Function<S extends T>() method<T>(S Function<S extends T>() f) => f;

abstract class A<T> {
  T Function<S extends T>(S s) foo = <S extends T>(S s) => s;
}

typedef F<T, S extends T> = int;
typedef G<T> = F<T, S> Function<S extends T>();
