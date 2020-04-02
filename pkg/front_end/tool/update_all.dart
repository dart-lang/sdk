// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id_testing.dart' as id;
import 'update_expectations.dart' as expectations;

const List<String> idTests = <String>[
  'pkg/front_end/test/covariance_check/covariance_check_test.dart',
  'pkg/front_end/test/extensions/extensions_test.dart',
  'pkg/front_end/test/id_testing/id_testing_test.dart',
  'pkg/front_end/test/id_tests/assigned_variables_test.dart',
  'pkg/front_end/test/id_tests/constant_test.dart',
  'pkg/front_end/test/id_tests/definite_assignment_test.dart',
  'pkg/front_end/test/id_tests/definite_unassignment_test.dart',
  'pkg/front_end/test/id_tests/inheritance_test.dart',
  'pkg/front_end/test/id_tests/nullability_test.dart',
  'pkg/front_end/test/id_tests/reachability_test.dart',
  'pkg/front_end/test/id_tests/type_promotion_test.dart',
  'pkg/front_end/test/language_versioning/language_versioning_test.dart',
  'pkg/front_end/test/patching/patching_test.dart',
  'pkg/front_end/test/static_types/static_type_test.dart',
];

main() async {
  // Update all tests based on expectation files.
  await expectations.main(const <String>[]);

  // Update all id-tests.
  await id.updateAllTests(idTests);
}
