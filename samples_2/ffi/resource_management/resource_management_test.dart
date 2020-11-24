// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file exercises the sample files so that they are tested.
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

// @dart = 2.9

import 'pool_isolate_shutdown_sample.dart' as pool_isolate;
import 'pool_sample.dart' as pool;
import 'pool_zoned_sample.dart' as pool_zoned;
import 'unmanaged_sample.dart' as unmanaged;

main() {
  pool_isolate.main();
  pool.main();
  pool_zoned.main();
  unmanaged.main();
}
