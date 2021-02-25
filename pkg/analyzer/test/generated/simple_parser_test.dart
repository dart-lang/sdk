// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
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
    ClassDeclaration classDecl = unit.declarations[0];
    expect(classDecl, isNotNull);
    return classDecl.extendsClause;
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
    ClassDeclaration classDecl = unit.declarations[0];
    expect(classDecl, isNotNull);
    return classDecl.implementsClause;
  }

  LibraryIdentifier parseLibraryIdentifier(String name) {
    createParser('library $name;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.directives, hasLength(1));
    LibraryDirective directive = unit.directives[0];
    return directive.name;
  }

  /// Parse the given [content] as a sequence of statements by enclosing it in a
  /// block. The [expectedCount] is the number of statements that are expected
  /// to be parsed. If [errorCodes] are provided, verify that the error codes of
  /// the errors that are expected are found.
  void parseStatementList(String content, int expectedCount) {
    Statement statement = parseStatement('{$content}');
    expect(statement, isBlock);
    Block block = statement;
    expect(block.statements, hasLength(expectedCount));
  }

  VariableDeclaration parseVariableDeclaration(String declaration) {
    createParser(declaration);
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    TopLevelVariableDeclaration decl = unit.declarations[0];
    expect(decl, isNotNull);
    return decl.variables.variables[0];
  }

  WithClause parseWithClause(String clause) {
    createParser('class TestClass extends Object $clause {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    ClassDeclaration classDecl = unit.declarations[0];
    expect(classDecl, isNotNull);
    return classDecl.withClause;
  }

  void test_classDeclaration_complexTypeParam() {
    CompilationUnit unit = parseCompilationUnit('''
class C<@Foo.bar(const [], const [1], const{"":r""}, 0xFF + 2, .3, 4.5) T> {}
''');
    ClassDeclaration clazz = unit.declarations[0];
    expect(clazz.name.name, 'C');
    expect(clazz.typeParameters.typeParameters, hasLength(1));
    TypeParameter typeParameter = clazz.typeParameters.typeParameters[0];
    expect(typeParameter.name.name, 'T');
    expect(typeParameter.metadata, hasLength(1));
    Annotation metadata = typeParameter.metadata[0];
    expect(metadata.name.name, 'Foo.bar');
  }

  void test_method_name_notNull_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'class C { f(<T>()); }', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 12, 1),
    ]);
    var classDeclaration = unit.declarations[0] as ClassDeclaration;
    var method = classDeclaration.members[0] as MethodDeclaration;
    expect(method.parameters.parameters, hasLength(1));
    var parameter =
        method.parameters.parameters[0] as FunctionTypedFormalParameter;
    expect(parameter.identifier, isNotNull);
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
    IntegerLiteral literal = result;
    expect(literal.value, 3);
  }

  test_parseArgument_named() {
    Expression result = parseArgument('foo: "a"');
    expect(result, const TypeMatcher<NamedExpression>());
    NamedExpression expression = result;
    StringLiteral literal = expression.expression;
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
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, isEmpty);
  }

  void test_parseCommentAndMetadata_cmc() {
    createParser('/** 1 */ @A /** 2 */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
    Comment comment = declaration.documentationComment;
    expect(comment.isDocumentation, isTrue);
    expect(comment.tokens, hasLength(1));
    expect(comment.tokens[0].lexeme, '/** 2 */');
    expect(declaration.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_cmcm() {
    createParser('/** 1 */ @A /** 2 */ @B class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_cmm() {
    createParser('/** 1 */ @A @B class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_m() {
    createParser('@A class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNull);
    expect(declaration.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_mcm() {
    createParser('@A /** 1 */ @B class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_mcmc() {
    createParser('@A /** 1 */ @B /** 2 */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.documentationComment.tokens[0].lexeme, contains('2'));
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
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment.tokens;
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
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment.tokens;
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
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment.tokens;
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
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment.tokens;
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
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.metadata, hasLength(0));
    List<Token> tokens = declaration.documentationComment.tokens;
    expect(tokens, hasLength(1));
    expect(tokens[0].lexeme, contains('aaa'));
  }

  void test_parseCommentAndMetadata_mm() {
    createParser('@A @B(x) class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNull);
    expect(declaration.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_none() {
    createParser('class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
    ClassDeclaration declaration = unit.declarations[0];
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
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.documentationComment, isNotNull);
    expect(declaration.metadata, isEmpty);
  }

  void test_parseCommentReference_new_prefixed() {
    createParser('');
    CommentReference reference = parseCommentReference('new a.b', 7);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isPrefixedIdentifier);
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "a");
    expect(prefix.offset, 11);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "b");
    expect(identifier.offset, 13);
  }

  void test_parseCommentReference_new_simple() {
    createParser('');
    CommentReference reference = parseCommentReference('new a', 5);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isSimpleIdentifier);
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 9);
  }

  void test_parseCommentReference_operator_withKeyword_notPrefixed() {
    createParser('');
    CommentReference reference = parseCommentReference('operator ==', 5);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isSimpleIdentifier);
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 14);
  }

  void test_parseCommentReference_operator_withKeyword_prefixed() {
    createParser('');
    CommentReference reference = parseCommentReference('Object.operator==', 7);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isPrefixedIdentifier);
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "Object");
    expect(prefix.offset, 7);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 22);
  }

  void test_parseCommentReference_operator_withoutKeyword_notPrefixed() {
    createParser('');
    CommentReference reference = parseCommentReference('==', 5);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isSimpleIdentifier);
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReference_operator_withoutKeyword_prefixed() {
    createParser('');
    CommentReference reference = parseCommentReference('Object.==', 7);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isPrefixedIdentifier);
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "Object");
    expect(prefix.offset, 7);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 14);
  }

  void test_parseCommentReference_prefixed() {
    createParser('');
    CommentReference reference = parseCommentReference('a.b', 7);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isPrefixedIdentifier);
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "a");
    expect(prefix.offset, 7);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "b");
    expect(identifier.offset, 9);
  }

  void test_parseCommentReference_simple() {
    createParser('');
    CommentReference reference = parseCommentReference('a', 5);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isSimpleIdentifier);
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReference_synthetic() {
    createParser('');
    CommentReference reference = parseCommentReference('', 5);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    expect(reference.identifier, isSimpleIdentifier);
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier, isNotNull);
    expect(identifier.isSynthetic, isTrue);
    expect(identifier.token, isNotNull);
    expect(identifier.name, "");
    expect(identifier.offset, 5);
    // Should end with EOF token.
    Token nextToken = identifier.token.next;
    expect(nextToken, isNotNull);
    expect(nextToken.type, TokenType.EOF);
  }

  @failingTest
  void test_parseCommentReference_this() {
    // This fails because we are returning null from the method and asserting
    // that the return value is not null.
    createParser('');
    CommentReference reference = parseCommentReference('this', 5);
    expectNotNullIfNoErrors(reference);
    assertNoErrors();
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReferences_33738() {
    CompilationUnit unit =
        parseCompilationUnit('/** [String] */ abstract class Foo {}');
    ClassDeclaration clazz = unit.declarations[0];
    Comment comment = clazz.documentationComment;
    expect(clazz.isAbstract, isTrue);
    List<CommentReference> references = comment.references;
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 5);
  }

  void test_parseCommentReferences_beforeAnnotation() {
    CompilationUnit unit = parseCompilationUnit('''
/// See [int] and [String]
/// and [Object].
@Annotation
abstract class Foo {}
''');
    ClassDeclaration clazz = unit.declarations[0];
    Comment comment = clazz.documentationComment;
    expect(clazz.isAbstract, isTrue);
    List<CommentReference> references = comment.references;
    expect(references, hasLength(3));

    expectReference(int index, String expectedText, int expectedOffset) {
      CommentReference reference = references[index];
      expect(reference.identifier.name, expectedText);
      expect(reference.offset, expectedOffset);
    }

    expectReference(0, 'int', 9);
    expectReference(1, 'String', 19);
    expectReference(2, 'Object', 36);
  }

  void test_parseCommentReferences_complex() {
    CompilationUnit unit = parseCompilationUnit('''
/// This dartdoc comment [should] be ignored
@Annotation
/// This dartdoc comment is [included].
// a non dartdoc comment [inbetween]
/// See [int] and [String] but `not [a]`
/// ```
/// This [code] block should be ignored
/// ```
/// and [Object].
abstract class Foo {}
''');
    ClassDeclaration clazz = unit.declarations[0];
    Comment comment = clazz.documentationComment;
    expect(clazz.isAbstract, isTrue);
    List<CommentReference> references = comment.references;
    expect(references, hasLength(4));

    expectReference(int index, String expectedText, int expectedOffset) {
      CommentReference reference = references[index];
      expect(reference.identifier.name, expectedText);
      expect(reference.offset, expectedOffset);
    }

    expectReference(0, 'included', 86);
    expectReference(1, 'int', 143);
    expectReference(2, 'String', 153);
    expectReference(3, 'Object', 240);
  }

  void test_parseCommentReferences_multiLine() {
    DocumentationCommentToken token = DocumentationCommentToken(
        TokenType.MULTI_LINE_COMMENT, "/** xxx [a] yyy [bb] zzz */", 3);
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[token];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(2));
    {
      CommentReference reference = references[0];
      expect(reference, isNotNull);
      expect(reference.identifier, isNotNull);
      expect(reference.offset, 12);
      Token referenceToken = reference.identifier.beginToken;
      expect(referenceToken.offset, 12);
      expect(referenceToken.lexeme, 'a');
    }
    {
      CommentReference reference = references[1];
      expect(reference, isNotNull);
      expect(reference.identifier, isNotNull);
      expect(reference.offset, 20);
      Token referenceToken = reference.identifier.beginToken;
      expect(referenceToken.offset, 20);
      expect(referenceToken.lexeme, 'bb');
    }
  }

  void test_parseCommentReferences_notClosed_noIdentifier() {
    DocumentationCommentToken docToken = DocumentationCommentToken(
        TokenType.MULTI_LINE_COMMENT, "/** [ some text", 5);
    createParser('');
    List<CommentReference> references =
        parser.parseCommentReferences(<DocumentationCommentToken>[docToken]);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    Token referenceToken = reference.identifier.beginToken;
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.identifier.isSynthetic, isTrue);
    expect(reference.identifier.name, "");
    // Should end with EOF token.
    Token nextToken = referenceToken.next;
    expect(nextToken, isNotNull);
    expect(nextToken.type, TokenType.EOF);
  }

  void test_parseCommentReferences_notClosed_withIdentifier() {
    DocumentationCommentToken docToken = DocumentationCommentToken(
        TokenType.MULTI_LINE_COMMENT, "/** [namePrefix some text", 5);
    createParser('');
    List<CommentReference> references =
        parser.parseCommentReferences(<DocumentationCommentToken>[docToken]);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    Token referenceToken = reference.identifier.beginToken;
    expect(reference, isNotNull);
    expect(referenceToken, same(reference.beginToken));
    expect(reference.identifier, isNotNull);
    expect(reference.identifier.isSynthetic, isFalse);
    expect(reference.identifier.name, "namePrefix");
    // Should end with EOF token.
    Token nextToken = referenceToken.next;
    expect(nextToken, isNotNull);
    expect(nextToken.type, TokenType.EOF);
  }

  void test_parseCommentReferences_singleLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.SINGLE_LINE_COMMENT, "/// xxx [a] yyy [b] zzz", 3),
      DocumentationCommentToken(TokenType.SINGLE_LINE_COMMENT, "/// x [c]", 28)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(3));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 12);
    reference = references[1];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 20);
    reference = references[2];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 35);
  }

  void test_parseCommentReferences_skipCodeBlock_4spaces_block() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/**\n *     a[i]\n * non-code line\n */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_4spaces_lines() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.SINGLE_LINE_COMMENT, "/// Code block:", 0),
      DocumentationCommentToken(
          TokenType.SINGLE_LINE_COMMENT, "///     a[i] == b[i]", 0)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_bracketed() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** [:xxx [a] yyy:] [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 24);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** `a[i]` and [b] */", 0)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 16);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub_multiLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT,
          r'''
/**
 * First.
 * ```dart
 * Some [int] reference.
 * ```
 * Last.
 */
''',
          3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub_multiLine_lines() {
    String commentText = r'''
/// First.
/// ```dart
/// Some [int] reference.
/// ```
/// Last.
''';
    List<DocumentationCommentToken> tokens = commentText
        .split('\n')
        .map((line) =>
            DocumentationCommentToken(TokenType.SINGLE_LINE_COMMENT, line, 0))
        .toList();
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub_notTerminated() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** `a[i] and [b] */", 0)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(2));
  }

  void test_parseCommentReferences_skipCodeBlock_spaces() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/**\n *     a[i]\n * xxx [i] zzz\n */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 27);
  }

  @failingTest
  void test_parseCommentReferences_skipLink_direct_multiLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT,
          '''
/**
 * [a link split across multiple
 * lines](http://www.google.com) [b] zzz
 */
''',
          3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 74);
  }

  void test_parseCommentReferences_skipLink_direct_singleLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/** [a](http://www.google.com) [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 35);
  }

  @failingTest
  void test_parseCommentReferences_skipLink_reference_multiLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT,
          '''
/**
 * [a link split across multiple
 * lines][c] [b] zzz
 */
''',
          3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 54);
  }

  void test_parseCommentReferences_skipLink_reference_singleLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** [a][c] [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 15);
  }

  void test_parseCommentReferences_skipLinkDefinition() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/** [a]: http://www.google.com (Google) [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 44);
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
    Comment comment = unit.declarations[0].documentationComment;
    expectNotNullIfNoErrors(comment);
    assertNoErrors();
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
  }

  void test_parseDocumentationComment_block_withReference() {
    createParser('/** [a] */ class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    Comment comment = unit.declarations[0].documentationComment;
    expectNotNullIfNoErrors(comment);
    assertNoErrors();
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
    NodeList<CommentReference> references = comment.references;
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.offset, 5);
  }

  void test_parseDocumentationComment_endOfLine() {
    createParser('/// \n/// \n class C {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    Comment comment = unit.declarations[0].documentationComment;
    expectNotNullIfNoErrors(comment);
    assertNoErrors();
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
  }

  void test_parseExtendsClause() {
    ExtendsClause clause = parseExtendsClause('extends B');
    expectNotNullIfNoErrors(clause);
    assertNoErrors();
    expect(clause.extendsKeyword, isNotNull);
    expect(clause.superclass, isNotNull);
    expect(clause.superclass, isTypeName);
  }

  void test_parseFunctionBody_block() {
    createParser('{}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNull);
    expect(body.star, isNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_block_async() {
    createParser('async {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Keyword.ASYNC.lexeme);
    expect(body.star, isNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_asyncGenerator() {
    createParser('async* {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Keyword.ASYNC.lexeme);
    expect(body.star, isNotNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isTrue);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_syncGenerator() {
    createParser('sync* {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isBlockFunctionBody);
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Keyword.SYNC.lexeme);
    expect(body.star, isNotNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isTrue);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_empty() {
    createParser(';');
    FunctionBody functionBody = parser.parseFunctionBody(true, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isEmptyFunctionBody);
    EmptyFunctionBody body = functionBody;
    expect(body.semicolon, isNotNull);
  }

  void test_parseFunctionBody_expression() {
    createParser('=> y;');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isExpressionFunctionBody);
    ExpressionFunctionBody body = functionBody;
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
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isExpressionFunctionBody);
    ExpressionFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Keyword.ASYNC.lexeme);
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
    enableOptionalNewAndConst = true;
    CompilationUnit unit = parseCompilationUnit('''
var c = new Future<int>.sync(() => 3).then<int>((e) => e);
''');
    expect(unit, isNotNull);
    TopLevelVariableDeclaration v = unit.declarations[0];
    MethodInvocation init = v.variables.variables[0].initializer;
    expect(init.methodName.name, 'then');
    NodeList<TypeAnnotation> typeArg = init.typeArguments.arguments;
    expect(typeArg, hasLength(1));
    expect(typeArg[0].beginToken.lexeme, 'int');
  }

  void test_parseInstanceCreation_noKeyword_33647() {
    enableOptionalNewAndConst = true;
    CompilationUnit unit = parseCompilationUnit('''
var c = Future<int>.sync(() => 3).then<int>((e) => e);
''');
    expect(unit, isNotNull);
    TopLevelVariableDeclaration v = unit.declarations[0];
    MethodInvocation init = v.variables.variables[0].initializer;
    expect(init.methodName.name, 'then');
    NodeList<TypeAnnotation> typeArg = init.typeArguments.arguments;
    expect(typeArg, hasLength(1));
    expect(typeArg[0].beginToken.lexeme, 'int');
  }

  void test_parseInstanceCreation_noKeyword_noPrefix() {
    enableOptionalNewAndConst = true;
    createParser('f() => C<E>.n();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    FunctionDeclaration f = unit.declarations[0];
    ExpressionFunctionBody body = f.functionExpression.body;
    expect(body.expression, isInstanceCreationExpression);
    InstanceCreationExpressionImpl creation = body.expression;
    expect(creation.keyword, isNull);
    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.type.toSource(), 'C<E>');
    expect(constructorName.period, isNotNull);
    expect(constructorName.name, isNotNull);
    expect(creation.argumentList, isNotNull);
    expect(creation.typeArguments, isNull);
  }

  void test_parseInstanceCreation_noKeyword_noPrefix_34403() {
    enableOptionalNewAndConst = true;
    createParser('f() => C<E>.n<B>();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    FunctionDeclaration f = unit.declarations[0];
    ExpressionFunctionBody body = f.functionExpression.body;
    expect(body.expression, isInstanceCreationExpression);
    InstanceCreationExpressionImpl creation = body.expression;
    expect(creation.keyword, isNull);
    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.type.toSource(), 'C<E>');
    expect(constructorName.period, isNotNull);
    expect(constructorName.name, isNotNull);
    expect(creation.argumentList, isNotNull);
    expect(creation.typeArguments.arguments, hasLength(1));
  }

  void test_parseInstanceCreation_noKeyword_prefix() {
    enableOptionalNewAndConst = true;
    createParser('f() => p.C<E>.n();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    FunctionDeclaration f = unit.declarations[0];
    ExpressionFunctionBody body = f.functionExpression.body;
    expect(body.expression, isInstanceCreationExpression);
    InstanceCreationExpression creation = body.expression;
    expect(creation.keyword, isNull);
    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.type.toSource(), 'p.C<E>');
    expect(constructorName.period, isNotNull);
    expect(constructorName.name, isNotNull);
    expect(creation.argumentList, isNotNull);
  }

  void test_parseInstanceCreation_noKeyword_varInit() {
    enableOptionalNewAndConst = true;
    createParser('''
class C<T, S> {}
void main() {final c = C<int, int Function(String)>();}
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    FunctionDeclaration f = unit.declarations[1];
    BlockFunctionBody body = f.functionExpression.body;
    VariableDeclarationStatement statement = body.block.statements[0];
    VariableDeclaration variable = statement.variables.variables[0];
    MethodInvocation creation = variable.initializer;
    expect(creation.methodName.name, 'C');
    expect(creation.typeArguments.toSource(), '<int, int Function(String)>');
  }

  void test_parseLibraryIdentifier_builtin() {
    String name = "deferred";
    LibraryIdentifier identifier = parseLibraryIdentifier(name);
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
    LibraryIdentifier identifier = parseLibraryIdentifier(name);
    expectNotNullIfNoErrors(identifier);
    assertNoErrors();
    expect(identifier.name, name);
  }

  void test_parseLibraryIdentifier_pseudo() {
    String name = "await";
    LibraryIdentifier identifier = parseLibraryIdentifier(name);
    expectNotNullIfNoErrors(identifier);
    assertNoErrors();
    expect(identifier.name, name);
    expect(identifier.beginToken.type.isPseudo, isTrue);
  }

  void test_parseLibraryIdentifier_single() {
    String name = "a";
    LibraryIdentifier identifier = parseLibraryIdentifier(name);
    expectNotNullIfNoErrors(identifier);
    assertNoErrors();
    expect(identifier.name, name);
  }

  void test_parseOptionalReturnType() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parseReturnStatement_noValue() {
    ReturnStatement statement = parseStatement('return;');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
    expect(statement.returnKeyword, isNotNull);
    expect(statement.expression, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseReturnStatement_value() {
    ReturnStatement statement = parseStatement('return x;');
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
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
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
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
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
    SimpleFormalParameter parameter = parameters[0];
    expect(parameter.identifier, isNull);
    expect(parameter.type, isTypeName);
    expect((parameter.type as TypeName).name.name, 'int');

    expect(parameters[1], isSimpleFormalParameter);
    parameter = parameters[1];
    expect(parameter.identifier, isNull);
    expect(parameter.type, isTypeName);
    expect((parameter.type as TypeName).name.name, 'int');
  }

  void test_parseTypeAnnotation_function_noReturnType_typeParameters() {
    createParser('Function<S, T>()');
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNull);
    expect(functionType.functionKeyword, isNotNull);
    TypeParameterList typeParameters = functionType.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(2));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void
      test_parseTypeAnnotation_function_noReturnType_typeParameters_parameters() {
    createParser('Function<T>(String, {T t})');
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNull);
    expect(functionType.functionKeyword, isNotNull);
    TypeParameterList typeParameters = functionType.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(1));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(2));
  }

  void test_parseTypeAnnotation_function_returnType_classFunction() {
    createParser('Function');
    TypeName functionType = parser.parseTypeAnnotation(false);
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_function_returnType_function() {
    createParser('A Function(B, C) Function(D)');
    // TODO(scheglov) improve the test to verify also the node properties
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_function_returnType_noParameters() {
    createParser('List<int> Function()');
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
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
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
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
    SimpleFormalParameter parameter = parameters[0];
    expect(parameter.identifier, isNotNull);
    expect(parameter.identifier.name, 's');
    expect(parameter.type, isTypeName);
    expect((parameter.type as TypeName).name.name, 'String');

    expect(parameters[1], isSimpleFormalParameter);
    parameter = parameters[1];
    expect(parameter.identifier, isNotNull);
    expect(parameter.identifier.name, 'i');
    expect(parameter.type, isTypeName);
    expect((parameter.type as TypeName).name.name, 'int');
  }

  void test_parseTypeAnnotation_function_returnType_simple() {
    createParser('A Function(B, C)');
    // TODO(scheglov) improve the test to verify also the node properties
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_function_returnType_typeParameters() {
    createParser('List<T> Function<T>()');
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNotNull);
    expect(functionType.functionKeyword, isNotNull);
    TypeParameterList typeParameters = functionType.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(1));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void
      test_parseTypeAnnotation_function_returnType_typeParameters_parameters() {
    createParser('List<T> Function<T>(String s, [T])');
    GenericFunctionType functionType = parser.parseTypeAnnotation(false);
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
    expect(functionType.returnType, isNotNull);
    expect(functionType.functionKeyword, isNotNull);
    TypeParameterList typeParameters = functionType.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters.typeParameters, hasLength(1));
    FormalParameterList parameterList = functionType.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(2));
  }

  void test_parseTypeAnnotation_function_returnType_withArguments() {
    createParser('A<B> Function(C)');
    // TODO(scheglov) improve this test to verify also the node properties
    var functionType = parser.parseTypeAnnotation(false) as GenericFunctionType;
    expectNotNullIfNoErrors(functionType);
    assertNoErrors();
  }

  void test_parseTypeAnnotation_named() {
    createParser('A<B>');
    TypeName typeName = parser.parseTypeAnnotation(false);
    expectNotNullIfNoErrors(typeName);
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
    TypeName argument = argumentList.arguments[0];
    expect(argument, isNotNull);
    TypeArgumentList innerList = argument.typeArguments;
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

    TypeName argument = argumentList.arguments[0];
    expect(argument, isNotNull);

    TypeArgumentList innerList = argument.typeArguments;
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

    TypeName argument = argumentList.arguments[0];
    expect(argument, isNotNull);

    TypeArgumentList innerList = argument.typeArguments;
    expect(innerList, isNotNull);
    expect(innerList.leftBracket, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(innerList.rightBracket, isNotNull);

    TypeName innerArgument = innerList.arguments[0];
    expect(innerArgument, isNotNull);

    TypeArgumentList innerInnerList = innerArgument.typeArguments;
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
    TypeName typeName = parser.parseTypeName(false);
    expectNotNullIfNoErrors(typeName);
    assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNotNull);
  }

  void test_parseTypeName_simple() {
    createParser('int');
    TypeName typeName = parser.parseTypeName(false);
    expectNotNullIfNoErrors(typeName);
    assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNull);
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
    expect(parameter.bound, isTypeName);
    expect(parameter.extendsKeyword, isNotNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameter_bounded_simple() {
    createParser('A extends B');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    assertNoErrors();
    expect(parameter.bound, isTypeName);
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
    TypeParameterList parameterList = parser.parseTypeParameterList();
    expectNotNullIfNoErrors(parameterList);
    assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(3));
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    createParser('<A extends B<E>>=', expectedEndOffset: 16);
    TypeParameterList parameterList = parser.parseTypeParameterList();
    expectNotNullIfNoErrors(parameterList);
    assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals2() {
    createParser('<A extends B<E /* foo */ >>=', expectedEndOffset: 27);
    TypeParameterList parameterList = parser.parseTypeParameterList();
    expectNotNullIfNoErrors(parameterList);
    assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
    TypeParameter typeParameter = parameterList.typeParameters[0];
    expect(typeParameter.name.name, 'A');
    TypeName bound = typeParameter.bound;
    expect(bound.name.name, 'B');
    TypeArgumentList typeArguments = bound.typeArguments;
    expect(typeArguments.arguments, hasLength(1));
    expect(typeArguments.rightBracket, isNotNull);
    expect(typeArguments.rightBracket.precedingComments.lexeme, '/* foo */');
    TypeName argument = typeArguments.arguments[0];
    expect(argument.name.name, 'E');
  }

  void test_parseTypeParameterList_single() {
    createParser('<<A>', expectedEndOffset: 0);
    TypeParameterList parameterList = parser.parseTypeParameterList();
    // TODO(danrubel): Consider splitting `<<` and marking the first `<`
    // as an unexpected token.
    expect(parameterList, isNull);
    assertNoErrors();
  }

  void test_parseTypeParameterList_withTrailingEquals() {
    createParser('<A>=', expectedEndOffset: 3);
    TypeParameterList parameterList = parser.parseTypeParameterList();
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
    var statement = parseStatement('final late a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertErrors(
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 4)]);
    expect(declarationList.keyword.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late() {
    var statement = parseStatement('late a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_final() {
    var statement = parseStatement('late final a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.keyword.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_init() {
    var statement = parseStatement('late a = 0;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_type() {
    var statement = parseStatement('late A a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_var() {
    var statement = parseStatement('late var a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword?.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_var_init() {
    var statement = parseStatement('late var a = 0;', featureSet: nonNullable)
        as VariableDeclarationStatement;
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
    expect(typeAlias.name.toSource(), 'K');
    var functionType = typeAlias.functionType;
    expect(functionType.parameters.parameters, hasLength(1));
    var parameter = functionType.parameters.parameters[0];
    expect(parameter.identifier, isNotNull);
  }

  void test_typeAlias_parameter_missingIdentifier_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'typedef T=Function(<S>());', errors: [
      expectedError(CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE, 19, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
    ]);
    var typeAlias = unit.declarations[0] as GenericTypeAlias;
    expect(typeAlias.name.toSource(), 'T');
    var functionType = typeAlias.functionType;
    expect(functionType.parameters.parameters, hasLength(1));
    var parameter = functionType.parameters.parameters[0];
    expect(parameter.identifier, isNotNull);
  }
}
