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
    defineReflectiveTests(NonConstantMapElementWithUiAsCodeAndConstantTest);
    defineReflectiveTests(NonConstantMapElementWithUiAsCodeTest);
    defineReflectiveTests(NonConstantMapKeyTest);
    defineReflectiveTests(NonConstantMapKeyWithUiAsCodeTest);
    defineReflectiveTests(NonConstantMapValueTest);
    defineReflectiveTests(NonConstantMapValueWithUiAsCodeTest);
  });
}

@reflectiveTest
class NonConstantMapElementWithUiAsCodeAndConstantTest
    extends NonConstantMapElementWithUiAsCodeTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
      EnableString.constant_update_2018
    ];
}

@reflectiveTest
class NonConstantMapElementWithUiAsCodeTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_forElement_cannotBeConst() async {
    await assertErrorCodesInCode('''
void main() {
  const {1: null, for (final x in const []) null: null};
}
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_forElement_nested_cannotBeConst() async {
    await assertErrorCodesInCode('''
void main() {
  const {1: null, if (true) for (final x in const []) null: null};
}
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_forElement_notConst_noError() async {
    await assertNoErrorsInCode('''
void main() {
  var x;
  print({x: x, for (final x2 in [x]) x2: x2});
}
''');
  }

  test_ifElement_mayBeConst() async {
    await assertErrorCodesInCode(
        '''
void main() {
  const {1: null, if (true) null: null};
}
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_ifElement_nested_mayBeConst() async {
    await assertErrorCodesInCode(
        '''
void main() {
  const {1: null, if (true) if (true) null: null};
}
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_ifElement_notConstCondition() async {
    await assertErrorCodesInCode('''
void main() {
  bool notConst = true;
  const {1: null, if (notConst) null: null};
}
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_ifElementWithElse_mayBeConst() async {
    await assertErrorCodesInCode(
        '''
void main() {
  const isTrue = true;
  const {1: null, if (isTrue) null: null else null: null};
}
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_spreadElement_mayBeConst() async {
    await assertErrorCodesInCode(
        '''
void main() {
  const {1: null, ...{null: null}};
}
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_spreadElement_notConst() async {
    await assertErrorCodesInCode('''
void main() {
  var notConst = {};
  const {1: null, ...notConst};
}
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }
}

@reflectiveTest
class NonConstantMapKeyTest extends DriverResolutionTest {
  test_const_topVar() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const <int, int>{a: 0};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = <int, int>{a: 0};
''');
  }
}

@reflectiveTest
class NonConstantMapKeyWithUiAsCodeTest extends NonConstantMapKeyTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: 0 else a: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0 else 0: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: 0 else a: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0 else 0: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }
}

@reflectiveTest
class NonConstantMapValueTest extends DriverResolutionTest {
  test_const_topVar() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const <int, int>{0: a};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = <int, int>{0: a};
''');
  }
}

@reflectiveTest
class NonConstantMapValueWithUiAsCodeTest extends NonConstantMapValueTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: 0 else 0: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a else 0: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: 0 else 0: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a else 0: 0};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorCodesInCode(
        '''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }
}
