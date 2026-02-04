// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' as fasta;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import '../util/feature_sets.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorParserTest);
  });
}

/// This defines parser tests that test the parsing of code to ensure that
/// errors are correctly reported, and in some cases, not reported.
@reflectiveTest
class ErrorParserTest extends FastaParserTestCase {
  void test_abstractClassMember_constructor() {
    createParser('abstract C.c();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.abstractClassMember, 0, 8)]);
  }

  void test_abstractClassMember_field() {
    createParser('abstract C f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_abstractClassMember_getter() {
    createParser('abstract get m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.abstractClassMember, 0, 8)]);
  }

  void test_abstractClassMember_method() {
    createParser('abstract m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.abstractClassMember, 0, 8)]);
  }

  void test_abstractClassMember_setter() {
    createParser('abstract set m(v);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.abstractClassMember, 0, 8)]);
  }

  void test_abstractEnum() {
    parseCompilationUnit(
      "abstract enum E {ONE}",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 8)],
    );
  }

  void test_abstractTopLevelFunction_function() {
    parseCompilationUnit(
      "abstract f(v) {}",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 8)],
    );
  }

  void test_abstractTopLevelFunction_getter() {
    parseCompilationUnit(
      "abstract get m {}",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 8)],
    );
  }

  void test_abstractTopLevelFunction_setter() {
    parseCompilationUnit(
      "abstract set m(v) {}",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 8)],
    );
  }

  void test_abstractTopLevelVariable() {
    parseCompilationUnit(
      "abstract C f;",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 8)],
    );
  }

  void test_abstractTypeDef() {
    parseCompilationUnit(
      "abstract typedef F();",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 8)],
    );
  }

  void test_await_missing_async2_issue36048() {
    parseCompilationUnit(
      '''
main() { // missing async
  await foo.bar();
}
''',
      diagnostics: [expectedError(diag.awaitInWrongContext, 28, 5)],
    );
  }

  void test_await_missing_async3_issue36048() {
    parseCompilationUnit(
      '''
main() { // missing async
  (await foo);
}
''',
      diagnostics: [expectedError(diag.awaitInWrongContext, 29, 5)],
    );
  }

  void test_await_missing_async4_issue36048() {
    parseCompilationUnit(
      '''
main() { // missing async
  [await foo];
}
''',
      diagnostics: [expectedError(diag.awaitInWrongContext, 29, 5)],
    );
  }

  void test_await_missing_async_issue36048() {
    parseCompilationUnit(
      '''
main() { // missing async
  await foo();
}
''',
      diagnostics: [expectedError(diag.awaitInWrongContext, 28, 5)],
    );
  }

  void test_breakOutsideOfLoop_breakInDoStatement() {
    var statement = parseStatement('do {break;} while (x);') as DoStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInForStatement() {
    var statement = parseStatement('for (; x;) {break;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInIfStatement() {
    var statement = parseStatement('if (x) {break;}') as IfStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([expectedError(diag.breakOutsideOfLoop, 8, 5)]);
  }

  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    var statement =
        parseStatement('switch (x) {case 1: break;}') as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInWhileStatement() {
    var statement = parseStatement('while (x) {break;}') as WhileStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    parseStatement("for(; x;) {() {break;};}");
    listener.assertErrors([expectedError(diag.breakOutsideOfLoop, 15, 5)]);
  }

  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    parseStatement("() {for (; x;) {break;}};");
  }

  void test_classInClass_abstract() {
    parseCompilationUnit(
      "class C { abstract class B {} }",
      diagnostics: [
        expectedError(diag.abstractClassMember, 10, 8),
        expectedError(diag.classInClass, 19, 5),
      ],
    );
  }

  void test_classInClass_nonAbstract() {
    parseCompilationUnit(
      "class C { class B {} }",
      diagnostics: [expectedError(diag.classInClass, 10, 5)],
    );
  }

  void test_classTypeAlias_abstractAfterEq() {
    // This syntax has been removed from the language in favor of
    // "abstract class A = B with C;" (issue 18098).
    createParser('class A = abstract B with C;', expectedEndOffset: 21);
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.builtInIdentifierAsType, 10, 8),
      expectedError(diag.expectedToken, 19, 1),
      expectedError(diag.expectedToken, 19, 1),
    ]);
  }

  void test_colonInPlaceOfIn() {
    parseStatement("for (var x : list) {}");
    listener.assertErrors([expectedError(diag.colonInPlaceOfIn, 11, 1)]);
  }

  void test_constAndCovariant() {
    createParser('covariant const C f = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.conflictingModifiers, 10, 5)]);
  }

  void test_constAndFinal() {
    createParser('const final int x = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.constAndFinal, 6, 5)]);
  }

  void test_constAndVar() {
    createParser('const var x = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.conflictingModifiers, 6, 3)]);
  }

  void test_constClass() {
    parseCompilationUnit(
      "const class C {}",
      diagnostics: [expectedError(diag.constClass, 0, 5)],
    );
  }

  void test_constEnum() {
    parseCompilationUnit(
      "const enum E {ONE}",
      diagnostics: [
        // Fasta interprets the `const` as a malformed top level const
        // and `enum` as the start of an enum declaration.
        expectedError(diag.expectedToken, 0, 5),
        expectedError(diag.missingIdentifier, 6, 4),
      ],
    );
  }

  void test_constFactory() {
    createParser('const factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([]);
  }

  void test_constMethod() {
    createParser('const int m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.constMethod, 0, 5)]);
  }

  void test_constMethod_noReturnType() {
    createParser('const m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.constMethod, 0, 5)]);
  }

  void test_constMethod_noReturnType2() {
    createParser('const m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.constMethod, 0, 5)]);
  }

  void test_constructor_super_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    parseCompilationUnit(
      'class B extends A { B(): super.. {} }',
      diagnostics: [
        expectedError(diag.invalidSuperInInitializer, 25, 5),
        expectedError(diag.expectedToken, 30, 2),
        expectedError(diag.missingIdentifier, 33, 1),
      ],
    );
  }

  void test_constructor_super_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit(
      'class B extends A { B(): super().foo {} }',
      diagnostics: [expectedError(diag.invalidSuperInInitializer, 25, 5)],
    );
  }

  void test_constructor_super_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit(
      'class B extends A { B(): super().foo() {} }',
      diagnostics: [expectedError(diag.invalidSuperInInitializer, 25, 5)],
    );
  }

  void test_constructor_super_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit(
      'class B extends A { B(): super.c().create() {} }',
      diagnostics: [expectedError(diag.invalidSuperInInitializer, 25, 5)],
    );
  }

  void test_constructor_super_named_method_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit(
      'class B extends A { B(): super.c().create().x() {} }',
      diagnostics: [expectedError(diag.invalidSuperInInitializer, 25, 5)],
    );
  }

  void test_constructor_this_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    parseCompilationUnit(
      'class B extends A { B(): this.. {} }',
      diagnostics: [
        expectedError(diag.missingAssignmentInInitializer, 25, 4),
        expectedError(diag.expectedToken, 29, 2),
        expectedError(diag.missingIdentifier, 32, 1),
      ],
    );
  }

  void test_constructor_this_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit(
      'class B extends A { B(): this().foo; }',
      diagnostics: [expectedError(diag.invalidThisInInitializer, 25, 4)],
    );
  }

  void test_constructor_this_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit(
      'class B extends A { B(): this().foo(); }',
      diagnostics: [expectedError(diag.invalidThisInInitializer, 25, 4)],
    );
  }

  void test_constructor_this_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit(
      'class B extends A { B(): super.c().create() {} }',
      diagnostics: [expectedError(diag.invalidSuperInInitializer, 25, 5)],
    );
  }

  void test_constructor_this_named_method_field() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit(
      'class B extends A { B(): super.c().create().x {} }',
      diagnostics: [expectedError(diag.invalidSuperInInitializer, 25, 5)],
    );
  }

  void test_constructorPartial() {
    createParser('class C { C< }');
    parser.parseCompilationUnit2();
    listener.assertErrors([
      expectedError(diag.expectedToken, 11, 1),
      expectedError(diag.expectedTypeName, 13, 1),
      expectedError(diag.missingIdentifier, 13, 1),
    ]);
  }

  void test_constructorPartial2() {
    createParser('class C { C<@Foo }');
    parser.parseCompilationUnit2();
    listener.assertErrors([
      expectedError(diag.annotationOnTypeArgument, 12, 4),
      expectedError(diag.expectedToken, 13, 3),
      expectedError(diag.expectedTypeName, 17, 1),
      expectedError(diag.missingIdentifier, 17, 1),
    ]);
  }

  void test_constructorPartial3() {
    createParser('class C { C<@Foo @Bar() }');
    parser.parseCompilationUnit2();
    listener.assertErrors([
      expectedError(diag.annotationOnTypeArgument, 12, 4),
      expectedError(diag.annotationOnTypeArgument, 17, 6),
      expectedError(diag.expectedToken, 22, 1),
      expectedError(diag.expectedTypeName, 24, 1),
      expectedError(diag.missingIdentifier, 24, 1),
    ]);
  }

  void test_constructorWithReturnType() {
    createParser('C C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.constructorWithReturnType, 0, 1),
    ]);
  }

  void test_constructorWithReturnType_var() {
    createParser('var C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.varReturnType, 0, 3)]);
  }

  void test_constTypedef() {
    parseCompilationUnit(
      "const typedef F();",
      diagnostics: [
        // Fasta interprets the `const` as a malformed top level const
        // and `typedef` as the start of an typedef declaration.
        expectedError(diag.expectedToken, 0, 5),
        expectedError(diag.missingIdentifier, 6, 7),
      ],
    );
  }

  void test_continueOutsideOfLoop_continueInDoStatement() {
    var statement = parseStatement('do {continue;} while (x);') as DoStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInForStatement() {
    var statement = parseStatement('for (; x;) {continue;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInIfStatement() {
    var statement = parseStatement('if (x) {continue;}') as IfStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([expectedError(diag.continueOutsideOfLoop, 8, 8)]);
  }

  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    var statement =
        parseStatement('switch (x) {case 1: continue a;}') as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInWhileStatement() {
    var statement = parseStatement('while (x) {continue;}') as WhileStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    parseStatement("for(; x;) {() {continue;};}");
    listener.assertErrors([expectedError(diag.continueOutsideOfLoop, 15, 8)]);
  }

  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    parseStatement("() {for (; x;) {continue;}};");
  }

  void test_continueWithoutLabelInCase_error() {
    var statement =
        parseStatement('switch (x) {case 1: continue;}') as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.continueWithoutLabelInCase, 20, 8),
    ]);
  }

  void test_continueWithoutLabelInCase_noError() {
    var statement =
        parseStatement('switch (x) {case 1: continue a;}') as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    var statement =
        parseStatement('while (a) { switch (b) {default: continue;}}')
            as WhileStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_covariantAfterVar() {
    createParser('var covariant f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.modifierOutOfOrder, 4, 9)]);
  }

  void test_covariantAndFinal() {
    createParser('covariant final f = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([diag.finalAndCovariant]);
  }

  void test_covariantAndStatic() {
    createParser('covariant static A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.covariantAndStatic, 10, 6)]);
  }

  void test_covariantAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    parseStatement("covariant int x;");
    listener.assertErrors([expectedError(diag.extraneousModifier, 0, 9)]);
  }

  void test_covariantConstructor() {
    createParser('class C { covariant C(); }');
    var member = parseFullCompilationUnitMember() as ClassDeclaration;
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.covariantMember, 10, 9)]);
  }

  void test_covariantMember_getter_noReturnType() {
    createParser('static covariant get x => 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.covariantAndStatic, 7, 9)]);
  }

  void test_covariantMember_getter_returnType() {
    createParser('static covariant int get x => 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.covariantAndStatic, 7, 9)]);
  }

  void test_covariantMember_method() {
    createParser('covariant int m() => 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.covariantMember, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_class() {
    createParser('covariant class C {}');
    var member = parseFullCompilationUnitMember() as ClassDeclaration;
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.extraneousModifier, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_enum() {
    createParser('covariant enum E { v }');
    var member = parseFullCompilationUnitMember() as EnumDeclaration;
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.extraneousModifier, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_typedef() {
    parseCompilationUnit(
      "covariant typedef F();",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 9)],
    );
  }

  void test_defaultValueInFunctionType_named_colon() {
    createParser('({int x : 0})');
    FormalParameter parameter = parser
        .parseFormalParameterList(inFunctionType: true)
        .parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors([
      expectedError(diag.defaultValueInFunctionType, 8, 1),
    ]);
  }

  void test_defaultValueInFunctionType_named_equal() {
    createParser('({int x = 0})');
    FormalParameter parameter = parser
        .parseFormalParameterList(inFunctionType: true)
        .parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors([
      expectedError(diag.defaultValueInFunctionType, 8, 1),
    ]);
  }

  void test_defaultValueInFunctionType_positional() {
    createParser('([int x = 0])');
    FormalParameter parameter = parser
        .parseFormalParameterList(inFunctionType: true)
        .parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors([
      expectedError(diag.defaultValueInFunctionType, 8, 1),
    ]);
  }

  void test_directiveAfterDeclaration_classBeforeDirective() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    CompilationUnit unit = parseCompilationUnit(
      "class Foo{} library l;",
      codes: [diag.libraryDirectiveNotFirst],
      diagnostics: [expectedError(diag.libraryDirectiveNotFirst, 12, 10)],
    );
    expect(unit, isNotNull);
  }

  void test_directiveAfterDeclaration_classBetweenDirectives() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    CompilationUnit unit = parseCompilationUnit(
      "library l;\nclass Foo{}\npart 'a.dart';",
      codes: [diag.directiveAfterDeclaration],
      diagnostics: [expectedError(diag.directiveAfterDeclaration, 23, 14)],
    );
    expect(unit, isNotNull);
  }

  void test_duplicatedModifier_const() {
    createParser('const const m = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.duplicatedModifier, 6, 5)]);
  }

  void test_duplicatedModifier_external() {
    createParser('external external f();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.duplicatedModifier, 9, 8)]);
  }

  void test_duplicatedModifier_factory() {
    createParser('factory factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.duplicatedModifier, 8, 7)]);
  }

  void test_duplicatedModifier_final() {
    createParser('final final m = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.duplicatedModifier, 6, 5)]);
  }

  void test_duplicatedModifier_static() {
    createParser('static static var m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.duplicatedModifier, 7, 6)]);
  }

  void test_duplicatedModifier_var() {
    createParser('var var m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.duplicatedModifier, 4, 3)]);
  }

  void test_duplicateLabelInSwitchStatement() {
    var statement =
        parseStatement('switch (e) {l1: case 0: break; l1: case 1: break;}')
            as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.duplicateLabelInSwitchStatement, 31, 2),
    ]);
  }

  void test_emptyEnumBody() {
    createParser('enum E {}');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expectNotNullIfNoErrors(declaration);
    // TODO(brianwilkerson): Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([]);
    //    listener
    //        .assertErrors([expectedError(ParserErrorCode.EMPTY_ENUM_BODY, 7, 2),]);
  }

  void test_enumInClass() {
    parseCompilationUnit(
      r'''
class Foo {
  enum Bar {
    Bar1, Bar2, Bar3
  }
}
''',
      diagnostics: [expectedError(diag.enumInClass, 14, 4)],
    );
  }

  void test_equalityCannotBeEqualityOperand_eq_eq() {
    parseExpression(
      "1 == 2 == 3",
      diagnostics: [expectedError(diag.equalityCannotBeEqualityOperand, 7, 2)],
    );
  }

  void test_equalityCannotBeEqualityOperand_eq_neq() {
    parseExpression(
      "1 == 2 != 3",
      diagnostics: [expectedError(diag.equalityCannotBeEqualityOperand, 7, 2)],
    );
  }

  void test_equalityCannotBeEqualityOperand_neq_eq() {
    parseExpression(
      "1 != 2 == 3",
      diagnostics: [expectedError(diag.equalityCannotBeEqualityOperand, 7, 2)],
    );
  }

  void test_expectedBody_class() {
    parseCompilationUnit(
      "class A class B {}",
      diagnostics: [expectedError(diag.expectedClassBody, 6, 1)],
    );
  }

  void test_expectedCaseOrDefault() {
    var statement = parseStatement('switch (e) {break;}') as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([expectedError(diag.expectedToken, 12, 5)]);
  }

  void test_expectedClassMember_inClass_afterType() {
    parseCompilationUnit(
      'class C{ heart 2 heart }',
      diagnostics: [
        expectedError(diag.missingConstFinalVarOrType, 9, 5),
        expectedError(diag.expectedToken, 9, 5),
        expectedError(diag.expectedClassMember, 15, 1),
        expectedError(diag.missingConstFinalVarOrType, 17, 5),
        expectedError(diag.expectedToken, 17, 5),
      ],
    );
  }

  void test_expectedClassMember_inClass_beforeType() {
    parseCompilationUnit(
      'class C { 4 score }',
      diagnostics: [
        expectedError(diag.expectedClassMember, 10, 1),
        expectedError(diag.missingConstFinalVarOrType, 12, 5),
        expectedError(diag.expectedToken, 12, 5),
      ],
    );
  }

  void test_expectedExecutable_afterAnnotation_atEOF() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseCompilationUnit(
      '@A',
      codes: [diag.expectedExecutable],
      diagnostics: [expectedError(diag.expectedExecutable, 1, 1)],
    );
  }

  void test_expectedExecutable_inClass_afterVoid() {
    parseCompilationUnit(
      'class C { void 2 void }',
      diagnostics: [
        expectedError(diag.missingIdentifier, 15, 1),
        expectedError(diag.expectedToken, 15, 1),
        expectedError(diag.expectedToken, 17, 4),
        expectedError(diag.missingIdentifier, 22, 1),
      ],
    );
  }

  void test_expectedExecutable_topLevel_afterType() {
    CompilationUnit unit = parseCompilationUnit(
      'heart 2 heart',
      diagnostics: [
        expectedError(diag.missingConstFinalVarOrType, 0, 5),
        expectedError(diag.expectedToken, 0, 5),
        expectedError(diag.expectedExecutable, 6, 1),
        expectedError(diag.missingConstFinalVarOrType, 8, 5),
        expectedError(diag.expectedToken, 8, 5),
      ],
    );
    expect(unit, isNotNull);
  }

  void test_expectedExecutable_topLevel_afterVoid() {
    CompilationUnit unit = parseCompilationUnit(
      'void 2 void',
      diagnostics: [
        expectedError(diag.expectedToken, 0, 4),
        expectedError(diag.missingIdentifier, 5, 1),
        expectedError(diag.expectedExecutable, 5, 1),
        expectedError(diag.expectedToken, 7, 4),
        expectedError(diag.missingIdentifier, 11, 0),
      ],
    );
    expect(unit, isNotNull);
  }

  void test_expectedExecutable_topLevel_beforeType() {
    parseCompilationUnit(
      '4 score',
      diagnostics: [
        expectedError(diag.expectedExecutable, 0, 1),
        expectedError(diag.missingConstFinalVarOrType, 2, 5),
        expectedError(diag.expectedToken, 2, 5),
      ],
    );
  }

  void test_expectedExecutable_topLevel_eof() {
    parseCompilationUnit(
      'x',
      diagnostics: [
        expectedError(diag.missingConstFinalVarOrType, 0, 1),
        expectedError(diag.expectedToken, 0, 1),
      ],
    );
  }

  void test_expectedInterpolationIdentifier() {
    var literal =
        parseExpression(
              "'\$x\$'",
              diagnostics: [expectedError(diag.missingIdentifier, 4, 1)],
            )
            as StringLiteral;
    expectNotNullIfNoErrors(literal);
  }

  void test_expectedInterpolationIdentifier_emptyString() {
    // The scanner inserts an empty string token between the two $'s; we need to
    // make sure that the MISSING_IDENTIFIER error that is generated has a
    // nonzero width so that it will show up in the editor UI.
    var literal =
        parseExpression(
              "'\$\$foo'",
              diagnostics: [expectedError(diag.missingIdentifier, 2, 1)],
            )
            as StringLiteral;
    expectNotNullIfNoErrors(literal);
  }

  void test_expectedToken_commaMissingInArgumentList() {
    createParser('(x, y z)');
    ArgumentList list = parser.parseArgumentList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 6, 1)]);
  }

  void test_expectedToken_parseStatement_afterVoid() {
    parseStatement("void}", expectedEndOffset: 4);
    listener.assertErrors([
      expectedError(diag.expectedToken, 0, 4),
      expectedError(diag.missingIdentifier, 4, 1),
    ]);
  }

  void test_expectedToken_semicolonMissingAfterExport() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    CompilationUnit unit = parseCompilationUnit(
      "export '' class A {}",
      codes: [diag.expectedToken],
      diagnostics: [expectedError(diag.expectedToken, 7, 2)],
    );
    ExportDirective directive = unit.directives[0] as ExportDirective;
    expect(directive.uri, isNotNull);
    expect(directive.uri.stringValue, '');
    expect(directive.uri.beginToken.isSynthetic, false);
    expect(directive.uri.isSynthetic, false);
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
    ClassDeclaration clazz = unit.declarations[0] as ClassDeclaration;
    expect(clazz.namePart.typeName.lexeme, 'A');
  }

  void test_expectedToken_semicolonMissingAfterExpression() {
    parseStatement("x");
    // TODO(brianwilkerson): Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([diag.expectedToken]);
    //    listener
    //        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 1)]);
  }

  void test_expectedToken_semicolonMissingAfterImport() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    CompilationUnit unit = parseCompilationUnit(
      "import '' class A {}",
      codes: [diag.expectedToken],
      diagnostics: [expectedError(diag.expectedToken, 7, 2)],
    );
    ImportDirective directive = unit.directives[0] as ImportDirective;
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
  }

  void test_expectedToken_uriAndSemicolonMissingAfterExport() {
    CompilationUnit unit = parseCompilationUnit(
      "export class A {}",
      diagnostics: [
        expectedError(diag.expectedToken, 0, 6),
        expectedError(diag.expectedStringLiteral, 7, 5),
      ],
    );
    ExportDirective directive = unit.directives[0] as ExportDirective;
    expect(directive.uri, isNotNull);
    expect(directive.uri.stringValue, '');
    expect(directive.uri.beginToken.isSynthetic, true);
    expect(directive.uri.isSynthetic, true);
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
    ClassDeclaration clazz = unit.declarations[0] as ClassDeclaration;
    expect(clazz.namePart.typeName.lexeme, 'A');
  }

  void test_expectedToken_whileMissingInDoStatement() {
    parseStatement("do {} (x);");
    listener.assertErrors([expectedError(diag.expectedToken, 6, 1)]);
  }

  void test_expectedTypeName_as() {
    parseExpression(
      "x as",
      diagnostics: [expectedError(diag.expectedTypeName, 4, 0)],
    );
  }

  void test_expectedTypeName_as_void() {
    parseExpression(
      "x as void)",
      expectedEndOffset: 9,
      diagnostics: [expectedError(diag.expectedTypeName, 5, 4)],
    );
  }

  void test_expectedTypeName_is() {
    parseExpression(
      "x is",
      diagnostics: [expectedError(diag.expectedTypeName, 4, 0)],
    );
  }

  void test_expectedTypeName_is_void() {
    parseExpression(
      "x is void)",
      expectedEndOffset: 9,
      diagnostics: [expectedError(diag.expectedTypeName, 5, 4)],
    );
  }

  void test_exportAsType() {
    parseCompilationUnit(
      'export<dynamic> foo;',
      diagnostics: [expectedError(diag.builtInIdentifierAsType, 0, 6)],
    );
  }

  void test_exportAsType_inClass() {
    parseCompilationUnit(
      'class C { export<dynamic> foo; }',
      diagnostics: [expectedError(diag.builtInIdentifierAsType, 10, 6)],
    );
  }

  void test_externalAfterConst() {
    createParser('const external C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.modifierOutOfOrder, 6, 8)]);
  }

  void test_externalAfterFactory() {
    createParser('factory external C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.modifierOutOfOrder, 8, 8)]);
  }

  void test_externalAfterStatic() {
    createParser('static external int m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.modifierOutOfOrder, 7, 8)]);
  }

  void test_externalClass() {
    parseCompilationUnit(
      "external class C {}",
      diagnostics: [expectedError(diag.externalClass, 0, 8)],
    );
  }

  void test_externalEnum() {
    parseCompilationUnit(
      "external enum E {ONE}",
      diagnostics: [expectedError(diag.externalEnum, 0, 8)],
    );
  }

  void test_externalField_const() {
    createParser('external const A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([]);
  }

  void test_externalField_final() {
    createParser('external final A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_externalField_static() {
    createParser('external static A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_externalField_typed() {
    createParser('external A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_externalField_untyped() {
    createParser('external var f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_externalTypedef() {
    parseCompilationUnit(
      "external typedef F();",
      diagnostics: [expectedError(diag.externalTypedef, 0, 8)],
    );
  }

  void test_extraCommaInParameterList() {
    createParser('(int a, , int b)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.missingIdentifier, 8, 1)]);
  }

  void test_extraCommaTrailingNamedParameterGroup() {
    createParser('({int b},)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 8, 1)]);
  }

  void test_extraCommaTrailingPositionalParameterGroup() {
    createParser('([int b],)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 8, 1)]);
  }

  void test_extraTrailingCommaInParameterList() {
    createParser('(a,,)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.missingIdentifier, 3, 1)]);
  }

  void test_factory_issue_36400() {
    parseCompilationUnit(
      'class T { T factory T() { return null; } }',
      diagnostics: [expectedError(diag.typeBeforeFactory, 10, 1)],
    );
  }

  void test_factoryTopLevelDeclaration_class() {
    parseCompilationUnit(
      "factory class C {}",
      diagnostics: [expectedError(diag.factoryTopLevelDeclaration, 0, 7)],
    );
  }

  void test_factoryTopLevelDeclaration_enum() {
    parseCompilationUnit(
      "factory enum E { v }",
      diagnostics: [expectedError(diag.factoryTopLevelDeclaration, 0, 7)],
    );
  }

  void test_factoryTopLevelDeclaration_typedef() {
    parseCompilationUnit(
      "factory typedef F();",
      diagnostics: [expectedError(diag.factoryTopLevelDeclaration, 0, 7)],
    );
  }

  void test_factoryWithInitializers() {
    createParser('factory C() : x = 3 {}', expectedEndOffset: 12);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingFunctionBody, 12, 1)]);
  }

  void test_factoryWithoutBody() {
    createParser('factory C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingFunctionBody, 11, 1)]);
  }

  void test_fieldInitializerOutsideConstructor() {
    createParser('void m(this.x);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    // Error is not reported during parsing.
    listener.assertNoErrors();
  }

  void test_finalAndCovariant() {
    createParser('final covariant f = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.modifierOutOfOrder, 6, 9),
      expectedError(diag.finalAndCovariant, 6, 9),
    ]);
  }

  void test_finalAndVar() {
    createParser('final var x = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.finalAndVar, 6, 3)]);
  }

  void test_finalClassMember_modifierOnly() {
    createParser('final');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.expectedToken, 0, 5),
      expectedError(diag.missingIdentifier, 5, 0),
    ]);
  }

  void test_finalConstructor() {
    createParser('final C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.extraneousModifier, 0, 5)]);
  }

  void test_finalEnum() {
    parseCompilationUnit(
      "final enum E {ONE}",
      diagnostics: [error(diag.finalEnum, 0, 5)],
    );
  }

  void test_finalMethod() {
    createParser('final int m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.extraneousModifier, 0, 5)]);
  }

  void test_finalTypedef() {
    parseCompilationUnit(
      "final typedef F();",
      diagnostics: [
        // Fasta interprets the `final` as a malformed top level final
        // and `typedef` as the start of an typedef declaration.
        expectedError(diag.expectedToken, 0, 5),
        expectedError(diag.missingIdentifier, 6, 7),
      ],
    );
  }

  void test_functionTypedField_invalidType_abstract() {
    parseCompilationUnit(
      "Function(abstract) x = null;",
      diagnostics: [expectedError(diag.builtInIdentifierAsType, 9, 8)],
    );
  }

  void test_functionTypedField_invalidType_class() {
    parseCompilationUnit(
      "Function(class) x = null;",
      diagnostics: [
        expectedError(diag.expectedTypeName, 9, 5),
        expectedError(diag.expectedIdentifierButGotKeyword, 9, 5),
      ],
    );
  }

  void test_functionTypedParameter_const() {
    parseCompilationUnit(
      "void f(const x()) {}",
      diagnostics: [
        expectedError(diag.extraneousModifier, 7, 5),
        expectedError(diag.functionTypedParameterVar, 7, 5),
      ],
    );
  }

  void test_functionTypedParameter_final() {
    parseCompilationUnit(
      "void f(final x()) {}",
      diagnostics: [expectedError(diag.functionTypedParameterVar, 7, 5)],
    );
  }

  void test_functionTypedParameter_incomplete1() {
    parseCompilationUnit(
      "void f(int Function(",
      diagnostics: [
        expectedError(diag.expectedToken, 20, 1),
        expectedError(diag.expectedToken, 20, 1),
        expectedError(diag.missingFunctionBody, 20, 0),
      ],
    );
  }

  void test_functionTypedParameter_var() {
    parseCompilationUnit(
      "void f(var x()) {}",
      diagnostics: [expectedError(diag.functionTypedParameterVar, 7, 3)],
    );
  }

  void test_genericFunctionType_asIdentifier() {
    createParser('final int Function = 0;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([]);
  }

  void test_genericFunctionType_asIdentifier2() {
    createParser('int Function() {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([]);
  }

  void test_genericFunctionType_asIdentifier3() {
    createParser('int Function() => 0;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([]);
  }

  void test_genericFunctionType_extraLessThan() {
    createParser('''
class Wrong<T> {
  T Function(<List<int> foo) bar;
}''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([
      expectedError(diag.expectedTypeName, 30, 1),
      expectedError(diag.expectedToken, 30, 1),
    ]);
  }

  void test_getterInFunction_block_noReturnType() {
    Statement result = parseStatement(
      "get x { return _x; }",
      expectedEndOffset: 4,
    );
    // Fasta considers `get` to be an identifier in this situation.
    // TODO(danrubel): Investigate better recovery.
    var statement = result as ExpressionStatement;
    listener.assertErrors([expectedError(diag.expectedToken, 0, 3)]);
    expect(statement.expression.toSource(), 'get');
  }

  void test_getterInFunction_block_returnType() {
    // Fasta considers `get` to be an identifier in this situation.
    parseStatement("int get x { return _x; }", expectedEndOffset: 8);
    listener.assertErrors([expectedError(diag.expectedToken, 4, 3)]);
  }

  void test_getterInFunction_expression_noReturnType() {
    // Fasta considers `get` to be an identifier in this situation.
    parseStatement("get x => _x;", expectedEndOffset: 4);
    listener.assertErrors([expectedError(diag.expectedToken, 0, 3)]);
  }

  void test_getterInFunction_expression_returnType() {
    // Fasta considers `get` to be an identifier in this situation.
    parseStatement("int get x => _x;", expectedEndOffset: 8);
    listener.assertErrors([expectedError(diag.expectedToken, 4, 3)]);
  }

  void test_getterNativeWithBody() {
    createParser('String get m native "str" => 0;');
    parser.parseClassMember('C') as MethodDeclaration;
    if (!allowNativeClause) {
      assertErrorsWithCodes([diag.nativeClauseShouldBeAnnotation]);
    } else {
      assertNoErrors();
    }
  }

  void test_getterWithParameters() {
    createParser('int get x() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    // TODO(brianwilkerson): Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([diag.getterWithParameters]);
    //    listener.assertErrors(
    //        [expectedError(ParserErrorCode.GETTER_WITH_PARAMETERS, 9, 2)]);
  }

  void test_illegalAssignmentToNonAssignable_assign_int() {
    parseStatement("0 = 1;");
    listener.assertErrors([
      expectedError(diag.missingAssignableSelector, 0, 1),
      expectedError(diag.illegalAssignmentToNonAssignable, 0, 1),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_assign_this() {
    parseStatement("this = 1;");
    listener.assertErrors([
      expectedError(diag.missingAssignableSelector, 0, 4),
      expectedError(diag.illegalAssignmentToNonAssignable, 0, 4),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    parseExpression(
      "0--",
      diagnostics: [expectedError(diag.illegalAssignmentToNonAssignable, 1, 2)],
    );
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    parseExpression(
      "0++",
      diagnostics: [expectedError(diag.illegalAssignmentToNonAssignable, 1, 2)],
    );
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    parseExpression(
      "(x)++",
      diagnostics: [expectedError(diag.illegalAssignmentToNonAssignable, 3, 2)],
    );
  }

  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    parseExpression(
      "x(y)(z)++",
      diagnostics: [expectedError(diag.illegalAssignmentToNonAssignable, 7, 2)],
    );
  }

  void test_illegalAssignmentToNonAssignable_superAssigned() {
    parseStatement("super = x;");
    listener.assertErrors([
      expectedError(diag.missingAssignableSelector, 0, 5),
      expectedError(diag.illegalAssignmentToNonAssignable, 0, 5),
    ]);
  }

  void test_implementsBeforeExtends() {
    parseCompilationUnit(
      "class A implements B extends C {}",
      diagnostics: [expectedError(diag.implementsBeforeExtends, 21, 7)],
    );
  }

  void test_implementsBeforeWith() {
    parseCompilationUnit(
      "class A extends B implements C with D {}",
      diagnostics: [expectedError(diag.implementsBeforeWith, 31, 4)],
    );
  }

  void test_initializedVariableInForEach() {
    var statement = parseStatement('for (int a = 0 in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.initializedVariableInForEach, 11, 1),
    ]);
  }

  void test_initializedVariableInForEach_annotation() {
    var statement = parseStatement('for (@Foo var a = 0 in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.initializedVariableInForEach, 16, 1),
    ]);
  }

  void test_initializedVariableInForEach_localFunction() {
    var statement = parseStatement('for (f()) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.expectedToken, 7, 1),
      expectedError(diag.expectedToken, 7, 1),
      expectedError(diag.missingIdentifier, 8, 1),
    ]);
  }

  void test_initializedVariableInForEach_localFunction2() {
    var statement = parseStatement('for (T f()) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.expectedToken, 7, 1),
      expectedError(diag.expectedToken, 9, 1),
    ]);
  }

  void test_initializedVariableInForEach_var() {
    var statement = parseStatement('for (var a = 0 in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.initializedVariableInForEach, 11, 1),
    ]);
  }

  void test_invalidAwaitInFor() {
    var statement = parseStatement('await for (; ;) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([expectedError(diag.invalidAwaitInFor, 0, 5)]);
  }

  void test_invalidCodePoint() {
    var literal =
        parseExpression(
              "'begin \\u{110000}'",
              diagnostics: [expectedError(diag.invalidCodePoint, 7, 9)],
            )
            as StringLiteral;
    expectNotNullIfNoErrors(literal);
  }

  @failingTest
  void test_invalidCommentReference__new_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    createParser('');
    var reference = parseCommentReference('new 42', 0) as CommentReference;
    expectNotNullIfNoErrors(reference);
    listener.assertErrors([expectedError(diag.invalidCommentReference, 0, 6)]);
  }

  @failingTest
  void test_invalidCommentReference__new_tooMuch() {
    createParser('');
    var reference = parseCommentReference('new a.b.c.d', 0) as CommentReference;
    expectNotNullIfNoErrors(reference);
    listener.assertErrors([expectedError(diag.invalidCommentReference, 0, 11)]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    createParser('');
    var reference = parseCommentReference('42', 0) as CommentReference;
    expectNotNullIfNoErrors(reference);
    listener.assertErrors([expectedError(diag.invalidCommentReference, 0, 2)]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_tooMuch() {
    createParser('');
    var reference = parseCommentReference('a.b.c.d', 0) as CommentReference;
    expectNotNullIfNoErrors(reference);
    listener.assertErrors([expectedError(diag.invalidCommentReference, 0, 7)]);
  }

  void test_invalidConstructorName_star() {
    createParser("C.*();");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingIdentifier, 2, 1)]);
  }

  void test_invalidConstructorName_with() {
    createParser("C.with();");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.expectedIdentifierButGotKeyword, 2, 4),
    ]);
  }

  void test_invalidConstructorSuperAssignment() {
    createParser("C() : super = 42;");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      error(diag.missingAssignableSelector, 6, 5),
      error(diag.invalidInitializer, 6, 10),
    ]);
  }

  void test_invalidConstructorSuperFieldAssignment() {
    createParser("C() : super.a = 42;");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.fieldInitializedOutsideDeclaringClass, 12, 1),
    ]);
  }

  void test_invalidHexEscape_invalidDigit() {
    var literal =
        parseExpression(
              "'not \\x0 a'",
              diagnostics: [expectedError(diag.invalidHexEscape, 5, 3)],
            )
            as StringLiteral;
    expectNotNullIfNoErrors(literal);
  }

  void test_invalidHexEscape_tooFewDigits() {
    var literal =
        parseExpression(
              "'\\x0'",
              diagnostics: [expectedError(diag.invalidHexEscape, 1, 3)],
            )
            as StringLiteral;
    expectNotNullIfNoErrors(literal);
  }

  void test_invalidInlineFunctionType() {
    parseCompilationUnit(
      'typedef F = int Function(int a());',
      diagnostics: [expectedError(diag.invalidInlineFunctionType, 30, 1)],
    );
  }

  void test_invalidInterpolation_missingClosingBrace_issue35900() {
    parseCompilationUnit(
      r"main () { print('${x' '); }",
      diagnostics: [
        expectedError(diag.expectedToken, 23, 1),
        expectedError(diag.unterminatedStringLiteral, 26, 1),
        expectedError(diag.expectedToken, 20, 3),
        expectedError(diag.expectedStringLiteral, 23, 1),
        expectedError(diag.expectedExecutable, 27, 0),
      ],
    );
  }

  void test_invalidInterpolationIdentifier_startWithDigit() {
    var literal =
        parseExpression(
              "'\$1'",
              diagnostics: [expectedError(diag.missingIdentifier, 2, 1)],
            )
            as StringLiteral;
    expectNotNullIfNoErrors(literal);
  }

  void test_invalidLiteralInConfiguration() {
    createParser("if (a == 'x \$y z') 'a.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    listener.assertErrors([
      expectedError(diag.invalidLiteralInConfiguration, 12, 2),
    ]);
  }

  void test_invalidOperator() {
    CompilationUnit unit = parseCompilationUnit(
      'class C { void operator ===(x) { } }',
      diagnostics: [expectedError(diag.unsupportedOperator, 24, 1)],
    );
    expect(unit, isNotNull);
  }

  void test_invalidOperator_unary() {
    createParser('class C { int operator unary- => 0; }');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([
      expectedError(diag.unexpectedToken, 23, 5),
      expectedError(diag.missingMethodParameters, 28, 1),
    ]);
  }

  void test_invalidOperatorAfterSuper_assignableExpression() {
    Expression expression = parseAssignableExpression('super?.v', false);
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidOperatorQuestionmarkPeriodForSuper, 5, 2),
    ]);
  }

  void test_invalidOperatorAfterSuper_constructorInitializer2() {
    parseCompilationUnit(
      'class C { C() : super?.namedConstructor(); }',
      diagnostics: [
        expectedError(diag.invalidOperatorQuestionmarkPeriodForSuper, 21, 2),
      ],
    );
  }

  void test_invalidOperatorAfterSuper_primaryExpression() {
    Expression expression = parseExpression(
      'super?.v',
      diagnostics: [
        expectedError(diag.invalidOperatorQuestionmarkPeriodForSuper, 5, 2),
      ],
    );
    expectNotNullIfNoErrors(expression);
  }

  void test_invalidOperatorForSuper() {
    createParser('++super');
    Expression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.missingAssignableSelector, 2, 5),
    ]);
  }

  void test_invalidPropertyAccess_this() {
    parseExpression(
      'x.this',
      diagnostics: [expectedError(diag.missingIdentifier, 2, 4)],
    );
  }

  void test_invalidStarAfterAsync() {
    createParser('foo() async* => 0;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([expectedError(diag.returnInGenerator, 13, 2)]);
  }

  void test_invalidSync() {
    createParser('foo() sync* => 0;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([expectedError(diag.returnInGenerator, 12, 2)]);
  }

  void test_invalidTopLevelSetter() {
    parseCompilationUnit(
      "var set foo; main(){}",
      diagnostics: [
        expectedError(diag.varReturnType, 0, 3),
        expectedError(diag.missingFunctionParameters, 8, 3),
        expectedError(diag.missingFunctionBody, 11, 1),
      ],
    );
  }

  void test_invalidTopLevelVar() {
    parseCompilationUnit(
      "var Function(var arg);",
      diagnostics: [
        expectedError(diag.varReturnType, 0, 3),
        expectedError(diag.missingFunctionBody, 21, 1),
      ],
    );
  }

  void test_invalidTypedef() {
    parseCompilationUnit(
      "typedef var Function(var arg);",
      diagnostics: [
        expectedError(diag.expectedToken, 0, 7),
        expectedError(diag.missingIdentifier, 8, 3),
        expectedError(diag.missingTypedefParameters, 8, 3),
        expectedError(diag.varReturnType, 8, 3),
        expectedError(diag.missingFunctionBody, 29, 1),
      ],
    );
  }

  void test_invalidTypedef2() {
    // https://github.com/dart-lang/sdk/issues/31171
    parseCompilationUnit(
      "typedef T = typedef F = Map<String, dynamic> Function();",
      diagnostics: [
        expectedError(diag.expectedToken, 10, 1),
        expectedError(diag.expectedTypeName, 12, 7),
      ],
    );
  }

  void test_invalidUnicodeEscape_incomplete_noDigits() {
    Expression expression = parseStringLiteral("'\\u{'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidUnicodeEscapeUBracket, 1, 3),
    ]);
  }

  void test_invalidUnicodeEscape_incomplete_noDigits_noBracket() {
    Expression expression = parseStringLiteral("'\\u'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidUnicodeEscapeUStarted, 1, 2),
    ]);
  }

  void test_invalidUnicodeEscape_incomplete_someDigits() {
    Expression expression = parseStringLiteral("'\\u{0A'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidUnicodeEscapeUBracket, 1, 5),
    ]);
  }

  void test_invalidUnicodeEscape_invalidDigit() {
    Expression expression = parseStringLiteral("'\\u0 and some more'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidUnicodeEscapeUNoBracket, 1, 3),
    ]);
  }

  void test_invalidUnicodeEscape_too_high_number_variable() {
    Expression expression = parseStringLiteral("'\\u{110000}'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([expectedError(diag.invalidCodePoint, 1, 9)]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    Expression expression = parseStringLiteral("'\\u04'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidUnicodeEscapeUNoBracket, 1, 4),
    ]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    Expression expression = parseStringLiteral("'\\u{}'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidUnicodeEscapeUBracket, 1, 4),
    ]);
  }

  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    Expression expression = parseStringLiteral("'\\u{0000000001}'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(diag.invalidUnicodeEscapeUBracket, 1, 9),
    ]);
  }

  void test_libraryDirectiveNotFirst() {
    parseCompilationUnit(
      "import 'x.dart'; library l;",
      diagnostics: [expectedError(diag.libraryDirectiveNotFirst, 17, 7)],
    );
  }

  void test_libraryDirectiveNotFirst_afterPart() {
    CompilationUnit unit = parseCompilationUnit(
      "part 'a.dart';\nlibrary l;",
      diagnostics: [expectedError(diag.libraryDirectiveNotFirst, 15, 7)],
    );
    expect(unit, isNotNull);
  }

  void test_localFunction_annotation() {
    CompilationUnit unit = parseCompilationUnit(
      "class C { m() { @Foo f() {} } }",
    );
    expect(unit.declarations, hasLength(1));
    var declaration = unit.declarations[0] as ClassDeclaration;
    var classBody = declaration.body as BlockClassBody;
    expect(classBody.members, hasLength(1));
    var member = classBody.members[0] as MethodDeclaration;
    var body = member.body as BlockFunctionBody;
    expect(body.block.statements, hasLength(1));
    var statement = body.block.statements[0] as FunctionDeclarationStatement;
    expect(statement.functionDeclaration.metadata, hasLength(1));
    Annotation metadata = statement.functionDeclaration.metadata[0];
    expect(metadata.name.name, 'Foo');
  }

  void test_localFunctionDeclarationModifier_abstract() {
    parseCompilationUnit(
      "class C { m() { abstract f() {} } }",
      diagnostics: [expectedError(diag.extraneousModifier, 16, 8)],
    );
  }

  void test_localFunctionDeclarationModifier_external() {
    parseCompilationUnit(
      "class C { m() { external f() {} } }",
      diagnostics: [expectedError(diag.extraneousModifier, 16, 8)],
    );
  }

  void test_localFunctionDeclarationModifier_factory() {
    parseCompilationUnit(
      "class C { m() { factory f() {} } }",
      diagnostics: [expectedError(diag.expectedToken, 16, 7)],
    );
  }

  void test_localFunctionDeclarationModifier_static() {
    parseCompilationUnit(
      "class C { m() { static f() {} } }",
      diagnostics: [expectedError(diag.extraneousModifier, 16, 6)],
    );
  }

  void test_method_invalidTypeParameterExtends() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25739.

    // TODO(jmesserly): ideally we'd be better at parser recovery here.
    createParser('f<E>(E extends num p);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.expectedToken, 7, 7)]);
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(
      method.parameters.toString(),
      '(E)',
      reason: 'parser recovers what it can',
    );
  }

  void test_method_invalidTypeParameters() {
    createParser('void m<E, hello!>() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.expectedToken, 10, 5)]);
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(
      method.typeParameters.toString(),
      '<E, hello>',
      reason: 'parser recovers what it can',
    );
  }

  void test_missing_closing_bracket_issue37528() {
    var code = '\${foo';
    createParser(code);
    var result = fasta.scanString(code);
    expect(result.hasErrors, isTrue);
    var token = parserProxy.fastaParser.syntheticPreviousToken(result.tokens);
    try {
      parserProxy.fastaParser.parseExpression(token);
      // TODO(danrubel): Replace this test once root cause is found
      fail('exception expected');
    } catch (e) {
      var msg = e.toString();
      expect(msg.contains('test_missing_closing_bracket_issue37528'), isTrue);
    }
  }

  void test_missingAssignableSelector_identifiersAssigned() {
    parseExpression("x.y = y;", expectedEndOffset: 7);
  }

  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    parseExpression(
      "--0",
      diagnostics: [expectedError(diag.missingAssignableSelector, 2, 1)],
    );
  }

  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    parseExpression(
      "++0",
      diagnostics: [expectedError(diag.missingAssignableSelector, 2, 1)],
    );
  }

  void test_missingAssignableSelector_selector() {
    parseExpression("x(y)(z).a++");
  }

  void test_missingAssignableSelector_superAsExpressionFunctionBody() {
    CompilationUnit unit = parseCompilationUnit(
      'main() => super;',
      diagnostics: [error(diag.missingAssignableSelector, 10, 5)],
    );
    var declaration = unit.declarations.first as FunctionDeclaration;
    var body = declaration.functionExpression.body as ExpressionFunctionBody;
    var expression = body.expression;
    expect(expression, isSuperExpression);
    var superExpression = expression as SuperExpression;
    expect(superExpression.superKeyword, isNotNull);
  }

  void test_missingAssignableSelector_superPrimaryExpression() {
    CompilationUnit unit = parseCompilationUnit(
      'main() {super;}',
      diagnostics: [expectedError(diag.missingAssignableSelector, 8, 5)],
    );
    var declaration = unit.declarations.first as FunctionDeclaration;
    var blockBody = declaration.functionExpression.body as BlockFunctionBody;
    var statement = blockBody.block.statements.first as ExpressionStatement;
    var expression = statement.expression;
    expect(expression, isSuperExpression);
    var superExpression = expression as SuperExpression;
    expect(superExpression.superKeyword, isNotNull);
  }

  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    parseExpression("super.x = x;", expectedEndOffset: 11);
  }

  void test_missingCatchOrFinally() {
    var statement = parseStatement('try {}') as TryStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([expectedError(diag.missingCatchOrFinally, 0, 3)]);
    expect(statement, isNotNull);
  }

  void test_missingClosingParenthesis() {
    createParser(
      '(int a, int b ;',
      expectedEndOffset: 14 /* parsing ends at synthetic ')' */,
    );
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 14, 1)]);
  }

  void test_missingConstFinalVarOrType_static() {
    parseCompilationUnit(
      "class A { static f; }",
      diagnostics: [expectedError(diag.missingConstFinalVarOrType, 17, 1)],
    );
  }

  void test_missingConstFinalVarOrType_topLevel() {
    parseCompilationUnit(
      'a;',
      diagnostics: [expectedError(diag.missingConstFinalVarOrType, 0, 1)],
    );
  }

  void test_missingEnumBody() {
    createParser('enum E;', expectedEndOffset: 6);
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expectNotNullIfNoErrors(declaration);
    listener.assertErrors([expectedError(diag.missingEnumBody, 6, 1)]);
  }

  void test_missingEnumComma() {
    createParser('enum E {one two}');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expectNotNullIfNoErrors(declaration);
    listener.assertErrors([expectedError(diag.expectedToken, 12, 3)]);
  }

  void test_missingExpressionInThrow() {
    var expression =
        (parseStatement('throw;') as ExpressionStatement).expression
            as ThrowExpression;
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([expectedError(diag.missingExpressionInThrow, 5, 1)]);
  }

  void test_missingFunctionBody_emptyNotAllowed() {
    createParser(';');
    FunctionBody functionBody = parser.parseFunctionBody(
      false,
      diag.missingFunctionBody,
      false,
    );
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrors([expectedError(diag.missingFunctionBody, 0, 1)]);
  }

  void test_missingFunctionBody_invalid() {
    createParser('return 0;');
    FunctionBody functionBody = parser.parseFunctionBody(
      false,
      diag.missingFunctionBody,
      false,
    );
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrors([expectedError(diag.missingFunctionBody, 0, 6)]);
  }

  void test_missingFunctionParameters_local_nonVoid_block() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    parseStatement("int f { return x;}", expectedEndOffset: 6);
    listener.assertErrors([expectedError(diag.expectedToken, 4, 1)]);
  }

  void test_missingFunctionParameters_local_nonVoid_expression() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    parseStatement("int f => x;");
    listener.assertErrors([
      expectedError(diag.missingFunctionParameters, 6, 2),
    ]);
  }

  void test_missingFunctionParameters_local_void_block() {
    parseStatement("void f { return x;}", expectedEndOffset: 7);
    listener.assertErrors([expectedError(diag.expectedToken, 5, 1)]);
  }

  void test_missingFunctionParameters_local_void_expression() {
    parseStatement("void f => x;");
    listener.assertErrors([
      expectedError(diag.missingFunctionParameters, 7, 2),
    ]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    parseCompilationUnit(
      "int f { return x;}",
      diagnostics: [expectedError(diag.missingFunctionParameters, 4, 1)],
    );
  }

  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    parseCompilationUnit(
      "int f => x;",
      diagnostics: [expectedError(diag.missingFunctionParameters, 4, 1)],
    );
  }

  void test_missingFunctionParameters_topLevel_void_block() {
    CompilationUnit unit = parseCompilationUnit(
      "void f { return x;}",
      diagnostics: [expectedError(diag.missingFunctionParameters, 5, 1)],
    );
    var funct = unit.declarations[0] as FunctionDeclaration;
    expect(funct.functionExpression.parameters, hasLength(0));
  }

  void test_missingFunctionParameters_topLevel_void_expression() {
    CompilationUnit unit = parseCompilationUnit(
      "void f => x;",
      diagnostics: [expectedError(diag.missingFunctionParameters, 5, 1)],
    );
    var funct = unit.declarations[0] as FunctionDeclaration;
    expect(funct.functionExpression.parameters, hasLength(0));
  }

  void test_missingIdentifier_afterOperator() {
    createParser('1 *');
    var expression = parser.parseMultiplicativeExpression() as BinaryExpression;
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([expectedError(diag.missingIdentifier, 3, 0)]);
  }

  void test_missingIdentifier_beforeClosingCurly() {
    createParser('int}', expectedEndOffset: 3);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.missingConstFinalVarOrType, 0, 3),
      expectedError(diag.expectedToken, 0, 3),
    ]);
  }

  void test_missingIdentifier_inEnum() {
    createParser('enum E {, TWO}');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expectNotNullIfNoErrors(declaration);
    listener.assertErrors([expectedError(diag.missingIdentifier, 8, 1)]);
  }

  void test_missingIdentifier_inParameterGroupNamed() {
    createParser('(a, {})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.missingIdentifier, 5, 1)]);
  }

  void test_missingIdentifier_inParameterGroupOptional() {
    createParser('(a, [])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.missingIdentifier, 5, 1)]);
  }

  void test_missingIdentifier_inSymbol_afterPeriod() {
    SymbolLiteral literal = parseSymbolLiteral('#a.');
    expectNotNullIfNoErrors(literal);
    listener.assertErrors([expectedError(diag.missingIdentifier, 3, 1)]);
  }

  void test_missingIdentifier_inSymbol_first() {
    SymbolLiteral literal = parseSymbolLiteral('#');
    expectNotNullIfNoErrors(literal);
    listener.assertErrors([expectedError(diag.missingIdentifier, 1, 1)]);
  }

  void test_missingIdentifierForParameterGroup() {
    createParser('(,)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.missingIdentifier, 1, 1)]);
  }

  void test_missingKeywordOperator() {
    createParser('+(x) {}');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    expectNotNullIfNoErrors(method);
    listener.assertErrors([expectedError(diag.missingKeywordOperator, 0, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember() {
    createParser('+() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingKeywordOperator, 0, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    createParser('int +() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingKeywordOperator, 4, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    createParser('void +() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingKeywordOperator, 5, 1)]);
  }

  void test_missingMethodParameters_void_block() {
    createParser('void m {} }', expectedEndOffset: 10);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingMethodParameters, 5, 1)]);
    expect(member, isMethodDeclaration);
    var method = member as MethodDeclaration;
    expect(method.parameters, hasLength(0));
  }

  void test_missingMethodParameters_void_expression() {
    createParser('void m => null; }', expectedEndOffset: 16);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingMethodParameters, 5, 1)]);
  }

  void test_missingNameForNamedParameter_colon() {
    createParser('({int : 0})');
    FormalParameter parameter = parser
        .parseFormalParameterList(inFunctionType: true)
        .parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors([
      expectedError(diag.missingIdentifier, 6, 1),
      expectedError(diag.defaultValueInFunctionType, 6, 1),
    ]);
    expect(parameter.name, isNotNull);
  }

  void test_missingNameForNamedParameter_equals() {
    createParser('({int = 0})');
    FormalParameter parameter = parser
        .parseFormalParameterList(inFunctionType: true)
        .parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors([
      expectedError(diag.missingIdentifier, 6, 1),
      expectedError(diag.defaultValueInFunctionType, 6, 1),
    ]);
    expect(parameter.name, isNotNull);
  }

  void test_missingNameForNamedParameter_noDefault() {
    createParser('({int})');
    FormalParameter parameter = parser
        .parseFormalParameterList(inFunctionType: true)
        .parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors([expectedError(diag.missingIdentifier, 5, 1)]);
    expect(parameter.name, isNotNull);
  }

  void test_missingNameInPartOfDirective() {
    CompilationUnit unit = parseCompilationUnit(
      "part of;",
      diagnostics: [expectedError(diag.expectedStringLiteral, 7, 1)],
    );
    expect(unit, isNotNull);
  }

  void test_missingPrefixInDeferredImport() {
    parseCompilationUnit(
      "import 'foo.dart' deferred;",
      diagnostics: [expectedError(diag.missingPrefixInDeferredImport, 18, 8)],
    );
  }

  void test_missingStartAfterSync() {
    createParser('sync {}');
    FunctionBody functionBody = parser.parseFunctionBody(
      false,
      diag.missingFunctionBody,
      false,
    );
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrors([expectedError(diag.missingStarAfterSync, 0, 4)]);
  }

  void test_missingStatement() {
    parseStatement("is");
    listener.assertErrors([
      expectedError(diag.expectedToken, 0, 2),
      expectedError(diag.missingIdentifier, 0, 2),
      expectedError(diag.expectedTypeName, 2, 0),
    ]);
  }

  void test_missingStatement_afterVoid() {
    parseStatement("void;");
    listener.assertErrors([expectedError(diag.missingIdentifier, 4, 1)]);
  }

  void test_missingTerminatorForParameterGroup_named() {
    createParser('(a, {b: 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 9, 1)]);
  }

  void test_missingTerminatorForParameterGroup_optional() {
    createParser('(a, [b = 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 10, 1)]);
  }

  void test_missingTypedefParameters_nonVoid() {
    parseCompilationUnit(
      "typedef int F;",
      diagnostics: [expectedError(diag.missingTypedefParameters, 13, 1)],
    );
  }

  void test_missingTypedefParameters_typeParameters() {
    parseCompilationUnit(
      "typedef F<E>;",
      diagnostics: [expectedError(diag.missingTypedefParameters, 12, 1)],
    );
  }

  void test_missingTypedefParameters_void() {
    parseCompilationUnit(
      "typedef void F;",
      diagnostics: [expectedError(diag.missingTypedefParameters, 14, 1)],
    );
  }

  void test_missingVariableInForEach() {
    var statement = parseStatement('for (a < b in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([expectedError(diag.unexpectedToken, 7, 1)]);
  }

  void test_mixedParameterGroups_namedPositional() {
    createParser('(a, {b}, [c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 7, 1)]);
  }

  void test_mixedParameterGroups_positionalNamed() {
    createParser('(a, [b], {c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 7, 1)]);
  }

  void test_mixin_application_lacks_with_clause() {
    parseCompilationUnit(
      "class Foo = Bar;",
      diagnostics: [expectedError(diag.expectedToken, 15, 1)],
    );
  }

  void test_multipleExtendsClauses() {
    parseCompilationUnit(
      "class A extends B extends C {}",
      diagnostics: [expectedError(diag.multipleExtendsClauses, 18, 7)],
    );
  }

  void test_multipleImplementsClauses() {
    parseCompilationUnit(
      "class A implements B implements C {}",
      diagnostics: [expectedError(diag.multipleImplementsClauses, 21, 10)],
    );
  }

  void test_multipleLibraryDirectives() {
    parseCompilationUnit(
      "library l; library m;",
      diagnostics: [expectedError(diag.multipleLibraryDirectives, 11, 7)],
    );
  }

  void test_multipleNamedParameterGroups() {
    createParser('(a, {b}, {c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 7, 1)]);
  }

  void test_multiplePartOfDirectives() {
    parseCompilationUnit(
      "part of l; part of m;",
      diagnostics: [expectedError(diag.multiplePartOfDirectives, 11, 4)],
    );
  }

  void test_multiplePositionalParameterGroups() {
    createParser('(a, [b], [c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 7, 1)]);
  }

  void test_multipleVariablesInForEach() {
    var statement = parseStatement('for (int a, b in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([expectedError(diag.unexpectedToken, 10, 1)]);
  }

  void test_multipleWithClauses() {
    parseCompilationUnit(
      "class A extends B with C with D {}",
      diagnostics: [expectedError(diag.multipleWithClauses, 25, 4)],
    );
  }

  void test_namedFunctionExpression() {
    Expression expression;
    createParser('f() {}');
    expression = parser.parsePrimaryExpression();
    listener.assertErrors([expectedError(diag.namedFunctionExpression, 0, 1)]);
    expect(expression, isFunctionExpression);
  }

  void test_namedParameterOutsideGroup() {
    createParser('(a, b : 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([
      expectedError(diag.namedParameterOutsideGroup, 6, 1),
    ]);
    expect(list.parameters[0].isRequired, isTrue);
    expect(list.parameters[1].isNamed, isTrue);
  }

  void test_nonConstructorFactory_field() {
    createParser('factory int x;', expectedEndOffset: 12);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.missingFunctionParameters, 12, 1),
      expectedError(diag.missingFunctionBody, 12, 1),
    ]);
  }

  void test_nonConstructorFactory_method() {
    createParser('factory int m() {}', expectedEndOffset: 12);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.missingFunctionParameters, 12, 1),
      expectedError(diag.missingFunctionBody, 12, 1),
    ]);
  }

  void test_nonIdentifierLibraryName_library() {
    CompilationUnit unit = parseCompilationUnit(
      "library 'lib';",
      diagnostics: [expectedError(diag.missingIdentifier, 8, 5)],
    );
    expect(unit, isNotNull);
  }

  void test_nonIdentifierLibraryName_partOf() {
    CompilationUnit unit = parseCompilationUnit(
      "part of 3;",
      diagnostics: [
        expectedError(diag.expectedToken, 5, 2),
        expectedError(diag.expectedStringLiteral, 8, 1),
        expectedError(diag.expectedExecutable, 8, 1),
        expectedError(diag.unexpectedToken, 9, 1),
      ],
    );
    expect(unit, isNotNull);
  }

  void test_nonUserDefinableOperator() {
    createParser('operator +=(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.invalidOperator, 9, 2)]);
  }

  void test_optionalAfterNormalParameters_named() {
    parseCompilationUnit(
      "f({a}, b) {}",
      diagnostics: [expectedError(diag.expectedToken, 5, 1)],
    );
  }

  void test_optionalAfterNormalParameters_positional() {
    parseCompilationUnit(
      "f([a], b) {}",
      diagnostics: [expectedError(diag.expectedToken, 5, 1)],
    );
  }

  void test_parseCascadeSection_missingIdentifier() {
    var methodInvocation = parseCascadeSection('..()') as MethodInvocation;
    expectNotNullIfNoErrors(methodInvocation);
    listener.assertErrors([
      // Cascade section is preceded by `null` in this test
      // and error is reported on '('.
      expectedError(diag.missingIdentifier, 6, 1),
    ]);
    expect(methodInvocation.target, isNull);
    expect(methodInvocation.methodName.name, "");
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList.arguments, hasLength(0));
  }

  void test_parseCascadeSection_missingIdentifier_typeArguments() {
    var methodInvocation = parseCascadeSection('..<E>()') as MethodInvocation;
    expectNotNullIfNoErrors(methodInvocation);
    listener.assertErrors([
      // Cascade section is preceded by `null` in this test
      // and error is reported on '<'.
      expectedError(diag.missingIdentifier, 6, 1),
    ]);
    expect(methodInvocation.target, isNull);
    expect(methodInvocation.methodName.name, "");
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList.arguments, hasLength(0));
  }

  void test_partialNamedConstructor() {
    parseCompilationUnit(
      'class C { C. }',
      diagnostics: [
        expectedError(diag.missingIdentifier, 13, 1),
        expectedError(diag.missingMethodParameters, 10, 1),
        expectedError(diag.missingFunctionBody, 13, 1),
      ],
    );
  }

  void test_positionalAfterNamedArgument() {
    createParser('(x: 1, 2)', featureSet: FeatureSets.language_2_16);
    ArgumentList list = parser.parseArgumentList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([
      expectedError(diag.positionalAfterNamedArgument, 7, 1),
    ]);
  }

  void test_positionalParameterOutsideGroup() {
    createParser('(a, b = 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([
      expectedError(diag.namedParameterOutsideGroup, 6, 1),
    ]);
    expect(list.parameters[0].isRequired, isTrue);
    expect(list.parameters[1].isNamed, isTrue);
  }

  void test_redirectionInNonFactoryConstructor() {
    createParser('C() = D;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(diag.redirectionInNonFactoryConstructor, 4, 1),
    ]);
  }

  void test_setterInFunction_block() {
    parseStatement("set x(v) {_x = v;}");
    listener.assertErrors([expectedError(diag.unexpectedToken, 0, 3)]);
  }

  void test_setterInFunction_expression() {
    parseStatement("set x(v) => _x = v;");
    listener.assertErrors([expectedError(diag.unexpectedToken, 0, 3)]);
  }

  void test_staticAfterConst() {
    createParser('final static int f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.modifierOutOfOrder, 6, 6)]);
  }

  void test_staticAfterFinal() {
    createParser('const static int f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.modifierOutOfOrder, 6, 6)]);
  }

  void test_staticAfterVar() {
    createParser('var static f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.modifierOutOfOrder, 4, 6)]);
  }

  void test_staticConstructor() {
    createParser('static C.m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.staticConstructor, 0, 6)]);
  }

  void test_staticGetterWithoutBody() {
    createParser('static get m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingFunctionBody, 12, 1)]);
  }

  void test_staticOperator_noReturnType() {
    createParser('static operator +(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.staticOperator, 0, 6)]);
  }

  void test_staticOperator_returnType() {
    createParser('static int operator +(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.staticOperator, 0, 6)]);
  }

  void test_staticOperatorNamedMethod() {
    // operator can be used as a method name
    parseCompilationUnit('class C { static operator(x) => x; }');
  }

  void test_staticSetterWithoutBody() {
    createParser('static set m(x);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.missingFunctionBody, 15, 1)]);
  }

  void test_staticTopLevelDeclaration_class() {
    parseCompilationUnit(
      "static class C {}",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 6)],
    );
  }

  void test_staticTopLevelDeclaration_enum() {
    parseCompilationUnit(
      "static enum E { v }",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 6)],
    );
  }

  void test_staticTopLevelDeclaration_function() {
    parseCompilationUnit(
      "static f() {}",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 6)],
    );
  }

  void test_staticTopLevelDeclaration_typedef() {
    parseCompilationUnit(
      "static typedef F();",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 6)],
    );
  }

  void test_staticTopLevelDeclaration_variable() {
    parseCompilationUnit(
      "static var x;",
      diagnostics: [expectedError(diag.extraneousModifier, 0, 6)],
    );
  }

  void test_string_unterminated_interpolation_block() {
    parseCompilationUnit(
      r'''
m() {
 {
 '${${
''',
      codes: [
        diag.unterminatedStringLiteral,
        diag.expectedToken,
        diag.expectedToken,
        diag.expectedToken,
        diag.expectedToken,
        diag.expectedToken,
        diag.expectedToken,
      ],
    );
  }

  void test_switchCase_missingColon() {
    var statement =
        parseStatement('switch (a) {case 1 return 0;}') as SwitchStatement;
    expect(statement, isNotNull);
    listener.assertErrors([expectedError(diag.expectedToken, 19, 6)]);
  }

  void test_switchDefault_missingColon() {
    var statement =
        parseStatement('switch (a) {default return 0;}') as SwitchStatement;
    expect(statement, isNotNull);
    listener.assertErrors([expectedError(diag.expectedToken, 20, 6)]);
  }

  void test_switchHasCaseAfterDefaultCase() {
    var statement =
        parseStatement('switch (a) {default: return 0; case 1: return 1;}')
            as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.switchHasCaseAfterDefaultCase, 31, 4),
    ]);
  }

  void test_switchHasCaseAfterDefaultCase_repeated() {
    var statement =
        parseStatement(
              'switch (a) {default: return 0; case 1: return 1; case 2: return 2;}',
            )
            as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.switchHasCaseAfterDefaultCase, 31, 4),
      expectedError(diag.switchHasCaseAfterDefaultCase, 49, 4),
    ]);
  }

  void test_switchHasMultipleDefaultCases() {
    var statement =
        parseStatement('switch (a) {default: return 0; default: return 1;}')
            as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.switchHasMultipleDefaultCases, 31, 7),
    ]);
  }

  void test_switchHasMultipleDefaultCases_repeated() {
    var statement =
        parseStatement(
              'switch (a) {default: return 0; default: return 1; default: return 2;}',
            )
            as SwitchStatement;
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(diag.switchHasMultipleDefaultCases, 31, 7),
      expectedError(diag.switchHasMultipleDefaultCases, 50, 7),
    ]);
  }

  void test_switchMissingBlock() {
    var statement =
        parseStatement('switch (a) return;', expectedEndOffset: 11)
            as SwitchStatement;
    expect(statement, isNotNull);
    listener.assertErrors([
      expectedError(diag.expectedSwitchStatementBody, 9, 1),
    ]);
  }

  void test_topLevel_getter() {
    createParser('get x => 7;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var function = member as FunctionDeclaration;
    expect(function.functionExpression.parameters, isNull);
  }

  void test_topLevelFactory_withFunction() {
    parseCompilationUnit(
      'factory Function() x = null;',
      diagnostics: [expectedError(diag.factoryTopLevelDeclaration, 0, 7)],
    );
  }

  void test_topLevelOperator_withFunction() {
    parseCompilationUnit(
      'operator Function() x = null;',
      diagnostics: [expectedError(diag.topLevelOperator, 0, 8)],
    );
  }

  void test_topLevelOperator_withoutOperator() {
    createParser('+(bool x, bool y) => x | y;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.topLevelOperator, 0, 1)]);
  }

  void test_topLevelOperator_withoutType() {
    parseCompilationUnit(
      'operator +(bool x, bool y) => x | y;',
      diagnostics: [expectedError(diag.topLevelOperator, 0, 8)],
    );
  }

  void test_topLevelOperator_withType() {
    parseCompilationUnit(
      'bool operator +(bool x, bool y) => x | y;',
      diagnostics: [expectedError(diag.topLevelOperator, 5, 8)],
    );
  }

  void test_topLevelOperator_withVoid() {
    parseCompilationUnit(
      'void operator +(bool x, bool y) => x | y;',
      diagnostics: [expectedError(diag.topLevelOperator, 5, 8)],
    );
  }

  void test_topLevelVariable_withMetadata() {
    parseCompilationUnit(
      "String @A string;",
      codes: [
        diag.missingConstFinalVarOrType,
        diag.expectedToken,
        diag.missingConstFinalVarOrType,
      ],
    );
  }

  void test_typedef_incomplete() {
    // TODO(brianwilkerson): Improve recovery for this case.
    parseCompilationUnit(
      '''
class A {}
class B extends A {}

typedef T

main() {
  Function<
}
''',
      diagnostics: [
        expectedError(diag.expectedToken, 49, 1),
        expectedError(diag.expectedExecutable, 51, 1),
      ],
    );
  }

  void test_typedef_namedFunction() {
    parseCompilationUnit(
      'typedef void Function();',
      codes: [diag.expectedIdentifierButGotKeyword],
    );
  }

  void test_typedefInClass_withoutReturnType() {
    parseCompilationUnit(
      "class C { typedef F(x); }",
      diagnostics: [expectedError(diag.typedefInClass, 10, 7)],
    );
  }

  void test_typedefInClass_withReturnType() {
    parseCompilationUnit(
      "class C { typedef int F(int x); }",
      diagnostics: [expectedError(diag.typedefInClass, 10, 7)],
    );
  }

  void test_unexpectedCommaThenInterpolation() {
    // https://github.com/Dart-Code/Dart-Code/issues/1548
    parseCompilationUnit(
      r"main() { String s = 'a' 'b', 'c$foo'; return s; }",
      diagnostics: [
        expectedError(diag.expectedToken, 27, 1),
        expectedError(diag.missingIdentifier, 29, 2),
      ],
    );
  }

  void test_unexpectedTerminatorForParameterGroup_named() {
    createParser('(a, b})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 5, 1)]);
  }

  void test_unexpectedTerminatorForParameterGroup_optional() {
    createParser('(a, b])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.expectedToken, 5, 1)]);
  }

  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    parseStatement("String s = (null));", expectedEndOffset: 17);
    listener.assertErrors([expectedError(diag.expectedToken, 16, 1)]);
  }

  void test_unexpectedToken_invalidPostfixExpression() {
    parseExpression(
      "f()++",
      diagnostics: [expectedError(diag.illegalAssignmentToNonAssignable, 3, 2)],
    );
  }

  void test_unexpectedToken_invalidPrefixExpression() {
    parseExpression(
      "++f()",
      diagnostics: [expectedError(diag.missingAssignableSelector, 4, 1)],
    );
  }

  void test_unexpectedToken_returnInExpressionFunctionBody() {
    parseCompilationUnit(
      "f() => return null;",
      diagnostics: [expectedError(diag.unexpectedToken, 7, 6)],
    );
  }

  void test_unexpectedToken_semicolonBetweenClassMembers() {
    createParser('class C { int x; ; int y;}');
    var declaration = parseFullCompilationUnitMember() as ClassDeclaration;
    expectNotNullIfNoErrors(declaration);
    listener.assertErrors([expectedError(diag.expectedClassMember, 17, 1)]);
  }

  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    parseCompilationUnit(
      "int x; ; int y;",
      diagnostics: [expectedError(diag.unexpectedToken, 7, 1)],
    );
  }

  void test_unnamedLibraryDirective() {
    CompilationUnit unit = parseCompilationUnit(
      "library;",
      featureSet: FeatureSets.language_2_18,
      diagnostics: [expectedError(diag.experimentNotEnabled, 0, 7)],
    );
    expect(unit, isNotNull);
  }

  void test_unnamedLibraryDirective_enabled() {
    CompilationUnit unit = parseCompilationUnit("library;");
    expect(unit, isNotNull);
  }

  void test_unterminatedString_at_eof() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    parseCompilationUnit(
      r'''
void main() {
  var x = "''',
      diagnostics: [
        expectedError(diag.unterminatedStringLiteral, 24, 1),
        expectedError(diag.expectedToken, 25, 1),
        expectedError(diag.expectedToken, 24, 1),
      ],
    );
  }

  void test_unterminatedString_at_eol() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    parseCompilationUnit(
      r'''
void main() {
  var x = "
;
}
''',
      diagnostics: [expectedError(diag.unterminatedStringLiteral, 24, 1)],
    );
  }

  void test_unterminatedString_multiline_at_eof_3_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseCompilationUnit(
      r'''
void main() {
  var x = """''',
      codes: [
        diag.unterminatedStringLiteral,
        diag.expectedToken,
        diag.expectedToken,
      ],
      diagnostics: [
        expectedError(diag.unterminatedStringLiteral, 24, 1),
        expectedError(diag.expectedToken, 30, 0),
        expectedError(diag.expectedToken, 30, 0),
      ],
    );
  }

  void test_unterminatedString_multiline_at_eof_4_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseCompilationUnit(
      r'''
void main() {
  var x = """"''',
      codes: [
        diag.unterminatedStringLiteral,
        diag.expectedToken,
        diag.expectedToken,
      ],
      diagnostics: [
        expectedError(diag.unterminatedStringLiteral, 24, 1),
        expectedError(diag.expectedToken, 31, 0),
        expectedError(diag.expectedToken, 31, 0),
      ],
    );
  }

  void test_unterminatedString_multiline_at_eof_5_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseCompilationUnit(
      r'''
void main() {
  var x = """""''',
      codes: [
        diag.unterminatedStringLiteral,
        diag.expectedToken,
        diag.expectedToken,
      ],
      diagnostics: [
        expectedError(diag.unterminatedStringLiteral, 28, 1),
        expectedError(diag.expectedToken, 32, 0),
        expectedError(diag.expectedToken, 32, 0),
      ],
    );
  }

  void test_useOfUnaryPlusOperator() {
    createParser('+x');
    Expression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([expectedError(diag.missingIdentifier, 0, 1)]);
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand.isSynthetic, isTrue);
    expect(binaryExpression.rightOperand.isSynthetic, isFalse);
    var identifier = binaryExpression.rightOperand as SimpleIdentifier;
    expect(identifier.name, 'x');
  }

  void test_varAndType_field() {
    parseCompilationUnit(
      "class C { var int x; }",
      diagnostics: [expectedError(diag.varAndType, 10, 3)],
    );
  }

  void test_varAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    parseStatement("var int x;");
    listener.assertErrors([expectedError(diag.varAndType, 0, 3)]);
  }

  void test_varAndType_parameter() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    createParser('(var int x)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([expectedError(diag.varAndType, 1, 3)]);
  }

  void test_varAndType_topLevelVariable() {
    parseCompilationUnit(
      "var int x;",
      diagnostics: [expectedError(diag.varAndType, 0, 3)],
    );
  }

  void test_varAsTypeName_as() {
    parseExpression(
      "x as var",
      expectedEndOffset: 5,
      diagnostics: [expectedError(diag.expectedTypeName, 5, 3)],
    );
  }

  void test_varClass() {
    parseCompilationUnit(
      "var class C {}",
      diagnostics: [
        // Fasta interprets the `var` as a malformed top level var
        // and `class` as the start of a class declaration.
        expectedError(diag.expectedToken, 0, 3),
        expectedError(diag.missingIdentifier, 4, 5),
      ],
    );
  }

  void test_varEnum() {
    parseCompilationUnit(
      "var enum E {ONE}",
      diagnostics: [
        // Fasta interprets the `var` as a malformed top level var
        // and `enum` as the start of an enum declaration.
        expectedError(diag.expectedToken, 0, 3),
        expectedError(diag.missingIdentifier, 4, 4),
      ],
    );
  }

  void test_varReturnType() {
    createParser('var m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(diag.varReturnType, 0, 3)]);
  }

  void test_varTypedef() {
    parseCompilationUnit(
      "var typedef F();",
      diagnostics: [
        // Fasta interprets the `var` as a malformed top level var
        // and `typedef` as the start of an typedef declaration.
        expectedError(diag.expectedToken, 0, 3),
        expectedError(diag.missingIdentifier, 4, 7),
      ],
    );
  }

  void test_voidParameter() {
    var parameter =
        parseFormalParameterList('(void a)').parameters[0]
            as NormalFormalParameter;
    expectNotNullIfNoErrors(parameter);
    assertNoErrors();
  }

  void test_voidVariable_parseClassMember_initializer() {
    createParser('void x = 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_voidVariable_parseClassMember_noInitializer() {
    createParser('void x;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_voidVariable_parseCompilationUnit_initializer() {
    parseCompilationUnit("void x = 0;");
  }

  void test_voidVariable_parseCompilationUnit_noInitializer() {
    parseCompilationUnit("void x;");
  }

  void test_voidVariable_parseCompilationUnitMember_initializer() {
    createParser('void a = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    createParser('void a;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_voidVariable_statement_initializer() {
    parseStatement("void x = 0;");
    assertNoErrors();
  }

  void test_voidVariable_statement_noInitializer() {
    parseStatement("void x;");
    assertNoErrors();
  }

  void test_withBeforeExtends() {
    parseCompilationUnit(
      "class A with B extends C {}",
      diagnostics: [expectedError(diag.withBeforeExtends, 15, 7)],
    );
  }

  void test_withWithoutExtends() {
    createParser('class A with B, C {}');
    var declaration = parseFullCompilationUnitMember() as ClassDeclaration;
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
  }

  void test_wrongSeparatorForPositionalParameter() {
    createParser('(a, [b : 0])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([
      expectedError(diag.wrongSeparatorForPositionalParameter, 7, 1),
    ]);
  }

  void test_wrongTerminatorForParameterGroup_named() {
    createParser('(a, {b, c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    // fasta scanner generates '(a, {b, c]})' where '}' is synthetic
    listener.assertErrors([
      expectedError(diag.expectedToken, 9, 1),
      expectedError(diag.expectedToken, 10, 1),
    ]);
  }

  void test_wrongTerminatorForParameterGroup_optional() {
    createParser('(a, [b, c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    // fasta scanner generates '(a, [b, c}])' where ']' is synthetic
    listener.assertErrors([
      expectedError(diag.expectedToken, 9, 1),
      expectedError(diag.expectedToken, 10, 1),
    ]);
  }

  void test_yieldAsLabel() {
    // yield can be used as a label
    parseCompilationUnit('main() { yield: break yield; }');
  }
}
