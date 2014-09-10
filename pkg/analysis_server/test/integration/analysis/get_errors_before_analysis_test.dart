// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.get.errors.before.analysis;

import '../../reflective_tests.dart';

import 'get_errors.dart';

@ReflectiveTestCase()
class Test extends AnalysisDomainGetErrorsTest {
  Test() : super(false);
}

main() {
  runReflectiveTests(Test);
}
