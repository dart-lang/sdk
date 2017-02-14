// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictModeTest_Driver);
    defineReflectiveTests(TypePropagationTest_Driver);
  });
}

@reflectiveTest
class StrictModeTest_Driver extends StrictModeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}

@reflectiveTest
class TypePropagationTest_Driver extends TypePropagationTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
