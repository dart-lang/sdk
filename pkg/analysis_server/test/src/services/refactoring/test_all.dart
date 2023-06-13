// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'convert_formal_parameters_test.dart' as convert_formal_parameters;
import 'move_top_level_to_file_test.dart' as move_top_level_to_file;

void main() {
  defineReflectiveSuite(() {
    convert_formal_parameters.main();
    move_top_level_to_file.main();
  }, name: 'refactoring');
}
