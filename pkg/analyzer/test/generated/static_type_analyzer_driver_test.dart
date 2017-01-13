// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_type_analyzer_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeAnalyzer2Test_Driver);
  });
}

@reflectiveTest
class StaticTypeAnalyzer2Test_Driver extends StaticTypeAnalyzer2Test {
  @override
  bool get enableNewAnalysisDriver => true;
}
