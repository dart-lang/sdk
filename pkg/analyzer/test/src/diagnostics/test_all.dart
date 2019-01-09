// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'argument_type_not_assignable_test.dart' as argument_type_not_assignable;
import 'can_be_null_after_null_aware_test.dart' as can_be_null_after_null_aware;
import 'deprecated_member_use_test.dart' as deprecated_member_use;
import 'division_optimization_test.dart' as division_optimization;
import 'invalid_required_param_test.dart' as invalid_required_param;

main() {
  defineReflectiveSuite(() {
    argument_type_not_assignable.main();
    can_be_null_after_null_aware.main();
    deprecated_member_use.main();
    division_optimization.main();
    invalid_required_param.main();
  }, name: 'diagnostics');
}
