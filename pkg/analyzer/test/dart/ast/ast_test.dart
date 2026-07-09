// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../src/dart/resolution/node_text_expectations.dart';
import '../../src/diagnostics/parser_diagnostics.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorDeclarationTest);
    defineReflectiveTests(FieldFormalParameterTest);
    defineReflectiveTests(FormalParameterIsExplicitlyTypedTest);
    defineReflectiveTests(HideClauseImplTest);
    defineReflectiveTests(ImplementsClauseImplTest);
    defineReflectiveTests(IndexExpressionTest);
    defineReflectiveTests(InterpolationStringTest);
    defineReflectiveTests(MethodDeclarationTest);
    defineReflectiveTests(MethodInvocationTest);
    defineReflectiveTests(NodeListTest);
    defineReflectiveTests(NormalFormalParameterTest);
    defineReflectiveTests(OnClauseImplTest);
    defineReflectiveTests(PreviousTokenTest);
    defineReflectiveTests(PropertyAccessTest);
    defineReflectiveTests(ShowClauseImplTest);
    defineReflectiveTests(SimpleIdentifierTest);
    defineReflectiveTests(SimpleStringLiteralTest);
    defineReflectiveTests(SpreadElementTest);
    defineReflectiveTests(StringInterpolationTest);
    defineReflectiveTests(SuperFormalParameterTest);
    defineReflectiveTests(VariableDeclarationTest);
    defineReflectiveTests(WithClauseImplTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstructorDeclarationTest extends ParserDiagnosticsTest {
  void test_firstTokenAfterCommentAndMetadata_all_inverted() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory const external A();
//        ^^^^^
// [diag.modifierOutOfOrder] The modifier 'const' should be before the modifier 'factory'.
//              ^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'external' should be before the modifier 'factory'.
}
''');

    var node = parseResult.findNode.constructor('A()');
    expect(node.firstTokenAfterCommentAndMetadata, node.factoryKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_all_normal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  external const factory A();
}
''');

    var node = parseResult.findNode.constructor('A()');
    expect(node.firstTokenAfterCommentAndMetadata, node.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_constOnly() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  const A();
}
''');

    var node = parseResult.findNode.constructor('A()');
    expect(node.firstTokenAfterCommentAndMetadata, node.constKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_externalOnly() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  external A();
}
''');

    var node = parseResult.findNode.constructor('A()');
    expect(node.firstTokenAfterCommentAndMetadata, node.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_factoryOnly() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw 0;
}
''');

    var node = parseResult.findNode.constructor('A()');
    expect(node.firstTokenAfterCommentAndMetadata, node.factoryKeyword);
  }
}

@reflectiveTest
class FieldFormalParameterTest extends ParserDiagnosticsTest {
  void test_endToken_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int foo;
  A(this.foo);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    expect(node.endToken, node.name);
  }

  void test_endToken_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final Object foo;
  A(this.foo(a, b));
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    expect(node.endToken, node.functionTypedSuffix!.formalParameters.endToken);
  }
}

@reflectiveTest
class FormalParameterIsExplicitlyTypedTest extends ParserDiagnosticsTest {
  test_field_functionTyped_explicitReturn() {
    _checkExplicitlyTyped('''
class C {
  C(int this.x());
  final Object x;
}
''', true);
  }

  test_field_functionTyped_explicitReturn_default() {
    _checkExplicitlyTyped('''
class C {
  C([int this.x() = y]);
  final Object x;
}
''', true);
  }

  test_field_functionTyped_explicitReturn_named() {
    _checkExplicitlyTyped('''
class C {
  C({required int this.x()});
  final Object x;
}
''', true);
  }

  test_field_functionTyped_explicitReturn_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({int this.x() = y});
  final Object x;
}
''', true);
  }

  test_field_functionTyped_implicitReturn() {
    _checkExplicitlyTyped('''
class C {
  C(this.x());
  final Object x;
}
''', true);
  }

  test_field_functionTyped_implicitReturn_default() {
    _checkExplicitlyTyped('''
class C {
  C([this.x() = y]);
  final Object x;
}
''', true);
  }

  test_field_functionTyped_implicitReturn_named() {
    _checkExplicitlyTyped('''
class C {
  C({required this.x()});
  final Object x;
}
''', true);
  }

  test_field_functionTyped_implicitReturn_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({this.x() = y});
  final Object x;
}
''', true);
  }

  test_field_simple_explicit() {
    _checkExplicitlyTyped('''
class C {
  C(int this.x);
  final Object x;
}
''', true);
  }

  test_field_simple_explicit_default() {
    _checkExplicitlyTyped('''
class C {
  C([int this.x = y]);
  final Object x;
}
''', true);
  }

  test_field_simple_explicit_named() {
    _checkExplicitlyTyped('''
class C {
  C({int? this.x});
  final Object? x;
}
''', true);
  }

  test_field_simple_explicit_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({int this.x = y});
  final Object x;
}
''', true);
  }

  test_field_simple_implicit() {
    _checkExplicitlyTyped('''
class C {
  C(this.x);
  final Object x;
}
''', false);
  }

  test_field_simple_implicit_default() {
    _checkExplicitlyTyped('''
class C {
  C([this.x = y]);
  final Object x;
}
''', false);
  }

  test_field_simple_implicit_named() {
    _checkExplicitlyTyped('''
class C {
  C({this.x});
  final Object? x;
}
''', false);
  }

  test_field_simple_implicit_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({this.x = y});
  final Object x;
}
''', false);
  }

  test_functionTyped_explicitReturn() {
    _checkExplicitlyTyped('''
class C {
  C(int x());
}
''', true);
  }

  test_functionTyped_explicitReturn_default() {
    _checkExplicitlyTyped('''
class C {
  C([int x() = y]);
}
''', true);
  }

  test_functionTyped_explicitReturn_named() {
    _checkExplicitlyTyped('''
class C {
  C({required int x()});
}
''', true);
  }

  test_functionTyped_explicitReturn_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({int x() = y});
}
''', true);
  }

  test_functionTyped_implicitReturn() {
    _checkExplicitlyTyped('''
class C {
  C(x());
}
''', true);
  }

  test_functionTyped_implicitReturn_default() {
    _checkExplicitlyTyped('''
class C {
  C([x() = y]);
}
''', true);
  }

  test_functionTyped_implicitReturn_named() {
    _checkExplicitlyTyped('''
class C {
  C({required x()});
}
''', true);
  }

  test_functionTyped_implicitReturn_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({x() = y});
}
''', true);
  }

  test_simple_explicit() {
    _checkExplicitlyTyped('''
class C {
  C(int x);
}
''', true);
  }

  test_simple_explicit_default() {
    _checkExplicitlyTyped('''
class C {
  C([int x = y]);
}
''', true);
  }

  test_simple_explicit_named() {
    _checkExplicitlyTyped('''
class C {
  C({int? x});
}
''', true);
  }

  test_simple_explicit_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({int x = y});
}
''', true);
  }

  test_simple_implicit() {
    _checkExplicitlyTyped('''
class C {
  C(x);
}
''', false);
  }

  test_simple_implicit_default() {
    _checkExplicitlyTyped('''
class C {
  C([x = y]);
}
''', false);
  }

  test_simple_implicit_named() {
    _checkExplicitlyTyped('''
class C {
  C({x});
}
''', false);
  }

  test_simple_implicit_named_default() {
    _checkExplicitlyTyped('''
class C {
  C({x = y});
}
''', false);
  }

  test_super_functionTyped_explicitReturn() {
    _checkExplicitlyTyped('''
class C extends B {
  C(int super.x());
}
''', true);
  }

  test_super_functionTyped_explicitReturn_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C([int super.x() = y]);
}
''', true);
  }

  test_super_functionTyped_explicitReturn_named() {
    _checkExplicitlyTyped('''
class C extends B {
  C({required int super.x()});
}
''', true);
  }

  test_super_functionTyped_explicitReturn_named_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C({int super.x() = y});
}
''', true);
  }

  test_super_functionTyped_implicitReturn() {
    _checkExplicitlyTyped('''
class C extends B {
  C(super.x());
}
''', true);
  }

  test_super_functionTyped_implicitReturn_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C([super.x() = y]);
}
''', true);
  }

  test_super_functionTyped_implicitReturn_named() {
    _checkExplicitlyTyped('''
class C extends B {
  C({required super.x()});
}
''', true);
  }

  test_super_functionTyped_implicitReturn_named_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C({super.x() = y});
}
''', true);
  }

  test_super_simple_explicit() {
    _checkExplicitlyTyped('''
class C extends B {
  C(int super.x);
}
''', true);
  }

  test_super_simple_explicit_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C([int super.x = y]);
}
''', true);
  }

  test_super_simple_explicit_named() {
    _checkExplicitlyTyped('''
class C extends B {
  C({int? super.x});
}
''', true);
  }

  test_super_simple_explicit_named_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C({int super.x = y});
}
''', true);
  }

  test_super_simple_implicit() {
    _checkExplicitlyTyped('''
class C extends B {
  C(super.x);
}
''', false);
  }

  test_super_simple_implicit_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C([super.x = y]);
}
''', false);
  }

  test_super_simple_implicit_named() {
    _checkExplicitlyTyped('''
class C extends B {
  C({super.x});
}
''', false);
  }

  test_super_simple_implicit_named_default() {
    _checkExplicitlyTyped('''
class C extends B {
  C({super.x = y});
}
''', false);
  }

  void _checkExplicitlyTyped(String input, bool expected) {
    var parseResult = parseTestCodeWithDiagnostics(input);
    var class_ = parseResult.unit.declarations[0] as ClassDeclaration;
    var body = class_.body as BlockClassBody;
    var constructor = body.members[0] as ConstructorDeclaration;
    var parameter = constructor.parameters.parameters[0];
    expect(parameter.isExplicitlyTyped, expected);
  }
}

@reflectiveTest
class HideClauseImplTest extends ParserDiagnosticsTest {
  void test_endToken_invalidClass() {
    var parseResult = parseTestCodeWithDiagnostics('''
import 'dart:core' hide int Function();
//                      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.import('import');
    expect(node.combinators[0].endToken, isNotNull);
  }
}

@reflectiveTest
class ImplementsClauseImplTest extends ParserDiagnosticsTest {
  void test_endToken_invalidClass() {
    var parseResult = parseTestCodeWithDiagnostics('''
class A implements C Function() {}
//                 ^^^^^^^^^^^^
// [diag.expectedNamedTypeImplements] Expected the name of a class or mixin.
class C {}
''');
    var node = parseResult.findNode.classDeclaration('A');
    expect(node.implementsClause!.endToken, isNotNull);
  }
}

@reflectiveTest
class IndexExpressionTest extends ParserDiagnosticsTest {
  void test_inGetterContext_assignment_compound_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a[0] += 0;
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inGetterContext(), isTrue);
  }

  void test_inGetterContext_assignment_simple_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a[0] = 0;
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inGetterContext(), isFalse);
  }

  void test_inGetterContext_nonAssignment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a[b] + c;
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inGetterContext(), isTrue);
  }

  void test_inSetterContext_assignment_compound_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a[0] += 0;
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isTrue);
  }

  void test_inSetterContext_assignment_compound_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  b += a[0];
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isFalse);
  }

  void test_inSetterContext_assignment_simple_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a[0] = 0;
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isTrue);
  }

  void test_inSetterContext_assignment_simple_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  b = a[0];
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isFalse);
  }

  void test_inSetterContext_nonAssignment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a[b] + c;
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isFalse);
  }

  void test_inSetterContext_postfix_bang() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a[0]!;
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isFalse);
  }

  void test_inSetterContext_postfix_plusPlus() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a[0]++;
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isTrue);
  }

  void test_inSetterContext_prefix_bang() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  !a[0];
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isFalse);
  }

  void test_inSetterContext_prefix_minusMinus() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  --a[0];
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isTrue);
  }

  void test_inSetterContext_prefix_plusPlus() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  ++a[0];
}
''');
    var node = parseResult.findNode.singleIndexExpression;
    expect(node.inSetterContext(), isTrue);
  }

  void test_isNullAware_cascade_false() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a..[0];
}
''');
    var expression = parseResult.findNode.index('[0]');
    expect(expression.isNullAware, isFalse);
  }

  void test_isNullAware_cascade_true() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?..[0];
}
''');
    var expression = parseResult.findNode.index('[0]');
    expect(expression.isNullAware, isTrue);
  }

  void test_isNullAware_false() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a[0];
}
''');
    var expression = parseResult.findNode.index('[0]');
    expect(expression.isNullAware, isFalse);
  }

  void test_isNullAware_true() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?[0];
}
''');
    var expression = parseResult.findNode.index('[0]');
    expect(expression.isNullAware, isTrue);
  }
}

@reflectiveTest
class InterpolationStringTest extends ParserDiagnosticsTest {
  void test_contentsOffset_doubleQuote_first() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "foo$x last";
''');
    var node = parseResult.findNode.singleStringInterpolation.firstString;
    _assertContentsOffsetEnd(node, 9, 12);
  }

  void test_contentsOffset_doubleQuote_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "first $x foo";
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 17, 21);
  }

  void test_contentsOffset_doubleQuote_last_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "first $x";
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 17, 17);
  }

  void test_contentsOffset_doubleQuote_last_unterminated() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "first $x foo
//               ^^^^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 17, 21);
  }

  void test_contentsOffset_doubleQuote_multiline_first() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = """foo
$x last""";
''');
    var node = parseResult.findNode.singleStringInterpolation.firstString;
    _assertContentsOffsetEnd(node, 11, 15);
  }

  void test_contentsOffset_doubleQuote_multiline_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = """first$x foo
""";
    ''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 18, 23);
  }

  void test_contentsOffset_doubleQuote_multiline_last_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = """first$x""";
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 18, 18);
  }

  void test_contentsOffset_doubleQuote_multiline_last_unterminated() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = """first$x foo
//                ^^^^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 18, 22);
  }

  void test_contentsOffset_escapeCharacters() {
    // Contents offset cannot use 'value' string, because of escape sequences.
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "foo\nbar$x last";
''');
    var node = parseResult.findNode.singleStringInterpolation.firstString;
    _assertContentsOffsetEnd(node, 9, 17);
  }

  void test_contentsOffset_middle() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "first $x foo\nbar $y last";
''');
    var interpolation = parseResult.findNode.singleStringInterpolation;
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 17, 27);
  }

  void test_contentsOffset_middle_quoteBegin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "first $x 'foo$y last";
''');
    var interpolation = parseResult.findNode.singleStringInterpolation;
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 17, 22);
  }

  void test_contentsOffset_middle_quoteBeginEnd() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "first $x 'foo'$y last";
''');
    var interpolation = parseResult.findNode.singleStringInterpolation;
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 17, 23);
  }

  void test_contentsOffset_middle_quoteEnd() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = "first $x foo'$y last";
''');
    var interpolation = parseResult.findNode.singleStringInterpolation;
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 17, 22);
  }

  void test_contentsOffset_singleQuote_first() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = 'foo$x last';
''');
    var node = parseResult.findNode.singleStringInterpolation.firstString;
    _assertContentsOffsetEnd(node, 9, 12);
  }

  void test_contentsOffset_singleQuote_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = 'first $x foo';
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 17, 21);
  }

  void test_contentsOffset_singleQuote_last_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = 'first $x';
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 17, 17);
  }

  void test_contentsOffset_singleQuote_last_unterminated() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = 'first $x
//              ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
//               ^
// [diag.expectedToken][column 18][length 0] Expected to find ';'.
''');
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 17, 17);
  }

  void test_contentsOffset_singleQuote_multiline_first() {
    var parseResult = parseTestCodeWithDiagnostics(r"""
var x = '''foo
$x last''';
""");
    var node = parseResult.findNode.singleStringInterpolation.firstString;
    _assertContentsOffsetEnd(node, 11, 15);
  }

  void test_contentsOffset_singleQuote_multiline_last() {
    var parseResult = parseTestCodeWithDiagnostics(r"""
var x = '''first$x foo
''';
""");
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 18, 23);
  }

  void test_contentsOffset_singleQuote_multiline_last_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r"""
var x = '''first$x''';
""");
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 18, 18);
  }

  void test_contentsOffset_singleQuote_multiline_last_unterminated() {
    var parseResult = parseTestCodeWithDiagnostics(r"""
var x = '''first$x''';
""");
    var node = parseResult.findNode.singleStringInterpolation.lastString;
    _assertContentsOffsetEnd(node, 18, 18);
  }

  void _assertContentsOffsetEnd(InterpolationString node, int offset, int end) {
    expect(node.contentsOffset, offset);
    expect(node.contentsEnd, end);
  }
}

@reflectiveTest
class MethodDeclarationTest extends ParserDiagnosticsTest {
  void test_firstTokenAfterCommentAndMetadata_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  external void foo();
}
''');

    var node = parseResult.findNode.methodDeclaration('foo()');
    expect(node.firstTokenAfterCommentAndMetadata, node.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_external_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  external get foo;
}
''');

    var node = parseResult.findNode.methodDeclaration('get foo');
    expect(node.firstTokenAfterCommentAndMetadata, node.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_external_operator() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  external operator +(int other);
}
''');

    var node = parseResult.findNode.methodDeclaration('external operator');
    expect(node.firstTokenAfterCommentAndMetadata, node.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  get foo => 0;
}
''');

    var node = parseResult.findNode.methodDeclaration('get foo');
    expect(node.firstTokenAfterCommentAndMetadata, node.propertyKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_operator() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  operator +(int other) => 0;
}
''');

    var node = parseResult.findNode.methodDeclaration('operator');
    expect(node.firstTokenAfterCommentAndMetadata, node.operatorKeyword);
  }
}

@reflectiveTest
class MethodInvocationTest extends ParserDiagnosticsTest {
  void test_isNullAware_cascade() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a..foo();
}
''');
    var invocation = parseResult.findNode.methodInvocation('foo');
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_cascade_true() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?..foo();
}
''');
    var invocation = parseResult.findNode.methodInvocation('foo');
    expect(invocation.isNullAware, isTrue);
  }

  void test_isNullAware_regularInvocation() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a.foo();
}
''');
    var invocation = parseResult.findNode.methodInvocation('foo');
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_true() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?.foo();
}
''');
    var invocation = parseResult.findNode.methodInvocation('foo');
    expect(invocation.isNullAware, isTrue);
  }
}

@reflectiveTest
class NodeListTest extends ParserDiagnosticsTest {
  void test_getBeginToken_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = f();
''');

    var argumentList = parseResult.findNode.argumentList('()');
    var nodeList = argumentList.arguments;
    expect(nodeList.beginToken, isNull);
  }

  void test_getBeginToken_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = f(0, 1);
''');

    var argumentList = parseResult.findNode.argumentList('(0');
    var nodeList = argumentList.arguments;
    var first = nodeList[0];
    expect(nodeList.beginToken, same(first.beginToken));
  }

  void test_getEndToken_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = f();
''');

    var argumentList = parseResult.findNode.argumentList('()');
    var nodeList = argumentList.arguments;
    expect(nodeList.endToken, isNull);
  }

  void test_getEndToken_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = f(0, 1);
''');

    var argumentList = parseResult.findNode.argumentList('(0');
    var nodeList = argumentList.arguments;
    var last = nodeList[nodeList.length - 1];
    expect(nodeList.endToken, same(last.endToken));
  }

  void test_indexOf() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = f(0, 1, 2);
final y = 42;
''');

    var argumentList = parseResult.findNode.argumentList('(0');
    var nodeList = argumentList.arguments;

    var first = nodeList[0];
    var second = nodeList[1];
    var third = nodeList[2];

    expect(nodeList, hasLength(3));
    expect(nodeList.indexOf(first), 0);
    expect(nodeList.indexOf(second), 1);
    expect(nodeList.indexOf(third), 2);

    var notInList = parseResult.findNode.integerLiteral('42');
    expect(nodeList.indexOf(notInList), -1);
  }

  void test_set_negative() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = f(0);
final y = 42;
''');

    var argumentList = parseResult.findNode.argumentList('(0');
    var nodeList = argumentList.arguments;

    try {
      nodeList[-1] = nodeList.first;
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_set_tooBig() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = f(0);
final y = 42;
''');

    var argumentList = parseResult.findNode.argumentList('(0');
    var nodeList = argumentList.arguments;
    try {
      nodeList[1] = nodeList.first;
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }
}

@reflectiveTest
class NormalFormalParameterTest extends ParserDiagnosticsTest {
  test_sortedCommentAndAnnotations_noComment() {
    var result = parseTestCodeWithDiagnostics('''
void f(int i) {}
''');
    var function = result.unit.declarations[0] as FunctionDeclaration;
    var parameters = function.functionExpression.parameters;
    var parameter = parameters?.parameters[0] as FormalParameter;
    expect(parameter.sortedCommentAndAnnotations, isEmpty);
  }
}

@reflectiveTest
class OnClauseImplTest extends ParserDiagnosticsTest {
  void test_endToken_invalidClass() {
    var parseResult = parseTestCodeWithDiagnostics('''
mixin M on C Function() {}
//         ^^^^^^^^^^^^
// [diag.expectedNamedTypeOn] Expected the name of a class or mixin.
class C {}
''');
    var node = parseResult.findNode.mixinDeclaration('M');
    expect(node.onClause!.endToken, isNotNull);
  }
}

@reflectiveTest
class PreviousTokenTest extends ParserDiagnosticsTest {
  static final String contents = '''
class A {
  B foo(C c) {
    return bar;
  }
  D get baz => null;
}
E f() => g;
''';

  CompilationUnit? _unit;

  CompilationUnit get unit {
    return _unit ??= parseTestCodeWithDiagnostics(contents).unit;
  }

  Token findToken(String lexeme) {
    Token token = unit.beginToken;
    while (!token.isEof) {
      if (token.lexeme == lexeme) {
        return token;
      }
      token = token.next!;
    }
    fail('Failed to find $lexeme');
  }

  void test_findPrevious_basic_class() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    expect(clazz.findPrevious(findToken('A'))!.lexeme, 'class');
  }

  void test_findPrevious_basic_method() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var body = clazz.body as BlockClassBody;
    var method = body.members[0] as MethodDeclaration;
    expect(method.findPrevious(findToken('foo'))!.lexeme, 'B');
  }

  void test_findPrevious_basic_statement() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var classBody = clazz.body as BlockClassBody;
    var method = classBody.members[0] as MethodDeclaration;
    var body = method.body as BlockFunctionBody;
    Statement statement = body.block.statements[0];
    expect(statement.findPrevious(findToken('bar'))!.lexeme, 'return');
    expect(statement.findPrevious(findToken(';'))!.lexeme, 'bar');
  }

  void test_findPrevious_missing() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var classBody = clazz.body as BlockClassBody;
    var method = classBody.members[0] as MethodDeclaration;
    var body = method.body as BlockFunctionBody;
    Statement statement = body.block.statements[0];

    var missing = parseTestCodeWithDiagnostics(r'''
missing
// [diag.missingConstFinalVarOrType][column 1][length 7] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
''').unit.beginToken;
    expect(statement.findPrevious(missing), null);
  }

  void test_findPrevious_parent_method() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var classBody = clazz.body as BlockClassBody;
    var method = classBody.members[0] as MethodDeclaration;
    expect(method.findPrevious(findToken('B'))!.lexeme, '{');
  }

  void test_findPrevious_parent_statement() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var classBody = clazz.body as BlockClassBody;
    var method = classBody.members[0] as MethodDeclaration;
    var body = method.body as BlockFunctionBody;
    Statement statement = body.block.statements[0];
    expect(statement.findPrevious(findToken('return'))!.lexeme, '{');
  }

  void test_findPrevious_sibling_class() {
    CompilationUnitMember declaration = unit.declarations[1];
    expect(declaration.findPrevious(findToken('E'))!.lexeme, '}');
  }

  void test_findPrevious_sibling_method() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var classBody = clazz.body as BlockClassBody;
    var method = classBody.members[1] as MethodDeclaration;
    expect(method.findPrevious(findToken('D'))!.lexeme, '}');
  }
}

@reflectiveTest
class PropertyAccessTest extends ParserDiagnosticsTest {
  void test_isNullAware_cascade() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a..foo;
}
''');
    var invocation = parseResult.findNode.propertyAccess('foo');
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_cascade_true() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?..foo;
}
''');
    var invocation = parseResult.findNode.propertyAccess('foo');
    expect(invocation.isNullAware, isTrue);
  }

  void test_isNullAware_regularPropertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  (a).foo;
}
''');
    var invocation = parseResult.findNode.propertyAccess('foo');
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_true() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?.foo;
}
''');
    var invocation = parseResult.findNode.propertyAccess('foo');
    expect(invocation.isNullAware, isTrue);
  }
}

@reflectiveTest
class ShowClauseImplTest extends ParserDiagnosticsTest {
  void test_endToken_invalidClass() {
    var parseResult = parseTestCodeWithDiagnostics('''
import 'dart:core' show int Function();
//                      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.import('import');
    expect(node.combinators[0].endToken, isNotNull);
  }
}

@reflectiveTest
class SimpleIdentifierTest extends ParserDiagnosticsTest {
  void test_inGetterContext() {
    for (_WrapperKind wrapper in _WrapperKind.values) {
      for (_AssignmentKind assignment in _AssignmentKind.values) {
        SimpleIdentifier identifier = _createIdentifier(wrapper, assignment);
        if (assignment == _AssignmentKind.SIMPLE_LEFT &&
            wrapper != _WrapperKind.PREFIXED_LEFT &&
            wrapper != _WrapperKind.PROPERTY_LEFT) {
          if (identifier.inGetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be false");
          }
        } else {
          if (!identifier.inGetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be true");
          }
        }
      }
    }
  }

  void test_inGetterContext_constructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A() : f = 0;
}
''');
    var initializer = parseResult.findNode.singleConstructorFieldInitializer;
    SimpleIdentifier identifier = initializer.fieldName;
    expect(identifier.inGetterContext(), isFalse);
  }

  void test_inGetterContext_forEachLoop() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for (v in [0]) {}
}
''');
    var identifier = parseResult.findNode.simple('v in');
    expect(identifier.inGetterContext(), isFalse);
  }

  void test_inSetterContext() {
    for (_WrapperKind wrapper in _WrapperKind.values) {
      for (_AssignmentKind assignment in _AssignmentKind.values) {
        SimpleIdentifier identifier = _createIdentifier(wrapper, assignment);
        if (wrapper == _WrapperKind.PREFIXED_LEFT ||
            wrapper == _WrapperKind.PROPERTY_LEFT ||
            assignment == _AssignmentKind.BINARY ||
            assignment == _AssignmentKind.COMPOUND_RIGHT ||
            assignment == _AssignmentKind.POSTFIX_BANG ||
            assignment == _AssignmentKind.PREFIX_NOT ||
            assignment == _AssignmentKind.SIMPLE_RIGHT) {
          if (identifier.inSetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be false");
          }
        } else {
          if (!identifier.inSetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be true");
          }
        }
      }
    }
  }

  void test_inSetterContext_forEachLoop() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for (v in [0]) {}
}
''');
    var identifier = parseResult.findNode.simple('v in');
    expect(identifier.inSetterContext(), isTrue);
  }

  void test_isQualified_inConstructorName() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = List<String>.foo();
''');
    var constructor = parseResult.findNode.singleConstructorName;
    var name = constructor.name!;
    expect(name.isQualified, isTrue);
  }

  void test_isQualified_inMethodInvocation_noTarget() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  foo(0);
}
''');
    var invocation = parseResult.findNode.methodInvocation('foo');
    var identifier = invocation.methodName;
    expect(identifier.isQualified, isFalse);
  }

  void test_isQualified_inMethodInvocation_withTarget() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a.foo();
}
''');
    var invocation = parseResult.findNode.methodInvocation('foo');
    var identifier = invocation.methodName;
    expect(identifier.isQualified, isTrue);
  }

  void test_isQualified_inPrefixedIdentifier_name() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  prefix.foo;
}
''');
    var identifier = parseResult.findNode.simple('foo');
    expect(identifier.isQualified, isTrue);
  }

  void test_isQualified_inPrefixedIdentifier_prefix() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  prefix.foo;
}
''');
    var identifier = parseResult.findNode.simple('prefix');
    expect(identifier.isQualified, isFalse);
  }

  void test_isQualified_inPropertyAccess_name() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  prefix?.foo;
}
''');
    var identifier = parseResult.findNode.simple('foo');
    expect(identifier.isQualified, isTrue);
  }

  void test_isQualified_inPropertyAccess_target() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  prefix?.foo;
}
''');
    var identifier = parseResult.findNode.simple('prefix');
    expect(identifier.isQualified, isFalse);
  }

  void test_isQualified_inReturnStatement() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  return test;
}
''');
    var identifier = parseResult.findNode.simple('test');
    expect(identifier.isQualified, isFalse);
  }

  SimpleIdentifier _createIdentifier(
    _WrapperKind wrapper,
    _AssignmentKind assignment,
  ) {
    String code;
    if (wrapper == _WrapperKind.PREFIXED_LEFT) {
      code = 'test.right';
    } else if (wrapper == _WrapperKind.PREFIXED_RIGHT) {
      code = 'left.test';
    } else if (wrapper == _WrapperKind.PROPERTY_LEFT) {
      code = 'test?.right';
    } else if (wrapper == _WrapperKind.PROPERTY_RIGHT) {
      code = 'left?.test';
    } else {
      throw UnimplementedError();
    }

    if (assignment == _AssignmentKind.BINARY) {
      code = '$code + 0';
    } else if (assignment == _AssignmentKind.COMPOUND_LEFT) {
      code = '$code += 0';
    } else if (assignment == _AssignmentKind.COMPOUND_RIGHT) {
      code = 'other += $code';
    } else if (assignment == _AssignmentKind.POSTFIX_BANG) {
      code = '$code!';
    } else if (assignment == _AssignmentKind.POSTFIX_INC) {
      code = '$code++';
    } else if (assignment == _AssignmentKind.PREFIX_DEC) {
      code = '--$code';
    } else if (assignment == _AssignmentKind.PREFIX_INC) {
      code = '++$code';
    } else if (assignment == _AssignmentKind.PREFIX_NOT) {
      code = '!$code';
    } else if (assignment == _AssignmentKind.SIMPLE_LEFT) {
      code = '$code = 0';
    } else if (assignment == _AssignmentKind.SIMPLE_RIGHT) {
      code = 'other = $code';
    } else {
      throw UnimplementedError();
    }

    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    return parseResult.findNode.simple('test');
  }

  /// Return the top-most node in the AST structure containing the given
  /// identifier.
  ///
  /// @param identifier the identifier in the AST structure being traversed
  /// @return the root of the AST structure containing the identifier
  AstNode _topMostNode(SimpleIdentifier identifier) {
    AstNode child = identifier;
    var parent = identifier.parent;
    while (parent != null) {
      child = parent;
      parent = parent.parent;
    }
    return child;
  }
}

@reflectiveTest
class SimpleStringLiteralTest extends ParserDiagnosticsTest {
  void test_contentsEnd() {
    void assertContentsEnd(String code, int expected) {
      var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
      var node = parseResult.findNode.simpleStringLiteral(code);
      expect(node.contentsEnd - node.offset, expected);
    }

    assertContentsEnd("'X'", 2);
    assertContentsEnd('"X"', 2);

    assertContentsEnd('"""X"""', 4);
    assertContentsEnd("'''X'''", 4);

    assertContentsEnd("'''  \nX'''", 7);
    assertContentsEnd('"""  \nX"""', 7);

    assertContentsEnd("r'X'", 3);
    assertContentsEnd('r"X"', 3);

    assertContentsEnd('r"""X"""', 5);
    assertContentsEnd("r'''X'''", 5);

    assertContentsEnd("r'''  \nX'''", 8);
    assertContentsEnd('r"""  \nX"""', 8);
  }

  void test_contentsOffset() {
    void assertContentsOffset(String code, int expected) {
      var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
      var node = parseResult.findNode.simpleStringLiteral(code);
      expect(node.contentsOffset - node.offset, expected);
    }

    assertContentsOffset("'X'", 1);
    assertContentsOffset('"X"', 1);

    assertContentsOffset('"""X"""', 3);
    assertContentsOffset("'''X'''", 3);

    assertContentsOffset("'''  \nX'''", 6);
    assertContentsOffset('"""  \nX"""', 6);

    assertContentsOffset("r'X'", 2);
    assertContentsOffset('r"X"', 2);

    assertContentsOffset("r'''  \nX'''", 7);
    assertContentsOffset('r"""  \nX"""', 7);

    assertContentsOffset('r"""X"""', 4);
    assertContentsOffset("r'''X'''", 4);
  }

  void test_isMultiline() {
    void assertIsMultiline(String code, bool expected) {
      var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
      var node = parseResult.findNode.simpleStringLiteral(code);
      expect(node.isMultiline, expected);
    }

    assertIsMultiline("'X'", false);
    assertIsMultiline("r'X'", false);

    assertIsMultiline('"X"', false);
    assertIsMultiline('r"X"', false);

    assertIsMultiline("'''X'''", true);
    assertIsMultiline("r'''X'''", true);

    assertIsMultiline('"""X"""', true);
    assertIsMultiline('r"""X"""', true);
  }

  void test_isRaw() {
    void assertIsRaw(String code, bool expected) {
      var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
      var node = parseResult.findNode.simpleStringLiteral(code);
      expect(node.isRaw, expected);
    }

    assertIsRaw("'X'", false);
    assertIsRaw("r'X'", true);

    assertIsRaw('"X"', false);
    assertIsRaw('r"X"', true);

    assertIsRaw("'''X'''", false);
    assertIsRaw("r'''X'''", true);

    assertIsRaw('"""X"""', false);
    assertIsRaw('r"""X"""', true);
  }

  void test_isSingleQuoted() {
    void assertIsSingleQuoted(String code, bool expected) {
      var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
      var node = parseResult.findNode.simpleStringLiteral(code);
      expect(node.isSingleQuoted, expected);
    }

    assertIsSingleQuoted("'X'", true);
    assertIsSingleQuoted("r'X'", true);

    assertIsSingleQuoted('"X"', false);
    assertIsSingleQuoted('r"X"', false);

    assertIsSingleQuoted("'''X'''", true);
    assertIsSingleQuoted("r'''X'''", true);

    assertIsSingleQuoted('"""X"""', false);
    assertIsSingleQuoted('r"""X"""', false);
  }
}

@reflectiveTest
class SpreadElementTest extends ParserDiagnosticsTest {
  void test_notNullAwareSpread() {
    var parseResult = parseTestCodeWithDiagnostics('''
final x = [...foo];
''');
    var spread = parseResult.findNode.spreadElement('...foo');
    expect(spread.isNullAware, isFalse);
  }

  void test_nullAwareSpread() {
    var parseResult = parseTestCodeWithDiagnostics('''
final x = [...?foo];
''');
    var spread = parseResult.findNode.spreadElement('...?foo');
    expect(spread.isNullAware, isTrue);
  }
}

@reflectiveTest
class StringInterpolationTest extends ParserDiagnosticsTest {
  void test_contentsOffsetEnd() {
    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = 'a${bb}ccc';
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.contentsOffset, 11);
      expect(node.contentsEnd, 20);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r"""
final v = '''a${bb}ccc''';
""");
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.contentsOffset, 13);
      expect(node.contentsEnd, 22);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = """a${bb}ccc""";
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.contentsOffset, 13);
      expect(node.contentsEnd, 22);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = r'a${bb}ccc';
''');
      var node = parseResult.findNode.simpleStringLiteral('ccc');
      expect(node.contentsOffset, 12);
      expect(node.contentsEnd, 21);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r"""
final v = r'''a${bb}ccc''';
""");
      var node = parseResult.findNode.simpleStringLiteral('ccc');
      expect(node.contentsOffset, 14);
      expect(node.contentsEnd, 23);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = r"""a${bb}ccc""";
''');
      var node = parseResult.findNode.simpleStringLiteral('ccc');
      expect(node.contentsOffset, 14);
      expect(node.contentsEnd, 23);
    }
  }

  void test_isMultiline() {
    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = 'a${bb}ccc';
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isMultiline, isFalse);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = "a${bb}ccc";
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isMultiline, isFalse);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r"""
final v = '''a${bb}ccc''';
""");
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isMultiline, isTrue);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = """a${bb}ccc""";
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isMultiline, isTrue);
    }
  }

  void test_isRaw() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final v = 'a${bb}ccc';
''');
    var node = parseResult.findNode.stringInterpolation('ccc');
    expect(node.isRaw, isFalse);
  }

  void test_isSingleQuoted() {
    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = 'a${bb}ccc';
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isSingleQuoted, isTrue);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r"""
final v = '''a${bb}ccc''';
""");
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isSingleQuoted, isTrue);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = "a${bb}ccc";
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isSingleQuoted, isFalse);
    }

    {
      var parseResult = parseTestCodeWithDiagnostics(r'''
final v = """a${bb}ccc""";
''');
      var node = parseResult.findNode.stringInterpolation('ccc');
      expect(node.isSingleQuoted, isFalse);
    }
  }

  void test_this_followedByDollar() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void m(int foo) {
    '$this$foo';
  }
}
''');
    var node = parseResult.findNode.stringInterpolation('this');
    assertParsedNodeText(node, r'''
StringInterpolation
  elements
    InterpolationString
      contents: '
    InterpolationExpression
      leftBracket: $
      expression: ThisExpression
        thisKeyword: this
    InterpolationString
      contents: <empty> <synthetic>
    InterpolationExpression
      leftBracket: $
      expression: SimpleIdentifier
        token: foo
    InterpolationString
      contents: '
  stringValue: null
''');
  }
}

@reflectiveTest
class SuperFormalParameterTest extends ParserDiagnosticsTest {
  void test_endToken_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(super.foo);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    expect(node.endToken, node.name);
  }

  void test_endToken_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(super.foo(a, b));
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    expect(node.endToken, node.functionTypedSuffix!.formalParameters.endToken);
  }
}

@reflectiveTest
class VariableDeclarationTest extends ParserDiagnosticsTest {
  void test_getDocumentationComment_onGrandParent() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
var a = 0;
''');
    var node = parseResult.findNode.variableDeclaration('a =');
    expect(node.documentationComment, isNotNull);
  }

  test_sortedCommentAndAnnotations_noComment() {
    var parseResult = parseTestCodeWithDiagnostics('''
var a = 0;
''');
    var variable = parseResult.findNode.variableDeclaration('a =');
    expect(variable.sortedCommentAndAnnotations, isEmpty);
  }
}

@reflectiveTest
class WithClauseImplTest extends ParserDiagnosticsTest {
  void test_endToken_invalidClass() {
    var parseResult = parseTestCodeWithDiagnostics('''
class A with C Function() {}
//           ^^^^^^^^^^^^
// [diag.expectedNamedTypeWith] Expected a mixin name.
class C {}
''');
    var node = parseResult.findNode.classDeclaration('A');
    expect(node.withClause!.endToken, isNotNull);
  }
}

class _AssignmentKind {
  static const _AssignmentKind BINARY = _AssignmentKind('BINARY', 0);

  static const _AssignmentKind COMPOUND_LEFT = _AssignmentKind(
    'COMPOUND_LEFT',
    1,
  );

  static const _AssignmentKind COMPOUND_RIGHT = _AssignmentKind(
    'COMPOUND_RIGHT',
    2,
  );

  static const _AssignmentKind POSTFIX_BANG = _AssignmentKind('POSTFIX_INC', 3);

  static const _AssignmentKind POSTFIX_INC = _AssignmentKind('POSTFIX_INC', 4);

  static const _AssignmentKind PREFIX_DEC = _AssignmentKind('PREFIX_DEC', 5);

  static const _AssignmentKind PREFIX_INC = _AssignmentKind('PREFIX_INC', 6);

  static const _AssignmentKind PREFIX_NOT = _AssignmentKind('PREFIX_NOT', 7);

  static const _AssignmentKind SIMPLE_LEFT = _AssignmentKind('SIMPLE_LEFT', 8);

  static const _AssignmentKind SIMPLE_RIGHT = _AssignmentKind(
    'SIMPLE_RIGHT',
    9,
  );

  static const List<_AssignmentKind> values = [
    BINARY,
    COMPOUND_LEFT,
    COMPOUND_RIGHT,
    POSTFIX_BANG,
    POSTFIX_INC,
    PREFIX_DEC,
    PREFIX_INC,
    PREFIX_NOT,
    SIMPLE_LEFT,
    SIMPLE_RIGHT,
  ];

  final String name;

  final int ordinal;

  const _AssignmentKind(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  int compareTo(_AssignmentKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

class _WrapperKind {
  static const _WrapperKind PREFIXED_LEFT = _WrapperKind('PREFIXED_LEFT', 0);

  static const _WrapperKind PREFIXED_RIGHT = _WrapperKind('PREFIXED_RIGHT', 1);

  static const _WrapperKind PROPERTY_LEFT = _WrapperKind('PROPERTY_LEFT', 2);

  static const _WrapperKind PROPERTY_RIGHT = _WrapperKind('PROPERTY_RIGHT', 3);

  static const List<_WrapperKind> values = [
    PREFIXED_LEFT,
    PREFIXED_RIGHT,
    PROPERTY_LEFT,
    PROPERTY_RIGHT,
  ];

  final String name;

  final int ordinal;

  const _WrapperKind(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  int compareTo(_WrapperKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}
