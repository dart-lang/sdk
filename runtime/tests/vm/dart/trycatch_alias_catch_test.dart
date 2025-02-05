// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//
// Ensure that aliasing calculation takes try-catch into account.
// Otherwise, optimizations like dead store elimination can produce
// incorrect results.
//

import 'package:expect/expect.dart';

class C {
  int v = 0;
}

@pragma('vm:never-inline')
void alwaysThrow() {
  throw 'a';
}

void foo() {
  C? alias;
  final alloc = C();
  try {
    alias = alloc;
    alwaysThrow();
    alias = null;
  } catch (e) {}
  // here [alias] will be aliasing [alloc].
  // [alias] should be a `Phi(Constant(null), Parameter(...))`
  // where `Parameter` arrives from the catch entry.
  alias!.v = 42;
  // [alloc] should be referencing a AllocateObject
  // directly here.
  Expect.equals(42, alloc.v);
}

void main() {
  foo();
}
