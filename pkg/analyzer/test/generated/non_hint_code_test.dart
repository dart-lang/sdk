// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.non_hint_code_test;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonHintCodeTest);
  });
}

@reflectiveTest
class NonHintCodeTest extends ResolverTestCase {
  test_async_future_object_without_return() async {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_afterTryCatch() async {
    Source source = addSource('''
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_conditionalElse_debugConst() async {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_conditionalIf_debugConst() async {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_else() async {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_if_debugConst_prefixedIdentifier() async {
    Source source = addSource(r'''
class A {
  static const bool DEBUG = false;
}
f() {
  if(A.DEBUG) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_if_debugConst_prefixedIdentifier2() async {
    Source source = addSource(r'''
library L;
import 'lib2.dart';
f() {
  if(A.DEBUG) {}
}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
class A {
  static const bool DEBUG = false;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_if_debugConst_propertyAccessor() async {
    Source source = addSource(r'''
library L;
import 'lib2.dart' as LIB;
f() {
  if(LIB.A.DEBUG) {}
}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
class A {
  static const bool DEBUG = false;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_if_debugConst_simpleIdentifier() async {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  if(DEBUG) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadBlock_while_debugConst() async {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadCatch_onCatchSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadFinalBreakInCase() async {
    Source source = addSource(r'''
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadOperandLHS_and_debugConst() async {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_deadOperandLHS_or_debugConst() async {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deadCode_statementAfterIfWithoutElse() async {
    Source source = addSource(r'''
f() {
  if (1 < 0) {
    return;
  }
  int a = 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deprecatedMemberUse_inDeprecatedClass() async {
    Source source = addSource(r'''
@deprecated
f() {}

@deprecated
class C {
  m() {
    f();
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deprecatedMemberUse_inDeprecatedFunction() async {
    Source source = addSource(r'''
@deprecated
f() {}

@deprecated
g() {
  f();
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deprecatedMemberUse_inDeprecatedLibrary() async {
    Source source = addSource(r'''
@deprecated
library lib;

@deprecated
f() {}

class C {
  m() {
    f();
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deprecatedMemberUse_inDeprecatedMethod() async {
    Source source = addSource(r'''
@deprecated
f() {}

class C {
  @deprecated
  m() {
    f();
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deprecatedMemberUse_inDeprecatedMethod_inDeprecatedClass() async {
    Source source = addSource(r'''
@deprecated
f() {}

@deprecated
class C {
  @deprecated
  m() {
    f();
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_divisionOptimization() async {
    Source source = addSource(r'''
f(int x, int y) {
  var v = x / y.toInt();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_divisionOptimization_supressIfDivisionNotDefinedInCore() async {
    Source source = addSource(r'''
f(x, y) {
  var v = (x / y).toInt();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_divisionOptimization_supressIfDivisionOverridden() async {
    Source source = addSource(r'''
class A {
  num operator /(x) { return x; }
}
f(A x, A y) {
  var v = (x / y).toInt();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_duplicateImport_as() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
A a;
one.A a2;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_duplicateImport_hide() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
A a;
B b;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_duplicateImport_show() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' show A;
A a;
B b;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_importDeferredLibraryWithLoadFunction() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
f() {}''',
      r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }'''
    ], const <ErrorCode>[]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_1() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message, var dynamic_) {
  if (message is Function) {
    message = dynamic_;
  }
  int s = message;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_3() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message) {
  var dynamic_;
  if (message is Function) {
    message = dynamic_;
  } else {
    return;
  }
  int s = message;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_4() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message) {
  if (message is Function) {
    message = '';
  } else {
    return;
  }
  String s = message;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingReturn_emptyFunctionBody() async {
    Source source = addSource(r'''
abstract class A {
  int m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingReturn_expressionFunctionBody() async {
    Source source = addSource("int f() => 0;");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingReturn_noReturnType() async {
    Source source = addSource("f() {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingReturn_voidReturnType() async {
    Source source = addSource("void f() {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareInCondition_for_noCondition() async {
    Source source = addSource(r'''
m(x) {
  for (var v = x; ; v++) {}
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareInCondition_if_notTopLevel() async {
    Source source = addSource(r'''
m(x) {
  if (x?.y == null) {}
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideEqualsButNotHashCode() async {
    Source source = addSource(r'''
class A {
  bool operator ==(x) { return x; }
  get hashCode => 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingField_inInterface() async {
    Source source = addSource(r'''
class A {
  int get a => 0;
  void set b(_) {}
  int c;
}
class B implements A {
  @override
  final int a = 1;
  @override
  int b;
  @override
  int c;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingField_inSuperclass() async {
    Source source = addSource(r'''
class A {
  int get a => 0;
  void set b(_) {}
  int c;
}
class B extends A {
  @override
  final int a = 1;
  @override
  int b;
  @override
  int c;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingGetter_inInterface() async {
    Source source = addSource(r'''
class A {
  int get m => 0;
}
class B implements A {
  @override
  int get m => 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingGetter_inSuperclass() async {
    Source source = addSource(r'''
class A {
  int get m => 0;
}
class B extends A {
  @override
  int get m => 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingMethod_inInterface() async {
    Source source = addSource(r'''
class A {
  int m() => 0;
}
class B implements A {
  @override
  int m() => 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingMethod_inSuperclass() async {
    Source source = addSource(r'''
class A {
  int m() => 0;
}
class B extends A {
  @override
  int m() => 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingMethod_inSuperclass_abstract() async {
    Source source = addSource(r'''
abstract class A {
  int m();
}
class B extends A {
  @override
  int m() => 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingSetter_inInterface() async {
    Source source = addSource(r'''
class A {
  set m(int x) {}
}
class B implements A {
  @override
  set m(int x) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_overrideOnNonOverridingSetter_inSuperclass() async {
    Source source = addSource(r'''
class A {
  set m(int x) {}
}
class B extends A {
  @override
  set m(int x) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_propagatedFieldType() async {
    Source source = addSource(r'''
class A { }
class X<T> {
  final x = new List<T>();
}
class Z {
  final X<A> y = new X<A>();
  foo() {
    y.x.add(new A());
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_proxy_annotation_prefixed() async {
    Source source = addSource(r'''
library L;
@proxy
class A {}
f(var a) {
  a = new A();
  a.m();
  var x = a.g;
  a.s = 1;
  var y = a + a;
  a++;
  ++a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_prefixed2() async {
    Source source = addSource(r'''
library L;
@proxy
class A {}
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_prefixed3() async {
    Source source = addSource(r'''
library L;
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}
@proxy
class A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedGetter_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  get b => 0;
}
f(var a) {
  if(a is A) {
    return a.b;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_assignmentExpression_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a, var a2) {
  a = new A();
  a2 = new A();
  a += a2;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_dynamic() async {
    Source source = addSource(r'''
class D<T extends dynamic> {
  fieldAccess(T t) => t.abc;
  methodAccess(T t) => t.xyz(1, 2, 'three');
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  b() {}
}
f() {
  var a = new A();
  a.b();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_unionType_all() async {
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m() => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_unionType_some() async {
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m(0);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedOperator_binaryExpression_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {}
}
f(var a) {
  if(a is A) {
    a + 1;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedOperator_indexBoth_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if(a is A) {
    a[0]++;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedOperator_indexGetter_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if(a is A) {
    a[0];
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedOperator_indexSetter_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator []=(i, v) {}
}
f(var a) {
  if(a is A) {
    a[0] = 1;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedOperator_postfixExpression() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if(a is A) {
    a++;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedOperator_prefixExpression() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if(a is A) {
    ++a;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedSetter_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(var a) {
  if(a is A) {
    a.b = 0;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_unnecessaryCast_13855_parameter_A() async {
    // dartbug.com/13855, dartbug.com/13732
    Source source = addSource(r'''
class A{
  a() {}
}
class B<E> {
  E e;
  m() {
    (e as A).a();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryCast_conditionalExpression() async {
    Source source = addSource(r'''
abstract class I {}
class A implements I {}
class B implements I {}
I m(A a, B b) {
  return a == null ? b as I : a as I;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryCast_dynamic_type() async {
    Source source = addSource(r'''
m(v) {
  var b = v as Object;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryCast_generics() async {
    // dartbug.com/18953
    Source source = addSource(r'''
import 'dart:async';
Future<int> f() => new Future.value(0);
void g(bool c) {
  (c ? f(): new Future.value(0) as Future<int>).then((int value) {});
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryCast_type_dynamic() async {
    Source source = addSource(r'''
m(v) {
  var b = Object as dynamic;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryNoSuchMethod_blockBody_notReturnStatement() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    print(y);
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryNoSuchMethod_blockBody_notSingleStatement() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    print(y);
    return super.noSuchMethod(y);
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryNoSuchMethod_expressionBody_notNoSuchMethod() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.hashCode;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unnecessaryNoSuchMethod_expressionBody_notSuper() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => 42;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedImport_annotationOnDirective() async {
    Source source = addSource(r'''
library L;
@A()
import 'lib1.dart';''');
    Source source2 = addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {
  const A() {}
}''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source);
    verify([source, source2]);
  }

  test_unusedImport_as_equalPrefixes() async {
    // 18818
    Source source = addSource(r'''
library L;
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;
one.B b;''');
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
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    await computeAnalysisResult(source3);
    assertErrors(source);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  test_unusedImport_core_library() async {
    Source source = addSource(r'''
library L;
import 'dart:core';''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedImport_export() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Two two;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
export 'lib2.dart';
class One {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
class Two {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedImport_export2() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Three three;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
export 'lib2.dart';
class One {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
export 'lib3.dart';
class Two {}''');
    addNamedSource(
        "/lib3.dart",
        r'''
library lib3;
class Three {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedImport_export_infiniteLoop() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Two two;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
export 'lib2.dart';
class One {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
export 'lib3.dart';
class Two {}''');
    addNamedSource(
        "/lib3.dart",
        r'''
library lib3;
export 'lib2.dart';
class Three {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedImport_metadata() async {
    Source source = addSource(r'''
library L;
@A(x)
import 'lib1.dart';
class A {
  final int value;
  const A(this.value);
}''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
const x = 0;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedImport_prefix_topLevelFunction() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
  }
}''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class One {}
topLevelFunction() {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedImport_prefix_topLevelFunction2() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
import 'lib1.dart' as two show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
    two.topLevelFunction();
  }
}''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class One {}
topLevelFunction() {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_useOfVoidResult_implicitReturnValue() async {
    Source source = addSource(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_useOfVoidResult_nonVoidReturnValue() async {
    Source source = addSource(r'''
int f() => 1;
g() {
  var a = f();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_withSuperMixin() async {
    resetWith(options: new AnalysisOptionsImpl()..enableSuperMixins = true);
    Source source = addSource(r'''
abstract class A {
  void test();
}
class B extends A {
  void test() {
    super.test;
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }
}

class PubSuggestionCodeTest extends ResolverTestCase {
  test_import_package() async {
    Source source = addSource("import 'package:somepackage/other.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_import_packageWithDotDot() async {
    Source source = addSource("import 'package:somepackage/../other.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
      HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
    ]);
  }

  test_import_packageWithLeadingDotDot() async {
    Source source = addSource("import 'package:../other.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
      HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
    ]);
  }

  test_import_referenceIntoLibDirectory() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE]);
  }

  test_import_referenceIntoLibDirectory_no_pubspec() async {
    addNamedSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_referenceOutOfLibDirectory() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE]);
  }

  test_import_referenceOutOfLibDirectory_no_pubspec() async {
    addNamedSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_valid_inside_lib1() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import 'other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_valid_inside_lib2() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/lib/bar/other.dart", "");
    Source source = addNamedSource(
        "/myproj/lib/foo/test.dart", "import '../bar/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_valid_outside_lib() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib2/test.dart", "import '../web/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }
}
