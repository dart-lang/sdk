// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "deferred_lib2.dart" deferred as d;

class B extends d.A {}

class C implements d.A {}

mixin D on d.A {}

mixin E implements d.A {}

class F with d.M {}

class G = Object with d.M;

extension type ET1(d.A id) implements d.A {}

extension type ET2<T extends d.A>(T id) implements d.A {}

extension type ET3(int id) implements d.ET1 {}

extension type ET4(d.A id) {}

extension type ET5(d.A id) implements d.ET2 {}

extension type ET6(d.B id) implements d.B {}

d.A a = new d.A();

d.B b = 0;

main() {
  print(ET1);
  print(ET2);
}