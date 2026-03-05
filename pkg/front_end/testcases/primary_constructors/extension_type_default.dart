// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  A get name;
}

extension type ET1(name) implements A {}

extension type ET2(int? _) {
  int? get name => 0;
}

extension type ET3(name) implements ET2 {}
