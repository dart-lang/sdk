// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.get.errors.after.analysis;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_errors.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Test);
  });
}

@reflectiveTest
class Test extends AnalysisDomainGetErrorsTest {
  Test() : super(true);
}
