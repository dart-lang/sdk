// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fuzzy_matcher_test.dart' as fuzzy_matcher;

void main() {
  defineReflectiveSuite(() {
    fuzzy_matcher.main();
  }, name: 'filtering');
}
