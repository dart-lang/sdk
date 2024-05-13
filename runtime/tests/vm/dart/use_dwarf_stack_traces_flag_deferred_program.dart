// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that the full stacktrace in an error object matches the stacktrace
// handed to the catch clause.

// Put the unused deferred library before the used one, to ensure that the
// loaded units (the root loading unit and the loading unit for lib) are not
// given consecutive unit IDs.
import 'use_save_debugging_info_flag_program.dart' deferred as unused;
import 'use_dwarf_stack_traces_flag_program.dart' deferred as lib;

void main(List<String> args) async {
  // The test never calls this program with arguments, so unused is not
  // loaded during actual runs. This is just here to avoid the frontend
  // being too clever by half.
  if (!args.isEmpty) {
    await unused.loadLibrary();
  }
  await lib.loadLibrary();

  lib.main();
}
