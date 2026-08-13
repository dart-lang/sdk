// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'correction_utils_test.dart' as correction_utils;

void main() {
  defineReflectiveSuite(() {
    correction_utils.main();
  }, name: 'edit');
}
