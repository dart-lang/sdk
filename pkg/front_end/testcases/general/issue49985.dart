// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef A<T> = C<T, int>;

class B<X, Y> {
  X x;

  B(this.x);
}

mixin Mixin {}

class C<X, Y> = B<X, Y> with Mixin;

var field = A((a, b) => 42);
