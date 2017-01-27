// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_type_warning_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeWarningCodeTest_Driver);
    defineReflectiveTests(StrongModeStaticTypeWarningCodeTest_Driver);
  });
}

@reflectiveTest
class StaticTypeWarningCodeTest_Driver extends StaticTypeWarningCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest_Driver
    extends StrongModeStaticTypeWarningCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
