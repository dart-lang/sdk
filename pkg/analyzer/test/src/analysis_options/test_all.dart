// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_build_test.dart' as analysis_options_build;
import 'analysis_options_validation_test.dart' as analysis_options_validation;

main() {
  defineReflectiveSuite(() {
    analysis_options_build.main();
    analysis_options_validation.main();
  }, name: 'analysis_options');
}
