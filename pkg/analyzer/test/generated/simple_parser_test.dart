// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleParserTest);
  });
}

/// Parser tests that test individual parsing methods. The code fragments should
/// be as minimal as possible in order to test the method, but should not test
/// the interactions between the method under test and other methods.
///
/// More complex tests should be defined in the class [ComplexParserTest].
@reflectiveTest
class SimpleParserTest extends FastaParserTestCase {
  ConstructorName parseConstructorName(String name) {
    createParser('new $name();');
    Statement statement = parser.parseStatement2();
    expect(statement, isExpressionStatement);
    Expression expression = (statement as ExpressionStatement).expression;
    expect(expression, isInstanceCreationExpression);
    return (expression as InstanceCreationExpression).constructorName;
  }

  ExtendsClause parseExtendsClause(String clause) {
    createParser('class TestClass $clause {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl, isNotNull);
    return classDecl.extendsClause!;
  }

  List<SimpleIdentifier> parseIdentifierList(String identifiers) {
    createParser('show $identifiers');
    List<Combinator> combinators = parser.parseCombinators();
    expect(combinators, hasLength(1));
    return (combinators[0] as ShowCombinator).shownNames;
  }

  ImplementsClause parseImplementsClause(String clause) {
    createParser('class TestClass $clause {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl, isNotNull);
    return classDecl.implementsClause!;
  }

  LibraryIdentifier? parseLibraryIdentifier(String name) {
    createParser('library $name;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.directives, hasLength(1));
    var directive = unit.directives[0] as LibraryDirective;
    return directive.name2;
  }

  /// Parse the given [content] as a sequence of statements by enclosing it in a
  /// block. The [expectedCount] is the number of statements that are expected
  /// to be parsed. If [errorCodes] are provided, verify that the error codes of
  /// the errors that are expected are found.
  void parseStatementList(String content, int expectedCount) {
    Statement statement = parseStatement('{$content}');
    expect(statement, isBlock);
    var block = statement as Block;
    expect(block.statements, hasLength(expectedCount));
  }

  VariableDeclaration parseVariableDeclaration(String declaration) {
    createParser(declaration);
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    var decl = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(decl, isNotNull);
    return decl.variables.variables[0];
  }

  WithClause parseWithClause(String clause) {
    createParser('class TestClass extends Object $clause {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl, isNotNull);
    return classDecl.withClause!;
  }

  void test_classDeclaration_complexTypeParam() {
    CompilationUnit unit = parseCompilationUnit('''
class C<@Foo.bar(const [], const [1], const{"":r""}, 0xFF + 2, .3, 4.5) T> {}
''');
    var clazz = unit.declarations[0] as ClassDeclaration;
    expect(clazz.name.lexeme, 'C');
    expect(clazz.typeParameters!.typeParameters, hasLength(1));
    TypeParameter typeParameter = clazz.typeParameters!.typeParameters[0];
    expect(typeParameter.name.lexeme, 'T');
    expect(typeParameter.metadata, hasLength(1));
    Annotation metadata = typeParameter.metadata[0];
    expect(metadata.name.name, 'Foo.bar');
  }

  void test_classDeclaration_invalid_super() {
    parseCompilationUnit('''
class C {
  C() : super.const();
}
''', errors: [
      expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 18, 5),
      expectedError(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 24, 5),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 24, 5),
    ]);
  }

  void test_classDeclaration_invalid_this() {
    parseCompilationUnit('''
class C {
  C() : this.const();
}
''', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 18, 4),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 23, 5),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 23, 5),
      expectedError(ParserErrorCode.CONST_METHOD, 23, 5),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 28, 1),
    ]);
  }

  void test_method_name_notNull_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'class C { f(<T>()); }', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 12, 1),
    ]);
    var classDeclaration = unit.declarations[0] as ClassDeclaration;
    var method = classDeclaration.members[0] as MethodDeclaration;
    expect(method.parameters!.parameters, hasLength(1));
    var parameter =
        method.parameters!.parameters[0] as FunctionTypedFormalParameter;
    expect(parameter.name, isNotNull);
  }

  void test_parseAnnotation_n1() {
    createParser('@A');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n1_a() {
    createParser('@A(x,y)');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseAnnotation_n2() {
    createParser('@A.B');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n2_a() {
    createParser('@A.B(x,y)');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseAnnotation_n3() {
    createParser('@A.B.C');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNotNull);
    expect(annotation.constructorName, isNotNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n3_a() {
    createParser('@A.B.C(x,y)');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNotNull);
    expect(annotation.constructorName, isNotNull);
    expect(annotation.arguments, isNotNull);
  }

  test_parseArgument() {
    Expression result = parseArgument('3');
    expect(result, const TypeMatcher<IntegerLiteral>());
    var literal = result as IntegerLiteral;
    expect(literal.value, 3);
  }

  test_parseArgument_named() {
    Expression result = parseArgument('foo: "a"');
    expect(result, const TypeMatcher<NamedExpression>());
    var expression = result as NamedExpression;
    var literal = expression.expression as StringLiteral;
    expect(literal.stringValue, 'a');
  }

  void test_parseArgumentList_empty() {
    createParser('()');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(0));
  }

  void test_parseArgumentList_mixed() {
    createParser('(w, x, y: y, z: z)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(4));
  }

  void test_parseArgumentList_noNamed() {
    createParser('(x, y, z)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(3));
  }

  void test_parseArgumentList_onlyNamed() {
    createParser('(x: x, y: y)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(2));
  }

  void test_parseArgumentList_trailing_comma() {
    createParser('(x, y, z,)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(3));
  }

  void test_parseArgumentList_typeArguments() {
    createParser('(a<b,c>(d))');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(1));
  }

  void test_parseArgumentList_typeArguments_none() {
    createParser('(a<b,p.q.c>(d))');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(2));
  }

  void test_parseArgumentList_typeArguments_prefixed() {
    createParser('(a<b,p.c>(d))');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(1));
  }

  void test_parseCombinators_h() {
    createParser('hide a');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    assertNoErrors();
    expect(combinators, hasLength(1));
    HideCombinator combinator = combinators[0] as HideCombinator;
    expect(combinator, isNotNull);
    expect(combinator.keyword, isNotNull);
    expect(combinator.hiddenNames, hasLength(1));
  }

  void test_parseCombinators_hs() {
    createParser('hide a show b');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    assertNoErrors();
    expect(combinators, hasLength(2));
    HideCombinator hideCombinator = combinators[0] as HideCombinator;
    expect(hideCombinator, isNotNull);
    expect(hideCombinator.keyword, isNotNull);
    expect(hideCombinator.hiddenNames, hasLength(1));
    ShowCombinator showCombinator = combinators[1] as ShowCombinator;
    expect(showCombinator, isNotNull);
    expect(showCombinator.keyword, isNotNull);
    expect(showCombinator.shownNames, hasLength(1));
  }

  void test_parseCombinators_hshs() {
    createParser('hide a show b hide c show d');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    assertNoErrors();
    expect(combinators, hasLength(4));
  }

  void test_parseCombinators_s() {
    createParser('show a');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    assertNoErrors();
    expect(combinators, hasLength(1));
    ShowCombinator combinator = combinators[0] as ShowCombinator;
    expect(combinator, isNotNull);
    expect(combinator.keyword, isNotNull);
    expect(combinator.shownNames, hasLength(1));
  }

  void test_parseCommentAndMetadata_c() {
    createParser('/** 1 */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, isEmpty);
  }

  void test_parseCommentAndMetadata_cmc() {
    createParser('/** 1 */ @A /** 2 */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    Comment comment = declaration.documentationComment!;
    expect(comment.tokens, hasLength(1));
    expect(comment.tokens[0].lexeme, '/** 2 */');
    expect(declaration.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_cmcm() {
    createParser('/** 1 */ @A /** 2 */ @B class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_cmm() {
    createParser('/** 1 */ @A @B class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_m() {
    createParser('@A class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_mcm() {
    createParser('@A /** 1 */ @B class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_mcmc() {
    createParser('@A /** 1 */ @B /** 2 */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.documentationComment!.tokens[0].lexeme, contains('2'));
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_mix1() {
    createParser(r'''
/**
 * aaa
 */
/**
 * bbb
 */
class A {}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment!.tokens;
    expect(tokens, hasLength(1));
    expect(tokens[0].lexeme, contains('bbb'));
  }

  void test_parseCommentAndMetadata_mix2() {
    createParser(r'''
/**
 * aaa
 */
/// bbb
/// ccc
class B {}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment!.tokens;
    expect(tokens, hasLength(2));
    expect(tokens[0].lexeme, contains('bbb'));
    expect(tokens[1].lexeme, contains('ccc'));
  }

  void test_parseCommentAndMetadata_mix3() {
    createParser(r'''
/// aaa
/// bbb
/**
 * ccc
 */
class C {}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment!.tokens;
    expect(tokens, hasLength(1));
    expect(tokens[0].lexeme, contains('ccc'));
  }

  test_parseCommentAndMetadata_mix4() {
    createParser(r'''
/// aaa
/// bbb
/**
 * ccc
 */
/// ddd
class D {}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment!.tokens;
    expect(tokens, hasLength(1));
    expect(tokens[0].lexeme, contains('ddd'));
  }

  test_parseCommentAndMetadata_mix5() {
    createParser(r'''
/**
 * aaa
 */
// bbb
class E {}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment!.tokens;
    expect(tokens, hasLength(1));
    expect(tokens[0].lexeme, contains('aaa'));
  }

  void test_parseCommentAndMetadata_mm() {
    createParser('@A @B(x) class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_none() {
    createParser('class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.metadata, isEmpty);
  }

  void test_parseCommentAndMetadata_singleLine() {
    createParser(r'''
/// 1
/// 2
class C {}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, isEmpty);
  }

  void test_parseCommentReferences_notClosed_noIdentifier() {
    DocumentationCommentToken docToken = DocumentationCommentToken(
        TokenType.MULTI_LINE_COMMENT, "/** [ some text", 5);
    createParser('');
    var comment = parser.parseComment([docToken]);
    var references = comment.references;
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    Token referenceToken = reference.expression.beginToken;
    expect(reference, isNotNull);
    expect(reference.expression, isNotNull);
    var identifier = reference.expression as Identifier;
    expect(identifier.isSynthetic, isTrue);
    expect(identifier.name, "");
    // Should end with EOF token.
    Token nextToken = referenceToken.next!;
    expect(nextToken, isNotNull);
    expect(nextToken.type, TokenType.EOF);
  }

  void test_parseConfiguration_noOperator_dottedIdentifier() {
    createParser("if (a.b) 'c.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    expectDottedName(configuration.name, ["a", "b"]);
    expect(configuration.equalToken, isNull);
    expect(configuration.value, isNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConfiguration_noOperator_simpleIdentifier() {
    createParser("if (a) 'b.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    expectDottedName(configuration.name, ["a"]);
    expect(configuration.equalToken, isNull);
    expect(configuration.value, isNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConfiguration_operator_dottedIdentifier() {
    createParser("if (a.b == 'c') 'd.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    expectDottedName(configuration.name, ["a", "b"]);
    expect(configuration.equalToken, isNotNull);
    expect(configuration.value, isNotNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConfiguration_operator_simpleIdentifier() {
    createParser("if (a == 'b') 'c.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    expectDottedName(configuration.name, ["a"]);
    expect(configuration.equalToken, isNotNull);
    expect(configuration.value, isNotNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConstructorName_named_noPrefix() {
    ConstructorName name = parseConstructorName('A.n');
    expectNotNullIfNoErrors(name);
    assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseConstructorName_named_prefixed() {
    ConstructorName name = parseConstructorName('p.A.n');
    expectNotNullIfNoErrors(name);
    assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
  }

  void test_parseConstructorName_unnamed_noPrefix() {
    ConstructorName name = parseConstructorName('A');
    expectNotNullIfNoErrors(name);
    assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseConstructorName_unnamed_prefixed() {
    ConstructorName name = parseConstructorName('p.A');
    expectNotNullIfNoErrors(name);
    assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseDocumentationComment_block() {
    createParser('/** */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    Comment comment = unit.declarations[0].documentationComment!;
    expectNotNullIfNoErrors(comment);
    assertNoErrors();
  }

  void test_parseDocumentationComment_block_withReference() {
    createParser('/** [a] */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    Comment comment = unit.declarations[0].documentationComment!;
    expectNotNullIfNoErrors(comment);
    assertNoErrors();
    NodeList<CommentReference> references = comment.references;
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.offset, 5);
  }

  void test_parseDocumentationComment_endOfLine() {
    createParser('/// \n/// \n class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    Comment comment = unit.declarations[0].documentationComment!;
    expectNotNullIfNoErrors(comment);
    assertNoErrors();
  }

  void test_parseExtendsClause() {
    ExtendsClause clause = parseExtendsClause('extends B');
    expectNotNullIfNoErrors(clause);
    assertNoErrors();
    expect(clause.extendsKeyword, isNotNull);
    expect(clause.superclass, isNotNull);
    expect(clause.superclass, isNamedType);
  }

  void test_parseFunctionBody_block() {
    createParser('{}');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    var body = functionBody as BlockFunctionBody;
    expect(body.keyword, isNull);
    expect(body.star, isNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_block_async() {
    createParser('async {}');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    var body = functionBody as BlockFunctionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword!.lexeme, Keyword.ASYNC.lexeme);
    expect(body.star, isNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_asyncGenerator() {
    createParser('async* {}');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    var body = functionBody as BlockFunctionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword!.lexeme, Keyword.ASYNC.lexeme);
    expect(body.star, isNotNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isTrue);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_syncGenerator() {
    createParser('sync* {}');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    var body = functionBody as BlockFunctionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword!.lexeme, Keyword.SYNC.lexeme);
    expect(body.star, isNotNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isTrue);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_empty() {
    createParser(';');
    FunctionBody functionBody = parser.parseFunctionBody(
        true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isEmptyFunctionBody);
    var body = functionBody as EmptyFunctionBody;
    expect(body.semicolon, isNotNull);
  }

  void test_parseFunctionBody_expression() {
    createParser('=> y;');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isExpressionFunctionBody);
    var body = functionBody as ExpressionFunctionBody;
    expect(body.keyword, isNull);
    expect(body.functionDefinition, isNotNull);
    expect(body.expression, isNotNull);
    expect(body.semicolon, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_expression_async() {
    createParser('async => y;');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isExpressionFunctionBody);
    var body = functionBody as ExpressionFunctionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword!.lexeme, Keyword.ASYNC.lexeme);
    expect(body.functionDefinition, isNotNull);
    expect(body.expression, isNotNull);
    expect(body.semicolon, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseIdentifierList_multiple() {
    List<SimpleIdentifier> list = parseIdentifierList('a, b, c');
    expectNotNullIfNoErrors(list);
    assertNoErrors();
    expect(list, hasLength(3));
  }

  void test_parseIdentifierList_single() {
    List<SimpleIdentifier> list = parseIdentifierList('a');
    expectNotNullIfNoErrors(list);
    assertNoErrors();
    expect(list, hasLength(1));
  }

  void test_parseImplementsClause_multiple() {
    ImplementsClause clause = parseImplementsClause('implements A, B, C');
    expectNotNullIfNoErrors(clause);
    assertNoErrors();
    expect(clause.interfaces, hasLength(3));
    expect(clause.implementsKeyword, isNotNull);
  }

  void test_parseImplementsClause_single() {
    ImplementsClause clause = parseImplementsClause('implements A');
    expectNotNullIfNoErrors(clause);
    assertNoErrors();
    expect(clause.interfaces, hasLength(1));
    expect(clause.implementsKeyword, isNotNull);
  }

  void test_parseInstanceCreation_keyword_33647() {
    CompilationUnit unit = parseCompilationUnit('''
var c = new Future<int>.sync(() => 3).then<int>((e) => e);
''');
    expect(unit, isNotNull);
    var v = unit.declarations[0] as TopLevelVariableDeclaration;
    var init = v.variables.variables[0].initializer as MethodInvocation;
    expect(init.methodName.name, 'then');
    NodeList<TypeAnnotation> typeArg = init.typeArguments!.arguments;
    expect(typeArg, hasLength(1));
    expect(typeArg[0].beginToken.lexeme, 'int');
  }

  void test_parseInstanceCreation_noKeyword_33647() {
    CompilationUnit unit = parseCompilationUnit('''
var c = Future<int>.sync(() => 3).then<int>((e) => e);
''');
    expect(unit, isNotNull);
    var v = unit.declarations[0] as TopLevelVariableDeclaration;
    var init = v.variables.variables[0].initializer as MethodInvocation;
    expect(init.methodName.name, 'then');
    NodeList<TypeAnnotation> typeArg = init.typeArguments!.arguments;
    expect(typeArg, hasLength(1));
    expect(typeArg[0].beginToken.lexeme, 'int');
  }

  void test_parseInstanceCreation_noKeyword_noPrefix() {
    createParser('f() => C<E>.n();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    var f = unit.declarations[0] as FunctionDeclaration;
    var body = f.functionExpression.body as ExpressionFunctionBody;
    expect(body.expression, isInstanceCreationExpression);
    var creation = body.expression as InstanceCreationExpressionImpl;
    expect(creation.keyword, isNull);
    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.type.toSource(), 'C<E>');
    expect(constructorName.period, isNotNull);
    expect(constructorName.name, isNotNull);
    expect(creation.argumentList, isNotNull);
    expect(creation.typeArguments, isNull);
  }

  void test_parseInstanceCreation_noKeyword_noPrefix_34403() {
    createParser('f() => C<E>.n<B>();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    var f = unit.declarations[0] as FunctionDeclaration;
    var body = f.functionExpression.body as ExpressionFunctionBody;
    expect(body.expression, isMethodInvocation);
    var methodInvocation = body.expression as MethodInvocationImpl;
    var target = methodInvocation.target!;
    expect(target, isFunctionReference);
    expect(target.toSource(), 'C<E>');
    expect(methodInvocation.methodName.name, 'n');
    expect(methodInvocation.argumentList, isNotNull);
    expect(methodInvocation.typeArguments!.arguments, hasLength(1));
  }

  void test_parseInstanceCreation_noKeyword_prefix() {
    createParser('f() => p.C<E>.n();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    var f = unit.declarations[0] as FunctionDeclaration;
    var body = f.functionExpression.body as ExpressionFunctionBody;
    expect(body.expression, isInstanceCreationExpression);
    var creation = body.expression as InstanceCreationExpression;
    expect(creation.keyword, isNull);
    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.type.toSource(), 'p.C<E>');
    expect(constructorName.period, isNotNull);
    expect(constructorName.name, isNotNull);
    expect(creation.argumentList, isNotNull);
  }

  void test_parseInstanceCreation_noKeyword_varInit() {
    createParser('''
class C<T, S> {}
void main() {final c = C<int, int Function(String)>();}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    var f = unit.declarations[1] as FunctionDeclaration;
    var body = f.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as VariableDeclarationStatement;
    VariableDeclaration variable = statement.variables.variables[0];
    var creation = variable.initializer as MethodInvocation;
    expect(creation.methodName.name, 'C');
    expect(creation.typeArguments!.toSource(), '<int, int Function(String)>');
  }

  void test_parseLibraryIdentifier_builtin() {
    String name = "deferred";
    LibraryIdentifier identifier = parseLibraryIdentifier(name)!;
    expectNotNullIfNoErrors(identifier);
    assertNoErrors();
    expect(identifier.name, name);
    expect(identifier.beginToken.type.isBuiltIn, isTrue);
  }

  void test_parseLibraryIdentifier_invalid() {
    parseCompilationUnit('library <myLibId>;', errors: [
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 0, 7),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 17, 1),
    ]);
  }

  void test_parseLibraryIdentifier_multiple() {
    String name = "a.b.c";
    LibraryIdentifier identifier = parseLibraryIdentifier(name)!;
    expectNotNullIfNoErrors(identifier);
    assertNoErrors();
    expect(identifier.name, name);
  }

  void test_parseLibraryIdentifier_pseudo() {
    String name = "await";
    LibraryIdentifier identifier = parseLibraryIdentifier(name)!;
    expectNotNullIfNoErrors(identifier);
    assertNoErrors();
    expect(identifier.name, name);
    expect(identifier.beginToken.type.isPseudo, isTrue);
  }

  void test_parseLibraryIdentifier_single() {
    String name = "a";
    LibraryIdentifier identifier = parseLibraryIdentifier(name)!;
    expectNotNullIfNoErrors(identifier);
    assertNoErrors();
    expect(identifier.name, name);
  }

  void test_parseOptionalReturnType() {
    // TODO(brianwilkerson): Implement tests for this method.
  }

  void test_parseReturnStatement_noValue() {
    var statement = parseStatement('return;') as ReturnStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
    expect(statement.returnKeyword, isNotNull);
    expect(statement.expression, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseReturnStatement_value() {
    var statement = parseStatement('return x;') as ReturnStatement;
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
    expect(statement.returnKeyword, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseStatement_function_noReturnType() {
    createParser('''
Function<A>(core.List<core.int> x) m() => null;
''');
    Statement statement = parser.parseStatement2();
    expect(statement, isFunctionDeclarationStatement);
    expect(
        (statement as FunctionDeclarationStatement)
            .functionDeclaration
            .functionExpression
            .body,
        isExpressionFunctionBody);
  }

  void test_parseStatements_multiple() {
    parseStatementList("return; return;", 2);
  }

  void test_parseStatements_single() {
    parseStatementList("return;", 1);
  }

  void test_parseTypeAnnotation_function_noReturnType_noParameters() {
    createParser('Function()');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNull);
    expect(functionType.functionKeyword, isNotNull);
    expect(functionType.typeParameters, isNull);
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void test_parseTypeAnnotation_function_noReturnType_parameters() {
    createParser('Function(int, int)');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNull);
    expect(functionType.functionKeyword, isNotNull);
    expect(functionType.typeParameters, isNull);
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    NodeList<FormalParameter> parameters = parameterList.parameters;
    expect(parameters, hasLength(2));

    expect(parameters[0], isSimpleFormalParameter);
    var parameter = parameters[0] as SimpleFormalParameter;
    expect(parameter.name, isNull);
    expect(parameter.type, isNamedType);
    expect((parameter.type as NamedType).name2.lexeme, 'int');

    expect(parameters[1], isSimpleFormalParameter);
    parameter = parameters[1] as SimpleFormalParameter;
    expect(parameter.name, isNull);
    expect(parameter.type, isNamedType);
    expect((parameter.type as NamedType).name2.lexeme, 'int');
  }

  void test_parseTypeAnnotation_function_noReturnType_typeParameters() {
    createParser('Function<S, T>()');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNull);
    expect(functionType.functionKeyword, isNotNull);
    var typeParameters = functionType.typeParameters!;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(2));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void
      test_parseTypeAnnotation_function_noReturnType_typeParameters_parameters() {
    createParser('Function<T>(String, {T t})');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNull);
    expect(functionType.functionKeyword, isNotNull);
    var typeParameters = functionType.typeParameters!;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(1));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(2));
  }

  void test_parseTypeAnnotation_function_returnType_classFunction() {
    createParser('Function');
    var functionType = parser.parseTypeAnnotation(false) as NamedType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_function_returnType_function() {
    createParser('A Function(B, C) Function(D)');
    // TODO(scheglov): improve the test to verify also the node properties
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_function_returnType_noParameters() {
    createParser('List<int> Function()');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNotNull);
    expect(functionType.functionKeyword, isNotNull);
    expect(functionType.typeParameters, isNull);
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void test_parseTypeAnnotation_function_returnType_parameters() {
    createParser('List<int> Function(String s, int i)');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNotNull);
    expect(functionType.functionKeyword, isNotNull);
    expect(functionType.typeParameters, isNull);
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    NodeList<FormalParameter> parameters = parameterList.parameters;
    expect(parameters, hasLength(2));

    expect(parameters[0], isSimpleFormalParameter);
    var parameter = parameters[0] as SimpleFormalParameter;
    expect(parameter.name, isNotNull);
    expect(parameter.name!.lexeme, 's');
    expect(parameter.type, isNamedType);
    expect((parameter.type as NamedType).name2.lexeme, 'String');

    expect(parameters[1], isSimpleFormalParameter);
    parameter = parameters[1] as SimpleFormalParameter;
    expect(parameter.name, isNotNull);
    expect(parameter.name!.lexeme, 'i');
    expect(parameter.type, isNamedType);
    expect((parameter.type as NamedType).name2.lexeme, 'int');
  }

  void test_parseTypeAnnotation_function_returnType_simple() {
    createParser('A Function(B, C)');
    // TODO(scheglov): improve the test to verify also the node properties
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_function_returnType_typeParameters() {
    createParser('List<T> Function<T>()');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNotNull);
    expect(functionType.functionKeyword, isNotNull);
    var typeParameters = functionType.typeParameters!;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(1));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void
      test_parseTypeAnnotation_function_returnType_typeParameters_parameters() {
    createParser('List<T> Function<T>(String s, [T])');
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNotNull);
    expect(functionType.functionKeyword, isNotNull);
    var typeParameters = functionType.typeParameters!;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(1));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(2));
  }

  void test_parseTypeAnnotation_function_returnType_withArguments() {
    createParser('A<B> Function(C)');
    // TODO(scheglov): improve this test to verify also the node properties
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_named() {
    createParser('A<B>');
    var namedType = parser.parseTypeAnnotation(false) as NamedType;
    expectNotNullIfNoErrors(namedType);
    assertNoErrors();
  }

  void test_parseTypeArgumentList_empty() {
    createParser('<>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_TYPE_NAME]);
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_multiple() {
    createParser('<int, int, int>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(3));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_nested() {
    createParser('<A<B>>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    var argument = argumentList.arguments[0] as NamedType;
    expect(argument, isNotNull);
    var innerList = argument.typeArguments!;
    expect(innerList, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_nested_withComment_double() {
    createParser('<A<B /* 0 */ >>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.rightBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));

    var argument = argumentList.arguments[0] as NamedType;
    expect(argument, isNotNull);

    var innerList = argument.typeArguments!;
    expect(innerList, isNotNull);
    expect(innerList.leftBracket, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(innerList.rightBracket, isNotNull);
    expect(innerList.rightBracket.precedingComments, isNotNull);
  }

  void test_parseTypeArgumentList_nested_withComment_tripple() {
    createParser('<A<B<C /* 0 */ >>>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.rightBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));

    var argument = argumentList.arguments[0] as NamedType;
    expect(argument, isNotNull);

    var innerList = argument.typeArguments!;
    expect(innerList, isNotNull);
    expect(innerList.leftBracket, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(innerList.rightBracket, isNotNull);

    var innerArgument = innerList.arguments[0] as NamedType;
    expect(innerArgument, isNotNull);

    var innerInnerList = innerArgument.typeArguments!;
    expect(innerInnerList, isNotNull);
    expect(innerInnerList.leftBracket, isNotNull);
    expect(innerInnerList.arguments, hasLength(1));
    expect(innerInnerList.rightBracket, isNotNull);
    expect(innerInnerList.rightBracket.precedingComments, isNotNull);
  }

  void test_parseTypeArgumentList_single() {
    createParser('<int>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeName_parameterized() {
    createParser('List<int>');
    NamedType namedType = parser.parseTypeName(false);
    expectNotNullIfNoErrors(namedType);
    assertNoErrors();
    expect(namedType.name2, isNotNull);
    expect(namedType.typeArguments, isNotNull);
  }

  void test_parseTypeName_simple() {
    createParser('int');
    NamedType namedType = parser.parseTypeName(false);
    expectNotNullIfNoErrors(namedType);
    assertNoErrors();
    expect(namedType.name2, isNotNull);
    expect(namedType.typeArguments, isNull);
  }

  void test_parseTypeParameter_bounded_functionType_noReturn() {
    createParser('A extends Function(int)');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    assertNoErrors();
    expect(parameter.bound, isGenericFunctionType);
    expect(parameter.extendsKeyword, isNotNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameter_bounded_functionType_return() {
    createParser('A extends String Function(int)');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    assertNoErrors();
    expect(parameter.bound, isGenericFunctionType);
    expect(parameter.extendsKeyword, isNotNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameter_bounded_generic() {
    createParser('A extends B<C>');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    assertNoErrors();
    expect(parameter.bound, isNamedType);
    expect(parameter.extendsKeyword, isNotNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameter_bounded_simple() {
    createParser('A extends B');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    assertNoErrors();
    expect(parameter.bound, isNamedType);
    expect(parameter.extendsKeyword, isNotNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameter_simple() {
    createParser('A');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    assertNoErrors();
    expect(parameter.bound, isNull);
    expect(parameter.extendsKeyword, isNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameterList_multiple() {
    createParser('<A, B extends C, D>');
    TypeParameterList parameterList = parser.parseTypeParameterList()!;
    expectNotNullIfNoErrors(parameterList);
    assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(3));
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    createParser('<A extends B<E>>=', expectedEndOffset: 16);
    TypeParameterList parameterList = parser.parseTypeParameterList()!;
    expectNotNullIfNoErrors(parameterList);
    assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals2() {
    createParser('<A extends B<E /* foo */ >>=', expectedEndOffset: 27);
    TypeParameterList parameterList = parser.parseTypeParameterList()!;
    expectNotNullIfNoErrors(parameterList);
    assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
    TypeParameter typeParameter = parameterList.typeParameters[0];
    expect(typeParameter.name.lexeme, 'A');
    var bound = typeParameter.bound as NamedType;
    expect(bound.name2.lexeme, 'B');
    var typeArguments = bound.typeArguments!;
    expect(typeArguments.arguments, hasLength(1));
    expect(typeArguments.rightBracket, isNotNull);
    expect(typeArguments.rightBracket.precedingComments!.lexeme, '/* foo */');
    var argument = typeArguments.arguments[0] as NamedType;
    expect(argument.name2.lexeme, 'E');
  }

  void test_parseTypeParameterList_single() {
    createParser('<<A>', expectedEndOffset: 0);
    var parameterList = parser.parseTypeParameterList();
    // TODO(danrubel): Consider splitting `<<` and marking the first `<`
    // as an unexpected token.
    expect(parameterList, isNull);
    assertNoErrors();
  }

  void test_parseTypeParameterList_withTrailingEquals() {
    createParser('<A>=', expectedEndOffset: 3);
    TypeParameterList parameterList = parser.parseTypeParameterList()!;
    expectNotNullIfNoErrors(parameterList);
    assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseVariableDeclaration_equals() {
    VariableDeclaration declaration = parseVariableDeclaration('var a = b;');
    expectNotNullIfNoErrors(declaration);
    assertNoErrors();
    expect(declaration.name, isNotNull);
    expect(declaration.equals, isNotNull);
    expect(declaration.initializer, isNotNull);
  }

  void test_parseVariableDeclaration_final_late() {
    var statement =
        parseStatement('final late a;') as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertErrors(
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 4)]);
    expect(declarationList.keyword!.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late() {
    var statement = parseStatement('late a;') as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_final() {
    var statement =
        parseStatement('late final a;') as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.keyword!.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_init() {
    var statement =
        parseStatement('late a = 0;') as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_type() {
    var statement = parseStatement('late A a;') as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_var() {
    var statement =
        parseStatement('late var a;') as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword?.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_var_init() {
    var statement =
        parseStatement('late var a = 0;') as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword?.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_noEquals() {
    VariableDeclaration declaration = parseVariableDeclaration('var a;');
    expectNotNullIfNoErrors(declaration);
    assertNoErrors();
    expect(declaration.name, isNotNull);
    expect(declaration.equals, isNull);
    expect(declaration.initializer, isNull);
  }

  void test_parseWithClause_multiple() {
    WithClause clause = parseWithClause('with A, B, C');
    expectNotNullIfNoErrors(clause);
    assertNoErrors();
    expect(clause.withKeyword, isNotNull);
    expect(clause.mixinTypes, hasLength(3));
  }

  void test_parseWithClause_single() {
    WithClause clause = parseWithClause('with M');
    expectNotNullIfNoErrors(clause);
    assertNoErrors();
    expect(clause.withKeyword, isNotNull);
    expect(clause.mixinTypes, hasLength(1));
  }

  void test_typeAlias_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'typedef K=Function(<>($', errors: [
      expectedError(CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE, 19, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 20, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 22, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 23, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 23, 1),
    ]);
    var typeAlias = unit.declarations[0] as GenericTypeAlias;
    expect(typeAlias.name.lexeme, 'K');
    var functionType = typeAlias.functionType!;
    expect(functionType.parameters.parameters, hasLength(1));
    var parameter = functionType.parameters.parameters[0];
    expect(parameter.name, isNotNull);
  }

  void test_typeAlias_parameter_missingIdentifier_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'typedef T=Function(<S>());', errors: [
      expectedError(CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE, 19, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
    ]);
    var typeAlias = unit.declarations[0] as GenericTypeAlias;
    expect(typeAlias.name.lexeme, 'T');
    var functionType = typeAlias.functionType!;
    expect(functionType.parameters.parameters, hasLength(1));
    var parameter = functionType.parameters.parameters[0];
    expect(parameter.name, isNotNull);
  }
}
