// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast_test.dart' as ast;
import 'numeric_test.dart' as numeric;
import 'range_factory_test.dart' as range_factory;
import 'string_test.dart' as string;

void main() {
  defineReflectiveSuite(() {
    ast.main();
    numeric.main();
    range_factory.main();
    string.main();
  });
}
