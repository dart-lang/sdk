// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that the trailing "!" properly promotes the type `Null` to `Never`, by
// verifying that it's statically ok to pass it to a function expecting a
// non-null parameter.
import 'package:expect/expect.dart';

void f(int i) {}

void g(Null n) {
   // Statically ok because `Never <: int`.  Throws at runtime.
  f(n!);
}

main() {
  Expect.throws(() => g(null));
}
