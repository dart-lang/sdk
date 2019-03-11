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
    defineReflectiveTests(NonConstantMapElementWithUiAsCodeTest);
  });
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
    await assertErrorsInCode('''
void main() {
  const {1: null, for (final x in const []) null: null};
}
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_forElement_nested_cannotBeConst() async {
    await assertErrorsInCode('''
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
    await assertNoErrorsInCode('''
void main() {
  const {1: null, if (true) null: null};
}
''');
  }

  test_ifElement_nested_mayBeConst() async {
    await assertNoErrorsInCode('''
void main() {
  const {1: null, if (true) if (true) null: null};
}
''');
  }

  test_ifElement_notConstCondition() async {
    await assertErrorsInCode('''
void main() {
  bool notConst = true;
  const {1: null, if (notConst) null: null};
}
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_ifElementWithElse_mayBeConst() async {
    await assertNoErrorsInCode('''
void main() {
  const isTrue = true;
  const {1: null, if (isTrue) null: null else null: null};
}
''');
  }

  test_spreadElement_mayBeConst() async {
    await assertNoErrorsInCode('''
void main() {
  const {1: null, ...{null: null}};
}
''');
  }

  test_spreadElement_notConst() async {
    await assertErrorsInCode('''
void main() {
  var notConst = {};
  const {1: null, ...notConst};
}
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }
}
