// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  factory A() = BAlias;
  factory A.named() = BAlias.named;
}

typedef BAlias = B;

class B implements A {
  B();
  B.named();
}

main() {}
