// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/57084.
// Verifies that summmary collector is not called recursively
// when recording a constant field which is incorrectly marked
// as isCovariantByClass and needs type guard summary.

abstract class A<T> {
  T get field;
  void set field(T value);
}

class C<T> implements A<T> {
  @override
  final T field;

  const C(this.field);

  @override
  set field(value) => throw '';
}

const c = C<String>('');

void main() {
  print(c);
  () {
    print(c);
  }();
}
