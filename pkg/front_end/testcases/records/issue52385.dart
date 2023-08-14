// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {
  final T a;

  const Foo(T a) : a = a;
}

class Generic<T> {
  final (T a, T b) record;

  const Generic(T a) : record = (a, a);
}

class NotGeneric {
  final (int a, int b) record;

  const NotGeneric(int a) : record = (a, a);
}

void main() {
  const Foo(1);
  const Generic(1);
  const Generic<int>(1);
  const NotGeneric(1);
}
