// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapKeyTypeNotAssignableTest);
    defineReflectiveTests(MapKeyTypeNotAssignableWithUIAsCodeTest);
  });
}

@reflectiveTest
class MapKeyTypeNotAssignableTest extends DriverResolutionTest {
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/35569')
  test_explicitTypeArgs_const() async {
    // TODO(brianwilkerson) Fix this so that only one error is produced.
    await assertErrorsInCode('''
var v = const <String, int>{42 : 1};
''', [
      CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE
    ]);
  }

  test_explicitTypeArgs_notConst() async {
    await assertErrorsInCode('''
var v = <String, int>{42 : 1};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }
}

@reflectiveTest
class MapKeyTypeNotAssignableWithUIAsCodeTest
    extends MapKeyTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = ['control-flow-collections', 'spread-collections'];

  @failingTest
  @override
  test_explicitTypeArgs_const() async {
    await super.test_explicitTypeArgs_const();
  }

  test_spread_valid_const() async {
    await assertNoErrorsInCode('''
var v = const <String, int>{...{'a' : 1, 'b' : 2}};
''');
  }

  test_spread_valid_nonConst() async {
    await assertNoErrorsInCode('''
var v = <String, int>{...{'a' : 1, 'b' : 2}};
''');
  }
}
