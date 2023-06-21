// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that the first phase of flow analysis (used for "lookahead" to see
// what variables are assigned inside loops and closures) properly detects
// variables assigned inside pattern assignments.

void main() {
  late String s;
  // `s` is definitely unassigned at this point.
  () {
    (s,) = ('',);
  }();
  // `s` should be considered potentially assigned at this point, since there's
  // an assignment to it inside the closure. (In point of fact, it's definitely
  // assigned, because the closure has definitely been called at this point, and
  // all control paths through the closure definitely assign to `s`. But flow
  // analysis only tracks closure creation, not calls to closures, so all it
  // knows is that `s` is potentially assigned). Therefore it should be legal to
  // read from `s` now.
  print(s);
}
