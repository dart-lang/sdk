// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id_testing.dart' as id;

const List<String> idTests = <String>[
  'pkg/compiler/test/model/cfe_constant_test.dart',
  'pkg/compiler/test/annotations/annotations_test.dart',
  'pkg/compiler/test/closure/closure_test.dart',
  'pkg/compiler/test/codegen/model_test.dart',
  'pkg/compiler/test/deferred_loading/deferred_loading_test.dart',
  'pkg/compiler/test/field_analysis/jfield_analysis_test.dart',
  'pkg/compiler/test/field_analysis/kfield_analysis_test.dart',
  'pkg/compiler/test/impact/impact_test.dart',
  'pkg/compiler/test/inference/callers_test.dart',
  'pkg/compiler/test/inference/inference_test_helper.dart',
  'pkg/compiler/test/inference/inference_data_test.dart',
  'pkg/compiler/test/inference/side_effects_test.dart',
  'pkg/compiler/test/inlining/inlining_test.dart',
  'pkg/compiler/test/jumps/jump_test.dart',
  'pkg/compiler/test/member_usage/member_usage_test.dart',
  'pkg/compiler/test/optimization/optimization_test.dart',
  'pkg/compiler/test/rti/rti_need_test_helper.dart',
  'pkg/compiler/test/rti/rti_emission_test_helper.dart',
  'pkg/compiler/test/static_type/static_type_test.dart',
  'pkg/compiler/test/static_type/type_promotion_test.dart',
  'pkg/compiler/test/equivalence/id_testing_test.dart',
];

main() async {
  await id.updateAllTests(idTests);
}
