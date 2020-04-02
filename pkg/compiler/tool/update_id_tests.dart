// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id_testing.dart' as id;

const List<String> idTests = <String>[
  'tests/compiler/dart2js/model/cfe_constant_test.dart',
  'tests/compiler/dart2js/annotations/annotations_test.dart',
  'tests/compiler/dart2js/closure/closure_test.dart',
  'tests/compiler/dart2js/codegen/model_test.dart',
  'tests/compiler/dart2js/deferred_loading/deferred_loading_test.dart',
  'tests/compiler/dart2js/field_analysis/jfield_analysis_test.dart',
  'tests/compiler/dart2js/field_analysis/kfield_analysis_test.dart',
  'tests/compiler/dart2js/impact/impact_test.dart',
  'tests/compiler/dart2js/inference/callers_test.dart',
  'tests/compiler/dart2js/inference/inference_test_helper.dart',
  'tests/compiler/dart2js/inference/inference_data_test.dart',
  'tests/compiler/dart2js/inference/side_effects_test.dart',
  'tests/compiler/dart2js/inlining/inlining_test.dart',
  'tests/compiler/dart2js/jumps/jump_test.dart',
  'tests/compiler/dart2js/member_usage/member_usage_test.dart',
  'tests/compiler/dart2js/optimization/optimization_test.dart',
  'tests/compiler/dart2js/rti/rti_need_test_helper.dart',
  'tests/compiler/dart2js/rti/rti_emission_test.dart',
  'tests/compiler/dart2js/static_type/static_type_test.dart',
  'tests/compiler/dart2js/static_type/type_promotion_test.dart',
  'tests/compiler/dart2js/equivalence/id_testing_test.dart',
];

main() async {
  await id.updateAllTests(idTests);
}
