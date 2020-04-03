// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=1

// A phi can have Smi type but non-Smi bounds if it is dominated by a smi check
// which always deoptimizes. Test that bounds check generalizer guards against
// such situations.

@pragma('vm:prefer-inline')
int checkSmi(int a) => ~a;

@pragma('vm:prefer-inline')
bool lessThan(int x, int y) => x < y;

@pragma('vm:prefer-inline')
int accessArray(List<int> arr, int i) => arr[i];

void problem(List<int> arr, int n, bool f) {
  final C = 0x7000000000000000;
  for (var i = C, j = 0; lessThan(i, n); i++, j++) {
    if (f) {
      // Produce CheckSmi against C. This CheckSmi will be
      // hoisted out of the loop turning phi for j into a Smi
      // Phi.
      checkSmi(C);
      accessArray(arr, j); // Produce array access with bounds check for arr.
    }
  }
}

void main() {
  // Prime type feedback in checkSmi and accessArray helpers.
  // Note: we need these to be in separate helpers because we need
  // problematic code to appear on a never executed code path.
  // (It would trigger throw/deopt if it is ever executed).
  checkSmi(0);
  accessArray([1], 0);
  lessThan(1, 1);

  // Trigger the issue.
  problem([], 1, false);
}
