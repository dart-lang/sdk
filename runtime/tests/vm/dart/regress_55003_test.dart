// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler correctly chooses representation and
// doesn't crash when canonicalizing multiplication to a shift
// after the final SelectRepresentations pass.
// Regression test for https://github.com/dart-lang/sdk/issues/55003.

import 'package:expect/expect.dart';

int one = int.parse('1');

@pragma('vm:never-inline')
void test1() {
  // Truncation of 0xaabbccdd00000004 to uint32 is inserted
  // by SelectRepresentations_Final. After that, canonicalization
  // replaces BinaryUint32Op multiplication with a shift.
  Expect.equals(4, (one * 0xaabbccdd00000004) % 8);
}

@pragma('vm:never-inline')
void test2() {
  // Truncation of 0xaabbccdd00000000 to uint32 is inserted
  // by SelectRepresentations_Final. After that, canonicalization
  // replaces outer BinaryInt64Op multiplication with a shift.
  Expect.equals(4, one * (((one * 0xaabbccdd00000000) % 8) + 4));
}

main() {
  test1();
  test2();
}
