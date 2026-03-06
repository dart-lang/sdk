// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An empty declaration body, `{}`, can be replaced by `;`.

// SharedOptions=--enable-experiment=primary-constructors

// Classes
class C1;

class C2 with M1;

class C3(var int x) extends C1;

// Extension types
extension type E1(int x);

extension type const E2(int x);

// Mixin classes
mixin class M1 implements C1;

class M1With with M1;

mixin class M2;

class M2With with M2;

// Mixins
mixin M3;

class M3With with M3;

mixin M4 implements C1;

class M4With with M4;

mixin M5 on C1;

class M5With extends C1 with M5;

// Extension
extension Ext1 on C1;

void main() {
  print(C1());
  print(C2());
  print(C3(1));
  print(E1(1));
  print(E2(1));
  print(M1With());
  print(M2With());
  print(M3With());
  print(M4With());
  print(M5With());
}
