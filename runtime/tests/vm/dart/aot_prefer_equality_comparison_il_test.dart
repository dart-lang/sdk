// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we emit EqualityCompare rather than StrictCompare+BoxInt64
// when comparing non-nullable integer to a Smi.

// MatchIL[AOT]=factorial
// __ GraphEntry
// __ FunctionEntry
// __ CheckStackOverflow
// __ Branch(EqualityCompare)
@pragma('vm:never-inline')
int factorial(int value) => value == 1 ? value : value * factorial(value - 1);

void main() {
  print(factorial(4));
}
