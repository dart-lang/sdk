// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart version of two-argument Ackermann-Peter function.

library deferred_load_constants;

// Constant declaration.
const c = const C();

// Class declaration (`C` is a constant expression).
class C {
  const C();
  static int staticfun(int x) => x;
}

// Function type definition.
typedef int funtype(int x);
// Top-level function.
int toplevel(int x) => x;
