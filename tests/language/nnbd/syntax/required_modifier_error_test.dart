// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Invalid uses of "required" modifier

required //# 01: syntax error
int f1(
  required //# 02: syntax error
  int x
) => throw 0;

required //# 03: syntax error
class C1 {
  required //# 04: syntax error
  int f2 = 0;
}

// Duplicate modifier
void f2({
  required
  required //# 05: syntax error
  int i,
}){
}

// Out of order modifiers
class C2 {
  void m({
    required int i1,
    covariant required int i2, //# 07: syntax error
    final required int i3, //# 08: syntax error
  }) {
  }
}

main() {
}
