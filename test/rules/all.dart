// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'avoid_function_literals_in_foreach_calls.dart'
    as avoid_function_literals_in_foreach_calls;
import 'avoid_init_to_null.dart' as avoid_init_to_null;
import 'missing_whitespace_between_adjacent_strings.dart'
    as missing_whitespace_between_adjacent_strings;
import 'overridden_fields.dart' as overridden_fields;
import 'prefer_asserts_in_initializer_lists.dart'
    as prefer_asserts_in_initializer_lists;
import 'prefer_const_constructors_in_immutables.dart'
    as prefer_const_constructors_in_immutables;
import 'prefer_contains.dart' as prefer_contains;
import 'prefer_spread_collections.dart' as prefer_spread_collections;
import 'type_init_formals.dart' as type_init_formals;
import 'void_checks.dart' as void_checks;

void main() {
  avoid_function_literals_in_foreach_calls.main();
  avoid_init_to_null.main();
  missing_whitespace_between_adjacent_strings.main();
  overridden_fields.main();
  prefer_asserts_in_initializer_lists.main();
  prefer_const_constructors_in_immutables.main();
  prefer_contains.main();
  prefer_spread_collections.main();
  type_init_formals.main();
  void_checks.main();
}
