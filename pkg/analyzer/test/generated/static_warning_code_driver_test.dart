// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';
import 'static_warning_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetElementTypeNotAssignableTest);
    defineReflectiveTests(StaticWarningCodeTest_Driver);
  });
}

@reflectiveTest
class SetElementTypeNotAssignableTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.set_literals];

  @override
  bool get enableNewAnalysisDriver => true;

  test_setElementTypeNotAssignable() async {
    Source source = addSource("var v = <String>{42};");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
}

@reflectiveTest
class StaticWarningCodeTest_Driver extends StaticWarningCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
