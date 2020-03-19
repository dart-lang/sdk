// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'arglist_parameter_relevance_test.dart' as arglist_parameters;
import 'bool_assignment_relevance_test.dart' as bool_assignments;
import 'deprecated_member_relevance_test.dart' as deprecated_members;
import 'static_member_relevance_test.dart' as static_member_relevance;

void main() {
  defineReflectiveSuite(() {
    arglist_parameters.main();
    bool_assignments.main();
    deprecated_members.main();
    static_member_relevance.main();
  });
}
