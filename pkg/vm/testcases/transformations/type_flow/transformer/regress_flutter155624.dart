// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/155624.
// Verifies that TFA correctly tree shakes redirecting factory from
// extension types when tear-off of the factory is used.

extension type ET1(int id) {
  ET1.c1() : this(0);
  ET1.c2(this.id);
  factory ET1.f1() = ET1.c1;
  factory ET1.f2(int v) => ET1.c2(v);
}

void main() {
  print(ET1.f1);
  print(ET1.f2);
}
