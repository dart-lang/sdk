// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {
  e1,
  e2;
  factory E.f(int i) => E.values[i];
}

enum F {
  f1,
  f2(42),
  f3.foo();
  factory F(int i) => F.values[i];
}

main() {}
