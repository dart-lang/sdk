// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// When using non-static JavaScript interop via package:js, values flowing
/// through APIs defined to be non-nullable should not be checked for null when
/// `--interop-null-assertions` is not enabled.
///
/// Without that flag, null values can leak through APIs that are typed as
/// non-nullable, even when sound null safety is enabled.

import 'js_interop_non_null_asserts_utils.dart';

void main() {
  runTests(checksEnabled: false);
}
