// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--delete-tostring-package-uri=package:smith

import 'package:expect/expect.dart';

import 'delete_tostring_test.dart' show archX64, archArm;

main() {
  // The `toString()` was replaced with `super.toString()` which defaults to the
  // one from `Object.toString()`:
  Expect.equals('Instance of \'Architecture\'', archX64.toString());
  Expect.equals('Instance of \'Architecture\'', archArm.toString());
}
