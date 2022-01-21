// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test attempts to verify that the slow path for late static and
// instance field initialization appropriately restores the write barrier
// invariant.

import 'dart:_internal';

class Box {
  var field;
}

late var global = (() {
  VMInternalsForTesting.collectAllGarbage();
  return 10;
})();

@pragma('vm:never-inline')
foo() {
  final kTrue = int.parse('1') == 1;
  final box = Box(); // Ensure this box is allocated new
  if (kTrue) {
    global; // Will not block write-barrier elimination (GC in here should restore invariants)
    box.field = Box()..field = 42; // Runtime should've made `box` remembered.
    VMInternalsForTesting.collectAllGarbage();
  }
  return box;
}

main() {
  if (foo().field.field != 42) throw 'a';
}
