// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.dart.sdk.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'patch_test.dart' as patch_test;
import 'sdk_test.dart' as sdk;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    patch_test.main();
    sdk.main();
  }, name: 'sdk');
}
