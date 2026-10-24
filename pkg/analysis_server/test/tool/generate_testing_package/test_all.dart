// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'generate_testing_package_test.dart' as generate_testing_package_test;

void main() {
  defineReflectiveSuite(() {
    generate_testing_package_test.main();
  }, name: 'generate_testing_package');
}
