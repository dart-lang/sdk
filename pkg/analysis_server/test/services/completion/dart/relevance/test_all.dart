// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bool_assignment_relevance_test.dart' as bool_assignment;
import 'deprecated_member_relevance_test.dart' as deprecated_member;

main() {
  defineReflectiveSuite(() {
    bool_assignment.main();
    deprecated_member.main();
  });
}
