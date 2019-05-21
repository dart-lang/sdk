// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'equality_expressions_test.dart' as equality_expressions;
import 'list_literal_test.dart' as list_literal;
import 'logical_boolean_expressions_test.dart' as logical_boolean_expressions;
import 'map_literal_test.dart' as map_literal;
import 'prefix_expressions_test.dart' as prefix_expressions;
import 'set_literal_test.dart' as set_literal;
import 'type_test_expressions_test.dart' as type_test_expressions;

main() {
  defineReflectiveSuite(() {
    equality_expressions.main();
    list_literal.main();
    logical_boolean_expressions.main();
    map_literal.main();
    prefix_expressions.main();
    set_literal.main();
    type_test_expressions.main();
  }, name: 'type inference');
}
