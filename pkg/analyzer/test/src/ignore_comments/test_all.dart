// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'diagnostic_suppression_test.dart' as diagnostic_suppression_test;
import 'ignore_info_test.dart' as ignore_info;

main() {
  defineReflectiveSuite(() {
    diagnostic_suppression_test.main();
    ignore_info.main();
  }, name: 'src');
}
