// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef A<X> = B<X>;

extension type B<T>(int it) {
  B.named(this.it);
  factory B.fact(int it) => B(it);
  factory B.redirect(int it) = B;

  get g0 => A(1);
  get g1 => A.new;
  get g2 => A.named(1);
  get g3 => A.named;
  get g4 => A.fact(1);
  get g5 => A.fact;
  get g6 => A.redirect(1);
  get g7 => A.redirect;
}

void main() {}