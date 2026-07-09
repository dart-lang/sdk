// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> {
  factory A(T value) = _A;
}

class _A<T> implements A<T> {
  _A(T value);
}

abstract class B<T> {
  factory B(int value) = _B;
}

class _B<T> implements B<T> {
  _B(int value);
}

main() {}
