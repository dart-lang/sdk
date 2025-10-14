// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An empty class body, `{}`, can be replaced by `;`.

// SharedOptions=--enable-experiment=declaring-constructors

class C1;

class C2 with M1;

class C3(var int x) extends C1;

mixin class M1 implements C1;

mixin class M2;

extension type E1(int x);

extension type const E2(int x);

void main() {
  print(C1());
  print(C2());
  print(C3(1));
  print(E1(1));
  print(E2(1));
}
