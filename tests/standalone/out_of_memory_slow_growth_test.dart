// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--old_gen_heap_size=20
// VMOptions=--old_gen_heap_size=20 --enable_vm_service --pause_isolates_on_unhandled_exceptions

import "package:expect/expect.dart";

main() {
  var leak;
  var exceptionThrown = false;
  try {
    leak = [];
    while (true) {
      leak = [leak];
    }
  } on OutOfMemoryError catch (exception) {
    leak = null;
    exceptionThrown = true;
    print("Okay");
  }
  Expect.isTrue(exceptionThrown);
}
