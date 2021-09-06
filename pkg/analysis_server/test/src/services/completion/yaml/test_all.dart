// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_generator_test.dart' as analysis_options_generator;
import 'fix_data_generator_test.dart' as fix_data_generator;
import 'pubspec_generator_test.dart' as pubspec_generator;

void main() {
  defineReflectiveSuite(() {
    analysis_options_generator.main();
    fix_data_generator.main();
    pubspec_generator.main();
  }, name: 'yaml');
}
