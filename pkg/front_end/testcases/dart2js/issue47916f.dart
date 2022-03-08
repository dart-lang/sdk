// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> {
  const factory A() = B;
}

abstract class B<T> implements A<T> {
  const factory B() = C;
}

class C<T> implements B<T> {
  const factory C() = B;
}

test() {
  A.new;
  B.new;
  C.new;
}

main() {}
