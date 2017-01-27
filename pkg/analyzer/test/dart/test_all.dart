// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.dart.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast/test_all.dart' as ast;
import 'element/test_all.dart' as element;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    ast.main();
    element.main();
  }, name: 'dart');
}
