// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'google_analytics_manager_test.dart' as google_analytics_manager;
import 'percentile_calculator_test.dart' as percentile_calculator;

void main() {
  defineReflectiveSuite(() {
    google_analytics_manager.main();
    percentile_calculator.main();
  });
}
