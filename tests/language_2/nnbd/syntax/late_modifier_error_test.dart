// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Invalid uses of "late" modifier

late //# 01: compile-time error
int f1(
  late //# 02: compile-time error
  int x
) {}

late //# 03: compile-time error
class C1 {
  late //# 04: compile-time error
  int m() {}
}

main() {
}
