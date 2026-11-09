// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=irreducible
// typeFilter=NoMatch
// globalFilter=NoMatch

void main(List<String> args) {
  print(irreducible(args.length, 3));
}

/// Minimal 2-entry irreducible loop (`l1`, `l2`) where `x` is live only at `l1`
/// (producing `Constant(#undefined)` on edges entering `l2`) and `n` is live
/// across both entries.
@pragma('wasm:cfg')
int irreducible(int state, int n) {
  int x = 1;
  switch (state) {
    l1:
    case 1:
      if (n <= 0) return x;
      n--;
      continue l2;
    l2:
    default:
      x = 2;
      continue l1;
  }
}
