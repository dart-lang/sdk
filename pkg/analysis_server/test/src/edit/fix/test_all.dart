// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_nullable_fix_test.dart' as non_nullable_fix;

void main() {
  defineReflectiveSuite(() {
    non_nullable_fix.main();
  }, name: 'fix');
}
