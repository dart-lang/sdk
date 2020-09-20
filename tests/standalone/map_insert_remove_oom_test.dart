// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--old_gen_heap_size=12
//
// Notice we set the old gen heap size to 12 MB, which seems to be the minimum
// (in debug mode) to not cause us run OOM during isolate initialization.  The
// problem here is that we pre-allocate certain exceptions, e.g. NullThrownError
// during isolate initialization, but if we have an allocation failure before
// that, we end up running into a recursive allocate/throw loop.
//
// Test that compaction does occur on repeated add/remove.

main() {
  var x = {};
  for (int i = 0; i < 1000000; i++) {
    x[i] = 10;
    x.remove(i);
  }
}
