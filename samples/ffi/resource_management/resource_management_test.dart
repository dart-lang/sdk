// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file exercises the sample files so that they are tested.
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'arena_isolate_shutdown_sample.dart' as arena_isolate;
import 'arena_sample.dart' as arena;
import 'arena_zoned_sample.dart' as arena_zoned;
import 'unmanaged_sample.dart' as unmanaged;

main() {
  arena_isolate.main();
  arena.main();
  arena_zoned.main();
  unmanaged.main();
}
