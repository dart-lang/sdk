// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from co19/LanguageFeatures/Super-parameters/semantics_A04_t12

class S {
  int s1, s2;
  S(this.s1, {this.s2 = 0});
}

class C extends S {
  int i1;
  C(this.i1, super.s1, {super.s2, super.s2});
}

test() {
  C(1, 2, s2: 3);
}
