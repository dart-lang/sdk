// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadCodeTest);
    defineReflectiveTests(UncheckedUseOfNullableValueTest);
  });
}

@reflectiveTest
class DeadCodeTest extends DriverResolutionTest with PackageMixin {
  test_deadBlock_conditionalElse() async {
    await assertErrorsInCode(r'''
f() {
  true ? 1 : 2;
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_conditionalElse_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  true ? true : false && false;
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_conditionalIf() async {
    await assertErrorsInCode(r'''
f() {
  false ? 1 : 2;
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_conditionalIf_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  false ? false && false : true;
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_conditionalElse_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}''');
  }

  test_deadBlock_conditionalIf_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}''');
  }

  test_deadBlock_else() async {
    await assertErrorsInCode(r'''
f() {
  if(true) {} else {}
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_else_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}''');
  }

  test_deadBlock_if_debugConst_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  static const bool DEBUG = false;
}
f() {
  if(A.DEBUG) {}
}''');
  }

  test_deadBlock_if_debugConst_prefixedIdentifier2() async {
    newFile('/test/lib/lib2.dart', content: r'''
library lib2;
class A {
  static const bool DEBUG = false;
}''');
    await assertNoErrorsInCode(r'''
library L;
import 'lib2.dart';
f() {
  if(A.DEBUG) {}
}''');
  }

  test_deadBlock_if_debugConst_propertyAccessor() async {
    newFile('/test/lib/lib2.dart', content: r'''
library lib2;
class A {
  static const bool DEBUG = false;
}''');
    await assertNoErrorsInCode(r'''
library L;
import 'lib2.dart' as LIB;
f() {
  if(LIB.A.DEBUG) {}
}''');
  }

  test_deadBlock_if_debugConst_simpleIdentifier() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  if(DEBUG) {}
}''');
  }

  test_deadBlock_else_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  if(true) {} else {if (false) {}}
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_if() async {
    await assertErrorsInCode(r'''
f() {
  if(false) {}
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_if_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  if(false) {if(false) {}}
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_while() async {
    await assertErrorsInCode(r'''
f() {
  while(false) {}
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_while_nested() async {
    // Test that a dead while body can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  while(false) {if(false) {}}
}''', [HintCode.DEAD_CODE]);
  }

  test_deadBlock_while_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}''');
  }

  test_deadCatch_catchFollowingCatch() async {
    await assertErrorsInCode(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
}''', [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
  }

  test_deadCatch_catchFollowingCatch_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
}''', [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
  }

  test_deadCatch_catchFollowingCatch_object() async {
    await assertErrorsInCode(r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
}''', [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
  }

  test_deadCatch_catchFollowingCatch_object_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}''', [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
  }

  test_deadCatch_onCatchSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
}''', [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
  }

  test_deadCatch_onCatchSubtype_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
}''', [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
  }

  test_deadCatch_onCatchSupertype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
}''');
  }

  test_afterTryCatch() async {
    await assertNoErrorsInCode(r'''
main() {
  try {
    return f();
  } catch (e) {
    print(e);
  }
  print('not dead');
}
f() {
  throw 'foo';
}
''');
  }

  test_deadFinalReturnInCase() async {
    await assertErrorsInCode(r'''
f() {
  switch (true) {
  case true:
    try {
      int a = 1;
    } finally {
      return;
    }
    return;
  default:
    break;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_deadFinalStatementInCase() async {
    await assertErrorsInCode(r'''
f() {
  switch (true) {
  case true:
    try {
      int a = 1;
    } finally {
      return;
    }
    throw 'msg';
  default:
    break;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_deadFinalBreakInCase() async {
    await assertNoErrorsInCode(r'''
f() {
  switch (true) {
  case true:
    try {
      int a = 1;
    } finally {
      return;
    }
    break;
  default:
    break;
  }
}''');
  }

  test_deadOperandLHS_and() async {
    await assertErrorsInCode(r'''
f() {
  bool b = false && false;
}''', [HintCode.DEAD_CODE]);
  }

  test_deadOperandLHS_and_nested() async {
    await assertErrorsInCode(r'''
f() {
  bool b = false && (false && false);
}''', [HintCode.DEAD_CODE]);
  }

  test_deadOperandLHS_or() async {
    await assertErrorsInCode(r'''
f() {
  bool b = true || true;
}''', [HintCode.DEAD_CODE]);
  }

  test_deadOperandLHS_or_nested() async {
    await assertErrorsInCode(r'''
f() {
  bool b = true || (false && false);
}''', [HintCode.DEAD_CODE]);
  }

  test_deadOperandLHS_and_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
}''');
  }

  test_deadOperandLHS_or_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
}''');
  }

  test_statementAfterAlwaysThrowsFunction() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@alwaysThrows
void a() {
  throw 'msg';
}

f() {
  var one = 1;
  a();
  var two = 2;
}''', [HintCode.DEAD_CODE]);
  }

  @failingTest
  test_statementAfterAlwaysThrowsGetter() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
  int get a {
    throw 'msg';
  }

f() {
  var one = 1;
  new C().a;
  var two = 2;
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterAlwaysThrowsMethod() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
  void a() {
    throw 'msg';
  }
}

f() {
  var one = 1;
  new C().a();
  var two = 2;
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterBreak_inDefaultCase() async {
    await assertErrorsInCode(r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterBreak_inForEachStatement() async {
    await assertErrorsInCode(r'''
f() {
  var list;
  for(var l in list) {
    break;
    var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterBreak_inForStatement() async {
    await assertErrorsInCode(r'''
f() {
  for(;;) {
    break;
    var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterBreak_inSwitchCase() async {
    await assertErrorsInCode(r'''
f(v) {
  switch(v) {
    case 1:
      break;
      var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterBreak_inWhileStatement() async {
    await assertErrorsInCode(r'''
f(v) {
  while(v) {
    break;
    var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterContinue_inForEachStatement() async {
    await assertErrorsInCode(r'''
f() {
  var list;
  for(var l in list) {
    continue;
    var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterContinue_inForStatement() async {
    await assertErrorsInCode(r'''
f() {
  for(;;) {
    continue;
    var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterContinue_inWhileStatement() async {
    await assertErrorsInCode(r'''
f(v) {
  while(v) {
    continue;
    var a;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterExitingIf_returns() async {
    await assertErrorsInCode(r'''
f() {
  if (1 > 2) {
    return;
  } else {
    return;
  }
  var one = 1;
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterIfWithoutElse() async {
    await assertNoErrorsInCode(r'''
f() {
  if (1 < 0) {
    return;
  }
  int a = 1;
}''');
  }

  test_statementAfterRethrow() async {
    await assertErrorsInCode(r'''
f() {
  try {
    var one = 1;
  } catch (e) {
    rethrow;
    var two = 2;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterReturn_function() async {
    await assertErrorsInCode(r'''
f() {
  var one = 1;
  return;
  var two = 2;
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterReturn_ifStatement() async {
    await assertErrorsInCode(r'''
f(bool b) {
  if(b) {
    var one = 1;
    return;
    var two = 2;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterReturn_method() async {
    await assertErrorsInCode(r'''
class A {
  m() {
    var one = 1;
    return;
    var two = 2;
  }
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterReturn_nested() async {
    await assertErrorsInCode(r'''
f() {
  var one = 1;
  return;
  if(false) {}
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterReturn_twoReturns() async {
    await assertErrorsInCode(r'''
f() {
  var one = 1;
  return;
  var two = 2;
  return;
  var three = 3;
}''', [HintCode.DEAD_CODE]);
  }

  test_statementAfterThrow() async {
    await assertErrorsInCode(r'''
f() {
  var one = 1;
  throw 'Stop here';
  var two = 2;
}''', [HintCode.DEAD_CODE]);
  }

  test_afterForEachWithBreakLabel() async {
    await assertNoErrorsInCode(r'''
f() {
  named: {
    for (var x in [1]) {
      if (x == null)
        break named;
    }
    return;
  }
  print('not dead');
}
''');
  }

  test_afterForWithBreakLabel() async {
    await assertNoErrorsInCode(r'''
f() {
  named: {
    for (int i = 0; i < 7; i++) {
      if (i == null)
        break named;
    }
    return;
  }
  print('not dead');
}
''');
  }
}

@reflectiveTest
class UncheckedUseOfNullableValueTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_nullCoalesce_nonNullable() async {
    await assertErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int x;
  x ?? 1;
}
''', [HintCode.DEAD_CODE]);
  }

  test_nullCoalesce_nullable() async {
    await assertNoErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int? x;
  x ?? 1;
}
''');
  }

  test_nullCoalesceAssign_nonNullable() async {
    await assertErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int x;
  x ??= 1;
}
''', [HintCode.DEAD_CODE]);
  }

  test_nullCoalesceAssign_nullable() async {
    await assertNoErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int? x;
  x ??= 1;
}
''');
  }
}
