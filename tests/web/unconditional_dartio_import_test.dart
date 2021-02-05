// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that dart2js allows to import dart:io for web clients, but it
/// continues to indicate that it is not supported (so config-specific imports
/// continue to have the same semantics as before).
library unconditional_dartio_import_test;

import 'dart:io' as io; // import is allowed!
import 'package:expect/expect.dart';

main() {
  // their APIs throw:
  Expect.throws(() => new io.File('name').existsSync());

  // ... but environment variable will indicate it is not supported.
  Expect.isFalse(const bool.fromEnvironment('dart.library.io'));
}
