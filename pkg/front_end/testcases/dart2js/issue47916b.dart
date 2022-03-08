// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> {
  const factory A() = B;
}

abstract class B<S, T> implements A<T> {
  const factory B() = C;
}

class C<T, S, U> implements B<S, T> {
  const C();
}

main() {
  A<int>.new;
  B<String, double>.new;
  C<bool, num, void>.new;
}
