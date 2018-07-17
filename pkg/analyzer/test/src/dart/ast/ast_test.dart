// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/parser_test.dart';
import '../../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionImplTest);
    defineReflectiveTests(InstanceCreationExpressionImplTest);
    defineReflectiveTests(IntegerLiteralImplTest);
  });
}

@reflectiveTest
class ExpressionImplTest extends ParserTestCase {
  String testSource;
  CompilationUnitImpl testUnit;

  void assertInContext(String snippet, bool isInContext) {
    int index = testSource.indexOf(snippet);
    expect(index >= 0, isTrue);
    NodeLocator visitor = new NodeLocator(index);
    AstNodeImpl node = visitor.searchWithin(testUnit);
    expect(node, new TypeMatcher<ExpressionImpl>());
    expect((node as ExpressionImpl).inConstantContext,
        isInContext ? isTrue : isFalse);
  }

  void parse(String source) {
    testSource = source;
    testUnit = parseCompilationUnit(source);
  }

  test_inConstantContext_instanceCreation_annotation_true() {
    parse('''
@C(C(0))
class C {
  const C(_);
}
''');
    assertInContext("C(0", true);
  }

  test_inConstantContext_instanceCreation_fieldWithConstConstructor() {
    parse('''
class C {
  final d = D();
  const C();
}
class D {
  const D();
}
''');
    assertInContext("D()", false);
  }

  test_inConstantContext_instanceCreation_fieldWithoutConstConstructor() {
    parse('''
class C {
  final d = D();
  C();
}
class D {
  const D();
}
''');
    assertInContext("D()", false);
  }

  test_inConstantContext_instanceCreation_functionLiteral() {
    parse('''
const V = () => C();
class C {
  const C();
}
''');
    assertInContext("C()", false);
  }

  test_inConstantContext_instanceCreation_instanceCreation_false() {
    parse('''
f() {
  return new C(C());
}
class C {
  const C(_);
}
''');
    assertInContext("C())", false);
  }

  test_inConstantContext_instanceCreation_instanceCreation_true() {
    parse('''
f() {
  return new C(C());
}
class C {
  const C(_);
}
''');
    assertInContext("C())", false);
  }

  test_inConstantContext_instanceCreation_listLiteral_false() {
    parse('''
f() {
  return [C()];
}
class C {
  const C();
}
''');
    assertInContext("C()]", false);
  }

  test_inConstantContext_instanceCreation_listLiteral_true() {
    parse('''
f() {
  return const [C()];
}
class C {
  const C();
}
''');
    assertInContext("C()]", true);
  }

  test_inConstantContext_instanceCreation_mapLiteral_false() {
    parse('''
f() {
  return {'a' : C()};
}
class C {
  const C();
}
''');
    assertInContext("C()}", false);
  }

  test_inConstantContext_instanceCreation_mapLiteral_true() {
    parse('''
f() {
  return const {'a' : C()};
}
class C {
  const C();
}
''');
    assertInContext("C()}", true);
  }

  test_inConstantContext_instanceCreation_nestedListLiteral_false() {
    parse('''
f() {
  return [[''], [C()]];
}
class C {
  const C();
}
''');
    assertInContext("C()]", false);
  }

  test_inConstantContext_instanceCreation_nestedListLiteral_true() {
    parse('''
f() {
  return const [[''], [C()]];
}
class C {
  const C();
}
''');
    assertInContext("C()]", true);
  }

  test_inConstantContext_instanceCreation_nestedMapLiteral_false() {
    parse('''
f() {
  return {'a' : {C() : C()}};
}
class C {
  const C();
}
''');
    assertInContext("C() :", false);
    assertInContext("C()}", false);
  }

  test_inConstantContext_instanceCreation_nestedMapLiteral_true() {
    parse('''
f() {
  return const {'a' : {C() : C()}};
}
class C {
  const C();
}
''');
    assertInContext("C() :", true);
    assertInContext("C()}", true);
  }

  test_inConstantContext_instanceCreation_switch_true() {
    parse('''
f(v) {
  switch (v) {
  case C():
    break;
  }
}
class C {
  const C();
}
''');
    assertInContext("C()", true);
  }

  test_inConstantContext_instanceCreation_topLevelVariable_false() {
    parse('''
var c = C();
class C {
  const C();
}
''');
    assertInContext("C()", false);
  }

  test_inConstantContext_instanceCreation_topLevelVariable_true() {
    parse('''
const c = C();
class C {
  const C();
}
''');
    assertInContext("C()", true);
  }

  test_inConstantContext_listLiteral_annotation_true() {
    parse('''
@C([])
class C {
  const C(_);
}
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_functionLiteral() {
    parse('''
const V = () => [];
class C {
  const C();
}
''');
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_initializer_false() {
    parse('''
var c = [];
''');
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_initializer_true() {
    parse('''
const c = [];
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_instanceCreation_false() {
    parse('''
f() {
  return new C([]);
}
class C {
  const C(_);
}
''');
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_instanceCreation_true() {
    parse('''
f() {
  return const C([]);
}
class C {
  const C(_);
}
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_listLiteral_false() {
    parse('''
f() {
  return [[''], []];
}
''');
    assertInContext("['']", false);
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_listLiteral_true() {
    parse('''
f() {
  return const [[''], []];
}
''');
    assertInContext("['']", true);
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_mapLiteral_false() {
    parse('''
f() {
  return {'a' : [''], 'b' : []};
}
''');
    assertInContext("['']", false);
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_mapLiteral_true() {
    parse('''
f() {
  return const {'a' : [''], 'b' : []};
}
''');
    assertInContext("['']", true);
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_switch_true() {
    parse('''
f(v) {
  switch (v) {
  case []:
    break;
  }
}
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_mapLiteral_annotation_true() {
    parse('''
@C({})
class C {
  const C(_);
}
''');
    assertInContext("{}", true);
  }

  test_inConstantContext_mapLiteral_functionLiteral() {
    parse('''
const V = () => {};
class C {
  const C();
}
''');
    assertInContext("{}", false);
  }

  test_inConstantContext_mapLiteral_initializer_false() {
    parse('''
var c = {};
''');
    assertInContext("{}", false);
  }

  test_inConstantContext_mapLiteral_initializer_true() {
    parse('''
const c = {};
''');
    assertInContext("{}", true);
  }

  test_inConstantContext_mapLiteral_instanceCreation_false() {
    parse('''
f() {
  return new C({});
}
class C {
  const C(_);
}
''');
    assertInContext("{}", false);
  }

  test_inConstantContext_mapLiteral_instanceCreation_true() {
    parse('''
f() {
  return const C({});
}
class C {
  const C(_);
}
''');
    assertInContext("{}", true);
  }

  test_inConstantContext_mapLiteral_listLiteral_false() {
    parse('''
f() {
  return [{'a' : 1}, {'b' : 2}];
}
''');
    assertInContext("{'a", false);
    assertInContext("{'b", false);
  }

  test_inConstantContext_mapLiteral_listLiteral_true() {
    parse('''
f() {
  return const [{'a' : 1}, {'b' : 2}];
}
''');
    assertInContext("{'a", true);
    assertInContext("{'b", true);
  }

  test_inConstantContext_mapLiteral_mapLiteral_false() {
    parse('''
f() {
  return {'a' : {'b' : 0}, 'c' : {'d' : 1}};
}
''');
    assertInContext("{'b", false);
    assertInContext("{'d", false);
  }

  test_inConstantContext_mapLiteral_mapLiteral_true() {
    parse('''
f() {
  return const {'a' : {'b' : 0}, 'c' : {'d' : 1}};
}
''');
    assertInContext("{'b", true);
    assertInContext("{'d", true);
  }

  test_inConstantContext_mapLiteral_switch_true() {
    parse('''
f(v) {
  switch (v) {
  case {}:
    break;
  }
}
''');
    assertInContext("{}", true);
  }
}

@reflectiveTest
class InstanceCreationExpressionImplTest extends ResolverTestCase {
  String testSource;
  CompilationUnitImpl testUnit;

  bool get enableNewAnalysisDriver => true;

  void assertCanBeConst(String snippet, bool expectedResult) {
    int index = testSource.indexOf(snippet);
    expect(index >= 0, isTrue);
    NodeLocator visitor = new NodeLocator(index);
    AstNodeImpl node = visitor.searchWithin(testUnit);
    node = node.getAncestor((node) => node is InstanceCreationExpressionImpl);
    expect(node, isNotNull);
    expect((node as InstanceCreationExpressionImpl).canBeConst(),
        expectedResult ? isTrue : isFalse);
  }

  void assertIsConst(String snippet, bool expectedResult) {
    int index = testSource.indexOf(snippet);
    expect(index >= 0, isTrue);
    NodeLocator visitor = new NodeLocator(index);
    AstNodeImpl node = visitor.searchWithin(testUnit);
    node = node.getAncestor((node) => node is InstanceCreationExpressionImpl);
    expect(node, isNotNull);
    expect((node as InstanceCreationExpressionImpl).isConst,
        expectedResult ? isTrue : isFalse);
  }

  void enablePreviewDart2() {
    resetWith(options: new AnalysisOptionsImpl()..previewDart2 = true);
  }

  Future<void> resolve(String source) async {
    testSource = source;
    testUnit = await resolveSource2('/test.dart', source);
  }

  void test_canBeConst_false_argument_invocation() async {
    enablePreviewDart2();
    await resolve('''
class A {}
class B {
  const B(A a);
}
A f() => A();
B g() => B(f());
''');
    assertCanBeConst("B(f", false);
  }

  void test_canBeConst_false_argument_invocationInList() async {
    enablePreviewDart2();
    await resolve('''
class A {}
class B {
  const B(a);
}
A f() => A();
B g() => B([f()]);
''');
    assertCanBeConst("B([", false);
  }

  void test_canBeConst_false_argument_nonConstConstructor() async {
    enablePreviewDart2();
    await resolve('''
class A {}
class B {
  const B(A a);
}
B f() => B(A());
''');
    assertCanBeConst("B(A(", false);
  }

  void test_canBeConst_false_nonConstConstructor() async {
    enablePreviewDart2();
    await resolve('''
class A {}
A f() => A();
''');
    assertCanBeConst("A(", false);
  }

  @failingTest
  void test_canBeConst_true_argument_constConstructor() async {
    enablePreviewDart2();
    await resolve('''
class A {
  const A();
}
class B {
  const B(A a);
}
B f() => B(A());
''');
    assertCanBeConst("B(A(", true);
  }

  void
      test_isConst_notInContext_constructor_const_constParam_identifier() async {
    enablePreviewDart2();
    await resolve('''
var v = C(C.a);
class C {
  static const C a = C.c();
  const C(c);
  const C.c();
}
''');
    assertIsConst("C(C", false);
  }

  void test_isConst_notInContext_constructor_const_constParam_named() async {
    enablePreviewDart2();
    await resolve('''
var v = C(c: C());
class C {
  const C({c});
}
''');
    assertIsConst("C(c", false);
  }

  void
      test_isConst_notInContext_constructor_const_constParam_named_parens() async {
    enablePreviewDart2();
    await resolve('''
var v = C(c: (C()));
class C {
  const C({c});
}
''');
    assertIsConst("C(c", false);
  }

  void test_isConst_notInContext_constructor_const_constParam_parens() async {
    enablePreviewDart2();
    await resolve('''
var v = C( (C.c()) );
class C {
  const C(c);
  const C.c();
}
''');
    assertIsConst("C( (", false);
  }

  void test_isConst_notInContext_constructor_const_generic_named() async {
    enablePreviewDart2();
    await resolve('''
f() => <Object>[C<int>.n()];
class C<E> {
  const C.n();
}
''');
    assertIsConst("C<int>.n", false);
  }

  void
      test_isConst_notInContext_constructor_const_generic_named_prefixed() async {
    enablePreviewDart2();
    addNamedSource('/c.dart', '''
class C<E> {
  const C.n();
}
''');
    await resolve('''
import 'c.dart' as p;
f() => <Object>[p.C<int>.n()];
''');
    assertIsConst("C<int>", false);
  }

  void test_isConst_notInContext_constructor_const_generic_unnamed() async {
    enablePreviewDart2();
    await resolve('''
f() => <Object>[C<int>()];
class C<E> {
  const C();
}
''');
    assertIsConst("C<int>", false);
  }

  void
      test_isConst_notInContext_constructor_const_generic_unnamed_prefixed() async {
    enablePreviewDart2();
    addNamedSource('/c.dart', '''
class C<E> {
  const C();
}
''');
    await resolve('''
import 'c.dart' as p;
f() => <Object>[p.C<int>()];
''');
    assertIsConst("C<int>", false);
  }

  void
      test_isConst_notInContext_constructor_const_nonConstParam_constructor() async {
    enablePreviewDart2();
    await resolve('''
f() {
  return A(B());
}

class A {
  const A(B b);
}

class B {
  B();
}
''');
    assertIsConst("B())", false);
  }

  void
      test_isConst_notInContext_constructor_const_nonConstParam_variable() async {
    enablePreviewDart2();
    await resolve('''
f(int i) => <Object>[C(i)];
class C {
  final int f;
  const C(this.f);
}
''');
    assertIsConst("C(i)", false);
  }

  void test_isConst_notInContext_constructor_const_nonGeneric_named() async {
    enablePreviewDart2();
    await resolve('''
f() => <Object>[C.n()];
class C<E> {
  const C.n();
}
''');
    assertIsConst("C.n()", false);
  }

  void
      test_isConst_notInContext_constructor_const_nonGeneric_named_prefixed() async {
    enablePreviewDart2();
    addNamedSource('/c.dart', '''
class C {
  const C.n();
}
''');
    await resolve('''
import 'c.dart' as p;
f() => <Object>[p.C.n()];
''');
    assertIsConst("C.n()", false);
  }

  void test_isConst_notInContext_constructor_const_nonGeneric_unnamed() async {
    enablePreviewDart2();
    await resolve('''
f() => <Object>[C()];
class C {
  const C();
}
''');
    assertIsConst("C()", false);
  }

  void
      test_isConst_notInContext_constructor_const_nonGeneric_unnamed_prefixed() async {
    enablePreviewDart2();
    addNamedSource('/c.dart', '''
class C {
  const C();
}
''');
    await resolve('''
import 'c.dart' as p;
f() => <Object>[p.C()];
''');
    assertIsConst("C()", false);
  }

  void test_isConst_notInContext_constructor_nonConst() async {
    enablePreviewDart2();
    await resolve('''
f() => <Object>[C()];
class C {
  C();
}
''');
    assertIsConst("C()", false);
  }
}

@reflectiveTest
class IntegerLiteralImplTest {
  test_isValidLiteral_dec_negative_equalMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775808', true), true);
  }

  test_isValidLiteral_dec_negative_fewDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('24', true), true);
  }

  test_isValidLiteral_dec_negative_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidLiteral('009923372036854775807', true),
        false);
  }

  test_isValidLiteral_dec_negative_leadingZeros_underMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('004223372036854775807', true), true);
  }

  test_isValidLiteral_dec_negative_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775809', true), false);
  }

  test_isValidLiteral_dec_negative_tooManyDigits() {
    expect(
        IntegerLiteralImpl.isValidLiteral('10223372036854775808', true), false);
  }

  test_isValidLiteral_dec_positive_equalMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775807', false), true);
  }

  test_isValidLiteral_dec_positive_fewDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('42', false), true);
  }

  test_isValidLiteral_dec_positive_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidLiteral('009923372036854775807', false),
        false);
  }

  test_isValidLiteral_dec_positive_leadingZeros_underMax() {
    expect(IntegerLiteralImpl.isValidLiteral('004223372036854775807', false),
        true);
  }

  test_isValidLiteral_dec_positive_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775808', false), false);
  }

  test_isValidLiteral_dec_positive_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('10223372036854775808', false),
        false);
  }

  test_isValidLiteral_hex_negative_equalMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0x8000000000000000', true), true);
  }

  test_isValidLiteral_heX_negative_equalMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0X8000000000000000', true), true);
  }

  test_isValidLiteral_hex_negative_fewDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('0xFF', true), true);
  }

  test_isValidLiteral_heX_negative_fewDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('0XFF', true), true);
  }

  test_isValidLiteral_hex_negative_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0x00FFFFFFFFFFFFFFFFF', true),
        false);
  }

  test_isValidLiteral_heX_negative_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0X00FFFFFFFFFFFFFFFFF', true),
        false);
  }

  test_isValidLiteral_hex_negative_leadingZeros_underMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x007FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_heX_negative_leadingZeros_underMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X007FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_hex_negative_oneBelowMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0x7FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_heX_negative_oneBelowMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0X7FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_hex_negative_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x8000000000000001', true), false);
  }

  test_isValidLiteral_heX_negative_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X8000000000000001', true), false);
  }

  test_isValidLiteral_hex_negative_tooManyDigits() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x10000000000000000', true), false);
  }

  test_isValidLiteral_heX_negative_tooManyDigits() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X10000000000000000', true), false);
  }

  test_isValidLiteral_hex_positive_equalMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x7FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_heX_positive_equalMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X7FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_hex_positive_fewDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('0xFF', false), true);
  }

  test_isValidLiteral_heX_positive_fewDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('0XFF', false), true);
  }

  test_isValidLiteral_hex_positive_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0x00FFFFFFFFFFFFFFFFF', false),
        false);
  }

  test_isValidLiteral_heX_positive_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidLiteral('0X00FFFFFFFFFFFFFFFFF', false),
        false);
  }

  test_isValidLiteral_hex_positive_leadingZeros_underMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x007FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_heX_positive_leadingZeros_underMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X007FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_hex_positive_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x10000000000000000', false), false);
  }

  test_isValidLiteral_heX_positive_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X10000000000000000', false), false);
  }

  test_isValidLiteral_hex_positive_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('0xFF0000000000000000', false),
        false);
  }

  test_isValidLiteral_heX_positive_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidLiteral('0XFF0000000000000000', false),
        false);
  }
}
