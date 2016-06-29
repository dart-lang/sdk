// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.hint_code_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'analysis_context_factory.dart';
import 'resolver_test_case.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(HintCodeTest);
}

@reflectiveTest
class HintCodeTest extends ResolverTestCase {
  void fail_isInt() {
    Source source = addSource("var v = 1 is int;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.IS_INT]);
    verify([source]);
  }

  void fail_isNotInt() {
    Source source = addSource("var v = 1 is! int;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.IS_NOT_INT]);
    verify([source]);
  }

  void fail_overrideEqualsButNotHashCode() {
    Source source = addSource(r'''
class A {
  bool operator ==(x) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE]);
    verify([source]);
  }

  void fail_unusedImport_as_equalPrefixes() {
    // See todo at ImportsVerifier.prefixElementMap.
    Source source = addSource(r'''
library L;
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}''');
    Source source3 = addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
class B {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  @override
  void reset() {
    analysisContext2 = AnalysisContextFactory.contextWithCoreAndPackages({
      'package:meta/meta.dart': r'''
library meta;

const _Factory factory = const _Factory();
const _Literal literal = const _Literal();
const _MustCallSuper mustCallSuper = const _MustCallSuper();
const _Override override = const _Override();
const _Protected protected = const _Protected();
const Required required = const Required();
class Required {
  final String reason;
  const Required([this.reason]);
}

class _Factory {
  const _Factory();
}
class _Literal {
  const _Literal();
}
class _MustCallSuper {
  const _MustCallSuper();
}
class _Override {
  const _Override();
}
class _Protected {
  const _Protected();
}
class _Required {
  final String reason;
  const _Required([this.reason]));
}
''',
      'package:js/js.dart': r'''
library js;
class JS {
  const JS([String js]) { }
}
'''
    });
  }

  void test_argumentTypeNotAssignable_functionType() {
    Source source = addSource(r'''
m() {
  var a = new A();
  a.n(() => 0);
}
class A {
  n(void f(int i)) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_message() {
    // The implementation of HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE assumes that
    // StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE has the same message.
    expect(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE.message,
        HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE.message);
  }

  void test_argumentTypeNotAssignable_type() {
    Source source = addSource(r'''
m() {
  var i = '';
  n(i);
}
n(int i) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_canBeNullAfterNullAware_false_methodInvocation() {
    Source source = addSource(r'''
m(x) {
  x?.a()?.b();
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_canBeNullAfterNullAware_false_propertyAccess() {
    Source source = addSource(r'''
m(x) {
  x?.a?.b;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_canBeNullAfterNullAware_methodInvocation() {
    Source source = addSource(r'''
m(x) {
  x?.a.b();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.CAN_BE_NULL_AFTER_NULL_AWARE]);
    verify([source]);
  }

  void test_canBeNullAfterNullAware_parenthesized() {
    Source source = addSource(r'''
m(x) {
  (x?.a).b;
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.CAN_BE_NULL_AFTER_NULL_AWARE]);
    verify([source]);
  }

  void test_canBeNullAfterNullAware_propertyAccess() {
    Source source = addSource(r'''
m(x) {
  x?.a.b;
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.CAN_BE_NULL_AFTER_NULL_AWARE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalElse() {
    Source source = addSource(r'''
f() {
  true ? 1 : 2;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalElse_nested() {
    // test that a dead else-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  true ? true : false && false;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalIf() {
    Source source = addSource(r'''
f() {
  false ? 1 : 2;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalIf_nested() {
    // test that a dead then-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  false ? false && false : true;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_else() {
    Source source = addSource(r'''
f() {
  if(true) {} else {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_else_nested() {
    // test that a dead else-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  if(true) {} else {if (false) {}}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_if() {
    Source source = addSource(r'''
f() {
  if(false) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_nested() {
    // test that a dead then-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  if(false) {if(false) {}}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_while() {
    Source source = addSource(r'''
f() {
  while(false) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_while_nested() {
    // test that a dead while body can't generate additional violations
    Source source = addSource(r'''
f() {
  while(false) {if(false) {}}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch() {
    Source source = addSource(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch_nested() {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch_object() {
    Source source = addSource(r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch_object_nested() {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_onCatchSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
    verify([source]);
  }

  void test_deadCode_deadCatch_onCatchSubtype_nested() {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
    verify([source]);
  }

  void test_deadCode_deadFinalReturnInCase() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadFinalStatementInCase() {
    Source source = addSource(r'''
f() {
  switch (true) {
  case true:
    try {
      int a = 1;
    } finally {
      return;
    }
    int b = 1;
  default:
    break;
  }
}''');
    computeLibrarySourceErrors(source);
    // A single dead statement at the end of a switch case that is not a
    // terminating statement will yield two errors.
    assertErrors(source,
        [HintCode.DEAD_CODE, StaticWarningCode.CASE_BLOCK_NOT_TERMINATED]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_and() {
    Source source = addSource(r'''
f() {
  bool b = false && false;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_and_nested() {
    Source source = addSource(r'''
f() {
  bool b = false && (false && false);
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_or() {
    Source source = addSource(r'''
f() {
  bool b = true || true;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_or_nested() {
    Source source = addSource(r'''
f() {
  bool b = true || (false && false);
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inDefaultCase() {
    Source source = addSource(r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inForEachStatement() {
    Source source = addSource(r'''
f() {
  var list;
  for(var l in list) {
    break;
    var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inForStatement() {
    Source source = addSource(r'''
f() {
  for(;;) {
    break;
    var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inSwitchCase() {
    Source source = addSource(r'''
f(v) {
  switch(v) {
    case 1:
      break;
      var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inWhileStatement() {
    Source source = addSource(r'''
f(v) {
  while(v) {
    break;
    var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterContinue_inForEachStatement() {
    Source source = addSource(r'''
f() {
  var list;
  for(var l in list) {
    continue;
    var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterContinue_inForStatement() {
    Source source = addSource(r'''
f() {
  for(;;) {
    continue;
    var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterContinue_inWhileStatement() {
    Source source = addSource(r'''
f(v) {
  while(v) {
    continue;
    var a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterExitingIf_returns() {
    Source source = addSource(r'''
f() {
  if (1 > 2) {
    return;
  } else {
    return;
  }
  var one = 1;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterRethrow() {
    Source source = addSource(r'''
f() {
  try {
    var one = 1;
  } catch (e) {
    rethrow;
    var two = 2;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_function() {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  var two = 2;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_ifStatement() {
    Source source = addSource(r'''
f(bool b) {
  if(b) {
    var one = 1;
    return;
    var two = 2;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_method() {
    Source source = addSource(r'''
class A {
  m() {
    var one = 1;
    return;
    var two = 2;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_nested() {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  if(false) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_twoReturns() {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  var two = 2;
  return;
  var three = 3;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterThrow() {
    Source source = addSource(r'''
f() {
  var one = 1;
  throw 'Stop here';
  var two = 2;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_assignment() {
    Source source = addSource(r'''
class A {
  @deprecated
  A operator+(A a) { return a; }
}
f(A a) {
  A b;
  a += b;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_call() {
    Source source = addSource(r'''
class A {
  @deprecated
  call() {}
  m() {
    A a = new A();
    a();
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_deprecated() {
    Source source = addSource(r'''
class A {
  @deprecated
  m() {}
  n() {m();}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_Deprecated() {
    Source source = addSource(r'''
class A {
  @Deprecated('0.9')
  m() {}
  n() {m();}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_export() {
    Source source = addSource("export 'deprecated_library.dart';");
    addNamedSource(
        "/deprecated_library.dart",
        r'''
@deprecated
library deprecated_library;
class A {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_field() {
    Source source = addSource(r'''
class A {
  @deprecated
  int x = 1;
}
f(A a) {
  return a.x;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_getter() {
    Source source = addSource(r'''
class A {
  @deprecated
  get m => 1;
}
f(A a) {
  return a.m;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_import() {
    Source source = addSource(r'''
import 'deprecated_library.dart';
f(A a) {}''');
    addNamedSource(
        "/deprecated_library.dart",
        r'''
@deprecated
library deprecated_library;
class A {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_indexExpression() {
    Source source = addSource(r'''
class A {
  @deprecated
  operator[](int i) {}
}
f(A a) {
  return a[1];
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_instanceCreation() {
    Source source = addSource(r'''
class A {
  @deprecated
  A(int i) {}
}
f() {
  A a = new A(1);
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_instanceCreation_namedConstructor() {
    Source source = addSource(r'''
class A {
  @deprecated
  A.named(int i) {}
}
f() {
  A a = new A.named(1);
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_named() {
    Source source = addSource(r'''
class A {
  m({@deprecated int x}) {}
  n() {m(x: 1);}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_operator() {
    Source source = addSource(r'''
class A {
  @deprecated
  operator+(A a) {}
}
f(A a) {
  A b;
  return a + b;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_positional() {
    Source source = addSource(r'''
class A {
  m([@deprecated int x]) {}
  n() {m(1);}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_setter() {
    Source source = addSource(r'''
class A {
  @deprecated
  set s(v) {}
}
f(A a) {
  return a.s = 1;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_superConstructor() {
    Source source = addSource(r'''
class A {
  @deprecated
  A() {}
}
class B extends A {
  B() : super() {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_superConstructor_namedConstructor() {
    Source source = addSource(r'''
class A {
  @deprecated
  A.named() {}
}
class B extends A {
  B() : super.named() {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_divisionOptimization_double() {
    Source source = addSource(r'''
f(double x, double y) {
  var v = (x / y).toInt();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_divisionOptimization_int() {
    Source source = addSource(r'''
f(int x, int y) {
  var v = (x / y).toInt();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_divisionOptimization_propagatedType() {
    // Tests the propagated type information of the '/' method
    Source source = addSource(r'''
f(x, y) {
  x = 1;
  y = 1;
  var v = (x / y).toInt();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_divisionOptimization_wrappedBinaryExpression() {
    Source source = addSource(r'''
f(int x, int y) {
  var v = (((x / y))).toInt();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_duplicateImport() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  void test_duplicateImport2() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}''');
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [HintCode.DUPLICATE_IMPORT, HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  void test_duplicateImport3() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as M show A hide B;
import 'lib1.dart' as M show A hide B;
M.A a;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
class B {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  void test_factory__expr_return_null_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() => null;
}

class State { }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_factory_abstract_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

abstract class Stateful {
  @factory
  State createState();
}

class State { }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_factory_bad_return() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  State _s = new State();

  @factory
  State createState() => _s;
}

class State { }
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.INVALID_FACTORY_METHOD_IMPL]);
    verify([source]);
  }

  void test_factory_block_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() {
    return new State();
  }
}

class State { }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_factory_block_return_null_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() {
    return null;
  }
}

class State { }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_factory_expr_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() => new State();
}

class State { }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_factory_misplaced_annotation() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

@factory
class X {
  @factory
  int x;
}

@factory
main() { }
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      HintCode.INVALID_FACTORY_ANNOTATION,
      HintCode.INVALID_FACTORY_ANNOTATION,
      HintCode.INVALID_FACTORY_ANNOTATION
    ]);
    verify([source]);
  }

  void test_factory_no_return_type_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  createState() {
    return new Stateful();
  }
}
''');
    computeLibrarySourceErrors(source);
    // Null return types will get flagged elsewhere, no need to pile-on here.
    assertNoErrors(source);
    verify([source]);
  }

  void test_factory_subclass_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

abstract class Stateful {
  @factory
  State createState();
}

class MyThing extends Stateful {
  @override
  State createState() {
    print('my state');
    return new MyState();
  }
}

class State { }
class MyState extends State { }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_factory_void_return() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  void createState() {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.INVALID_FACTORY_METHOD_DECL]);
    verify([source]);
  }

  void test_importDeferredLibraryWithLoadFunction() {
    resolveWithErrors(<String>[
      r'''
library lib1;
loadLibrary() {}
f() {}''',
      r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }'''
    ], <ErrorCode>[
      HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION
    ]);
  }

  void test_invalidAssignment_instanceVariable() {
    Source source = addSource(r'''
class A {
  int x;
}
f(var y) {
  A a;
  if(y is String) {
    a.x = y;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_localVariable() {
    Source source = addSource(r'''
f(var y) {
  if(y is String) {
    int x = y;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_message() {
    // The implementation of HintCode.INVALID_ASSIGNMENT assumes that
    // StaticTypeWarningCode.INVALID_ASSIGNMENT has the same message.
    expect(StaticTypeWarningCode.INVALID_ASSIGNMENT.message,
        HintCode.INVALID_ASSIGNMENT.message);
  }

  void test_invalidAssignment_staticVariable() {
    Source source = addSource(r'''
class A {
  static int x;
}
f(var y) {
  if(y is String) {
    A.x = y;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_variableDeclaration() {
    // 17971
    Source source = addSource(r'''
class Point {
  final num x, y;
  Point(this.x, this.y);
  Point operator +(Point other) {
    return new Point(x+other.x, y+other.y);
  }
}
main() {
  var p1 = new Point(0, 0);
  var p2 = new Point(10, 10);
  int n = p1 + p2;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_closure() {
    Source source = addNamedSource(
        '/lib1.dart',
        r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int a() => 42;
}
''');
    Source source2 = addNamedSource(
        '/lib2.dart',
        r'''
import 'lib1.dart';

void main() {
  var leak = new A().a;
  print(leak);
}
''');
    computeLibrarySourceErrors(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  void test_invalidUseOfProtectedMember_field() {
    Source source = addNamedSource(
        '/lib1.dart',
        r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
''');
    Source source2 = addNamedSource(
        '/lib2.dart',
        r'''
import 'lib1.dart';

abstract class B {
  int b() => new A().a;
}
''');
    computeLibrarySourceErrors(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  void test_invalidUseOfProtectedMember_field_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
abstract class B implements A {
  int b() => a;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_function() {
    Source source = addNamedSource(
        '/lib1.dart',
        r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource(
        '/lib2.dart',
        r'''
import 'lib1.dart';

main() {
  new A().a();
}
''');
    computeLibrarySourceErrors(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  void test_invalidUseOfProtectedMember_function_OK2() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
main() {
  new A().a();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_function_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a() => 0;
}

abstract class B implements A {
  int b() => a();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_getter() {
    Source source = addNamedSource(
        '/lib1.dart',
        r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');
    Source source2 = addNamedSource(
        '/lib2.dart',
        r'''
import 'lib1.dart';

class B {
  A a;
  int b() => a.a;
}
''');
    computeLibrarySourceErrors(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  void test_invalidUseOfProtectedMember_getter_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
abstract class B implements A {
  int b() => a;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_in_docs_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int a() => c;
  @protected
  int get b => a();
  @protected
  int c = 42;
}

/// OK: [A.a], [A.b], [A.c].
f() {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_message() {
    Source source = addNamedSource(
        '/lib1.dart',
        r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource(
        '/lib2.dart',
        r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    List<AnalysisError> errors = analysisContext2.computeErrors(source2);
    expect(errors, hasLength(1));
    expect(errors[0].message,
        "The member 'a' can only be used within instance members of subclasses of 'A'");
    verify([source, source2]);
  }

  void test_invalidUseOfProtectedMember_method_1() {
    Source source = addNamedSource(
        '/lib1.dart',
        r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource(
        '/lib2.dart',
        r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    computeLibrarySourceErrors(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  void test_invalidUseOfProtectedMember_method_OK() {
    // https://github.com/dart-lang/linter/issues/257
    Source source = addSource(r'''
import 'package:meta/meta.dart';

typedef void VoidCallback();

class State<E> {
  @protected
  void setState(VoidCallback fn) {}
}

class Button extends State<Object> {
  void handleSomething() {
    setState(() {});
  }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_1() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void b() => a();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_2() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends Object with A {
  void b() => a();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_3() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected m1() {}
}
class B extends A {
  static m2(A a) => a.m1();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_4() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void a() => a();
}
main() {
  new B().a();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_field() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a = 42;
}
class B extends A {
  int b() => a;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_getter() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
class B extends A {
  int b() => a;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_setter() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
class B extends A {
  void b(int i) {
    a = i;
  }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_OK_setter_2() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  int _a;
  @protected
  void set a(int a) { _a = a; }
  A(int a) {
    this.a = a;
  }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_setter() {
    Source source = addNamedSource(
        '/lib1.dart',
        r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
''');
    Source source2 = addNamedSource(
        '/lib2.dart',
        r'''
import 'lib1.dart';

class B{
  A a;
  b(int i) {
    a.a = i;
  }
}
''');
    computeLibrarySourceErrors(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  void test_invalidUseOfProtectedMember_setter_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
abstract class B implements A {
  b(int i) {
    a = i;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidUseOfProtectedMember_topLevelVariable() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@protected
int x = 0;
main() {
  print(x);
}''');
    computeLibrarySourceErrors(source);
    // TODO(brianwilkerson) This should produce a hint because the annotation is
    // being applied to the wrong kind of declaration.
    assertNoErrors(source);
    verify([source]);
  }

  void test_isDouble() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWithOptions(options);
    Source source = addSource("var v = 1 is double;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.IS_DOUBLE]);
    verify([source]);
  }

  void test_isNotDouble() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWithOptions(options);
    Source source = addSource("var v = 1 is! double;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.IS_NOT_DOUBLE]);
    verify([source]);
  }

  void test_js_lib_OK() {
    Source source = addSource(r'''
@JS()
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missing_js_lib_on_class_decl() {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  void test_missing_js_lib_on_function() {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS('acxZIndex')
set _currentZIndex(int value) { }
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  void test_missing_js_lib_on_member() {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

class A {
  @JS()
  void a() { }
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  void test_missingReturn_async() {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  void test_missingReturn_factory() {
    Source source = addSource(r'''
class A {
  factory A() {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  void test_missingReturn_function() {
    Source source = addSource("int f() {}");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  void test_missingReturn_method() {
    Source source = addSource(r'''
class A {
  int m() {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  void test_mustCallSuper() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a()
  {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MUST_CALL_SUPER]);
    verify([source]);
  }

  void test_mustCallSuper_indirect() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a();
  }
}
class D extends C {
  @override
  void a() {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MUST_CALL_SUPER]);
    verify([source]);
  }

  void test_mustCallSuper_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a(); //OK
  }
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
    verify([source]);
  }

  void test_nullAwareInCondition_assert() {
    Source source = addSource(r'''
m(x) {
  assert (x?.a);
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_conditionalExpression() {
    Source source = addSource(r'''
m(x) {
  return x?.a ? 0 : 1;
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_do() {
    Source source = addSource(r'''
m(x) {
  do {} while (x?.a);
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_for() {
    Source source = addSource(r'''
m(x) {
  for (var v = x; v?.a; v = v.next) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if() {
    Source source = addSource(r'''
m(x) {
  if (x?.a) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_conditionalAnd_first() {
    Source source = addSource(r'''
m(x) {
  if (x?.a && x.b) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_conditionalAnd_second() {
    Source source = addSource(r'''
m(x) {
  if (x.a && x?.b) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_conditionalAnd_third() {
    Source source = addSource(r'''
m(x) {
  if (x.a && x.b && x?.c) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_conditionalOr_first() {
    Source source = addSource(r'''
m(x) {
  if (x?.a || x.b) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_conditionalOr_second() {
    Source source = addSource(r'''
m(x) {
  if (x.a || x?.b) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_conditionalOr_third() {
    Source source = addSource(r'''
m(x) {
  if (x.a || x.b || x?.c) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_not() {
    Source source = addSource(r'''
m(x) {
  if (!x?.a) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_if_parenthesized() {
    Source source = addSource(r'''
m(x) {
  if ((x?.a)) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_nullAwareInCondition_while() {
    Source source = addSource(r'''
m(x) {
  while (x?.a) {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  void test_overrideOnNonOverridingGetter_invalid() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
}
class B extends A {
  @override
  int get m => 1;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER]);
    verify([source]);
  }

  void test_overrideOnNonOverridingMethod_invalid() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
}
class B extends A {
  @override
  int m() => 1;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD]);
    verify([source]);
  }

  void test_overrideOnNonOverridingSetter_invalid() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
}
class B extends A {
  @override
  set m(int x) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER]);
    verify([source]);
  }

  void test_required_constructor_param() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

main() {
  new C();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  void test_required_constructor_param_no_reason() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  void test_required_constructor_param_null_reason() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required(null) int a}) {}
}

main() {
  new C();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  void test_required_constructor_param_OK() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C(a: 2);
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_required_constructor_param_redirecting_cons_call() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int x});
  C.named() : this();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  void test_required_constructor_param_super_call() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

class D extends C {
  D() : super();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  void test_required_function_param() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

void f({@Required('must specify an `a`') int a}) {}

main() {
  f();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  void test_required_method_param() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
f() {
  new A().m();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  void test_required_method_param_in_other_lib() {
    addNamedSource(
        '/a_lib.dart',
        r'''
library a_lib;
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
''');

    Source source = addSource(r'''
import "a_lib.dart";
f() {
  new A().m();
}
''');

    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  void test_required_typedef_function_param() {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

String test(C c) => c.m()();

typedef String F({@required String x});

class C {
  F m() => ({@required String x}) => null;
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  void test_typeCheck_type_is_Null() {
    Source source = addSource(r'''
m(i) {
  bool b = i is Null;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.TYPE_CHECK_IS_NULL]);
    verify([source]);
  }

  void test_typeCheck_type_not_Null() {
    Source source = addSource(r'''
m(i) {
  bool b = i is! Null;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.TYPE_CHECK_IS_NOT_NULL]);
    verify([source]);
  }

  void test_undefinedGetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    return a.m;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_message() {
    // The implementation of HintCode.UNDEFINED_SETTER assumes that
    // UNDEFINED_SETTER in StaticTypeWarningCode and StaticWarningCode are the
    // same, this verifies that assumption.
    expect(StaticWarningCode.UNDEFINED_GETTER.message,
        StaticTypeWarningCode.UNDEFINED_GETTER.message);
  }

  void test_undefinedIdentifier_exportHide() {
    Source source = addSource(r'''
library L;
export 'lib1.dart' hide a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_HIDDEN_NAME]);
    verify([source]);
  }

  void test_undefinedIdentifier_exportShow() {
    Source source = addSource(r'''
library L;
export 'lib1.dart' show a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_SHOWN_NAME]);
    verify([source]);
  }

  void test_undefinedIdentifier_importHide() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' hide a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [HintCode.UNUSED_IMPORT, HintCode.UNDEFINED_HIDDEN_NAME]);
    verify([source]);
  }

  void test_undefinedIdentifier_importShow() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [HintCode.UNUSED_IMPORT, HintCode.UNDEFINED_SHOWN_NAME]);
    verify([source]);
  }

  void test_undefinedMethod() {
    Source source = addSource(r'''
f() {
  var a = 'str';
  a.notAMethodOnString();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_assignmentExpression() {
    Source source = addSource(r'''
class A {}
class B {
  f(var a, var a2) {
    a = new A();
    a2 = new A();
    a += a2;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_METHOD]);
  }

  void test_undefinedOperator_binaryExpression() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a + 1;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexBoth() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0]++;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexGetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0];
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexSetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0] = 1;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_postfixExpression() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a++;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_prefixExpression() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    ++a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedSetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a.m = 0;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSetter_message() {
    // The implementation of HintCode.UNDEFINED_SETTER assumes that
    // UNDEFINED_SETTER in StaticTypeWarningCode and StaticWarningCode are the
    // same, this verifies that assumption.
    expect(StaticWarningCode.UNDEFINED_SETTER.message,
        StaticTypeWarningCode.UNDEFINED_SETTER.message);
  }

  void test_unnecessaryCast_type_supertype() {
    Source source = addSource(r'''
m(int i) {
  var b = i as Object;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_CAST]);
    verify([source]);
  }

  void test_unnecessaryCast_type_type() {
    Source source = addSource(r'''
m(num i) {
  var b = i as num;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_CAST]);
    verify([source]);
  }

  void test_unnecessaryNoSuchMethod_blockBody() {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    return super.noSuchMethod(y);
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_NO_SUCH_METHOD]);
    verify([source]);
  }

  void test_unnecessaryNoSuchMethod_expressionBody() {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.noSuchMethod(y);
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_NO_SUCH_METHOD]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_null_is_Null() {
    Source source = addSource("bool b = null is Null;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_null_not_Null() {
    Source source = addSource("bool b = null is! Null;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_is_dynamic() {
    Source source = addSource(r'''
m(i) {
  bool b = i is dynamic;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_is_object() {
    Source source = addSource(r'''
m(i) {
  bool b = i is Object;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_not_dynamic() {
    Source source = addSource(r'''
m(i) {
  bool b = i is! dynamic;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_not_object() {
    Source source = addSource(r'''
m(i) {
  bool b = i is! Object;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_extends() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
class B extends _A {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_fieldDeclaration() {
    enableUnusedElement = true;
    var src = r'''
class Foo {
  _Bar x;
}

class _Bar {
}
''';
    Source source = addSource(src);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_implements() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
class B implements _A {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_instanceCreation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  new _A();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_staticFieldAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static const F = 42;
}
main() {
  _A.F;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_staticMethodInvocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static m() {}
}
main() {
  _A.m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_typeArgument() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  var v = new List<_A>();
  print(v);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_notUsed_inClassMember() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static staticMethod() {
    new _A();
  }
  instanceMethod() {
    new _A();
  }
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_notUsed_inConstructorName() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  _A() {}
  _A.named() {}
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_notUsed_isExpression() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main(p) {
  if (p is _A) {
  }
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_notUsed_variableDeclaration() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  _A v;
  print(v);
}
print(x) {}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_enum_isUsed_fieldReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
enum _MyEnum {A, B, C}
main() {
  print(_MyEnum.B);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_enum_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
enum _MyEnum {A, B, C}
main() {
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionLocal_isUsed_closure() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  print(() {});
}
print(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionLocal_isUsed_invocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
  f();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionLocal_isUsed_reference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
  print(f);
}
print(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionLocal_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionLocal_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  _f(int p) {
    _f(p - 1);
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionTop_isUsed_invocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
  _f();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTop_isUsed_reference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
  print(_f);
}
print(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTop_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionTop_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f(int p) {
  _f(p - 1);
}
main() {
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionTypeAlias_isUsed_isExpression() {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main(f) {
  if (f is _F) {
    print('F');
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTypeAlias_isUsed_reference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main(_F f) {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTypeAlias_isUsed_typeArgument() {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main() {
  var v = new List<_F>();
  print(v);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTypeAlias_isUsed_variableDeclaration() {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
class A {
  _F f;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTypeAlias_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main() {
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_getter_isUsed_invocation_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
  useGetter() {
    var v = _g;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_getter_isUsed_invocation_PrefixedIdentifier() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}
main(A a) {
  var v = a._g;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_getter_isUsed_invocation_PropertyAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}
main() {
  var v = new A()._g;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_getter_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_getter_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g {
    return _g;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
print(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_implicitThis_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
class B extends A {
  _m() {}
}
print(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_PrefixedIdentifier() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main(A a) {
  a._m;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_PropertyAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  new A()._m;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_implicitThis_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}
class B extends A {
  _m() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_MemberElement() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A<T> {
  _m(T t) {}
}
main(A<int> a) {
  a._m(0);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_propagated() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  var a = new A();
  a._m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_static() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  A a = new A();
  a._m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
class B extends A {
  _m() {}
}
main(A a) {
  a._m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_notPrivate() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  m() {}
}
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_staticInvocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m() {}
}
main() {
  A._m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m() {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_method_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m(int p) {
    _m(p - 1);
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_setter_isUsed_invocation_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
  useSetter() {
    _s = 42;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_setter_isUsed_invocation_PrefixedIdentifier() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}
main(A a) {
  a._s = 42;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_setter_isUsed_invocation_PropertyAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}
main() {
  new A()._s = 42;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_setter_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_setter_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(int x) {
    if (x > 5) {
      _s = x - 1;
    }
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedField_isUsed_argument() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f = 0;
  main() {
    print(++_f);
  }
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_implicitThis_expressionFunctionBody() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  m() => _f;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_implicitThis_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
class B extends A {
  int _f;
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_qualified_propagatedElement() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
main() {
  var a = new A();
  print(a._f);
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_qualified_staticElement() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
main() {
  A a = new A();
  print(a._f);
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_qualified_unresolved() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
main(a) {
  print(a._f);
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_notUsed_compoundAssign() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  main() {
    _f += 2;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_constructorFieldInitializers() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  A() : _f = 0;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_fieldFormalParameter() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  A(this._f);
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_postfixExpr() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f = 0;
  main() {
    _f++;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_prefixExpr() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f = 0;
  main() {
    ++_f;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_simpleAssignment() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  m() {
    _f = 1;
  }
}
main(A a) {
  a._f = 2;
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedImport() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';''');
    Source source2 = addNamedSource("/lib1.dart", "library lib1;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedImport_as() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
one.A a;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedImport_hide() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
A a;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedImport_inComment_libraryDirective() {
    Source source = addSource(r'''
/// Use [Future] class.
library L;
import 'dart:async';
''');
    assertNoErrors(source);
  }

  void test_unusedImport_show() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show A;
import 'lib1.dart' show B;
A a;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
class B {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedLocalVariable_inCatch_exception() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } on String catch (exception) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_CATCH_CLAUSE]);
    verify([source]);
  }

  void test_unusedLocalVariable_inCatch_exception_hasStack() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stack) {
    print(stack);
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_inCatch_exception_noOnClause() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_inCatch_stackTrace() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stackTrace) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_CATCH_STACK]);
    verify([source]);
  }

  void test_unusedLocalVariable_inCatch_stackTrace_used() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stackTrace) {
    print('exception at $stackTrace');
  }
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_inFor_underscore_ignored() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  for (var _ in [1,2,3]) {
    for (var __ in [4,5,6]) {
      // do something
    }
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_inFunction() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v = 2;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_inMethod() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
class A {
  foo() {
    var v = 1;
    v = 2;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isInvoked() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
typedef Foo();
main() {
  Foo foo;
  foo();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_notUsed_compoundAssign() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v += 2;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_notUsed_postfixExpr() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v++;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_notUsed_prefixExpr() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  ++v;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_usedArgument() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  print(++v);
}
print(x) {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_usedInvocationTarget() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedShownName() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show A, B;
A a;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
class B {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedShownName_as() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as p show A, B;
p.A a;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
class B {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedShownName_duplicates() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show A, B;
import 'lib1.dart' show C, D;
A a;
C c;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
class B {}
class C {}
class D {}''');
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [HintCode.UNUSED_SHOWN_NAME, HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedShownName_topLevelVariable() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show var1, var2;
import 'lib1.dart' show var3, var4;
int a = var1;
int b = var2;
int c = var3;''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
const int var1 = 1;
const int var2 = 2;
const int var3 = 3;
const int var4 = 4;''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_useOfVoidResult_assignmentExpression_function() {
    Source source = addSource(r'''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_assignmentExpression_method() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_inForLoop() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    for(var a = m();;) {}
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_variableDeclaration_function() {
    Source source = addSource(r'''
void f() {}
class A {
  n() {
    var a = f();
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_variableDeclaration_method() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    var a = m();
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_variableDeclaration_method2() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    var a = m(), b = m();
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [HintCode.USE_OF_VOID_RESULT, HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }
}
