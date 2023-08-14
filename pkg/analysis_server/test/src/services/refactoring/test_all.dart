// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'convert_all_formal_parameters_to_named_test.dart'
    as convert_all_formal_parameters_to_named;
import 'convert_selected_formal_parameters_to_named_test.dart'
    as convert_selected_formal_parameters_to_named;
import 'move_selected_formal_parameters_left_test.dart'
    as move_selected_formal_parameters_left;
import 'move_top_level_to_file_test.dart' as move_top_level_to_file;

void main() {
  defineReflectiveSuite(() {
    convert_all_formal_parameters_to_named.main();
    convert_selected_formal_parameters_to_named.main();
    move_selected_formal_parameters_left.main();
    move_top_level_to_file.main();
  }, name: 'refactoring');
}
