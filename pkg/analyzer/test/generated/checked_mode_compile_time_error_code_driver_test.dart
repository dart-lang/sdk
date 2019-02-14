// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'checked_mode_compile_time_error_code_test.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckedModeCompileTimeErrorCodeTest_Driver);
    defineReflectiveTests(SetElementTypeNotAssignableTest);
  });
}

@reflectiveTest
class CheckedModeCompileTimeErrorCodeTest_Driver
    extends CheckedModeCompileTimeErrorCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}

@reflectiveTest
class SetElementTypeNotAssignableTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.set_literals];

  @override
  bool get enableNewAnalysisDriver => true;

  test_simple() async {
    Source source = addSource("var v = const <String>{42};");
    await computeAnalysisResult(source);
    // TODO(brianwilkerson) Fix this so that only one error is produced.
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }
}
