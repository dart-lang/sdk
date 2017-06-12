// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.utilities_test;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstClonerTest);
    defineReflectiveTests(BooleanArrayTest);
    defineReflectiveTests(DirectedGraphTest);
    defineReflectiveTests(ExceptionHandlingDelegatingAstVisitorTest);
    defineReflectiveTests(LineInfoTest);
    defineReflectiveTests(MultipleMapIteratorTest);
    defineReflectiveTests(NodeReplacerTest);
    defineReflectiveTests(SingleMapIteratorTest);
    defineReflectiveTests(SourceRangeTest);
    defineReflectiveTests(StringUtilitiesTest);
    defineReflectiveTests(TokenMapTest);
  });
}

class AstCloneComparator extends AstComparator {
  final bool expectTokensCopied;

  AstCloneComparator(this.expectTokensCopied);

  @override
  bool isEqualNodes(AstNode first, AstNode second) {
    if (first != null && identical(first, second)) {
      fail('Failed to copy node: $first (${first.offset})');
      return false;
    }
    return super.isEqualNodes(first, second);
  }

  @override
  bool isEqualTokens(Token first, Token second) {
    if (expectTokensCopied && first != null && identical(first, second)) {
      fail('Failed to copy token: ${first.lexeme} (${first.offset})');
      return false;
    }
    if (first?.precedingComments != null) {
      CommentToken comment = first.precedingComments;
      if (comment.parent != first) {
        fail('Failed to link the comment "$comment" with the token "$first".');
      }
    }
    return super.isEqualTokens(first, second);
  }
}

@reflectiveTest
class AstClonerTest extends EngineTestCase {
  void test_visitAdjacentStrings() {
    _assertCloneExpression("'a' 'b'");
  }

  void test_visitAnnotation_constant() {
    _assertCloneUnitMember('@A main() {}');
  }

  void test_visitAnnotation_constructor() {
    _assertCloneUnitMember('@A.c() main() {}');
  }

  void test_visitAnnotation_withComment() {
    CompilationUnitMember clazz =
        _parseUnitMember('/** comment */ @deprecated class A {}');
    Annotation annotation = clazz.metadata.single;
    _assertClone(annotation);
  }

  void test_visitArgumentList() {
    _assertCloneExpression('m(a, b)');
  }

  void test_visitAsExpression() {
    _assertCloneExpression('e as T');
  }

  void test_visitAssertStatement() {
    _assertCloneStatement('assert(a);');
  }

  void test_visitAssignmentExpression() {
    _assertCloneStatement('a = b;');
  }

  void test_visitAwaitExpression() {
    _assertCloneStatement('await a;');
  }

  void test_visitBinaryExpression() {
    _assertCloneExpression('a + b');
  }

  void test_visitBlock_empty() {
    _assertCloneStatement('{}');
  }

  void test_visitBlock_nonEmpty() {
    _assertCloneStatement('{ print(1); print(2); }');
  }

  void test_visitBlockFunctionBody() {
    _assertCloneUnitMember('main() {}');
  }

  void test_visitBooleanLiteral_false() {
    _assertCloneExpression('false');
  }

  void test_visitBooleanLiteral_true() {
    _assertCloneExpression('true');
  }

  void test_visitBreakStatement_label() {
    _assertCloneStatement('l: while(true) { break l; }');
  }

  void test_visitBreakStatement_noLabel() {
    _assertCloneStatement('while(true) { break; }');
  }

  void test_visitCascadeExpression_field() {
    _assertCloneExpression('a..b..c');
  }

  void test_visitCascadeExpression_index() {
    _assertCloneExpression('a..[0]..[1]');
  }

  void test_visitCascadeExpression_method() {
    _assertCloneExpression('a..b()..c()');
  }

  void test_visitCatchClause_catch_noStack() {
    _assertCloneStatement('try {} catch (e) {}');
  }

  void test_visitCatchClause_catch_stack() {
    _assertCloneStatement('try {} catch (e, s) {}');
  }

  void test_visitCatchClause_on() {
    _assertCloneStatement('try {} on E {}');
  }

  void test_visitCatchClause_on_catch() {
    _assertCloneStatement('try {} on E catch (e) {}');
  }

  void test_visitClassDeclaration_abstract() {
    _assertCloneUnitMember('abstract class C {}');
  }

  void test_visitClassDeclaration_empty() {
    _assertCloneUnitMember('class C {}');
  }

  void test_visitClassDeclaration_extends() {
    _assertCloneUnitMember('class C extends A {}');
  }

  void test_visitClassDeclaration_extends_implements() {
    _assertCloneUnitMember('class C extends A implements B {}');
  }

  void test_visitClassDeclaration_extends_with() {
    _assertCloneUnitMember('class C extends A with M {}');
  }

  void test_visitClassDeclaration_extends_with_implements() {
    _assertCloneUnitMember('class C extends A with M implements B {}');
  }

  void test_visitClassDeclaration_implements() {
    _assertCloneUnitMember('class C implements B {}');
  }

  void test_visitClassDeclaration_multipleMember() {
    _assertCloneUnitMember('class C { var a;  var b; }');
  }

  void test_visitClassDeclaration_parameters() {
    _assertCloneUnitMember('class C<E> {}');
  }

  void test_visitClassDeclaration_parameters_extends() {
    _assertCloneUnitMember('class C<E> extends A {}');
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    _assertCloneUnitMember('class C<E> extends A implements B {}');
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    _assertCloneUnitMember('class C<E> extends A with M {}');
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    _assertCloneUnitMember('class C<E> extends A with M implements B {}');
  }

  void test_visitClassDeclaration_parameters_implements() {
    _assertCloneUnitMember('class C<E> implements B {}');
  }

  void test_visitClassDeclaration_singleMember() {
    _assertCloneUnitMember('class C { var a; }');
  }

  void test_visitClassDeclaration_withMetadata() {
    _assertCloneUnitMember('@deprecated class C {}');
  }

  void test_visitClassTypeAlias_abstract() {
    _assertCloneUnitMember('abstract class C = S with M1;');
  }

  void test_visitClassTypeAlias_abstract_implements() {
    _assertCloneUnitMember('abstract class C = S with M1 implements I;');
  }

  void test_visitClassTypeAlias_generic() {
    _assertCloneUnitMember('class C<E> = S<E> with M1<E>;');
  }

  void test_visitClassTypeAlias_implements() {
    _assertCloneUnitMember('class C = S with M1 implements I;');
  }

  void test_visitClassTypeAlias_minimal() {
    _assertCloneUnitMember('class C = S with M1;');
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    _assertCloneUnitMember('abstract class C = S<E> with M1;');
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    _assertCloneUnitMember('abstract class C = S<E> with M1 implements I;');
  }

  void test_visitClassTypeAlias_parameters_implements() {
    _assertCloneUnitMember('class C = S<E> with M1 implements I;');
  }

  void test_visitClassTypeAlias_withMetadata() {
    _assertCloneUnitMember('@deprecated class C = S with M;');
  }

  void test_visitComment() {
    _assertCloneUnitMember('main() { print(1);  /* comment */  print(2); }');
  }

  void test_visitComment_beginToken() {
    _assertCloneUnitMember('/** comment */ main() {}');
  }

  void test_visitCommentReference() {
    _assertCloneUnitMember('/** ref [a]. */ main(a) {}');
  }

  void test_visitCompilationUnit_declaration() {
    _assertCloneUnitMember('var a;');
  }

  void test_visitCompilationUnit_directive() {
    _assertCloneUnit('library l;');
  }

  void test_visitCompilationUnit_directive_declaration() {
    _assertCloneUnit('library l;  var a;');
  }

  void test_visitCompilationUnit_directive_withComment() {
    _assertCloneUnit(r'''
/// aaa
/// bbb
library l;''');
  }

  void test_visitCompilationUnit_empty() {
    _assertCloneUnit('');
  }

  void test_visitCompilationUnit_script() {
    _assertCloneUnit('#!/bin/dartvm');
  }

  void test_visitCompilationUnit_script_declaration() {
    _assertCloneUnit('#!/bin/dartvm \n var a;');
  }

  void test_visitCompilationUnit_script_directive() {
    _assertCloneUnit('#!/bin/dartvm \n library l;');
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    _assertCloneUnit('#!/bin/dartvm \n library l;  var a;');
  }

  void test_visitConditionalExpression() {
    _assertCloneExpression('a ? b : c');
  }

  void test_visitConstructorDeclaration_const() {
    _assertCloneUnitMember('class C { const C(); }');
  }

  void test_visitConstructorDeclaration_external() {
    _assertCloneUnitMember('class C { external C(); }');
  }

  void test_visitConstructorDeclaration_minimal() {
    _assertCloneUnitMember('class C { C() {} }');
  }

  void test_visitConstructorDeclaration_multipleInitializers() {
    _assertCloneUnitMember('class C { C() : a = b, c = d {} }');
  }

  void test_visitConstructorDeclaration_multipleParameters() {
    _assertCloneUnitMember('class C { C(var a, var b) {} }');
  }

  void test_visitConstructorDeclaration_named() {
    _assertCloneUnitMember('class C { C.m() {} }');
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    _assertCloneUnitMember('class C { C() : a = b {} }');
  }

  void test_visitConstructorDeclaration_withMetadata() {
    _assertCloneUnitMember('class C { @deprecated C() {} }');
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    _assertCloneUnitMember('class C { C() : a = b {} }');
  }

  void test_visitConstructorFieldInitializer_withThis() {
    _assertCloneUnitMember('class C { C() : this.a = b {} }');
  }

  void test_visitConstructorName_named_prefix() {
    _assertCloneExpression('new p.C.n()');
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    _assertCloneExpression('new C()');
  }

  void test_visitConstructorName_unnamed_prefix() {
    _assertCloneExpression('new p.C()');
  }

  void test_visitContinueStatement_label() {
    _assertCloneStatement('l: while (true) { continue l; }');
  }

  void test_visitContinueStatement_noLabel() {
    _assertCloneStatement('while (true) { continue; }');
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    _assertCloneUnitMember('main({p}) {}');
  }

  void test_visitDefaultFormalParameter_named_value() {
    _assertCloneUnitMember('main({p : 0}) {}');
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    _assertCloneUnitMember('main([p]) {}');
  }

  void test_visitDefaultFormalParameter_positional_value() {
    _assertCloneUnitMember('main([p = 0]) {}');
  }

  void test_visitDoStatement() {
    _assertCloneStatement('do {} while (c);');
  }

  void test_visitDoubleLiteral() {
    _assertCloneExpression('4.2');
  }

  void test_visitEmptyFunctionBody() {
    _assertCloneUnitMember('main() {}');
  }

  void test_visitEmptyStatement() {
    _assertCloneUnitMember('main() { ; }');
  }

  void test_visitExportDirective_combinator() {
    _assertCloneUnit('export "a.dart" show A;');
  }

  void test_visitExportDirective_combinators() {
    _assertCloneUnit('export "a.dart" show A hide B;');
  }

  void test_visitExportDirective_minimal() {
    _assertCloneUnit('export "a.dart";');
  }

  void test_visitExportDirective_withMetadata() {
    _assertCloneUnit('@deprecated export "a.dart";');
  }

  void test_visitExpressionFunctionBody() {
    _assertCloneUnitMember('main() => a;');
  }

  void test_visitExpressionStatement() {
    _assertCloneStatement('a;');
  }

  void test_visitExtendsClause() {
    _assertCloneUnitMember('class A extends B {}');
  }

  void test_visitFieldDeclaration_instance() {
    _assertCloneUnitMember('class C { var a; }');
  }

  void test_visitFieldDeclaration_static() {
    _assertCloneUnitMember('class C { static var a; }');
  }

  void test_visitFieldDeclaration_withMetadata() {
    _assertCloneUnitMember('class C { @deprecated var a; }');
  }

  void test_visitFieldFormalParameter_functionTyped() {
    _assertCloneUnitMember('class C { C(A this.a(b)); }');
  }

  void test_visitFieldFormalParameter_keyword() {
    _assertCloneUnitMember('class C { C(var this.a); }');
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    _assertCloneUnitMember('class C { C(final A this.a); }');
  }

  void test_visitFieldFormalParameter_type() {
    _assertCloneUnitMember('class C { C(A this.a); }');
  }

  void test_visitForEachStatement_declared() {
    _assertCloneStatement('for (var a in b) {}');
  }

  void test_visitForEachStatement_variable() {
    _assertCloneStatement('for (a in b) {}');
  }

  void test_visitForEachStatement_variable_await() {
    _assertCloneUnitMember('main(s) async { await for (a in s) {} }');
  }

  void test_visitFormalParameterList_empty() {
    _assertCloneUnitMember('main() {}');
  }

  void test_visitFormalParameterList_n() {
    _assertCloneUnitMember('main({a: 0}) {}');
  }

  void test_visitFormalParameterList_nn() {
    _assertCloneUnitMember('main({a: 0, b: 1}) {}');
  }

  void test_visitFormalParameterList_p() {
    _assertCloneUnitMember('main([a = 0]) {}');
  }

  void test_visitFormalParameterList_pp() {
    _assertCloneUnitMember('main([a = 0, b = 1]) {}');
  }

  void test_visitFormalParameterList_r() {
    _assertCloneUnitMember('main(a) {}');
  }

  void test_visitFormalParameterList_rn() {
    _assertCloneUnitMember('main(a, {b: 1}) {}');
  }

  void test_visitFormalParameterList_rnn() {
    _assertCloneUnitMember('main(a, {b: 1, c: 2}) {}');
  }

  void test_visitFormalParameterList_rp() {
    _assertCloneUnitMember('main(a, [b = 1]) {}');
  }

  void test_visitFormalParameterList_rpp() {
    _assertCloneUnitMember('main(a, [b = 1, c = 2]) {}');
  }

  void test_visitFormalParameterList_rr() {
    _assertCloneUnitMember('main(a, b) {}');
  }

  void test_visitFormalParameterList_rrn() {
    _assertCloneUnitMember('main(a, b, {c: 3}) {}');
  }

  void test_visitFormalParameterList_rrnn() {
    _assertCloneUnitMember('main(a, b, {c: 3, d: 4}) {}');
  }

  void test_visitFormalParameterList_rrp() {
    _assertCloneUnitMember('main(a, b, [c = 3]) {}');
  }

  void test_visitFormalParameterList_rrpp() {
    _assertCloneUnitMember('main(a, b, [c = 3, d = 4]) {}');
  }

  void test_visitForStatement_c() {
    _assertCloneStatement('for (; c;) {}');
  }

  void test_visitForStatement_cu() {
    _assertCloneStatement('for (; c; u) {}');
  }

  void test_visitForStatement_e() {
    _assertCloneStatement('for (e; ;) {}');
  }

  void test_visitForStatement_ec() {
    _assertCloneStatement('for (e; c;) {}');
  }

  void test_visitForStatement_ecu() {
    _assertCloneStatement('for (e; c; u) {}');
  }

  void test_visitForStatement_eu() {
    _assertCloneStatement('for (e; ; u) {}');
  }

  void test_visitForStatement_i() {
    _assertCloneStatement('for (var i; ;) {}');
  }

  void test_visitForStatement_ic() {
    _assertCloneStatement('for (var i; c;) {}');
  }

  void test_visitForStatement_icu() {
    _assertCloneStatement('for (var i; c; u) {}');
  }

  void test_visitForStatement_iu() {
    _assertCloneStatement('for (var i; ; u) {}');
  }

  void test_visitForStatement_u() {
    _assertCloneStatement('for (; ; u) {}');
  }

  void test_visitFunctionDeclaration_getter() {
    _assertCloneUnitMember('get f {}');
  }

  void test_visitFunctionDeclaration_normal() {
    _assertCloneUnitMember('f() {}');
  }

  void test_visitFunctionDeclaration_setter() {
    _assertCloneUnitMember('set f(x) {}');
  }

  void test_visitFunctionDeclaration_withMetadata() {
    _assertCloneUnitMember('@deprecated f() {}');
  }

  void test_visitFunctionDeclarationStatement() {
    _assertCloneStatement('f() {}');
  }

  void test_visitFunctionExpressionInvocation() {
    _assertCloneStatement('{ () {}(); }');
  }

  void test_visitFunctionTypeAlias_generic() {
    _assertCloneUnitMember('typedef A F<B>();');
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    _assertCloneUnitMember('typedef A F();');
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    _assertCloneUnitMember('@deprecated typedef A F();');
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    _assertCloneUnitMember('main( f() ) {}');
  }

  void test_visitFunctionTypedFormalParameter_type() {
    _assertCloneUnitMember('main( T f() ) {}');
  }

  void test_visitIfStatement_withElse() {
    _assertCloneStatement('if (c) {} else {}');
  }

  void test_visitIfStatement_withoutElse() {
    _assertCloneStatement('if (c) {}');
  }

  void test_visitImplementsClause_multiple() {
    _assertCloneUnitMember('class A implements B, C {}');
  }

  void test_visitImplementsClause_single() {
    _assertCloneUnitMember('class A implements B {}');
  }

  void test_visitImportDirective_combinator() {
    _assertCloneUnit('import "a.dart" show A;');
  }

  void test_visitImportDirective_combinators() {
    _assertCloneUnit('import "a.dart" show A hide B;');
  }

  void test_visitImportDirective_minimal() {
    _assertCloneUnit('import "a.dart";');
  }

  void test_visitImportDirective_prefix() {
    _assertCloneUnit('import "a.dart" as p;');
  }

  void test_visitImportDirective_prefix_combinator() {
    _assertCloneUnit('import "a.dart" as p show A;');
  }

  void test_visitImportDirective_prefix_combinators() {
    _assertCloneUnit('import "a.dart" as p show A hide B;');
  }

  void test_visitImportDirective_withMetadata() {
    _assertCloneUnit('@deprecated import "a.dart";');
  }

  void test_visitImportHideCombinator_multiple() {
    _assertCloneUnit('import "a.dart" hide a, b;');
  }

  void test_visitImportHideCombinator_single() {
    _assertCloneUnit('import "a.dart" hide a;');
  }

  void test_visitImportShowCombinator_multiple() {
    _assertCloneUnit('import "a.dart" show a, b;');
  }

  void test_visitImportShowCombinator_single() {
    _assertCloneUnit('import "a.dart" show a;');
  }

  void test_visitIndexExpression() {
    _assertCloneExpression('a[i]');
  }

  void test_visitInstanceCreationExpression_const() {
    _assertCloneExpression('const C()');
  }

  void test_visitInstanceCreationExpression_named() {
    _assertCloneExpression('new C.c()');
  }

  void test_visitInstanceCreationExpression_unnamed() {
    _assertCloneExpression('new C()');
  }

  void test_visitIntegerLiteral() {
    _assertCloneExpression('42');
  }

  void test_visitInterpolationExpression_expression() {
    _assertCloneExpression(r'"${c}"');
  }

  void test_visitInterpolationExpression_identifier() {
    _assertCloneExpression(r'"$c"');
  }

  void test_visitIsExpression_negated() {
    _assertCloneExpression('a is! C');
  }

  void test_visitIsExpression_normal() {
    _assertCloneExpression('a is C');
  }

  void test_visitLabel() {
    _assertCloneStatement('a: return;');
  }

  void test_visitLabeledStatement_multiple() {
    _assertCloneStatement('a: b: return;');
  }

  void test_visitLabeledStatement_single() {
    _assertCloneStatement('a: return;');
  }

  void test_visitLibraryDirective() {
    _assertCloneUnit('library l;');
  }

  void test_visitLibraryDirective_withMetadata() {
    _assertCloneUnit('@deprecated library l;');
  }

  void test_visitLibraryIdentifier_multiple() {
    _assertCloneUnit('library a.b.c;');
  }

  void test_visitLibraryIdentifier_single() {
    _assertCloneUnit('library a;');
  }

  void test_visitListLiteral_const() {
    _assertCloneExpression('const []');
  }

  void test_visitListLiteral_empty() {
    _assertCloneExpression('[]');
  }

  void test_visitListLiteral_nonEmpty() {
    _assertCloneExpression('[a, b, c]');
  }

  void test_visitMapLiteral_const() {
    _assertCloneExpression('const {}');
  }

  void test_visitMapLiteral_empty() {
    _assertCloneExpression('{}');
  }

  void test_visitMapLiteral_nonEmpty() {
    _assertCloneExpression('{a: a, b: b, c: c}');
  }

  void test_visitMethodDeclaration_external() {
    _assertCloneUnitMember('class C { external m(); }');
  }

  void test_visitMethodDeclaration_external_returnType() {
    _assertCloneUnitMember('class C { T m(); }');
  }

  void test_visitMethodDeclaration_getter() {
    _assertCloneUnitMember('class C { get m {} }');
  }

  void test_visitMethodDeclaration_getter_returnType() {
    _assertCloneUnitMember('class C { T get m {} }');
  }

  void test_visitMethodDeclaration_minimal() {
    _assertCloneUnitMember('class C { m() {} }');
  }

  void test_visitMethodDeclaration_multipleParameters() {
    _assertCloneUnitMember('class C { m(var a, var b) {} }');
  }

  void test_visitMethodDeclaration_operator() {
    _assertCloneUnitMember('class C { operator+() {} }');
  }

  void test_visitMethodDeclaration_operator_returnType() {
    _assertCloneUnitMember('class C { T operator+() {} }');
  }

  void test_visitMethodDeclaration_returnType() {
    _assertCloneUnitMember('class C { T m() {} }');
  }

  void test_visitMethodDeclaration_setter() {
    _assertCloneUnitMember('class C { set m(var v) {} }');
  }

  void test_visitMethodDeclaration_setter_returnType() {
    _assertCloneUnitMember('class C { T set m(v) {} }');
  }

  void test_visitMethodDeclaration_static() {
    _assertCloneUnitMember('class C { static m() {} }');
  }

  void test_visitMethodDeclaration_static_returnType() {
    _assertCloneUnitMember('class C { static T m() {} }');
  }

  void test_visitMethodDeclaration_withMetadata() {
    _assertCloneUnitMember('class C { @deprecated m() {} }');
  }

  void test_visitMethodInvocation_noTarget() {
    _assertCloneExpression('m()');
  }

  void test_visitMethodInvocation_target() {
    _assertCloneExpression('t.m()');
  }

  void test_visitNamedExpression() {
    _assertCloneExpression('m(a: b)');
  }

  void test_visitNativeClause() {
    _assertCloneUnitMember('f() native "code";');
  }

  void test_visitNativeFunctionBody() {
    _assertCloneUnitMember('f() native "str";');
  }

  void test_visitNullLiteral() {
    _assertCloneExpression('null');
  }

  void test_visitParenthesizedExpression() {
    _assertCloneExpression('(a)');
  }

  void test_visitPartDirective() {
    _assertCloneUnit('part "a.dart";');
  }

  void test_visitPartDirective_withMetadata() {
    _assertCloneUnit('@deprecated part "a.dart";');
  }

  void test_visitPartOfDirective() {
    _assertCloneUnit('part of l;');
  }

  void test_visitPartOfDirective_withMetadata() {
    _assertCloneUnit('@deprecated part of l;');
  }

  void test_visitPositionalFormalParameter() {
    _assertCloneUnitMember('main([var p = 0]) {}');
  }

  void test_visitPostfixExpression() {
    _assertCloneExpression('a++');
  }

  void test_visitPrefixedIdentifier() {
    _assertCloneExpression('a.b');
  }

  void test_visitPrefixExpression() {
    _assertCloneExpression('-a');
  }

  void test_visitPropertyAccess() {
    _assertCloneExpression('a.b.c');
  }

  void test_visitRedirectingConstructorInvocation_named() {
    _assertCloneUnitMember('class A { factory A() = B.b; }');
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    _assertCloneUnitMember('class A { factory A() = B; }');
  }

  void test_visitRethrowExpression() {
    _assertCloneExpression('rethrow');
  }

  void test_visitReturnStatement_expression() {
    _assertCloneStatement('return a;');
  }

  void test_visitReturnStatement_noExpression() {
    _assertCloneStatement('return;');
  }

  void test_visitScriptTag() {
    _assertCloneUnit('#!/bin/dart.exe');
  }

  void test_visitSimpleFormalParameter_keyword() {
    _assertCloneUnitMember('main(var a) {}');
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    _assertCloneUnitMember('main(final A a) {}');
  }

  void test_visitSimpleFormalParameter_type() {
    _assertCloneUnitMember('main(A a) {}');
  }

  void test_visitSimpleIdentifier() {
    _assertCloneExpression('a');
  }

  void test_visitSimpleStringLiteral() {
    _assertCloneExpression("'a'");
  }

  void test_visitStringInterpolation() {
    _assertCloneExpression(r"'a${e}b'");
  }

  void test_visitSuperConstructorInvocation() {
    _assertCloneUnitMember('class C { C() : super(); }');
  }

  void test_visitSuperConstructorInvocation_named() {
    _assertCloneUnitMember('class C { C() : super.c(); }');
  }

  void test_visitSuperExpression() {
    _assertCloneUnitMember('class C { m() { super.m(); } }');
  }

  void test_visitSwitchCase_multipleLabels() {
    _assertCloneStatement('switch (v) {l1: l2: case a: {} }');
  }

  void test_visitSwitchCase_multipleStatements() {
    _assertCloneStatement('switch (v) { case a: {} {} }');
  }

  void test_visitSwitchCase_noLabels() {
    _assertCloneStatement('switch (v) { case a: {} }');
  }

  void test_visitSwitchCase_singleLabel() {
    _assertCloneStatement('switch (v) { l1: case a: {} }');
  }

  void test_visitSwitchDefault_multipleLabels() {
    _assertCloneStatement('switch (v) { l1: l2: default: {} }');
  }

  void test_visitSwitchDefault_multipleStatements() {
    _assertCloneStatement('switch (v) { default: {} {} }');
  }

  void test_visitSwitchDefault_noLabels() {
    _assertCloneStatement('switch (v) { default: {} }');
  }

  void test_visitSwitchDefault_singleLabel() {
    _assertCloneStatement('switch (v) { l1: default: {} }');
  }

  void test_visitSwitchStatement() {
    _assertCloneStatement('switch (a) { case b: {} default: {} }');
  }

  void test_visitSymbolLiteral_multiple() {
    _assertCloneExpression('#a.b.c');
  }

  void test_visitSymbolLiteral_single() {
    _assertCloneExpression('#a');
  }

  void test_visitThisExpression() {
    _assertCloneExpression('this');
  }

  void test_visitThrowStatement() {
    _assertCloneStatement('throw e;');
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    _assertCloneUnitMember('var a;');
  }

  void test_visitTopLevelVariableDeclaration_single() {
    _assertCloneUnitMember('var a, b;');
  }

  void test_visitTryStatement_catch() {
    _assertCloneStatement('try {} on E {}');
  }

  void test_visitTryStatement_catches() {
    _assertCloneStatement('try {} on E {} on F {}');
  }

  void test_visitTryStatement_catchFinally() {
    _assertCloneStatement('try {} on E {} finally {}');
  }

  void test_visitTryStatement_finally() {
    _assertCloneStatement('try {} finally {}');
  }

  void test_visitTypeName_multipleArgs() {
    _assertCloneExpression('new C<D, E>()');
  }

  void test_visitTypeName_nestedArg() {
    _assertCloneExpression('new C<D<E>>()');
  }

  void test_visitTypeName_noArgs() {
    _assertCloneExpression('new C()');
  }

  void test_visitTypeName_singleArg() {
    _assertCloneExpression('new C<D>()');
  }

  void test_visitTypeParameter_withExtends() {
    _assertCloneUnitMember('class A<E extends C> {}');
  }

  void test_visitTypeParameter_withMetadata() {
    _assertCloneUnitMember('class A<@deprecated E> {}');
  }

  void test_visitTypeParameter_withoutExtends() {
    _assertCloneUnitMember('class A<E> {}');
  }

  void test_visitTypeParameterList_multiple() {
    _assertCloneUnitMember('class A<E, F> {}');
  }

  void test_visitTypeParameterList_single() {
    _assertCloneUnitMember('class A<E> {}');
  }

  void test_visitVariableDeclaration_initialized() {
    _assertCloneStatement('var a = b;');
  }

  void test_visitVariableDeclaration_uninitialized() {
    _assertCloneStatement('var a;');
  }

  void test_visitVariableDeclarationList_const_type() {
    _assertCloneStatement('const C a, b;');
  }

  void test_visitVariableDeclarationList_final_noType() {
    _assertCloneStatement('final a, b;');
  }

  void test_visitVariableDeclarationList_final_withMetadata() {
    _assertCloneStatement('@deprecated final a, b;');
  }

  void test_visitVariableDeclarationList_type() {
    _assertCloneStatement('C a, b;');
  }

  void test_visitVariableDeclarationList_var() {
    _assertCloneStatement('var a, b;');
  }

  void test_visitVariableDeclarationStatement() {
    _assertCloneStatement('C c;');
  }

  void test_visitWhileStatement() {
    _assertCloneStatement('while (c) {}');
  }

  void test_visitWithClause_multiple() {
    _assertCloneUnitMember('class X extends Y with A, B, C {}');
  }

  void test_visitWithClause_single() {
    _assertCloneUnitMember('class X extends Y with A {}');
  }

  void test_visitYieldStatement() {
    _assertCloneUnitMember('main() async* { yield 42; }');
  }

  /**
   * Assert that an `AstCloner` will produce the expected AST structure when
   * visiting the given [node].
   *
   * @param node the AST node being visited to produce the cloned structure
   * @throws AFE if the visitor does not produce the expected source for the given node
   */
  void _assertClone(AstNode node) {
    {
      AstNode clone = node.accept(new AstCloner());
      AstCloneComparator comparator = new AstCloneComparator(false);
      if (!comparator.isEqualNodes(node, clone)) {
        fail("Failed to clone ${node.runtimeType.toString()}");
      }
      _assertEqualTokens(clone, node);
    }
    {
      AstNode clone = node.accept(new AstCloner(true));
      AstCloneComparator comparator = new AstCloneComparator(true);
      if (!comparator.isEqualNodes(node, clone)) {
        fail("Failed to clone ${node.runtimeType.toString()}");
      }
      _assertEqualTokens(clone, node);
    }
  }

  void _assertCloneExpression(String code) {
    AstNode node = _parseExpression(code);
    _assertClone(node);
  }

  void _assertCloneStatement(String code) {
    AstNode node = _parseStatement(code);
    _assertClone(node);
  }

  void _assertCloneUnit(String code) {
    AstNode node = _parseUnit(code);
    _assertClone(node);
  }

  void _assertCloneUnitMember(String code) {
    AstNode node = _parseUnitMember(code);
    _assertClone(node);
  }

  Expression _parseExpression(String code) {
    CompilationUnit unit = _parseUnit('var v = $code;');
    TopLevelVariableDeclaration decl = unit.declarations.single;
    return decl.variables.variables.single.initializer;
  }

  Statement _parseStatement(String code) {
    CompilationUnit unit = _parseUnit('main() { $code }');
    FunctionDeclaration main = unit.declarations.single;
    BlockFunctionBody body = main.functionExpression.body;
    return body.block.statements.single;
  }

  CompilationUnit _parseUnit(String code) {
    GatheringErrorListener listener = new GatheringErrorListener();
    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(null, reader, listener);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
    expect(unit, isNotNull);
    listener.assertNoErrors();
    return unit;
  }

  CompilationUnitMember _parseUnitMember(String code) {
    CompilationUnit unit = _parseUnit(code);
    return unit.declarations.single;
  }

  static void _assertEqualToken(Token clone, Token original) {
    expect(clone.type, original.type);
    expect(clone.offset, original.offset);
    expect(clone.length, original.length);
    expect(clone.lexeme, original.lexeme);
  }

  static void _assertEqualTokens(AstNode cloneNode, AstNode originalNode) {
    Token clone = cloneNode.beginToken;
    Token original = originalNode.beginToken;
    if (original is! CommentToken) {
      _assertHasPrevious(original);
      _assertHasPrevious(clone);
    }
    Token stopOriginalToken = originalNode.endToken.next;
    Token skipCloneComment = null;
    Token skipOriginalComment = null;
    while (original != stopOriginalToken) {
      expect(clone, isNotNull);
      _assertEqualToken(clone, original);
      // comments
      {
        Token cloneComment = clone.precedingComments;
        Token originalComment = original.precedingComments;
        if (cloneComment != skipCloneComment &&
            originalComment != skipOriginalComment) {
          while (true) {
            if (originalComment == null) {
              expect(cloneComment, isNull);
              break;
            }
            expect(cloneComment, isNotNull);
            _assertEqualToken(cloneComment, originalComment);
            cloneComment = cloneComment.next;
            originalComment = originalComment.next;
          }
        }
      }
      // next tokens
      if (original is CommentToken) {
        expect(clone, new isInstanceOf<CommentToken>());
        skipOriginalComment = original;
        skipCloneComment = clone;
        original = (original as CommentToken).parent;
        clone = (clone as CommentToken).parent;
      } else {
        clone = clone.next;
        original = original.next;
      }
    }
  }

  /**
   * Assert that the [token] has `previous` set, and if it `EOF`, then it
   * points itself.
   */
  static void _assertHasPrevious(Token token) {
    expect(token, isNotNull);
    if (token.type == TokenType.EOF) {
      return;
    }
    while (token != null) {
      Token previous = token.previous;
      expect(previous, isNotNull);
      if (token.type == TokenType.EOF) {
        expect(previous, same(token));
        break;
      }
      token = previous;
    }
  }
}

@reflectiveTest
class BooleanArrayTest {
  void test_get_negative() {
    try {
      BooleanArray.get(0, -1);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_get_tooBig() {
    try {
      BooleanArray.get(0, 31);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_get_valid() {
    expect(BooleanArray.get(0, 0), false);
    expect(BooleanArray.get(1, 0), true);
    expect(BooleanArray.get(0, 30), false);
    expect(BooleanArray.get(1 << 30, 30), true);
  }

  void test_set_negative() {
    try {
      BooleanArray.set(0, -1, true);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_set_tooBig() {
    try {
      BooleanArray.set(0, 32, true);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_set_valueChanging() {
    expect(BooleanArray.set(0, 0, true), 1);
    expect(BooleanArray.set(1, 0, false), 0);
    expect(BooleanArray.set(0, 30, true), 1 << 30);
    expect(BooleanArray.set(1 << 30, 30, false), 0);
  }

  void test_set_valuePreserving() {
    expect(BooleanArray.set(0, 0, false), 0);
    expect(BooleanArray.set(1, 0, true), 1);
    expect(BooleanArray.set(0, 30, false), 0);
    expect(BooleanArray.set(1 << 30, 30, true), 1 << 30);
  }
}

@reflectiveTest
class DirectedGraphTest extends EngineTestCase {
  void test_addEdge() {
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.isEmpty, isTrue);
    graph.addEdge(new DirectedGraphTest_Node(), new DirectedGraphTest_Node());
    expect(graph.isEmpty, isFalse);
  }

  void test_addNode() {
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.isEmpty, isTrue);
    graph.addNode(new DirectedGraphTest_Node());
    expect(graph.isEmpty, isFalse);
  }

  void test_containsPath_noCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    expect(graph.containsPath(node1, node1), isTrue);
    expect(graph.containsPath(node1, node2), isTrue);
    expect(graph.containsPath(node1, node3), isTrue);
    expect(graph.containsPath(node2, node1), isFalse);
    expect(graph.containsPath(node2, node2), isTrue);
    expect(graph.containsPath(node2, node3), isTrue);
    expect(graph.containsPath(node3, node1), isFalse);
    expect(graph.containsPath(node3, node2), isFalse);
    expect(graph.containsPath(node3, node3), isTrue);
  }

  void test_containsPath_withCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node4 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node1);
    graph.addEdge(node1, node3);
    graph.addEdge(node3, node4);
    graph.addEdge(node4, node3);
    expect(graph.containsPath(node1, node1), isTrue);
    expect(graph.containsPath(node1, node2), isTrue);
    expect(graph.containsPath(node1, node3), isTrue);
    expect(graph.containsPath(node1, node4), isTrue);
    expect(graph.containsPath(node2, node1), isTrue);
    expect(graph.containsPath(node2, node2), isTrue);
    expect(graph.containsPath(node2, node3), isTrue);
    expect(graph.containsPath(node2, node4), isTrue);
    expect(graph.containsPath(node3, node1), isFalse);
    expect(graph.containsPath(node3, node2), isFalse);
    expect(graph.containsPath(node3, node3), isTrue);
    expect(graph.containsPath(node3, node4), isTrue);
    expect(graph.containsPath(node4, node1), isFalse);
    expect(graph.containsPath(node4, node2), isFalse);
    expect(graph.containsPath(node4, node3), isTrue);
    expect(graph.containsPath(node4, node4), isTrue);
  }

  void test_creation() {
    expect(new DirectedGraph<DirectedGraphTest_Node>(), isNotNull);
  }

  void test_findCycleContaining_complexCycle() {
    // Two overlapping loops: (1, 2, 3) and (3, 4, 5)
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node4 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node5 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    graph.addEdge(node3, node1);
    graph.addEdge(node3, node4);
    graph.addEdge(node4, node5);
    graph.addEdge(node5, node3);
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node1);
    expect(cycle, hasLength(5));
    expect(cycle.contains(node1), isTrue);
    expect(cycle.contains(node2), isTrue);
    expect(cycle.contains(node3), isTrue);
    expect(cycle.contains(node4), isTrue);
    expect(cycle.contains(node5), isTrue);
  }

  void test_findCycleContaining_cycle() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    graph.addEdge(node2, new DirectedGraphTest_Node());
    graph.addEdge(node3, node1);
    graph.addEdge(node3, new DirectedGraphTest_Node());
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node1);
    expect(cycle, hasLength(3));
    expect(cycle.contains(node1), isTrue);
    expect(cycle.contains(node2), isTrue);
    expect(cycle.contains(node3), isTrue);
  }

  void test_findCycleContaining_notInGraph() {
    DirectedGraphTest_Node node = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node);
    expect(cycle, hasLength(1));
    expect(cycle[0], node);
  }

  void test_findCycleContaining_null() {
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(() => graph.findCycleContaining(null), throwsArgumentError);
  }

  void test_findCycleContaining_singleton() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node1);
    expect(cycle, hasLength(1));
    expect(cycle[0], node1);
  }

  void test_getNodeCount() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.nodeCount, 0);
    graph.addNode(node1);
    expect(graph.nodeCount, 1);
    graph.addNode(node2);
    expect(graph.nodeCount, 2);
    graph.removeNode(node1);
    expect(graph.nodeCount, 1);
  }

  void test_getTails() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.getTails(node1), hasLength(0));
    graph.addEdge(node1, node2);
    expect(graph.getTails(node1), hasLength(1));
    graph.addEdge(node1, node3);
    expect(graph.getTails(node1), hasLength(2));
  }

  void test_removeAllNodes() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    List<DirectedGraphTest_Node> nodes = new List<DirectedGraphTest_Node>();
    nodes.add(node1);
    nodes.add(node2);
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node1);
    expect(graph.isEmpty, isFalse);
    graph.removeAllNodes(nodes);
    expect(graph.isEmpty, isTrue);
  }

  void test_removeEdge() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    expect(graph.getTails(node1), hasLength(2));
    graph.removeEdge(node1, node2);
    expect(graph.getTails(node1), hasLength(1));
  }

  void test_removeNode() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    expect(graph.getTails(node1), hasLength(2));
    graph.removeNode(node2);
    expect(graph.getTails(node1), hasLength(1));
  }

  void test_removeSink() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    expect(graph.removeSink(), same(node2));
    expect(graph.removeSink(), same(node1));
    expect(graph.isEmpty, isTrue);
  }

  void test_topologicalSort_noCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node3);
    List<List<DirectedGraphTest_Node>> topologicalSort =
        graph.computeTopologicalSort();
    expect(topologicalSort, hasLength(3));
    expect(topologicalSort[0], hasLength(1));
    expect(topologicalSort[0][0], node3);
    expect(topologicalSort[1], hasLength(1));
    expect(topologicalSort[1][0], node2);
    expect(topologicalSort[2], hasLength(1));
    expect(topologicalSort[2][0], node1);
  }

  void test_topologicalSort_withCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node4 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node1);
    graph.addEdge(node1, node3);
    graph.addEdge(node3, node4);
    graph.addEdge(node4, node3);
    List<List<DirectedGraphTest_Node>> topologicalSort =
        graph.computeTopologicalSort();
    expect(topologicalSort, hasLength(2));
    expect(topologicalSort[0], unorderedEquals([node3, node4]));
    expect(topologicalSort[1], unorderedEquals([node1, node2]));
  }
}

/**
 * Instances of the class `Node` represent simple nodes used for testing purposes.
 */
class DirectedGraphTest_Node {}

@reflectiveTest
class ExceptionHandlingDelegatingAstVisitorTest extends EngineTestCase {
  void test_handlerIsCalled() {
    AstVisitor exceptionThrowingVisitor = new _ExceptionThrowingVisitor();
    bool handlerInvoked = false;
    AstVisitor visitor = new ExceptionHandlingDelegatingAstVisitor(
        [exceptionThrowingVisitor], (AstNode node, AstVisitor visitor,
            dynamic exception, StackTrace stackTrace) {
      handlerInvoked = true;
    });
    astFactory.nullLiteral(null).accept(visitor);
    expect(handlerInvoked, isTrue);
  }
}

class Getter_NodeReplacerTest_test_annotation
    implements NodeReplacerTest_Getter<Annotation, ArgumentList> {
  @override
  ArgumentList get(Annotation node) => node.arguments;
}

class Getter_NodeReplacerTest_test_annotation_2
    implements NodeReplacerTest_Getter<Annotation, Identifier> {
  @override
  Identifier get(Annotation node) => node.name;
}

class Getter_NodeReplacerTest_test_annotation_3
    implements NodeReplacerTest_Getter<Annotation, SimpleIdentifier> {
  @override
  SimpleIdentifier get(Annotation node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_asExpression
    implements NodeReplacerTest_Getter<AsExpression, TypeAnnotation> {
  @override
  TypeAnnotation get(AsExpression node) => node.type;
}

class Getter_NodeReplacerTest_test_asExpression_2
    implements NodeReplacerTest_Getter<AsExpression, Expression> {
  @override
  Expression get(AsExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_assertStatement
    implements NodeReplacerTest_Getter<AssertStatement, Expression> {
  @override
  Expression get(AssertStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_assertStatement_2
    implements NodeReplacerTest_Getter<AssertStatement, Expression> {
  @override
  Expression get(AssertStatement node) => node.message;
}

class Getter_NodeReplacerTest_test_assignmentExpression
    implements NodeReplacerTest_Getter<AssignmentExpression, Expression> {
  @override
  Expression get(AssignmentExpression node) => node.rightHandSide;
}

class Getter_NodeReplacerTest_test_assignmentExpression_2
    implements NodeReplacerTest_Getter<AssignmentExpression, Expression> {
  @override
  Expression get(AssignmentExpression node) => node.leftHandSide;
}

class Getter_NodeReplacerTest_test_awaitExpression
    implements NodeReplacerTest_Getter<AwaitExpression, Expression> {
  @override
  Expression get(AwaitExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_binaryExpression
    implements NodeReplacerTest_Getter<BinaryExpression, Expression> {
  @override
  Expression get(BinaryExpression node) => node.leftOperand;
}

class Getter_NodeReplacerTest_test_binaryExpression_2
    implements NodeReplacerTest_Getter<BinaryExpression, Expression> {
  @override
  Expression get(BinaryExpression node) => node.rightOperand;
}

class Getter_NodeReplacerTest_test_blockFunctionBody
    implements NodeReplacerTest_Getter<BlockFunctionBody, Block> {
  @override
  Block get(BlockFunctionBody node) => node.block;
}

class Getter_NodeReplacerTest_test_breakStatement
    implements NodeReplacerTest_Getter<BreakStatement, SimpleIdentifier> {
  @override
  SimpleIdentifier get(BreakStatement node) => node.label;
}

class Getter_NodeReplacerTest_test_cascadeExpression
    implements NodeReplacerTest_Getter<CascadeExpression, Expression> {
  @override
  Expression get(CascadeExpression node) => node.target;
}

class Getter_NodeReplacerTest_test_catchClause
    implements NodeReplacerTest_Getter<CatchClause, SimpleIdentifier> {
  @override
  SimpleIdentifier get(CatchClause node) => node.stackTraceParameter;
}

class Getter_NodeReplacerTest_test_catchClause_2
    implements NodeReplacerTest_Getter<CatchClause, SimpleIdentifier> {
  @override
  SimpleIdentifier get(CatchClause node) => node.exceptionParameter;
}

class Getter_NodeReplacerTest_test_catchClause_3
    implements NodeReplacerTest_Getter<CatchClause, TypeAnnotation> {
  @override
  TypeAnnotation get(CatchClause node) => node.exceptionType;
}

class Getter_NodeReplacerTest_test_classDeclaration
    implements NodeReplacerTest_Getter<ClassDeclaration, ImplementsClause> {
  @override
  ImplementsClause get(ClassDeclaration node) => node.implementsClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_2
    implements NodeReplacerTest_Getter<ClassDeclaration, WithClause> {
  @override
  WithClause get(ClassDeclaration node) => node.withClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_3
    implements NodeReplacerTest_Getter<ClassDeclaration, NativeClause> {
  @override
  NativeClause get(ClassDeclaration node) => node.nativeClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_4
    implements NodeReplacerTest_Getter<ClassDeclaration, ExtendsClause> {
  @override
  ExtendsClause get(ClassDeclaration node) => node.extendsClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_5
    implements NodeReplacerTest_Getter<ClassDeclaration, TypeParameterList> {
  @override
  TypeParameterList get(ClassDeclaration node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_classDeclaration_6
    implements NodeReplacerTest_Getter<ClassDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ClassDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_classTypeAlias
    implements NodeReplacerTest_Getter<ClassTypeAlias, TypeName> {
  @override
  TypeName get(ClassTypeAlias node) => node.superclass;
}

class Getter_NodeReplacerTest_test_classTypeAlias_2
    implements NodeReplacerTest_Getter<ClassTypeAlias, ImplementsClause> {
  @override
  ImplementsClause get(ClassTypeAlias node) => node.implementsClause;
}

class Getter_NodeReplacerTest_test_classTypeAlias_3
    implements NodeReplacerTest_Getter<ClassTypeAlias, WithClause> {
  @override
  WithClause get(ClassTypeAlias node) => node.withClause;
}

class Getter_NodeReplacerTest_test_classTypeAlias_4
    implements NodeReplacerTest_Getter<ClassTypeAlias, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ClassTypeAlias node) => node.name;
}

class Getter_NodeReplacerTest_test_classTypeAlias_5
    implements NodeReplacerTest_Getter<ClassTypeAlias, TypeParameterList> {
  @override
  TypeParameterList get(ClassTypeAlias node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_commentReference
    implements NodeReplacerTest_Getter<CommentReference, Identifier> {
  @override
  Identifier get(CommentReference node) => node.identifier;
}

class Getter_NodeReplacerTest_test_compilationUnit
    implements NodeReplacerTest_Getter<CompilationUnit, ScriptTag> {
  @override
  ScriptTag get(CompilationUnit node) => node.scriptTag;
}

class Getter_NodeReplacerTest_test_conditionalExpression
    implements NodeReplacerTest_Getter<ConditionalExpression, Expression> {
  @override
  Expression get(ConditionalExpression node) => node.elseExpression;
}

class Getter_NodeReplacerTest_test_conditionalExpression_2
    implements NodeReplacerTest_Getter<ConditionalExpression, Expression> {
  @override
  Expression get(ConditionalExpression node) => node.thenExpression;
}

class Getter_NodeReplacerTest_test_conditionalExpression_3
    implements NodeReplacerTest_Getter<ConditionalExpression, Expression> {
  @override
  Expression get(ConditionalExpression node) => node.condition;
}

class Getter_NodeReplacerTest_test_constructorDeclaration
    implements
        NodeReplacerTest_Getter<ConstructorDeclaration, ConstructorName> {
  @override
  ConstructorName get(ConstructorDeclaration node) =>
      node.redirectedConstructor;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_2
    implements
        NodeReplacerTest_Getter<ConstructorDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ConstructorDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_3
    implements NodeReplacerTest_Getter<ConstructorDeclaration, Identifier> {
  @override
  Identifier get(ConstructorDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_4
    implements
        NodeReplacerTest_Getter<ConstructorDeclaration, FormalParameterList> {
  @override
  FormalParameterList get(ConstructorDeclaration node) => node.parameters;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_5
    implements NodeReplacerTest_Getter<ConstructorDeclaration, FunctionBody> {
  @override
  FunctionBody get(ConstructorDeclaration node) => node.body;
}

class Getter_NodeReplacerTest_test_constructorFieldInitializer
    implements
        NodeReplacerTest_Getter<ConstructorFieldInitializer, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ConstructorFieldInitializer node) => node.fieldName;
}

class Getter_NodeReplacerTest_test_constructorFieldInitializer_2
    implements
        NodeReplacerTest_Getter<ConstructorFieldInitializer, Expression> {
  @override
  Expression get(ConstructorFieldInitializer node) => node.expression;
}

class Getter_NodeReplacerTest_test_constructorName
    implements NodeReplacerTest_Getter<ConstructorName, TypeName> {
  @override
  TypeName get(ConstructorName node) => node.type;
}

class Getter_NodeReplacerTest_test_constructorName_2
    implements NodeReplacerTest_Getter<ConstructorName, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ConstructorName node) => node.name;
}

class Getter_NodeReplacerTest_test_continueStatement
    implements NodeReplacerTest_Getter<ContinueStatement, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ContinueStatement node) => node.label;
}

class Getter_NodeReplacerTest_test_declaredIdentifier
    implements NodeReplacerTest_Getter<DeclaredIdentifier, TypeAnnotation> {
  @override
  TypeAnnotation get(DeclaredIdentifier node) => node.type;
}

class Getter_NodeReplacerTest_test_declaredIdentifier_2
    implements NodeReplacerTest_Getter<DeclaredIdentifier, SimpleIdentifier> {
  @override
  SimpleIdentifier get(DeclaredIdentifier node) => node.identifier;
}

class Getter_NodeReplacerTest_test_defaultFormalParameter
    implements
        NodeReplacerTest_Getter<DefaultFormalParameter, NormalFormalParameter> {
  @override
  NormalFormalParameter get(DefaultFormalParameter node) => node.parameter;
}

class Getter_NodeReplacerTest_test_defaultFormalParameter_2
    implements NodeReplacerTest_Getter<DefaultFormalParameter, Expression> {
  @override
  Expression get(DefaultFormalParameter node) => node.defaultValue;
}

class Getter_NodeReplacerTest_test_doStatement
    implements NodeReplacerTest_Getter<DoStatement, Expression> {
  @override
  Expression get(DoStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_doStatement_2
    implements NodeReplacerTest_Getter<DoStatement, Statement> {
  @override
  Statement get(DoStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_enumConstantDeclaration
    implements
        NodeReplacerTest_Getter<EnumConstantDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(EnumConstantDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_enumDeclaration
    implements NodeReplacerTest_Getter<EnumDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(EnumDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_expressionFunctionBody
    implements NodeReplacerTest_Getter<ExpressionFunctionBody, Expression> {
  @override
  Expression get(ExpressionFunctionBody node) => node.expression;
}

class Getter_NodeReplacerTest_test_expressionStatement
    implements NodeReplacerTest_Getter<ExpressionStatement, Expression> {
  @override
  Expression get(ExpressionStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_extendsClause
    implements NodeReplacerTest_Getter<ExtendsClause, TypeName> {
  @override
  TypeName get(ExtendsClause node) => node.superclass;
}

class Getter_NodeReplacerTest_test_fieldDeclaration
    implements
        NodeReplacerTest_Getter<FieldDeclaration, VariableDeclarationList> {
  @override
  VariableDeclarationList get(FieldDeclaration node) => node.fields;
}

class Getter_NodeReplacerTest_test_fieldFormalParameter
    implements
        NodeReplacerTest_Getter<FieldFormalParameter, FormalParameterList> {
  @override
  FormalParameterList get(FieldFormalParameter node) => node.parameters;
}

class Getter_NodeReplacerTest_test_fieldFormalParameter_2
    implements NodeReplacerTest_Getter<FieldFormalParameter, TypeAnnotation> {
  @override
  TypeAnnotation get(FieldFormalParameter node) => node.type;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier
    implements NodeReplacerTest_Getter<ForEachStatement, Statement> {
  @override
  Statement get(ForEachStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_2
    implements NodeReplacerTest_Getter<ForEachStatement, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ForEachStatement node) => node.identifier;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_3
    implements NodeReplacerTest_Getter<ForEachStatement, Expression> {
  @override
  Expression get(ForEachStatement node) => node.iterable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable
    implements NodeReplacerTest_Getter<ForEachStatement, Expression> {
  @override
  Expression get(ForEachStatement node) => node.iterable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_2
    implements NodeReplacerTest_Getter<ForEachStatement, DeclaredIdentifier> {
  @override
  DeclaredIdentifier get(ForEachStatement node) => node.loopVariable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_3
    implements NodeReplacerTest_Getter<ForEachStatement, Statement> {
  @override
  Statement get(ForEachStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization
    implements NodeReplacerTest_Getter<ForStatement, Statement> {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization_2
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression get(ForStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization_3
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression get(ForStatement node) => node.initialization;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables
    implements NodeReplacerTest_Getter<ForStatement, Statement> {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables_2
    implements NodeReplacerTest_Getter<ForStatement, VariableDeclarationList> {
  @override
  VariableDeclarationList get(ForStatement node) => node.variables;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables_3
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression get(ForStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_functionDeclaration
    implements NodeReplacerTest_Getter<FunctionDeclaration, TypeAnnotation> {
  @override
  TypeAnnotation get(FunctionDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionDeclaration_2
    implements
        NodeReplacerTest_Getter<FunctionDeclaration, FunctionExpression> {
  @override
  FunctionExpression get(FunctionDeclaration node) => node.functionExpression;
}

class Getter_NodeReplacerTest_test_functionDeclaration_3
    implements NodeReplacerTest_Getter<FunctionDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(FunctionDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_functionDeclarationStatement
    implements
        NodeReplacerTest_Getter<FunctionDeclarationStatement,
            FunctionDeclaration> {
  @override
  FunctionDeclaration get(FunctionDeclarationStatement node) =>
      node.functionDeclaration;
}

class Getter_NodeReplacerTest_test_functionExpression
    implements
        NodeReplacerTest_Getter<FunctionExpression, FormalParameterList> {
  @override
  FormalParameterList get(FunctionExpression node) => node.parameters;
}

class Getter_NodeReplacerTest_test_functionExpression_2
    implements NodeReplacerTest_Getter<FunctionExpression, FunctionBody> {
  @override
  FunctionBody get(FunctionExpression node) => node.body;
}

class Getter_NodeReplacerTest_test_functionExpressionInvocation
    implements
        NodeReplacerTest_Getter<FunctionExpressionInvocation, Expression> {
  @override
  Expression get(FunctionExpressionInvocation node) => node.function;
}

class Getter_NodeReplacerTest_test_functionExpressionInvocation_2
    implements
        NodeReplacerTest_Getter<FunctionExpressionInvocation, ArgumentList> {
  @override
  ArgumentList get(FunctionExpressionInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_functionTypeAlias
    implements NodeReplacerTest_Getter<FunctionTypeAlias, TypeParameterList> {
  @override
  TypeParameterList get(FunctionTypeAlias node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_2
    implements NodeReplacerTest_Getter<FunctionTypeAlias, FormalParameterList> {
  @override
  FormalParameterList get(FunctionTypeAlias node) => node.parameters;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_3
    implements NodeReplacerTest_Getter<FunctionTypeAlias, TypeAnnotation> {
  @override
  TypeAnnotation get(FunctionTypeAlias node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_4
    implements NodeReplacerTest_Getter<FunctionTypeAlias, SimpleIdentifier> {
  @override
  SimpleIdentifier get(FunctionTypeAlias node) => node.name;
}

class Getter_NodeReplacerTest_test_functionTypedFormalParameter
    implements
        NodeReplacerTest_Getter<FunctionTypedFormalParameter, TypeAnnotation> {
  @override
  TypeAnnotation get(FunctionTypedFormalParameter node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionTypedFormalParameter_2
    implements
        NodeReplacerTest_Getter<FunctionTypedFormalParameter,
            FormalParameterList> {
  @override
  FormalParameterList get(FunctionTypedFormalParameter node) => node.parameters;
}

class Getter_NodeReplacerTest_test_ifStatement
    implements NodeReplacerTest_Getter<IfStatement, Expression> {
  @override
  Expression get(IfStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_ifStatement_2
    implements NodeReplacerTest_Getter<IfStatement, Statement> {
  @override
  Statement get(IfStatement node) => node.elseStatement;
}

class Getter_NodeReplacerTest_test_ifStatement_3
    implements NodeReplacerTest_Getter<IfStatement, Statement> {
  @override
  Statement get(IfStatement node) => node.thenStatement;
}

class Getter_NodeReplacerTest_test_importDirective
    implements NodeReplacerTest_Getter<ImportDirective, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ImportDirective node) => node.prefix;
}

class Getter_NodeReplacerTest_test_indexExpression
    implements NodeReplacerTest_Getter<IndexExpression, Expression> {
  @override
  Expression get(IndexExpression node) => node.target;
}

class Getter_NodeReplacerTest_test_indexExpression_2
    implements NodeReplacerTest_Getter<IndexExpression, Expression> {
  @override
  Expression get(IndexExpression node) => node.index;
}

class Getter_NodeReplacerTest_test_instanceCreationExpression
    implements
        NodeReplacerTest_Getter<InstanceCreationExpression, ArgumentList> {
  @override
  ArgumentList get(InstanceCreationExpression node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_instanceCreationExpression_2
    implements
        NodeReplacerTest_Getter<InstanceCreationExpression, ConstructorName> {
  @override
  ConstructorName get(InstanceCreationExpression node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_interpolationExpression
    implements NodeReplacerTest_Getter<InterpolationExpression, Expression> {
  @override
  Expression get(InterpolationExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_isExpression
    implements NodeReplacerTest_Getter<IsExpression, Expression> {
  @override
  Expression get(IsExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_isExpression_2
    implements NodeReplacerTest_Getter<IsExpression, TypeAnnotation> {
  @override
  TypeAnnotation get(IsExpression node) => node.type;
}

class Getter_NodeReplacerTest_test_label
    implements NodeReplacerTest_Getter<Label, SimpleIdentifier> {
  @override
  SimpleIdentifier get(Label node) => node.label;
}

class Getter_NodeReplacerTest_test_labeledStatement
    implements NodeReplacerTest_Getter<LabeledStatement, Statement> {
  @override
  Statement get(LabeledStatement node) => node.statement;
}

class Getter_NodeReplacerTest_test_libraryDirective
    implements NodeReplacerTest_Getter<LibraryDirective, LibraryIdentifier> {
  @override
  LibraryIdentifier get(LibraryDirective node) => node.name;
}

class Getter_NodeReplacerTest_test_mapLiteralEntry
    implements NodeReplacerTest_Getter<MapLiteralEntry, Expression> {
  @override
  Expression get(MapLiteralEntry node) => node.value;
}

class Getter_NodeReplacerTest_test_mapLiteralEntry_2
    implements NodeReplacerTest_Getter<MapLiteralEntry, Expression> {
  @override
  Expression get(MapLiteralEntry node) => node.key;
}

class Getter_NodeReplacerTest_test_methodDeclaration
    implements NodeReplacerTest_Getter<MethodDeclaration, TypeAnnotation> {
  @override
  TypeAnnotation get(MethodDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_methodDeclaration_2
    implements NodeReplacerTest_Getter<MethodDeclaration, FunctionBody> {
  @override
  FunctionBody get(MethodDeclaration node) => node.body;
}

class Getter_NodeReplacerTest_test_methodDeclaration_3
    implements NodeReplacerTest_Getter<MethodDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(MethodDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_methodDeclaration_4
    implements NodeReplacerTest_Getter<MethodDeclaration, FormalParameterList> {
  @override
  FormalParameterList get(MethodDeclaration node) => node.parameters;
}

class Getter_NodeReplacerTest_test_methodInvocation
    implements NodeReplacerTest_Getter<MethodInvocation, ArgumentList> {
  @override
  ArgumentList get(MethodInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_methodInvocation_2
    implements NodeReplacerTest_Getter<MethodInvocation, Expression> {
  @override
  Expression get(MethodInvocation node) => node.target;
}

class Getter_NodeReplacerTest_test_methodInvocation_3
    implements NodeReplacerTest_Getter<MethodInvocation, SimpleIdentifier> {
  @override
  SimpleIdentifier get(MethodInvocation node) => node.methodName;
}

class Getter_NodeReplacerTest_test_namedExpression
    implements NodeReplacerTest_Getter<NamedExpression, Label> {
  @override
  Label get(NamedExpression node) => node.name;
}

class Getter_NodeReplacerTest_test_namedExpression_2
    implements NodeReplacerTest_Getter<NamedExpression, Expression> {
  @override
  Expression get(NamedExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_nativeClause
    implements NodeReplacerTest_Getter<NativeClause, StringLiteral> {
  @override
  StringLiteral get(NativeClause node) => node.name;
}

class Getter_NodeReplacerTest_test_nativeFunctionBody
    implements NodeReplacerTest_Getter<NativeFunctionBody, StringLiteral> {
  @override
  StringLiteral get(NativeFunctionBody node) => node.stringLiteral;
}

class Getter_NodeReplacerTest_test_parenthesizedExpression
    implements NodeReplacerTest_Getter<ParenthesizedExpression, Expression> {
  @override
  Expression get(ParenthesizedExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_partOfDirective
    implements NodeReplacerTest_Getter<PartOfDirective, LibraryIdentifier> {
  @override
  LibraryIdentifier get(PartOfDirective node) => node.libraryName;
}

class Getter_NodeReplacerTest_test_postfixExpression
    implements NodeReplacerTest_Getter<PostfixExpression, Expression> {
  @override
  Expression get(PostfixExpression node) => node.operand;
}

class Getter_NodeReplacerTest_test_prefixedIdentifier
    implements NodeReplacerTest_Getter<PrefixedIdentifier, SimpleIdentifier> {
  @override
  SimpleIdentifier get(PrefixedIdentifier node) => node.identifier;
}

class Getter_NodeReplacerTest_test_prefixedIdentifier_2
    implements NodeReplacerTest_Getter<PrefixedIdentifier, SimpleIdentifier> {
  @override
  SimpleIdentifier get(PrefixedIdentifier node) => node.prefix;
}

class Getter_NodeReplacerTest_test_prefixExpression
    implements NodeReplacerTest_Getter<PrefixExpression, Expression> {
  @override
  Expression get(PrefixExpression node) => node.operand;
}

class Getter_NodeReplacerTest_test_propertyAccess
    implements NodeReplacerTest_Getter<PropertyAccess, Expression> {
  @override
  Expression get(PropertyAccess node) => node.target;
}

class Getter_NodeReplacerTest_test_propertyAccess_2
    implements NodeReplacerTest_Getter<PropertyAccess, SimpleIdentifier> {
  @override
  SimpleIdentifier get(PropertyAccess node) => node.propertyName;
}

class Getter_NodeReplacerTest_test_redirectingConstructorInvocation
    implements
        NodeReplacerTest_Getter<RedirectingConstructorInvocation,
            SimpleIdentifier> {
  @override
  SimpleIdentifier get(RedirectingConstructorInvocation node) =>
      node.constructorName;
}

class Getter_NodeReplacerTest_test_redirectingConstructorInvocation_2
    implements
        NodeReplacerTest_Getter<RedirectingConstructorInvocation,
            ArgumentList> {
  @override
  ArgumentList get(RedirectingConstructorInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_returnStatement
    implements NodeReplacerTest_Getter<ReturnStatement, Expression> {
  @override
  Expression get(ReturnStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_simpleFormalParameter
    implements NodeReplacerTest_Getter<SimpleFormalParameter, TypeAnnotation> {
  @override
  TypeAnnotation get(SimpleFormalParameter node) => node.type;
}

class Getter_NodeReplacerTest_test_superConstructorInvocation
    implements
        NodeReplacerTest_Getter<SuperConstructorInvocation, SimpleIdentifier> {
  @override
  SimpleIdentifier get(SuperConstructorInvocation node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_superConstructorInvocation_2
    implements
        NodeReplacerTest_Getter<SuperConstructorInvocation, ArgumentList> {
  @override
  ArgumentList get(SuperConstructorInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_switchCase
    implements NodeReplacerTest_Getter<SwitchCase, Expression> {
  @override
  Expression get(SwitchCase node) => node.expression;
}

class Getter_NodeReplacerTest_test_switchStatement
    implements NodeReplacerTest_Getter<SwitchStatement, Expression> {
  @override
  Expression get(SwitchStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_throwExpression
    implements NodeReplacerTest_Getter<ThrowExpression, Expression> {
  @override
  Expression get(ThrowExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_topLevelVariableDeclaration
    implements
        NodeReplacerTest_Getter<TopLevelVariableDeclaration,
            VariableDeclarationList> {
  @override
  VariableDeclarationList get(TopLevelVariableDeclaration node) =>
      node.variables;
}

class Getter_NodeReplacerTest_test_tryStatement
    implements NodeReplacerTest_Getter<TryStatement, Block> {
  @override
  Block get(TryStatement node) => node.finallyBlock;
}

class Getter_NodeReplacerTest_test_tryStatement_2
    implements NodeReplacerTest_Getter<TryStatement, Block> {
  @override
  Block get(TryStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_typeName
    implements NodeReplacerTest_Getter<TypeName, TypeArgumentList> {
  @override
  TypeArgumentList get(TypeName node) => node.typeArguments;
}

class Getter_NodeReplacerTest_test_typeName_2
    implements NodeReplacerTest_Getter<TypeName, Identifier> {
  @override
  Identifier get(TypeName node) => node.name;
}

class Getter_NodeReplacerTest_test_typeParameter
    implements NodeReplacerTest_Getter<TypeParameter, TypeAnnotation> {
  @override
  TypeAnnotation get(TypeParameter node) => node.bound;
}

class Getter_NodeReplacerTest_test_typeParameter_2
    implements NodeReplacerTest_Getter<TypeParameter, SimpleIdentifier> {
  @override
  SimpleIdentifier get(TypeParameter node) => node.name;
}

class Getter_NodeReplacerTest_test_variableDeclaration
    implements NodeReplacerTest_Getter<VariableDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(VariableDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_variableDeclaration_2
    implements NodeReplacerTest_Getter<VariableDeclaration, Expression> {
  @override
  Expression get(VariableDeclaration node) => node.initializer;
}

class Getter_NodeReplacerTest_test_variableDeclarationList
    implements
        NodeReplacerTest_Getter<VariableDeclarationList, TypeAnnotation> {
  @override
  TypeAnnotation get(VariableDeclarationList node) => node.type;
}

class Getter_NodeReplacerTest_test_variableDeclarationStatement
    implements
        NodeReplacerTest_Getter<VariableDeclarationStatement,
            VariableDeclarationList> {
  @override
  VariableDeclarationList get(VariableDeclarationStatement node) =>
      node.variables;
}

class Getter_NodeReplacerTest_test_whileStatement
    implements NodeReplacerTest_Getter<WhileStatement, Expression> {
  @override
  Expression get(WhileStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_whileStatement_2
    implements NodeReplacerTest_Getter<WhileStatement, Statement> {
  @override
  Statement get(WhileStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_yieldStatement
    implements NodeReplacerTest_Getter<YieldStatement, Expression> {
  @override
  Expression get(YieldStatement node) => node.expression;
}

class Getter_NodeReplacerTest_testAnnotatedNode
    implements NodeReplacerTest_Getter<AnnotatedNode, Comment> {
  @override
  Comment get(AnnotatedNode node) => node.documentationComment;
}

class Getter_NodeReplacerTest_testNormalFormalParameter
    implements
        NodeReplacerTest_Getter<NormalFormalParameter, SimpleIdentifier> {
  @override
  SimpleIdentifier get(NormalFormalParameter node) => node.identifier;
}

class Getter_NodeReplacerTest_testNormalFormalParameter_2
    implements NodeReplacerTest_Getter<NormalFormalParameter, Comment> {
  @override
  Comment get(NormalFormalParameter node) => node.documentationComment;
}

class Getter_NodeReplacerTest_testTypedLiteral
    implements NodeReplacerTest_Getter<TypedLiteral, TypeArgumentList> {
  @override
  TypeArgumentList get(TypedLiteral node) => node.typeArguments;
}

class Getter_NodeReplacerTest_testUriBasedDirective
    implements NodeReplacerTest_Getter<UriBasedDirective, StringLiteral> {
  @override
  StringLiteral get(UriBasedDirective node) => node.uri;
}

@reflectiveTest
class LineInfoTest {
  void test_creation() {
    expect(new LineInfo(<int>[0]), isNotNull);
  }

  void test_creation_empty() {
    expect(() {
      new LineInfo(<int>[]);
    }, throwsArgumentError);
  }

  void test_creation_null() {
    expect(() {
      new LineInfo(null);
    }, throwsArgumentError);
  }

  void test_firstLine() {
    LineInfo info = new LineInfo(<int>[0, 12, 34]);
    LineInfo_Location location = info.getLocation(4);
    expect(location.lineNumber, 1);
    expect(location.columnNumber, 5);
  }

  void test_lastLine() {
    LineInfo info = new LineInfo(<int>[0, 12, 34]);
    LineInfo_Location location = info.getLocation(36);
    expect(location.lineNumber, 3);
    expect(location.columnNumber, 3);
  }

  void test_middleLine() {
    LineInfo info = new LineInfo(<int>[0, 12, 34]);
    LineInfo_Location location = info.getLocation(12);
    expect(location.lineNumber, 2);
    expect(location.columnNumber, 1);
  }
}

class ListGetter_NodeReplacerTest_test_adjacentStrings
    extends NodeReplacerTest_ListGetter<AdjacentStrings, StringLiteral> {
  ListGetter_NodeReplacerTest_test_adjacentStrings(int arg0) : super(arg0);

  @override
  NodeList<StringLiteral> getList(AdjacentStrings node) => node.strings;
}

class ListGetter_NodeReplacerTest_test_adjacentStrings_2
    extends NodeReplacerTest_ListGetter<AdjacentStrings, StringLiteral> {
  ListGetter_NodeReplacerTest_test_adjacentStrings_2(int arg0) : super(arg0);

  @override
  NodeList<StringLiteral> getList(AdjacentStrings node) => node.strings;
}

class ListGetter_NodeReplacerTest_test_argumentList
    extends NodeReplacerTest_ListGetter<ArgumentList, Expression> {
  ListGetter_NodeReplacerTest_test_argumentList(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(ArgumentList node) => node.arguments;
}

class ListGetter_NodeReplacerTest_test_block
    extends NodeReplacerTest_ListGetter<Block, Statement> {
  ListGetter_NodeReplacerTest_test_block(int arg0) : super(arg0);

  @override
  NodeList<Statement> getList(Block node) => node.statements;
}

class ListGetter_NodeReplacerTest_test_cascadeExpression
    extends NodeReplacerTest_ListGetter<CascadeExpression, Expression> {
  ListGetter_NodeReplacerTest_test_cascadeExpression(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(CascadeExpression node) => node.cascadeSections;
}

class ListGetter_NodeReplacerTest_test_classDeclaration
    extends NodeReplacerTest_ListGetter<ClassDeclaration, ClassMember> {
  ListGetter_NodeReplacerTest_test_classDeclaration(int arg0) : super(arg0);

  @override
  NodeList<ClassMember> getList(ClassDeclaration node) => node.members;
}

class ListGetter_NodeReplacerTest_test_comment
    extends NodeReplacerTest_ListGetter<Comment, CommentReference> {
  ListGetter_NodeReplacerTest_test_comment(int arg0) : super(arg0);

  @override
  NodeList<CommentReference> getList(Comment node) => node.references;
}

class ListGetter_NodeReplacerTest_test_compilationUnit
    extends NodeReplacerTest_ListGetter<CompilationUnit, Directive> {
  ListGetter_NodeReplacerTest_test_compilationUnit(int arg0) : super(arg0);

  @override
  NodeList<Directive> getList(CompilationUnit node) => node.directives;
}

class ListGetter_NodeReplacerTest_test_compilationUnit_2
    extends NodeReplacerTest_ListGetter<CompilationUnit,
        CompilationUnitMember> {
  ListGetter_NodeReplacerTest_test_compilationUnit_2(int arg0) : super(arg0);

  @override
  NodeList<CompilationUnitMember> getList(CompilationUnit node) =>
      node.declarations;
}

class ListGetter_NodeReplacerTest_test_constructorDeclaration
    extends NodeReplacerTest_ListGetter<ConstructorDeclaration,
        ConstructorInitializer> {
  ListGetter_NodeReplacerTest_test_constructorDeclaration(int arg0)
      : super(arg0);

  @override
  NodeList<ConstructorInitializer> getList(ConstructorDeclaration node) =>
      node.initializers;
}

class ListGetter_NodeReplacerTest_test_formalParameterList
    extends NodeReplacerTest_ListGetter<FormalParameterList, FormalParameter> {
  ListGetter_NodeReplacerTest_test_formalParameterList(int arg0) : super(arg0);

  @override
  NodeList<FormalParameter> getList(FormalParameterList node) =>
      node.parameters;
}

class ListGetter_NodeReplacerTest_test_forStatement_withInitialization
    extends NodeReplacerTest_ListGetter<ForStatement, Expression> {
  ListGetter_NodeReplacerTest_test_forStatement_withInitialization(int arg0)
      : super(arg0);

  @override
  NodeList<Expression> getList(ForStatement node) => node.updaters;
}

class ListGetter_NodeReplacerTest_test_forStatement_withVariables
    extends NodeReplacerTest_ListGetter<ForStatement, Expression> {
  ListGetter_NodeReplacerTest_test_forStatement_withVariables(int arg0)
      : super(arg0);

  @override
  NodeList<Expression> getList(ForStatement node) => node.updaters;
}

class ListGetter_NodeReplacerTest_test_hideCombinator
    extends NodeReplacerTest_ListGetter<HideCombinator, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_hideCombinator(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(HideCombinator node) => node.hiddenNames;
}

class ListGetter_NodeReplacerTest_test_implementsClause
    extends NodeReplacerTest_ListGetter<ImplementsClause, TypeName> {
  ListGetter_NodeReplacerTest_test_implementsClause(int arg0) : super(arg0);

  @override
  NodeList<TypeName> getList(ImplementsClause node) => node.interfaces;
}

class ListGetter_NodeReplacerTest_test_labeledStatement
    extends NodeReplacerTest_ListGetter<LabeledStatement, Label> {
  ListGetter_NodeReplacerTest_test_labeledStatement(int arg0) : super(arg0);

  @override
  NodeList<Label> getList(LabeledStatement node) => node.labels;
}

class ListGetter_NodeReplacerTest_test_libraryIdentifier
    extends NodeReplacerTest_ListGetter<LibraryIdentifier, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_libraryIdentifier(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(LibraryIdentifier node) => node.components;
}

class ListGetter_NodeReplacerTest_test_listLiteral
    extends NodeReplacerTest_ListGetter<ListLiteral, Expression> {
  ListGetter_NodeReplacerTest_test_listLiteral(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(ListLiteral node) => node.elements;
}

class ListGetter_NodeReplacerTest_test_mapLiteral
    extends NodeReplacerTest_ListGetter<MapLiteral, MapLiteralEntry> {
  ListGetter_NodeReplacerTest_test_mapLiteral(int arg0) : super(arg0);

  @override
  NodeList<MapLiteralEntry> getList(MapLiteral node) => node.entries;
}

class ListGetter_NodeReplacerTest_test_showCombinator
    extends NodeReplacerTest_ListGetter<ShowCombinator, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_showCombinator(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(ShowCombinator node) => node.shownNames;
}

class ListGetter_NodeReplacerTest_test_stringInterpolation
    extends NodeReplacerTest_ListGetter<StringInterpolation,
        InterpolationElement> {
  ListGetter_NodeReplacerTest_test_stringInterpolation(int arg0) : super(arg0);

  @override
  NodeList<InterpolationElement> getList(StringInterpolation node) =>
      node.elements;
}

class ListGetter_NodeReplacerTest_test_switchStatement
    extends NodeReplacerTest_ListGetter<SwitchStatement, SwitchMember> {
  ListGetter_NodeReplacerTest_test_switchStatement(int arg0) : super(arg0);

  @override
  NodeList<SwitchMember> getList(SwitchStatement node) => node.members;
}

class ListGetter_NodeReplacerTest_test_tryStatement
    extends NodeReplacerTest_ListGetter<TryStatement, CatchClause> {
  ListGetter_NodeReplacerTest_test_tryStatement(int arg0) : super(arg0);

  @override
  NodeList<CatchClause> getList(TryStatement node) => node.catchClauses;
}

class ListGetter_NodeReplacerTest_test_typeArgumentList
    extends NodeReplacerTest_ListGetter<TypeArgumentList, TypeAnnotation> {
  ListGetter_NodeReplacerTest_test_typeArgumentList(int arg0) : super(arg0);

  @override
  NodeList<TypeAnnotation> getList(TypeArgumentList node) => node.arguments;
}

class ListGetter_NodeReplacerTest_test_typeParameterList
    extends NodeReplacerTest_ListGetter<TypeParameterList, TypeParameter> {
  ListGetter_NodeReplacerTest_test_typeParameterList(int arg0) : super(arg0);

  @override
  NodeList<TypeParameter> getList(TypeParameterList node) =>
      node.typeParameters;
}

class ListGetter_NodeReplacerTest_test_variableDeclarationList
    extends NodeReplacerTest_ListGetter<VariableDeclarationList,
        VariableDeclaration> {
  ListGetter_NodeReplacerTest_test_variableDeclarationList(int arg0)
      : super(arg0);

  @override
  NodeList<VariableDeclaration> getList(VariableDeclarationList node) =>
      node.variables;
}

class ListGetter_NodeReplacerTest_test_withClause
    extends NodeReplacerTest_ListGetter<WithClause, TypeName> {
  ListGetter_NodeReplacerTest_test_withClause(int arg0) : super(arg0);

  @override
  NodeList<TypeName> getList(WithClause node) => node.mixinTypes;
}

class ListGetter_NodeReplacerTest_testAnnotatedNode
    extends NodeReplacerTest_ListGetter<AnnotatedNode, Annotation> {
  ListGetter_NodeReplacerTest_testAnnotatedNode(int arg0) : super(arg0);

  @override
  NodeList<Annotation> getList(AnnotatedNode node) => node.metadata;
}

class ListGetter_NodeReplacerTest_testNamespaceDirective
    extends NodeReplacerTest_ListGetter<NamespaceDirective, Combinator> {
  ListGetter_NodeReplacerTest_testNamespaceDirective(int arg0) : super(arg0);

  @override
  NodeList<Combinator> getList(NamespaceDirective node) => node.combinators;
}

class ListGetter_NodeReplacerTest_testNormalFormalParameter
    extends NodeReplacerTest_ListGetter<NormalFormalParameter, Annotation> {
  ListGetter_NodeReplacerTest_testNormalFormalParameter(int arg0) : super(arg0);

  @override
  NodeList<Annotation> getList(NormalFormalParameter node) => node.metadata;
}

class ListGetter_NodeReplacerTest_testSwitchMember
    extends NodeReplacerTest_ListGetter<SwitchMember, Label> {
  ListGetter_NodeReplacerTest_testSwitchMember(int arg0) : super(arg0);

  @override
  NodeList<Label> getList(SwitchMember node) => node.labels;
}

class ListGetter_NodeReplacerTest_testSwitchMember_2
    extends NodeReplacerTest_ListGetter<SwitchMember, Statement> {
  ListGetter_NodeReplacerTest_testSwitchMember_2(int arg0) : super(arg0);

  @override
  NodeList<Statement> getList(SwitchMember node) => node.statements;
}

@reflectiveTest
class MultipleMapIteratorTest extends EngineTestCase {
  void test_multipleMaps_firstEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    Map<String, String> map2 = new HashMap<String, String>();
    map2["k2"] = "v2";
    Map<String, String> map3 = new HashMap<String, String>();
    map3["k3"] = "v3";
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_multipleMaps_lastEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    map1["k1"] = "v1";
    Map<String, String> map2 = new HashMap<String, String>();
    map2["k2"] = "v2";
    Map<String, String> map3 = new HashMap<String, String>();
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_multipleMaps_middleEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    map1["k1"] = "v1";
    Map<String, String> map2 = new HashMap<String, String>();
    Map<String, String> map3 = new HashMap<String, String>();
    map3["k3"] = "v3";
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_multipleMaps_nonEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    map1["k1"] = "v1";
    Map<String, String> map2 = new HashMap<String, String>();
    map2["k2"] = "v2";
    Map<String, String> map3 = new HashMap<String, String>();
    map3["k3"] = "v3";
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_noMap() {
    MultipleMapIterator<String, String> iterator = _iterator([]);
    expect(iterator.moveNext(), isFalse);
    expect(iterator.moveNext(), isFalse);
  }

  void test_singleMap_empty() {
    Map<String, String> map = new HashMap<String, String>();
    MultipleMapIterator<String, String> iterator = _iterator(<Map>[map]);
    expect(iterator.moveNext(), isFalse);
    expect(() => iterator.key, throwsStateError);
    expect(() => iterator.value, throwsStateError);
    expect(() {
      iterator.value = 'x';
    }, throwsStateError);
  }

  void test_singleMap_multiple() {
    Map<String, String> map = new HashMap<String, String>();
    map["k1"] = "v1";
    map["k2"] = "v2";
    map["k3"] = "v3";
    MultipleMapIterator<String, String> iterator = _iterator([map]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_singleMap_single() {
    String key = "key";
    String value = "value";
    Map<String, String> map = new HashMap<String, String>();
    map[key] = value;
    MultipleMapIterator<String, String> iterator = _iterator([map]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.key, same(key));
    expect(iterator.value, same(value));
    String newValue = "newValue";
    iterator.value = newValue;
    expect(iterator.value, same(newValue));
    expect(iterator.moveNext(), isFalse);
  }

  MultipleMapIterator<String, String> _iterator(List<Map> maps) {
    return new MultipleMapIterator<String, String>(maps);
  }
}

@reflectiveTest
class NodeReplacerTest extends EngineTestCase {
  /**
   * An empty list of tokens.
   */
  static const List<Token> EMPTY_TOKEN_LIST = const <Token>[];

  void test_adjacentStrings() {
    AdjacentStrings node = AstTestFactory.adjacentStrings(
        [AstTestFactory.string2("a"), AstTestFactory.string2("b")]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_adjacentStrings_2(0));
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_adjacentStrings(1));
  }

  void test_annotation() {
    Annotation node = AstTestFactory.annotation2(
        AstTestFactory.identifier3("C"),
        AstTestFactory.identifier3("c"),
        AstTestFactory.argumentList([AstTestFactory.integer(0)]));
    _assertReplace(node, new Getter_NodeReplacerTest_test_annotation());
    _assertReplace(node, new Getter_NodeReplacerTest_test_annotation_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_annotation_2());
  }

  void test_argumentList() {
    ArgumentList node =
        AstTestFactory.argumentList([AstTestFactory.integer(0)]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_argumentList(0));
  }

  void test_asExpression() {
    AsExpression node = AstTestFactory.asExpression(
        AstTestFactory.integer(0),
        AstTestFactory.typeName3(
            AstTestFactory.identifier3("a"), [AstTestFactory.typeName4("C")]));
    _assertReplace(node, new Getter_NodeReplacerTest_test_asExpression_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_asExpression());
  }

  void test_assertStatement() {
    AssertStatement node = AstTestFactory.assertStatement(
        AstTestFactory.booleanLiteral(true), AstTestFactory.string2('foo'));
    _assertReplace(node, new Getter_NodeReplacerTest_test_assertStatement());
    _assertReplace(node, new Getter_NodeReplacerTest_test_assertStatement_2());
  }

  void test_assignmentExpression() {
    AssignmentExpression node = AstTestFactory.assignmentExpression(
        AstTestFactory.identifier3("l"),
        TokenType.EQ,
        AstTestFactory.identifier3("r"));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_assignmentExpression_2());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_assignmentExpression());
  }

  void test_awaitExpression() {
    var node = AstTestFactory.awaitExpression(AstTestFactory.identifier3("A"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_awaitExpression());
  }

  void test_binaryExpression() {
    BinaryExpression node = AstTestFactory.binaryExpression(
        AstTestFactory.identifier3("l"),
        TokenType.PLUS,
        AstTestFactory.identifier3("r"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_binaryExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_binaryExpression_2());
  }

  void test_block() {
    Block node = AstTestFactory.block([AstTestFactory.emptyStatement()]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_block(0));
  }

  void test_blockFunctionBody() {
    BlockFunctionBody node =
        AstTestFactory.blockFunctionBody(AstTestFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_blockFunctionBody());
  }

  void test_breakStatement() {
    BreakStatement node = AstTestFactory.breakStatement2("l");
    _assertReplace(node, new Getter_NodeReplacerTest_test_breakStatement());
  }

  void test_cascadeExpression() {
    CascadeExpression node = AstTestFactory.cascadeExpression(
        AstTestFactory.integer(0),
        [AstTestFactory.propertyAccess(null, AstTestFactory.identifier3("b"))]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_cascadeExpression());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_cascadeExpression(0));
  }

  void test_catchClause() {
    CatchClause node = AstTestFactory.catchClause5(
        AstTestFactory.typeName4("E"),
        "e",
        "s",
        [AstTestFactory.emptyStatement()]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_catchClause_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_catchClause_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_catchClause());
  }

  void test_classDeclaration() {
    ClassDeclaration node = AstTestFactory.classDeclaration(
        null,
        "A",
        AstTestFactory.typeParameterList(["E"]),
        AstTestFactory.extendsClause(AstTestFactory.typeName4("B")),
        AstTestFactory.withClause([AstTestFactory.typeName4("C")]),
        AstTestFactory.implementsClause([AstTestFactory.typeName4("D")]), [
      AstTestFactory.fieldDeclaration2(
          false, null, [AstTestFactory.variableDeclaration("f")])
    ]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    node.nativeClause = AstTestFactory.nativeClause("");
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_6());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_5());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_4());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_3());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_classDeclaration(0));
    _testAnnotatedNode(node);
  }

  void test_classTypeAlias() {
    ClassTypeAlias node = AstTestFactory.classTypeAlias(
        "A",
        AstTestFactory.typeParameterList(["E"]),
        null,
        AstTestFactory.typeName4("B"),
        AstTestFactory.withClause([AstTestFactory.typeName4("C")]),
        AstTestFactory.implementsClause([AstTestFactory.typeName4("D")]));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_4());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_5());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_2());
    _testAnnotatedNode(node);
  }

  void test_comment() {
    Comment node = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.references.add(
        astFactory.commentReference(null, AstTestFactory.identifier3("x")));
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_comment(0));
  }

  void test_commentReference() {
    CommentReference node =
        astFactory.commentReference(null, AstTestFactory.identifier3("x"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_commentReference());
  }

  void test_compilationUnit() {
    CompilationUnit node = AstTestFactory.compilationUnit8("", [
      AstTestFactory.libraryDirective2("lib")
    ], [
      AstTestFactory.topLevelVariableDeclaration2(
          null, [AstTestFactory.variableDeclaration("X")])
    ]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_compilationUnit());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_compilationUnit(0));
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_compilationUnit_2(0));
  }

  void test_conditionalExpression() {
    ConditionalExpression node = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true),
        AstTestFactory.integer(0),
        AstTestFactory.integer(1));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_conditionalExpression_3());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_conditionalExpression_2());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_conditionalExpression());
  }

  void test_constructorDeclaration() {
    ConstructorDeclaration node = AstTestFactory.constructorDeclaration2(
        null,
        null,
        AstTestFactory.identifier3("C"),
        "d",
        AstTestFactory.formalParameterList(),
        [
          AstTestFactory.constructorFieldInitializer(
              false, "x", AstTestFactory.integer(0))
        ],
        AstTestFactory.emptyFunctionBody());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    node.redirectedConstructor =
        AstTestFactory.constructorName(AstTestFactory.typeName4("B"), "a");
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_constructorDeclaration_3());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_constructorDeclaration_2());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_constructorDeclaration_4());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_constructorDeclaration());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_constructorDeclaration_5());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_constructorDeclaration(0));
    _testAnnotatedNode(node);
  }

  void test_constructorFieldInitializer() {
    ConstructorFieldInitializer node = AstTestFactory
        .constructorFieldInitializer(false, "f", AstTestFactory.integer(0));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_constructorFieldInitializer());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_constructorFieldInitializer_2());
  }

  void test_constructorName() {
    ConstructorName node =
        AstTestFactory.constructorName(AstTestFactory.typeName4("C"), "n");
    _assertReplace(node, new Getter_NodeReplacerTest_test_constructorName());
    _assertReplace(node, new Getter_NodeReplacerTest_test_constructorName_2());
  }

  void test_continueStatement() {
    ContinueStatement node = AstTestFactory.continueStatement("l");
    _assertReplace(node, new Getter_NodeReplacerTest_test_continueStatement());
  }

  void test_declaredIdentifier() {
    DeclaredIdentifier node =
        AstTestFactory.declaredIdentifier4(AstTestFactory.typeName4("C"), "i");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_declaredIdentifier());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_declaredIdentifier_2());
    _testAnnotatedNode(node);
  }

  void test_defaultFormalParameter() {
    DefaultFormalParameter node = AstTestFactory.positionalFormalParameter(
        AstTestFactory.simpleFormalParameter3("p"), AstTestFactory.integer(0));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_defaultFormalParameter());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_defaultFormalParameter_2());
  }

  void test_doStatement() {
    DoStatement node = AstTestFactory.doStatement(
        AstTestFactory.block(), AstTestFactory.booleanLiteral(true));
    _assertReplace(node, new Getter_NodeReplacerTest_test_doStatement_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_doStatement());
  }

  void test_enumConstantDeclaration() {
    EnumConstantDeclaration node = astFactory.enumConstantDeclaration(
        astFactory.endOfLineComment(EMPTY_TOKEN_LIST),
        [AstTestFactory.annotation(AstTestFactory.identifier3("a"))],
        AstTestFactory.identifier3("C"));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_enumConstantDeclaration());
    _testAnnotatedNode(node);
  }

  void test_enumDeclaration() {
    EnumDeclaration node = AstTestFactory.enumDeclaration2("E", ["ONE", "TWO"]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_enumDeclaration());
    _testAnnotatedNode(node);
  }

  void test_exportDirective() {
    ExportDirective node = AstTestFactory.exportDirective2("", [
      AstTestFactory.hideCombinator2(["C"])
    ]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _testNamespaceDirective(node);
  }

  void test_expressionFunctionBody() {
    ExpressionFunctionBody node =
        AstTestFactory.expressionFunctionBody(AstTestFactory.integer(0));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_expressionFunctionBody());
  }

  void test_expressionStatement() {
    ExpressionStatement node =
        AstTestFactory.expressionStatement(AstTestFactory.integer(0));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_expressionStatement());
  }

  void test_extendsClause() {
    ExtendsClause node =
        AstTestFactory.extendsClause(AstTestFactory.typeName4("S"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_extendsClause());
  }

  void test_fieldDeclaration() {
    FieldDeclaration node = AstTestFactory.fieldDeclaration(
        false,
        null,
        AstTestFactory.typeName4("C"),
        [AstTestFactory.variableDeclaration("c")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_fieldDeclaration());
    _testAnnotatedNode(node);
  }

  void test_fieldFormalParameter() {
    FieldFormalParameter node = AstTestFactory.fieldFormalParameter(
        null,
        AstTestFactory.typeName4("C"),
        "f",
        AstTestFactory.formalParameterList());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [
      AstTestFactory.annotation(AstTestFactory.identifier3("a"))
    ];
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_fieldFormalParameter_2());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_fieldFormalParameter());
    _testNormalFormalParameter(node);
  }

  void test_forEachStatement_withIdentifier() {
    ForEachStatement node = AstTestFactory.forEachStatement2(
        AstTestFactory.identifier3("i"),
        AstTestFactory.identifier3("l"),
        AstTestFactory.block());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_2());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_3());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forEachStatement_withIdentifier());
  }

  void test_forEachStatement_withLoopVariable() {
    ForEachStatement node = AstTestFactory.forEachStatement(
        AstTestFactory.declaredIdentifier3("e"),
        AstTestFactory.identifier3("l"),
        AstTestFactory.block());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_2());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_3());
  }

  void test_formalParameterList() {
    FormalParameterList node = AstTestFactory
        .formalParameterList([AstTestFactory.simpleFormalParameter3("p")]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_formalParameterList(0));
  }

  void test_forStatement_withInitialization() {
    ForStatement node = AstTestFactory.forStatement(
        AstTestFactory.identifier3("a"),
        AstTestFactory.booleanLiteral(true),
        [AstTestFactory.integer(0)],
        AstTestFactory.block());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forStatement_withInitialization_3());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forStatement_withInitialization_2());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_forStatement_withInitialization());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_forStatement_withInitialization(
            0));
  }

  void test_forStatement_withVariables() {
    ForStatement node = AstTestFactory.forStatement2(
        AstTestFactory.variableDeclarationList2(
            null, [AstTestFactory.variableDeclaration("i")]),
        AstTestFactory.booleanLiteral(true),
        [AstTestFactory.integer(0)],
        AstTestFactory.block());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_forStatement_withVariables_2());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_forStatement_withVariables_3());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_forStatement_withVariables());
    _assertReplace(node,
        new ListGetter_NodeReplacerTest_test_forStatement_withVariables(0));
  }

  void test_functionDeclaration() {
    FunctionDeclaration node = AstTestFactory.functionDeclaration(
        AstTestFactory.typeName4("R"),
        null,
        "f",
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody(AstTestFactory.block())));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionDeclaration());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionDeclaration_3());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_functionDeclarationStatement() {
    FunctionDeclarationStatement node =
        AstTestFactory.functionDeclarationStatement(
            AstTestFactory.typeName4("R"),
            null,
            "f",
            AstTestFactory.functionExpression2(
                AstTestFactory.formalParameterList(),
                AstTestFactory.blockFunctionBody(AstTestFactory.block())));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionDeclarationStatement());
  }

  void test_functionExpression() {
    FunctionExpression node = AstTestFactory.functionExpression2(
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody(AstTestFactory.block()));
    _assertReplace(node, new Getter_NodeReplacerTest_test_functionExpression());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionExpression_2());
  }

  void test_functionExpressionInvocation() {
    FunctionExpressionInvocation node = AstTestFactory
        .functionExpressionInvocation(
            AstTestFactory.identifier3("f"), [AstTestFactory.integer(0)]);
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionExpressionInvocation());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_functionExpressionInvocation_2());
  }

  void test_functionTypeAlias() {
    FunctionTypeAlias node = AstTestFactory.typeAlias(
        AstTestFactory.typeName4("R"),
        "F",
        AstTestFactory.typeParameterList(["E"]),
        AstTestFactory.formalParameterList());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionTypeAlias_3());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionTypeAlias_4());
    _assertReplace(node, new Getter_NodeReplacerTest_test_functionTypeAlias());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionTypeAlias_2());
    _testAnnotatedNode(node);
  }

  void test_functionTypedFormalParameter() {
    FunctionTypedFormalParameter node = AstTestFactory
        .functionTypedFormalParameter(AstTestFactory.typeName4("R"), "f",
            [AstTestFactory.simpleFormalParameter3("p")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [
      AstTestFactory.annotation(AstTestFactory.identifier3("a"))
    ];
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_functionTypedFormalParameter());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_functionTypedFormalParameter_2());
    _testNormalFormalParameter(node);
  }

  void test_hideCombinator() {
    HideCombinator node = AstTestFactory.hideCombinator2(["A", "B"]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_hideCombinator(0));
  }

  void test_ifStatement() {
    IfStatement node = AstTestFactory.ifStatement2(
        AstTestFactory.booleanLiteral(true),
        AstTestFactory.block(),
        AstTestFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_ifStatement());
    _assertReplace(node, new Getter_NodeReplacerTest_test_ifStatement_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_ifStatement_2());
  }

  void test_implementsClause() {
    ImplementsClause node = AstTestFactory.implementsClause(
        [AstTestFactory.typeName4("I"), AstTestFactory.typeName4("J")]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_implementsClause(0));
  }

  void test_importDirective() {
    ImportDirective node = AstTestFactory.importDirective3("", "p", [
      AstTestFactory.showCombinator2(["A"]),
      AstTestFactory.hideCombinator2(["B"])
    ]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_importDirective());
    _testNamespaceDirective(node);
  }

  void test_indexExpression() {
    IndexExpression node = AstTestFactory.indexExpression(
        AstTestFactory.identifier3("a"), AstTestFactory.identifier3("i"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_indexExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_indexExpression_2());
  }

  void test_instanceCreationExpression() {
    InstanceCreationExpression node = AstTestFactory
        .instanceCreationExpression3(null, AstTestFactory.typeName4("C"), "c",
            [AstTestFactory.integer(2)]);
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_instanceCreationExpression_2());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_instanceCreationExpression());
  }

  void test_interpolationExpression() {
    InterpolationExpression node = AstTestFactory.interpolationExpression2("x");
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_interpolationExpression());
  }

  void test_isExpression() {
    IsExpression node = AstTestFactory.isExpression(
        AstTestFactory.identifier3("v"), false, AstTestFactory.typeName4("T"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_isExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_isExpression_2());
  }

  void test_label() {
    Label node = AstTestFactory.label2("l");
    _assertReplace(node, new Getter_NodeReplacerTest_test_label());
  }

  void test_labeledStatement() {
    LabeledStatement node = AstTestFactory
        .labeledStatement([AstTestFactory.label2("l")], AstTestFactory.block());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_labeledStatement(0));
    _assertReplace(node, new Getter_NodeReplacerTest_test_labeledStatement());
  }

  void test_libraryDirective() {
    LibraryDirective node = AstTestFactory.libraryDirective2("lib");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_libraryDirective());
    _testAnnotatedNode(node);
  }

  void test_libraryIdentifier() {
    LibraryIdentifier node = AstTestFactory.libraryIdentifier2(["lib"]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_libraryIdentifier(0));
  }

  void test_listLiteral() {
    ListLiteral node = AstTestFactory.listLiteral2(
        null,
        AstTestFactory.typeArgumentList([AstTestFactory.typeName4("E")]),
        [AstTestFactory.identifier3("e")]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_listLiteral(0));
    _testTypedLiteral(node);
  }

  void test_mapLiteral() {
    MapLiteral node = AstTestFactory.mapLiteral(
        null,
        AstTestFactory.typeArgumentList([AstTestFactory.typeName4("E")]),
        [AstTestFactory.mapLiteralEntry("k", AstTestFactory.identifier3("v"))]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_mapLiteral(0));
    _testTypedLiteral(node);
  }

  void test_mapLiteralEntry() {
    MapLiteralEntry node =
        AstTestFactory.mapLiteralEntry("k", AstTestFactory.identifier3("v"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_mapLiteralEntry_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_mapLiteralEntry());
  }

  void test_methodDeclaration() {
    MethodDeclaration node = AstTestFactory.methodDeclaration2(
        null,
        AstTestFactory.typeName4("A"),
        null,
        null,
        AstTestFactory.identifier3("m"),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody(AstTestFactory.block()));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodDeclaration());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_methodDeclaration_3());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_methodDeclaration_4());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_methodDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_methodInvocation() {
    MethodInvocation node = AstTestFactory.methodInvocation(
        AstTestFactory.identifier3("t"), "m", [AstTestFactory.integer(0)]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodInvocation_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodInvocation_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodInvocation());
  }

  void test_namedExpression() {
    NamedExpression node =
        AstTestFactory.namedExpression2("l", AstTestFactory.identifier3("v"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_namedExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_namedExpression_2());
  }

  void test_nativeClause() {
    NativeClause node = AstTestFactory.nativeClause("");
    _assertReplace(node, new Getter_NodeReplacerTest_test_nativeClause());
  }

  void test_nativeFunctionBody() {
    NativeFunctionBody node = AstTestFactory.nativeFunctionBody("m");
    _assertReplace(node, new Getter_NodeReplacerTest_test_nativeFunctionBody());
  }

  void test_parenthesizedExpression() {
    ParenthesizedExpression node =
        AstTestFactory.parenthesizedExpression(AstTestFactory.integer(0));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_parenthesizedExpression());
  }

  void test_partDirective() {
    PartDirective node = AstTestFactory.partDirective2("");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _testUriBasedDirective(node);
  }

  void test_partOfDirective() {
    PartOfDirective node = AstTestFactory
        .partOfDirective(AstTestFactory.libraryIdentifier2(["lib"]));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, new Getter_NodeReplacerTest_test_partOfDirective());
    _testAnnotatedNode(node);
  }

  void test_postfixExpression() {
    PostfixExpression node = AstTestFactory.postfixExpression(
        AstTestFactory.identifier3("x"), TokenType.MINUS_MINUS);
    _assertReplace(node, new Getter_NodeReplacerTest_test_postfixExpression());
  }

  void test_prefixedIdentifier() {
    PrefixedIdentifier node = AstTestFactory.identifier5("a", "b");
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_prefixedIdentifier_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_prefixedIdentifier());
  }

  void test_prefixExpression() {
    PrefixExpression node = AstTestFactory.prefixExpression(
        TokenType.PLUS_PLUS, AstTestFactory.identifier3("y"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_prefixExpression());
  }

  void test_propertyAccess() {
    PropertyAccess node =
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("x"), "y");
    _assertReplace(node, new Getter_NodeReplacerTest_test_propertyAccess());
    _assertReplace(node, new Getter_NodeReplacerTest_test_propertyAccess_2());
  }

  void test_redirectingConstructorInvocation() {
    RedirectingConstructorInvocation node = AstTestFactory
        .redirectingConstructorInvocation2("c", [AstTestFactory.integer(0)]);
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_redirectingConstructorInvocation());
    _assertReplace(node,
        new Getter_NodeReplacerTest_test_redirectingConstructorInvocation_2());
  }

  void test_returnStatement() {
    ReturnStatement node =
        AstTestFactory.returnStatement2(AstTestFactory.integer(0));
    _assertReplace(node, new Getter_NodeReplacerTest_test_returnStatement());
  }

  void test_showCombinator() {
    ShowCombinator node = AstTestFactory.showCombinator2(["X", "Y"]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_showCombinator(0));
  }

  void test_simpleFormalParameter() {
    SimpleFormalParameter node = AstTestFactory.simpleFormalParameter4(
        AstTestFactory.typeName4("T"), "p");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [
      AstTestFactory.annotation(AstTestFactory.identifier3("a"))
    ];
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_simpleFormalParameter());
    _testNormalFormalParameter(node);
  }

  void test_stringInterpolation() {
    StringInterpolation node =
        AstTestFactory.string([AstTestFactory.interpolationExpression2("a")]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_stringInterpolation(0));
  }

  void test_superConstructorInvocation() {
    SuperConstructorInvocation node = AstTestFactory
        .superConstructorInvocation2("s", [AstTestFactory.integer(1)]);
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_superConstructorInvocation());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_superConstructorInvocation_2());
  }

  void test_switchCase() {
    SwitchCase node = AstTestFactory.switchCase2([AstTestFactory.label2("l")],
        AstTestFactory.integer(0), [AstTestFactory.block()]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_switchCase());
    _testSwitchMember(node);
  }

  void test_switchDefault() {
    SwitchDefault node = AstTestFactory
        .switchDefault([AstTestFactory.label2("l")], [AstTestFactory.block()]);
    _testSwitchMember(node);
  }

  void test_switchStatement() {
    SwitchStatement node =
        AstTestFactory.switchStatement(AstTestFactory.identifier3("x"), [
      AstTestFactory.switchCase2([AstTestFactory.label2("l")],
          AstTestFactory.integer(0), [AstTestFactory.block()]),
      AstTestFactory
          .switchDefault([AstTestFactory.label2("l")], [AstTestFactory.block()])
    ]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_switchStatement());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_switchStatement(0));
  }

  void test_throwExpression() {
    ThrowExpression node =
        AstTestFactory.throwExpression2(AstTestFactory.identifier3("e"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_throwExpression());
  }

  void test_topLevelVariableDeclaration() {
    TopLevelVariableDeclaration node = AstTestFactory
        .topLevelVariableDeclaration(null, AstTestFactory.typeName4("T"),
            [AstTestFactory.variableDeclaration("t")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_topLevelVariableDeclaration());
    _testAnnotatedNode(node);
  }

  void test_tryStatement() {
    TryStatement node = AstTestFactory.tryStatement3(
        AstTestFactory.block(),
        [
          AstTestFactory.catchClause("e", [AstTestFactory.block()])
        ],
        AstTestFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_tryStatement_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_tryStatement());
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_tryStatement(0));
  }

  void test_typeArgumentList() {
    TypeArgumentList node =
        AstTestFactory.typeArgumentList([AstTestFactory.typeName4("A")]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_typeArgumentList(0));
  }

  void test_typeName() {
    TypeName node = AstTestFactory.typeName4(
        "T", [AstTestFactory.typeName4("E"), AstTestFactory.typeName4("F")]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeName_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeName());
  }

  void test_typeParameter() {
    TypeParameter node =
        AstTestFactory.typeParameter2("E", AstTestFactory.typeName4("B"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeParameter_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeParameter());
  }

  void test_typeParameterList() {
    TypeParameterList node = AstTestFactory.typeParameterList(["A", "B"]);
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_typeParameterList(0));
  }

  void test_variableDeclaration() {
    VariableDeclaration node =
        AstTestFactory.variableDeclaration2("a", AstTestFactory.nullLiteral());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_variableDeclaration());
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_variableDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_variableDeclarationList() {
    VariableDeclarationList node = AstTestFactory.variableDeclarationList(
        null,
        AstTestFactory.typeName4("T"),
        [AstTestFactory.variableDeclaration("a")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_variableDeclarationList());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_test_variableDeclarationList(0));
    _testAnnotatedNode(node);
  }

  void test_variableDeclarationStatement() {
    VariableDeclarationStatement node = AstTestFactory
        .variableDeclarationStatement(null, AstTestFactory.typeName4("T"),
            [AstTestFactory.variableDeclaration("a")]);
    _assertReplace(
        node, new Getter_NodeReplacerTest_test_variableDeclarationStatement());
  }

  void test_whileStatement() {
    WhileStatement node = AstTestFactory.whileStatement(
        AstTestFactory.booleanLiteral(true), AstTestFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_whileStatement());
    _assertReplace(node, new Getter_NodeReplacerTest_test_whileStatement_2());
  }

  void test_withClause() {
    WithClause node =
        AstTestFactory.withClause([AstTestFactory.typeName4("M")]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_withClause(0));
  }

  void test_yieldStatement() {
    var node = AstTestFactory.yieldStatement(AstTestFactory.identifier3("A"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_yieldStatement());
  }

  void _assertReplace(AstNode parent, NodeReplacerTest_Getter getter) {
    AstNode child = getter.get(parent);
    if (child != null) {
      AstNode clone = child.accept(new AstCloner());
      NodeReplacer.replace(child, clone);
      expect(getter.get(parent), clone);
      expect(clone.parent, parent);
    }
  }

  void _testAnnotatedNode(AnnotatedNode node) {
    _assertReplace(node, new Getter_NodeReplacerTest_testAnnotatedNode());
    _assertReplace(node, new ListGetter_NodeReplacerTest_testAnnotatedNode(0));
  }

  void _testNamespaceDirective(NamespaceDirective node) {
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_testNamespaceDirective(0));
    _testUriBasedDirective(node);
  }

  void _testNormalFormalParameter(NormalFormalParameter node) {
    _assertReplace(
        node, new Getter_NodeReplacerTest_testNormalFormalParameter_2());
    _assertReplace(
        node, new Getter_NodeReplacerTest_testNormalFormalParameter());
    _assertReplace(
        node, new ListGetter_NodeReplacerTest_testNormalFormalParameter(0));
  }

  void _testSwitchMember(SwitchMember node) {
    _assertReplace(node, new ListGetter_NodeReplacerTest_testSwitchMember(0));
    _assertReplace(node, new ListGetter_NodeReplacerTest_testSwitchMember_2(0));
  }

  void _testTypedLiteral(TypedLiteral node) {
    _assertReplace(node, new Getter_NodeReplacerTest_testTypedLiteral());
  }

  void _testUriBasedDirective(UriBasedDirective node) {
    _assertReplace(node, new Getter_NodeReplacerTest_testUriBasedDirective());
    _testAnnotatedNode(node);
  }
}

abstract class NodeReplacerTest_Getter<P, C> {
  C get(P parent);
}

abstract class NodeReplacerTest_ListGetter<P extends AstNode, C extends AstNode>
    implements NodeReplacerTest_Getter<P, C> {
  final int _index;

  NodeReplacerTest_ListGetter(this._index);

  @override
  C get(P parent) {
    NodeList<C> list = getList(parent);
    if (list.isEmpty) {
      return null;
    }
    return list[_index];
  }

  NodeList<C> getList(P parent);
}

@reflectiveTest
class SingleMapIteratorTest extends EngineTestCase {
  void test_empty() {
    Map<String, String> map = new HashMap<String, String>();
    SingleMapIterator<String, String> iterator =
        new SingleMapIterator<String, String>(map);
    expect(iterator.moveNext(), isFalse);
    expect(() => iterator.key, throwsStateError);
    expect(() => iterator.value, throwsStateError);
    expect(() {
      iterator.value = 'x';
    }, throwsStateError);
    expect(iterator.moveNext(), isFalse);
  }

  void test_multiple() {
    Map<String, String> map = new HashMap<String, String>();
    map["k1"] = "v1";
    map["k2"] = "v2";
    map["k3"] = "v3";
    SingleMapIterator<String, String> iterator =
        new SingleMapIterator<String, String>(map);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_single() {
    String key = "key";
    String value = "value";
    Map<String, String> map = new HashMap<String, String>();
    map[key] = value;
    SingleMapIterator<String, String> iterator =
        new SingleMapIterator<String, String>(map);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.key, same(key));
    expect(iterator.value, same(value));
    String newValue = "newValue";
    iterator.value = newValue;
    expect(iterator.value, same(newValue));
    expect(iterator.moveNext(), isFalse);
  }
}

@reflectiveTest
class SourceRangeTest {
  void test_access() {
    SourceRange r = new SourceRange(10, 1);
    expect(r.offset, 10);
    expect(r.length, 1);
    expect(r.end, 10 + 1);
    // to check
    r.hashCode;
  }

  void test_contains() {
    SourceRange r = new SourceRange(5, 10);
    expect(r.contains(5), isTrue);
    expect(r.contains(10), isTrue);
    expect(r.contains(14), isTrue);
    expect(r.contains(0), isFalse);
    expect(r.contains(15), isFalse);
  }

  void test_containsExclusive() {
    SourceRange r = new SourceRange(5, 10);
    expect(r.containsExclusive(5), isFalse);
    expect(r.containsExclusive(10), isTrue);
    expect(r.containsExclusive(14), isTrue);
    expect(r.containsExclusive(0), isFalse);
    expect(r.containsExclusive(15), isFalse);
  }

  void test_coveredBy() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.coveredBy(new SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.coveredBy(new SourceRange(0, 3)), isFalse);
    // only intersects
    expect(r.coveredBy(new SourceRange(0, 10)), isFalse);
    expect(r.coveredBy(new SourceRange(10, 10)), isFalse);
    // covered
    expect(r.coveredBy(new SourceRange(0, 20)), isTrue);
    expect(r.coveredBy(new SourceRange(5, 10)), isTrue);
  }

  void test_covers() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.covers(new SourceRange(0, 3)), isFalse);
    // starts after
    expect(r.covers(new SourceRange(20, 3)), isFalse);
    // only intersects
    expect(r.covers(new SourceRange(0, 10)), isFalse);
    expect(r.covers(new SourceRange(10, 10)), isFalse);
    // covers
    expect(r.covers(new SourceRange(5, 10)), isTrue);
    expect(r.covers(new SourceRange(6, 9)), isTrue);
    expect(r.covers(new SourceRange(6, 8)), isTrue);
  }

  void test_endsIn() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.endsIn(new SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.endsIn(new SourceRange(0, 3)), isFalse);
    // ends
    expect(r.endsIn(new SourceRange(10, 20)), isTrue);
    expect(r.endsIn(new SourceRange(0, 20)), isTrue);
  }

  void test_equals() {
    SourceRange r = new SourceRange(10, 1);
    expect(r == null, isFalse);
    expect(r == this, isFalse);
    expect(r == new SourceRange(20, 2), isFalse);
    expect(r == new SourceRange(10, 1), isTrue);
    expect(r == r, isTrue);
  }

  void test_getExpanded() {
    SourceRange r = new SourceRange(5, 3);
    expect(r.getExpanded(0), r);
    expect(r.getExpanded(2), new SourceRange(3, 7));
    expect(r.getExpanded(-1), new SourceRange(6, 1));
  }

  void test_getMoveEnd() {
    SourceRange r = new SourceRange(5, 3);
    expect(r.getMoveEnd(0), r);
    expect(r.getMoveEnd(3), new SourceRange(5, 6));
    expect(r.getMoveEnd(-1), new SourceRange(5, 2));
  }

  void test_getTranslated() {
    SourceRange r = new SourceRange(5, 3);
    expect(r.getTranslated(0), r);
    expect(r.getTranslated(2), new SourceRange(7, 3));
    expect(r.getTranslated(-1), new SourceRange(4, 3));
  }

  void test_getUnion() {
    expect(new SourceRange(10, 10).getUnion(new SourceRange(15, 10)),
        new SourceRange(10, 15));
    expect(new SourceRange(15, 10).getUnion(new SourceRange(10, 10)),
        new SourceRange(10, 15));
    // "other" is covered/covers
    expect(new SourceRange(10, 10).getUnion(new SourceRange(15, 2)),
        new SourceRange(10, 10));
    expect(new SourceRange(15, 2).getUnion(new SourceRange(10, 10)),
        new SourceRange(10, 10));
  }

  void test_intersects() {
    SourceRange r = new SourceRange(5, 3);
    // null
    expect(r.intersects(null), isFalse);
    // ends before
    expect(r.intersects(new SourceRange(0, 5)), isFalse);
    // begins after
    expect(r.intersects(new SourceRange(8, 5)), isFalse);
    // begins on same offset
    expect(r.intersects(new SourceRange(5, 1)), isTrue);
    // begins inside, ends inside
    expect(r.intersects(new SourceRange(6, 1)), isTrue);
    // begins inside, ends after
    expect(r.intersects(new SourceRange(6, 10)), isTrue);
    // begins before, ends after
    expect(r.intersects(new SourceRange(0, 10)), isTrue);
  }

  void test_startsIn() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.startsIn(new SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.startsIn(new SourceRange(0, 3)), isFalse);
    // starts
    expect(r.startsIn(new SourceRange(5, 1)), isTrue);
    expect(r.startsIn(new SourceRange(0, 20)), isTrue);
  }

  void test_toString() {
    SourceRange r = new SourceRange(10, 1);
    expect(r.toString(), "[offset=10, length=1]");
  }
}

@reflectiveTest
class StringUtilitiesTest {
  void test_computeLineStarts_n() {
    List<int> starts = StringUtilities.computeLineStarts('a\nbb\nccc');
    expect(starts, <int>[0, 2, 5]);
  }

  void test_computeLineStarts_r() {
    List<int> starts = StringUtilities.computeLineStarts('a\rbb\rccc');
    expect(starts, <int>[0, 2, 5]);
  }

  void test_computeLineStarts_rn() {
    List<int> starts = StringUtilities.computeLineStarts('a\r\nbb\r\nccc');
    expect(starts, <int>[0, 3, 7]);
  }

  void test_EMPTY() {
    expect(StringUtilities.EMPTY, "");
    expect(StringUtilities.EMPTY.isEmpty, isTrue);
  }

  void test_EMPTY_ARRAY() {
    expect(StringUtilities.EMPTY_ARRAY.length, 0);
  }

  void test_endsWith3() {
    expect(StringUtilities.endsWith3("abc", 0x61, 0x62, 0x63), isTrue);
    expect(StringUtilities.endsWith3("abcdefghi", 0x67, 0x68, 0x69), isTrue);
    expect(StringUtilities.endsWith3("abcdefghi", 0x64, 0x65, 0x61), isFalse);
    // missing
  }

  void test_endsWithChar() {
    expect(StringUtilities.endsWithChar("a", 0x61), isTrue);
    expect(StringUtilities.endsWithChar("b", 0x61), isFalse);
    expect(StringUtilities.endsWithChar("", 0x61), isFalse);
  }

  void test_indexOf1() {
    expect(StringUtilities.indexOf1("a", 0, 0x61), 0);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x61), 0);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x63), 2);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x66), 5);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x7A), -1);
    expect(StringUtilities.indexOf1("abcdef", 1, 0x61), -1);
    // before start
  }

  void test_indexOf2() {
    expect(StringUtilities.indexOf2("ab", 0, 0x61, 0x62), 0);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x61, 0x62), 0);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x63, 0x64), 2);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x65, 0x66), 4);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x64, 0x61), -1);
    expect(StringUtilities.indexOf2("abcdef", 1, 0x61, 0x62), -1);
    // before start
  }

  void test_indexOf4() {
    expect(StringUtilities.indexOf4("abcd", 0, 0x61, 0x62, 0x63, 0x64), 0);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64), 0);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x63, 0x64, 0x65, 0x66), 2);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x66, 0x67, 0x68, 0x69), 5);
    expect(
        StringUtilities.indexOf4("abcdefghi", 0, 0x64, 0x65, 0x61, 0x64), -1);
    expect(
        StringUtilities.indexOf4("abcdefghi", 1, 0x61, 0x62, 0x63, 0x64), -1);
    // before start
  }

  void test_indexOf5() {
    expect(
        StringUtilities.indexOf5("abcde", 0, 0x61, 0x62, 0x63, 0x64, 0x65), 0);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        0);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x63, 0x64, 0x65, 0x66, 0x67),
        2);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x65, 0x66, 0x67, 0x68, 0x69),
        4);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x64, 0x65, 0x66, 0x69, 0x6E),
        -1);
    expect(
        StringUtilities.indexOf5("abcdefghi", 1, 0x61, 0x62, 0x63, 0x64, 0x65),
        -1);
    // before start
  }

  void test_isEmpty() {
    expect(StringUtilities.isEmpty(""), isTrue);
    expect(StringUtilities.isEmpty(" "), isFalse);
    expect(StringUtilities.isEmpty("a"), isFalse);
    expect(StringUtilities.isEmpty(StringUtilities.EMPTY), isTrue);
  }

  void test_isTagName() {
    expect(StringUtilities.isTagName(null), isFalse);
    expect(StringUtilities.isTagName(""), isFalse);
    expect(StringUtilities.isTagName("-"), isFalse);
    expect(StringUtilities.isTagName("0"), isFalse);
    expect(StringUtilities.isTagName("0a"), isFalse);
    expect(StringUtilities.isTagName("a b"), isFalse);
    expect(StringUtilities.isTagName("a0"), isTrue);
    expect(StringUtilities.isTagName("a"), isTrue);
    expect(StringUtilities.isTagName("ab"), isTrue);
    expect(StringUtilities.isTagName("a-b"), isTrue);
  }

  void test_printListOfQuotedNames_empty() {
    expect(() {
      StringUtilities.printListOfQuotedNames(new List<String>(0));
    }, throwsArgumentError);
  }

  void test_printListOfQuotedNames_five() {
    expect(
        StringUtilities
            .printListOfQuotedNames(<String>["a", "b", "c", "d", "e"]),
        "'a', 'b', 'c', 'd' and 'e'");
  }

  void test_printListOfQuotedNames_null() {
    expect(() {
      StringUtilities.printListOfQuotedNames(null);
    }, throwsArgumentError);
  }

  void test_printListOfQuotedNames_one() {
    expect(() {
      StringUtilities.printListOfQuotedNames(<String>["a"]);
    }, throwsArgumentError);
  }

  void test_printListOfQuotedNames_three() {
    expect(StringUtilities.printListOfQuotedNames(<String>["a", "b", "c"]),
        "'a', 'b' and 'c'");
  }

  void test_printListOfQuotedNames_two() {
    expect(StringUtilities.printListOfQuotedNames(<String>["a", "b"]),
        "'a' and 'b'");
  }

  void test_startsWith2() {
    expect(StringUtilities.startsWith2("ab", 0, 0x61, 0x62), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 0, 0x61, 0x62), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 2, 0x63, 0x64), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 5, 0x66, 0x67), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 0, 0x64, 0x64), isFalse);
    // missing
  }

  void test_startsWith3() {
    expect(StringUtilities.startsWith3("abc", 0, 0x61, 0x62, 0x63), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 0, 0x61, 0x62, 0x63), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 2, 0x63, 0x64, 0x65), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 6, 0x67, 0x68, 0x69), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 0, 0x64, 0x65, 0x61), isFalse);
    // missing
  }

  void test_startsWith4() {
    expect(
        StringUtilities.startsWith4("abcd", 0, 0x61, 0x62, 0x63, 0x64), isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64),
        isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 2, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 5, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 0, 0x64, 0x65, 0x61, 0x64),
        isFalse);
    // missing
  }

  void test_startsWith5() {
    expect(
        StringUtilities.startsWith5("abcde", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 2, 0x63, 0x64, 0x65, 0x66, 0x67),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 4, 0x65, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x62, 0x61),
        isFalse);
    // missing
  }

  void test_startsWith6() {
    expect(
        StringUtilities.startsWith6(
            "abcdef", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 2, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 3, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x67),
        isFalse);
    // missing
  }

  void test_startsWithChar() {
    expect(StringUtilities.startsWithChar("a", 0x61), isTrue);
    expect(StringUtilities.startsWithChar("b", 0x61), isFalse);
    expect(StringUtilities.startsWithChar("", 0x61), isFalse);
  }

  void test_substringBefore() {
    expect(StringUtilities.substringBefore(null, ""), null);
    expect(StringUtilities.substringBefore(null, "a"), null);
    expect(StringUtilities.substringBefore("", "a"), "");
    expect(StringUtilities.substringBefore("abc", "a"), "");
    expect(StringUtilities.substringBefore("abcba", "b"), "a");
    expect(StringUtilities.substringBefore("abc", "c"), "ab");
    expect(StringUtilities.substringBefore("abc", "d"), "abc");
    expect(StringUtilities.substringBefore("abc", ""), "");
    expect(StringUtilities.substringBefore("abc", null), "abc");
  }

  void test_substringBeforeChar() {
    expect(StringUtilities.substringBeforeChar(null, 0x61), null);
    expect(StringUtilities.substringBeforeChar("", 0x61), "");
    expect(StringUtilities.substringBeforeChar("abc", 0x61), "");
    expect(StringUtilities.substringBeforeChar("abcba", 0x62), "a");
    expect(StringUtilities.substringBeforeChar("abc", 0x63), "ab");
    expect(StringUtilities.substringBeforeChar("abc", 0x64), "abc");
  }
}

@reflectiveTest
class TokenMapTest {
  void test_creation() {
    expect(new TokenMap(), isNotNull);
  }

  void test_get_absent() {
    TokenMap tokenMap = new TokenMap();
    expect(tokenMap.get(TokenFactory.tokenFromType(TokenType.AT)), isNull);
  }

  void test_get_added() {
    TokenMap tokenMap = new TokenMap();
    Token key = TokenFactory.tokenFromType(TokenType.AT);
    Token value = TokenFactory.tokenFromType(TokenType.AT);
    tokenMap.put(key, value);
    expect(tokenMap.get(key), same(value));
  }
}

class _ExceptionThrowingVisitor extends SimpleAstVisitor {
  visitNullLiteral(NullLiteral node) {
    throw new ArgumentError('');
  }
}
