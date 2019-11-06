// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_test.dart' as element;
import 'function_type_test.dart' as function_type;
import 'inheritance_manager3_test.dart' as inheritance_manager3;
import 'least_upper_bound_helper_test.dart' as least_upper_bound_helper;
import 'subtype_test.dart' as subtype;
import 'type_algebra_test.dart' as type_algebra;
import 'type_parameter_element_test.dart' as type_parameter_element;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    element.main();
    function_type.main();
    inheritance_manager3.main();
    least_upper_bound_helper.main();
    subtype.main();
    type_algebra.main();
    type_parameter_element.main();
  }, name: 'element');
}
