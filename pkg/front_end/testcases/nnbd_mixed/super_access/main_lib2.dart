// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Value<T> {}

typedef Typedef<T extends Value, I> = Type Function(I item);

class Interface<T extends Value, I> {
  Typedef<T, I>? field;
  Typedef<T, I>? method1() => null;
  void method2(Typedef<T, I>? t) {}
}
