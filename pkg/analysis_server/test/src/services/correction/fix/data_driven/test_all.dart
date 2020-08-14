// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'convert_argument_to_type_argument_change_test.dart'
    as convert_argument_to_type_argument_change;
import 'rename_change_test.dart' as rename_change;

void main() {
  defineReflectiveSuite(() {
    convert_argument_to_type_argument_change.main();
    rename_change.main();
  });
}
