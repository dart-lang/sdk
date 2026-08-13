// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--interop-null-assertions
// ddcOptions=--interop-null-assertions

/// When using non-static JavaScript interop via package:js, values flowing
/// through APIs defined to be non-nullable should be checked for null when
/// `--interop-null-assertions` is enabled.
///
/// - In dart2js this is a compile time flag.
/// - In DDC this is a runtime flag so the option gets passed to the
///   bootstrapper script and set in the runtime before invoking the main
///   method.

import 'js_interop_non_null_asserts_utils.dart';

void main() {
  runTests(checksEnabled: true);
}
