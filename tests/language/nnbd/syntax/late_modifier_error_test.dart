// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

// Invalid uses of "late" modifier

late //# 01: syntax error
int f1(
  late //# 02: syntax error
  int x
) => throw 0;

late //# 03: syntax error
class C1 {
  late //# 04: syntax error
  int m() => throw 0;
}

main() {
}
