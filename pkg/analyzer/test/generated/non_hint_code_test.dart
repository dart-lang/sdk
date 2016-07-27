// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.non_hint_code_test;

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source_io.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(NonHintCodeTest);
}

@reflectiveTest
class NonHintCodeTest extends ResolverTestCase {
  void test_deadCode_afterTryCatch() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalElse_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalIf_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_else() {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_prefixedIdentifier() {
    Source source = addSource(r'''
class A {
  static const bool DEBUG = false;
}
f() {
  if(A.DEBUG) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_prefixedIdentifier2() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_propertyAccessor() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_simpleIdentifier() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  if(DEBUG) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_while_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadCatch_onCatchSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_and_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_or_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_statementAfterIfWithoutElse() {
    Source source = addSource(r'''
f() {
  if (1 < 0) {
    return;
  }
  int a = 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadFinalBreakInCase() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deprecatedMemberUse_inDeprecatedClass() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deprecatedMemberUse_inDeprecatedFunction() {
    Source source = addSource(r'''
@deprecated
f() {}

@deprecated
g() {
  f();
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deprecatedMemberUse_inDeprecatedMethod() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deprecatedMemberUse_inDeprecatedMethod_inDeprecatedClass() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_divisionOptimization() {
    Source source = addSource(r'''
f(int x, int y) {
  var v = x / y.toInt();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_divisionOptimization_supressIfDivisionNotDefinedInCore() {
    Source source = addSource(r'''
f(x, y) {
  var v = (x / y).toInt();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_divisionOptimization_supressIfDivisionOverridden() {
    Source source = addSource(r'''
class A {
  num operator /(x) { return x; }
}
f(A x, A y) {
  var v = (x / y).toInt();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateImport_as() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateImport_hide() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateImport_show() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_importDeferredLibraryWithLoadFunction() {
    resolveWithErrors(<String>[
      r'''
library lib1;
f() {}''',
      r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }'''
    ], ErrorCode.EMPTY_LIST);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_1() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message, var dynamic_) {
  if (message is Function) {
    message = dynamic_;
  }
  int s = message;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_3() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_4() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_emptyFunctionBody() {
    Source source = addSource(r'''
abstract class A {
  int m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_expressionFunctionBody() {
    Source source = addSource("int f() => 0;");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_noReturnType() {
    Source source = addSource("f() {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_voidReturnType() {
    Source source = addSource("void f() {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nullAwareInCondition_for_noCondition() {
    Source source = addSource(r'''
m(x) {
  for (var v = x; ; v++) {}
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nullAwareInCondition_if_notTopLevel() {
    Source source = addSource(r'''
m(x) {
  if (x?.y == null) {}
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideEqualsButNotHashCode() {
    Source source = addSource(r'''
class A {
  bool operator ==(x) { return x; }
  get hashCode => 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingGetter_inInterface() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int get m => 0;
}
class B implements A {
  @override
  int get m => 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingGetter_inSuperclass() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int get m => 0;
}
class B extends A {
  @override
  int get m => 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingMethod_inInterface() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int m() => 0;
}
class B implements A {
  @override
  int m() => 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingMethod_inSuperclass() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int m() => 0;
}
class B extends A {
  @override
  int m() => 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingSetter_inInterface() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  set m(int x) {}
}
class B implements A {
  @override
  set m(int x) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingSetter_inSuperclass() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  set m(int x) {}
}
class B extends A {
  @override
  set m(int x) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_propagatedFieldType() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_proxy_annotation_prefixed() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_prefixed2() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_prefixed3() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedGetter_inSubtype() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_assignmentExpression_inSubtype() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_dynamic() {
    Source source = addSource(r'''
class D<T extends dynamic> {
  fieldAccess(T t) => t.abc;
  methodAccess(T t) => t.xyz(1, 2, 'three');
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  b() {}
}
f() {
  var a = new A();
  a.b();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_unionType_all() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_unionType_some() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_binaryExpression_inSubtype() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_indexBoth_inSubtype() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_indexGetter_inSubtype() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_indexSetter_inSubtype() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_postfixExpression() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_prefixExpression() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_undefinedSetter_inSubtype() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_unnecessaryCast_13855_parameter_A() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryCast_conditionalExpression() {
    Source source = addSource(r'''
abstract class I {}
class A implements I {}
class B implements I {}
I m(A a, B b) {
  return a == null ? b as I : a as I;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryCast_dynamic_type() {
    Source source = addSource(r'''
m(v) {
  var b = v as Object;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryCast_generics() {
    // dartbug.com/18953
    Source source = addSource(r'''
import 'dart:async';
Future<int> f() => new Future.value(0);
void g(bool c) {
  (c ? f(): new Future.value(0) as Future<int>).then((int value) {});
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryCast_type_dynamic() {
    Source source = addSource(r'''
m(v) {
  var b = Object as dynamic;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryNoSuchMethod_blockBody_notReturnStatement() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryNoSuchMethod_blockBody_notSingleStatement() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryNoSuchMethod_expressionBody_notNoSuchMethod() {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.hashCode;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryNoSuchMethod_expressionBody_notSuper() {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => 42;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_annotationOnDirective() {
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
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source, source2]);
  }

  void test_unusedImport_as_equalPrefixes() {
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
    computeLibrarySourceErrors(source);
    assertErrors(source);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  void test_unusedImport_core_library() {
    Source source = addSource(r'''
library L;
import 'dart:core';''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_export() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_export2() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_export_infiniteLoop() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_metadata() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_prefix_topLevelFunction() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_prefix_topLevelFunction2() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_useOfVoidResult_implicitReturnValue() {
    Source source = addSource(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_useOfVoidResult_nonVoidReturnValue() {
    Source source = addSource(r'''
int f() => 1;
g() {
  var a = f();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }
}

class PubSuggestionCodeTest extends ResolverTestCase {
  void test_import_package() {
    Source source = addSource("import 'package:somepackage/other.dart';");
    computeLibrarySourceErrors(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  void test_import_packageWithDotDot() {
    Source source = addSource("import 'package:somepackage/../other.dart';");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
      HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
    ]);
  }

  void test_import_packageWithLeadingDotDot() {
    Source source = addSource("import 'package:../other.dart';");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
      HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
    ]);
  }

  void test_import_referenceIntoLibDirectory() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE]);
  }

  void test_import_referenceIntoLibDirectory_no_pubspec() {
    cacheSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_import_referenceOutOfLibDirectory() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [HintCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE]);
  }

  void test_import_referenceOutOfLibDirectory_no_pubspec() {
    cacheSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_import_valid_inside_lib1() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import 'other.dart';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_import_valid_inside_lib2() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/bar/other.dart", "");
    Source source = addNamedSource(
        "/myproj/lib/foo/test.dart", "import '../bar/other.dart';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_import_valid_outside_lib() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib2/test.dart", "import '../web/other.dart';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }
}
