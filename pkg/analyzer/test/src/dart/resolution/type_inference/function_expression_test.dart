// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionTest);
    defineReflectiveTests(FunctionExpressionWithNnbdTest);
  });
}

@reflectiveTest
class FunctionExpressionTest extends DriverResolutionTest {
  test_returnType_blockBody_notNullable() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return 0;
  return 1.2;
};
''');
    var element = findNode.functionExpression('(bool').declaredElement;
    assertType(element.returnType, 'num');
  }

  test_returnType_blockBody_notNullable_switch_onEnum() async {
    await assertErrorsInCode('''
enum E { a, b }

main() {
  (E e) {
    switch (e) {
      case E.a:
        return 0;
      case E.b:
        return 1;
    }
  };
}
''', [
      error(HintCode.MISSING_RETURN, 28, 102),
    ]);
    var element = findNode.functionExpression('(E e)').declaredElement;
    assertType(element.returnType, 'int');
  }

  test_returnType_blockBody_notNullable_switch_onEnum_imported() async {
    newFile('/test/lib/a.dart', content: r'''
enum E { a, b }
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  (p.E e) {
    switch (e) {
      case p.E.a:
        return 0;
      case p.E.b:
        return 1;
    }
  };
}
''', [
      error(HintCode.MISSING_RETURN, 34, 108),
    ]);
    var element = findNode.functionExpression('(p.E e)').declaredElement;
    assertType(element.returnType, 'int');
  }

  test_returnType_blockBody_null_hasReturn() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return;
};
''');
    var element = findNode.functionExpression('(bool').declaredElement;
    assertType(element.returnType, 'Null');
  }

  test_returnType_blockBody_null_noReturn() async {
    await resolveTestCode('''
var v = () {};
''');
    var element = findNode.functionExpression('() {}').declaredElement;
    assertType(element.returnType, 'Null');
  }

  test_returnType_blockBody_nullable() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return 0;
};
''');
    var element = findNode.functionExpression('(bool').declaredElement;
    if (typeToStringWithNullability) {
      assertType(element.returnType, 'int?');
    } else {
      assertType(element.returnType, 'int');
    }
  }

  test_returnType_blockBody_nullable_switch() async {
    await assertErrorsInCode('''
main() {
  (int a) {
    switch (a) {
      case 0:
        return 0;
    }
  };
}
''', [
      error(HintCode.MISSING_RETURN, 11, 68),
    ]);
    var element = findNode.functionExpression('(int a)').declaredElement;
    if (typeToStringWithNullability) {
      assertType(element.returnType, 'int?');
    } else {
      assertType(element.returnType, 'int');
    }
  }

  test_returnType_expressionBody_Never() async {
    await resolveTestCode('''
var v = () => throw 42;
''');
    var element = findNode.functionExpression('() =>').declaredElement;
    if (typeToStringWithNullability) {
      assertType(element.returnType, 'Never');
    } else {
      assertType(element.returnType, 'Null');
    }
  }

  test_returnType_expressionBody_notNullable() async {
    await resolveTestCode('''
var v = () => 42;
''');
    var element = findNode.functionExpression('() =>').declaredElement;
    assertType(element.returnType, 'int');
  }

  test_returnType_expressionBody_Null() async {
    await resolveTestCode('''
var v = () => null;
''');
    var element = findNode.functionExpression('() =>').declaredElement;
    assertType(element.returnType, 'Null');
  }
}

@reflectiveTest
class FunctionExpressionWithNnbdTest extends FunctionExpressionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;
}
