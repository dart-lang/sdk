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
    defineReflectiveTests(UndefinedGetterTest);
    defineReflectiveTests(UndefinedGetterWithControlFlowCollectionsTest);
  });
}

@reflectiveTest
class UndefinedGetterTest extends DriverResolutionTest {
  test_ifStatement_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  if (x is String) {
    x.length;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  test_ifStatement_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  if (x is String) {
    x.length;
  }
}
''');
  }

  test_promotedTypeParameter_regress35305() async {
    await assertErrorsInCode(r'''
void f<X extends num, Y extends X>(Y y) {
  if (y is int) {
    y.isEven;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }
}

@reflectiveTest
class UndefinedGetterWithControlFlowCollectionsTest
    extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.control_flow_collections];

  test_ifElement_inList_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return [if (x is String) x.length];
}
''', [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  test_ifElement_inList_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return [if (x is String) x.length];
}
''');
  }

  test_ifElement_inMap_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return {if (x is String) x : x.length};
}
''', [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  test_ifElement_inMap_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x : x.length};
}
''');
  }

  test_ifElement_inSet_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return {if (x is String) x.length};
}
''', [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  test_ifElement_inSet_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x.length};
}
''');
  }
}
