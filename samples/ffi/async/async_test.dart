// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file exercises the sample files so that they are tested.
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'sample_async_callback.dart' as sample0;
import 'sample_native_port_call.dart' as sample1;

main() {
  sample0.main();
  sample1.main();
}
