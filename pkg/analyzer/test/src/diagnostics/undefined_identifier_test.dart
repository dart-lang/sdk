// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedIdentifierTest);
    defineReflectiveTests(UndefinedIdentifierWithControlFlowCollectionsTest);
  });
}

@reflectiveTest
class UndefinedIdentifierTest extends DriverResolutionTest {
  test_forStatement_inBody() async {
    await assertNoErrorsInCode('''
f() {
  for (int x in []) {
    x;
  }
}
''');
  }

  test_forStatement_outsideBody() async {
    await assertErrorCodesInCode('''
f() {
  for (int x in []) {}
  x;
}
''', [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
}

@reflectiveTest
class UndefinedIdentifierWithControlFlowCollectionsTest
    extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.control_flow_collections];

  test_forElement_inList_insideElement() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return [for(int x in []) x, null];
}
''');
  }

  test_forElement_inList_outsideElement() async {
    await assertErrorCodesInCode('''
f() {
  return [for (int x in []) null, x];
}
''', [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
}
