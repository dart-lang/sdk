// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'language_feature_directive_lowering_test.dart'
    as language_feature_directive_lowering_test;

main() {
  defineReflectiveSuite(() {
    language_feature_directive_lowering_test.main();
  }, name: 'util');
}
