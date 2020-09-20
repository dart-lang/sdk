// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file exercises the sample files so that they are tested.
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'sample_ffi_bitfield.dart' as bitfield;
import 'sample_ffi_data.dart' as data;
import 'sample_ffi_dynamic_library.dart' as dynamic_library;
import 'sample_ffi_functions_callbacks_closures.dart'
    as functions_callbacks_closures;
import 'sample_ffi_functions_callbacks.dart' as functions_callbacks;
import 'sample_ffi_functions_structs.dart' as functions_structs;
import 'sample_ffi_functions.dart' as functions;
import 'sample_ffi_structs.dart' as structs;

main() {
  bitfield.main();
  data.main();
  dynamic_library.main();
  functions_callbacks_closures.main();
  functions_callbacks.main();
  functions_structs.main();
  functions.main();
  structs.main();
}
