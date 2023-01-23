// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'move_top_level_to_file_test.dart' as move_top_level_to_file;

void main() {
  defineReflectiveSuite(() {
    move_top_level_to_file.main();
  }, name: 'refactoring');
}
