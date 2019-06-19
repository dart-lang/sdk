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

  test_deadBlock_conditionalElse() async {
    await assertErrorsInCode(r'''
f() {
  true ? 1 : 2;
}''', [
      error(HintCode.DEAD_CODE, 19, 1),
    ]);
  }

  test_deadBlock_conditionalElse_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}''');
  }

  test_deadBlock_conditionalElse_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  true ? true : false && false;
}''', [
      error(HintCode.DEAD_CODE, 22, 14),
    ]);
  }

  test_deadBlock_conditionalIf() async {
    await assertErrorsInCode(r'''
f() {
  false ? 1 : 2;
}''', [
      error(HintCode.DEAD_CODE, 16, 1),
    ]);
  }

  test_deadBlock_conditionalIf_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}''');
  }

  test_deadBlock_conditionalIf_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  false ? false && false : true;
}''', [
      error(HintCode.DEAD_CODE, 16, 14),
    ]);
  }

  test_deadBlock_else() async {
    await assertErrorsInCode(r'''
f() {
  if(true) {} else {}
}''', [
      error(HintCode.DEAD_CODE, 25, 2),
    ]);
  }

  test_deadBlock_else_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}''');
  }

  test_deadBlock_else_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  if(true) {} else {if (false) {}}
}''', [
      error(HintCode.DEAD_CODE, 25, 15),
    ]);
  }

  test_deadBlock_if() async {
    await assertErrorsInCode(r'''
f() {
  if(false) {}
}''', [
      error(HintCode.DEAD_CODE, 18, 2),
    ]);
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

  test_deadBlock_if_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  if(false) {if(false) {}}
}''', [
      error(HintCode.DEAD_CODE, 18, 14),
    ]);
  }

  test_deadBlock_while() async {
    await assertErrorsInCode(r'''
f() {
  while(false) {}
}''', [
      error(HintCode.DEAD_CODE, 21, 2),
    ]);
  }

  test_deadBlock_while_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}''');
  }

  test_deadBlock_while_nested() async {
    // Test that a dead while body can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  while(false) {if(false) {}}
}''', [
      error(HintCode.DEAD_CODE, 21, 14),
    ]);
  }

  test_deadCatch_catchFollowingCatch() async {
    await assertErrorsInCode(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
}''', [
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 39, 12),
    ]);
  }

  test_deadCatch_catchFollowingCatch_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
}''', [
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 39, 24),
    ]);
  }

  test_deadCatch_catchFollowingCatch_object() async {
    await assertErrorsInCode(r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 32, 1),
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 38, 12),
    ]);
  }

  test_deadCatch_catchFollowingCatch_object_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 32, 1),
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 38, 24),
    ]);
  }

  test_deadCatch_onCatchSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(HintCode.DEAD_CODE_ON_CATCH_SUBTYPE, 65, 17),
      error(HintCode.UNUSED_CATCH_CLAUSE, 77, 1),
    ]);
  }

  test_deadCatch_onCatchSubtype_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(HintCode.DEAD_CODE_ON_CATCH_SUBTYPE, 65, 29),
      error(HintCode.UNUSED_CATCH_CLAUSE, 77, 1),
    ]);
  }

  test_deadCatch_onCatchSupertype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
}''');
  }

  test_deadFinalBreakInCase() async {
    await assertNoErrorsInCode(r'''
f() {
  switch (true) {
  case true:
    try {
      print(1);
    } finally {
      return;
    }
    break;
  default:
    break;
  }
}''');
  }

  test_deadFinalReturnInCase() async {
    await assertErrorsInCode(r'''
f() {
  switch (true) {
  case true:
    try {
      print(1);
    } finally {
      return;
    }
    return;
  default:
    break;
  }
}''', [
      error(HintCode.DEAD_CODE, 103, 7),
    ]);
  }

  test_deadFinalStatementInCase() async {
    await assertErrorsInCode(r'''
f() {
  switch (true) {
  case true:
    try {
      print(1);
    } finally {
      return;
    }
    throw 'msg';
  default:
    break;
  }
}''', [
      error(HintCode.DEAD_CODE, 103, 12),
    ]);
  }

  test_deadOperandLHS_and() async {
    await assertErrorsInCode(r'''
f() {
  bool b = false && false;
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 26, 5),
    ]);
  }

  test_deadOperandLHS_and_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
  print(b);
}''');
  }

  test_deadOperandLHS_and_nested() async {
    await assertErrorsInCode(r'''
f() {
  bool b = false && (false && false);
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 26, 16),
    ]);
  }

  test_deadOperandLHS_or() async {
    await assertErrorsInCode(r'''
f() {
  bool b = true || true;
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 25, 4),
    ]);
  }

  test_deadOperandLHS_or_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
}''');
  }

  test_deadOperandLHS_or_nested() async {
    await assertErrorsInCode(r'''
f() {
  bool b = true || (false && false);
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 25, 16),
    ]);
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
  print(1);
  a();
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 104, 9),
    ]);
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
  print(1);
  new C().a;
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 129, 9),
    ]);
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
  print(1);
  new C().a();
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 132, 9),
    ]);
  }

  test_statementAfterBreak_inDefaultCase() async {
    await assertErrorsInCode(r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 65, 9),
    ]);
  }

  test_statementAfterBreak_inForEachStatement() async {
    await assertErrorsInCode(r'''
f() {
  var list;
  for(var l in list) {
    break;
    print(l);
  }
}''', [
      error(HintCode.DEAD_CODE, 56, 9),
    ]);
  }

  test_statementAfterBreak_inForStatement() async {
    await assertErrorsInCode(r'''
f() {
  for(;;) {
    break;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 33, 9),
    ]);
  }

  test_statementAfterBreak_inSwitchCase() async {
    await assertErrorsInCode(r'''
f(v) {
  switch(v) {
    case 1:
      break;
      print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 52, 9),
    ]);
  }

  test_statementAfterBreak_inWhileStatement() async {
    await assertErrorsInCode(r'''
f(v) {
  while(v) {
    break;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 35, 9),
    ]);
  }

  test_statementAfterContinue_inForEachStatement() async {
    await assertErrorsInCode(r'''
f() {
  var list;
  for(var l in list) {
    continue;
    print(l);
  }
}''', [
      error(HintCode.DEAD_CODE, 59, 9),
    ]);
  }

  test_statementAfterContinue_inForStatement() async {
    await assertErrorsInCode(r'''
f() {
  for(;;) {
    continue;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 36, 9),
    ]);
  }

  test_statementAfterContinue_inWhileStatement() async {
    await assertErrorsInCode(r'''
f(v) {
  while(v) {
    continue;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 38, 9),
    ]);
  }

  test_statementAfterExitingIf_returns() async {
    await assertErrorsInCode(r'''
f() {
  if (1 > 2) {
    return;
  } else {
    return;
  }
  print(1);
}''', [
      error(HintCode.DEAD_CODE, 62, 9),
    ]);
  }

  test_statementAfterIfWithoutElse() async {
    await assertNoErrorsInCode(r'''
f() {
  if (1 < 0) {
    return;
  }
  print(1);
}''');
  }

  test_statementAfterRethrow() async {
    await assertErrorsInCode(r'''
f() {
  try {
    print(1);
  } catch (e) {
    rethrow;
    print(2);
  }
}''', [
      error(HintCode.DEAD_CODE, 61, 9),
    ]);
  }

  test_statementAfterReturn_function() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  return;
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 30, 9),
    ]);
  }

  test_statementAfterReturn_ifStatement() async {
    await assertErrorsInCode(r'''
f(bool b) {
  if(b) {
    print(1);
    return;
    print(2);
  }
}''', [
      error(HintCode.DEAD_CODE, 52, 9),
    ]);
  }

  test_statementAfterReturn_method() async {
    await assertErrorsInCode(r'''
class A {
  m() {
    print(1);
    return;
    print(2);
  }
}''', [
      error(HintCode.DEAD_CODE, 48, 9),
    ]);
  }

  test_statementAfterReturn_nested() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  return;
  if(false) {}
}''', [
      error(HintCode.DEAD_CODE, 30, 12),
    ]);
  }

  test_statementAfterReturn_twoReturns() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  return;
  print(2);
  return;
  print(3);
}''', [
      error(HintCode.DEAD_CODE, 30, 31),
    ]);
  }

  test_statementAfterThrow() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  throw 'Stop here';
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 41, 9),
    ]);
  }
}

@reflectiveTest
class UncheckedUseOfNullableValueTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_nullCoalesce_dynamic() async {
    await assertNoErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  dynamic x;
  x ?? 1;
}
''');
  }

  test_nullCoalesce_nonNullable() async {
    await assertErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m(int x) {
  x ?? 1;
}
''', [
      error(HintCode.DEAD_CODE, 65, 1),
    ]);
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

  test_nullCoalesce_nullType() async {
    await assertNoErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  Null x;
  x ?? 1;
}
''');
  }

  test_nullCoalesceAssign_dynamic() async {
    await assertNoErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  dynamic x;
  x ??= 1;
}
''');
  }

  test_nullCoalesceAssign_nonNullable() async {
    await assertErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m(int x) {
  x ??= 1;
}
''', [
      error(HintCode.DEAD_CODE, 66, 1),
    ]);
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
