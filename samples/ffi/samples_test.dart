// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file exercises the sample files so that they are tested.
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'sample_ffi_bitfield.dart' as sample0;
import 'sample_ffi_data.dart' as sample1;
import 'sample_ffi_dynamic_library.dart' as sample2;
import 'sample_ffi_functions_callbacks.dart' as sample3;
import 'sample_ffi_functions_structs.dart' as sample4;
import 'sample_ffi_functions.dart' as sample5;
import 'sample_ffi_structs.dart' as sample6;

main() {
  sample0.main();
  sample1.main();
  sample2.main();
  sample3.main();
  sample4.main();
  sample5.main();
  sample6.main();
}
