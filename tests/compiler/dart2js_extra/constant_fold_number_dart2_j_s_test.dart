// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// This test is making sure we don't try to constant fold numbers
// where the semantics differ at compile-time (Dart) and runtime (JS).

foo() => 0.0;
bar() => 0;

main() {
  Expect.equals(foo(), bar());
  Expect.equals(0.0, 0);
}
