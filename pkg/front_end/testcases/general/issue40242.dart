// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {}

extension E on C {
  errors() {
    this = new C();
  }
}

errors() {
  final C c1 = new C();
  c1 = new C();
  C = Object;
  C c2;
  (c2) = new C();
  const c3 = Object;
  c3 = null;
}

main() {}