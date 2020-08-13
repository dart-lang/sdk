// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These flags can cause WeakSerializationReferences to replace the owner of
// some Code, which must be accounted for in AssignLoadingUnitsCodeVisitor.

// VMOptions=--no_retain_function_objects
// VMOptions=--dwarf_stack_traces

import "splay_test.dart" deferred as splay; // Some non-trivial code.

main() async {
  await splay.loadLibrary();
  splay.main();
}
