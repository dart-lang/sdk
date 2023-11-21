// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast_to_ir_test.dart' as ast_to_ir;
import 'scope_analyzer_test.dart' as scope_analyzer;
import 'validator_test.dart' as validator;

main() {
  defineReflectiveSuite(() {
    ast_to_ir.main();
    scope_analyzer.main();
    validator.main();
  }, name: 'ir');
}
