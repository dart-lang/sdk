// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_target_test.dart' as completion_target_test;
import 'optype_test.dart' as optype_test;

main() {
  defineReflectiveSuite(() {
    completion_target_test.main();
    optype_test.main();
  }, name: 'completion');
}
