// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test checking that inlines replacing binding instructions with non-binding
// instructions do not cause the compiler to crash due to not appropriately
// replacing uses of the original binding instruction.
//
// Here, all phi nodes generated within the try block are kept alive, and one of
// the phi nodes within toList (which gets inlined) uses the value of an
// instance call to setLength. Inlining setLength wthin toList replaced the
// (binding) InstanceCall instruction with a (non-binding) StoreInstanceField
// instruction, which caused the phi node to have an invalid SSA index argument.

void foo() {
  try {
    for (var i = 0; i < 1000; i++) {
      List.filled(10, null).toList(growable: true);
    }
  } catch (e) {}
}

void main() {
  foo();
  foo();
}
