// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_errors.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetErrorsBeforeTest);
    defineReflectiveTests(GetErrorsBeforeTest_Driver);
  });
}

class AbstractGetErrorsBeforeTest extends AnalysisDomainGetErrorsTest {
  AbstractGetErrorsBeforeTest() : super(false);
}

@reflectiveTest
class GetErrorsBeforeTest extends AbstractGetErrorsBeforeTest {}

@reflectiveTest
class GetErrorsBeforeTest_Driver extends AbstractGetErrorsBeforeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
