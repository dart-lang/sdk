// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetVersionTest);
    defineReflectiveTests(GetVersionTest_Driver);
  });
}

class AbstractGetVersionTest extends AbstractAnalysisServerIntegrationTest {
  test_getVersion() {
    return sendServerGetVersion();
  }
}

@reflectiveTest
class GetVersionTest extends AbstractGetVersionTest {}

@reflectiveTest
class GetVersionTest_Driver extends AbstractGetVersionTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
