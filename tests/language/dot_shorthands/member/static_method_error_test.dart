// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Using dot shorthand syntax on an instance method.

// SharedOptions=--enable-experiment=dot-shorthands

class C {
  C foo() => C();
}

void main() {
  C c = .foo();
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'foo' isn't defined for the type 'C'.
}
