// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast_test.dart' as ast;
import 'utilities_test.dart' as utilities;

main() {
  defineReflectiveSuite(() {
    ast.main();
    utilities.main();
  }, name: 'ast');
}
