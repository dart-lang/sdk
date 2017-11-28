// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--old_gen_heap_size=10
// Test that compaction does occur on repeated add/remove.

main() {
  var x = {};
  for (int i = 0; i < 1000000; i++) {
    x[i] = 10;
    x.remove(i);
  }
}
