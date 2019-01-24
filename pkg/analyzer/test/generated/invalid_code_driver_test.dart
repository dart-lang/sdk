// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'invalid_code.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCodeTest_Driver);
  });
}

@reflectiveTest
class InvalidCodeTest_Driver extends InvalidCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
