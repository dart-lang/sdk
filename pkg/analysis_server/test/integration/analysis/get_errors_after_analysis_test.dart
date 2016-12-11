// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_errors.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetErrorsAfterTest);
    defineReflectiveTests(GetErrorsAfterTest_Driver);
  });
}

class AbstractGetErrorsAfterTest extends AnalysisDomainGetErrorsTest {
  AbstractGetErrorsAfterTest() : super(true);
}

@reflectiveTest
class GetErrorsAfterTest extends AbstractGetErrorsAfterTest {}

@reflectiveTest
class GetErrorsAfterTest_Driver extends AbstractGetErrorsAfterTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
