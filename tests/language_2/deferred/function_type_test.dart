// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=
// VMOptions=--dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects

import 'function_type_lib.dart' deferred as lib;

main() {
  lib.loadLibrary().then((_) {
    lib.runTest();
  });
}
