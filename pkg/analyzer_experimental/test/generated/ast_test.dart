// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.ast_test;

import 'dart:collection';
import 'package:analyzer_experimental/src/generated/java_core.dart';
import 'package:analyzer_experimental/src/generated/java_engine.dart';
import 'package:analyzer_experimental/src/generated/java_junit.dart';
import 'package:analyzer_experimental/src/generated/source.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/utilities_dart.dart';
import 'package:analyzer_experimental/src/generated/element.dart' show ClassElement;
import 'package:unittest/unittest.dart' as _ut;
import 'parser_test.dart' show ParserTestCase;
import 'test_support.dart';
import 'scanner_test.dart' show TokenFactory;

class NodeLocatorTest extends ParserTestCase {
  void test_offset() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("library myLib;", []);
    assertLocate(unit, 10, SimpleIdentifier);
  }
  void test_range() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("library myLib;", []);
    assertLocate2(unit, 4, 10, LibraryDirective);
  }
  void assertLocate(CompilationUnit unit, int offset, Type expectedClass) {
    assertLocate2(unit, offset, offset, expectedClass);
  }
  void assertLocate2(CompilationUnit unit, int start, int end, Type expectedClass) {
    NodeLocator locator = new NodeLocator.con2(start, end);
    ASTNode node = locator.searchWithin(unit);
    JUnitTestCase.assertNotNull(node);
    JUnitTestCase.assertTrueMsg("Node starts after range", node.offset <= start);
    JUnitTestCase.assertTrueMsg("Node ends before range", node.offset + node.length > end);
    EngineTestCase.assertInstanceOf(expectedClass, node);
  }
  static dartSuite() {
    _ut.group('NodeLocatorTest', () {
      _ut.test('test_offset', () {
        final __test = new NodeLocatorTest();
        runJUnitTest(__test, __test.test_offset);
      });
      _ut.test('test_range', () {
        final __test = new NodeLocatorTest();
        runJUnitTest(__test, __test.test_range);
      });
    });
  }
}
class IndexExpressionTest extends EngineTestCase {
  void test_inGetterContext_assignment_compound_left() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.assignmentExpression(expression, TokenType.PLUS_EQ, null);
    JUnitTestCase.assertTrue(expression.inGetterContext());
  }
  void test_inGetterContext_assignment_simple_left() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.assignmentExpression(expression, TokenType.EQ, null);
    JUnitTestCase.assertFalse(expression.inGetterContext());
  }
  void test_inGetterContext_nonAssignment() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.binaryExpression(expression, TokenType.PLUS, null);
    JUnitTestCase.assertTrue(expression.inGetterContext());
  }
  void test_inSetterContext_assignment_compound_left() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.assignmentExpression(expression, TokenType.PLUS_EQ, null);
    JUnitTestCase.assertTrue(expression.inSetterContext());
  }
  void test_inSetterContext_assignment_compound_right() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.assignmentExpression(null, TokenType.PLUS_EQ, expression);
    JUnitTestCase.assertFalse(expression.inSetterContext());
  }
  void test_inSetterContext_assignment_simple_left() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.assignmentExpression(expression, TokenType.EQ, null);
    JUnitTestCase.assertTrue(expression.inSetterContext());
  }
  void test_inSetterContext_assignment_simple_right() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.assignmentExpression(null, TokenType.EQ, expression);
    JUnitTestCase.assertFalse(expression.inSetterContext());
  }
  void test_inSetterContext_nonAssignment() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.binaryExpression(expression, TokenType.PLUS, null);
    JUnitTestCase.assertFalse(expression.inSetterContext());
  }
  void test_inSetterContext_postfix() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.postfixExpression(expression, TokenType.PLUS_PLUS);
    JUnitTestCase.assertTrue(expression.inSetterContext());
  }
  void test_inSetterContext_prefix_bang() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.prefixExpression(TokenType.BANG, expression);
    JUnitTestCase.assertFalse(expression.inSetterContext());
  }
  void test_inSetterContext_prefix_minusMinus() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.prefixExpression(TokenType.MINUS_MINUS, expression);
    JUnitTestCase.assertTrue(expression.inSetterContext());
  }
  void test_inSetterContext_prefix_plusPlus() {
    IndexExpression expression = ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"));
    ASTFactory.prefixExpression(TokenType.PLUS_PLUS, expression);
    JUnitTestCase.assertTrue(expression.inSetterContext());
  }
  static dartSuite() {
    _ut.group('IndexExpressionTest', () {
      _ut.test('test_inGetterContext_assignment_compound_left', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inGetterContext_assignment_compound_left);
      });
      _ut.test('test_inGetterContext_assignment_simple_left', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inGetterContext_assignment_simple_left);
      });
      _ut.test('test_inGetterContext_nonAssignment', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inGetterContext_nonAssignment);
      });
      _ut.test('test_inSetterContext_assignment_compound_left', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_assignment_compound_left);
      });
      _ut.test('test_inSetterContext_assignment_compound_right', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_assignment_compound_right);
      });
      _ut.test('test_inSetterContext_assignment_simple_left', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_assignment_simple_left);
      });
      _ut.test('test_inSetterContext_assignment_simple_right', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_assignment_simple_right);
      });
      _ut.test('test_inSetterContext_nonAssignment', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_nonAssignment);
      });
      _ut.test('test_inSetterContext_postfix', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_postfix);
      });
      _ut.test('test_inSetterContext_prefix_bang', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_prefix_bang);
      });
      _ut.test('test_inSetterContext_prefix_minusMinus', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_prefix_minusMinus);
      });
      _ut.test('test_inSetterContext_prefix_plusPlus', () {
        final __test = new IndexExpressionTest();
        runJUnitTest(__test, __test.test_inSetterContext_prefix_plusPlus);
      });
    });
  }
}
/**
 * The class {@code ASTFactory} defines utility methods that can be used to create AST nodes. The
 * nodes that are created are complete in the sense that all of the tokens that would have been
 * associated with the nodes by a parser are also created, but the token stream is not constructed.
 * None of the nodes are resolved.
 * <p>
 * The general pattern is for the name of the factory method to be the same as the name of the class
 * of AST node being created. There are two notable exceptions. The first is for methods creating
 * nodes that are part of a cascade expression. These methods are all prefixed with 'cascaded'. The
 * second is places where a shorter name seemed unambiguous and easier to read, such as using
 * 'identifier' rather than 'prefixedIdentifier', or 'integer' rather than 'integerLiteral'.
 */
class ASTFactory {
  static AdjacentStrings adjacentStrings(List<StringLiteral> strings) => new AdjacentStrings.full(list(strings));
  static Annotation annotation(Identifier name) => new Annotation.full(TokenFactory.token3(TokenType.AT), name, null, null, null);
  static Annotation annotation2(Identifier name, SimpleIdentifier constructorName, ArgumentList arguments) => new Annotation.full(TokenFactory.token3(TokenType.AT), name, TokenFactory.token3(TokenType.PERIOD), constructorName, arguments);
  static ArgumentDefinitionTest argumentDefinitionTest(String identifier) => new ArgumentDefinitionTest.full(TokenFactory.token3(TokenType.QUESTION), identifier3(identifier));
  static ArgumentList argumentList(List<Expression> arguments) => new ArgumentList.full(TokenFactory.token3(TokenType.OPEN_PAREN), list(arguments), TokenFactory.token3(TokenType.CLOSE_PAREN));
  static AsExpression asExpression(Expression expression, TypeName type) => new AsExpression.full(expression, TokenFactory.token(Keyword.AS), type);
  static AssertStatement assertStatement(Expression condition) => new AssertStatement.full(TokenFactory.token(Keyword.ASSERT), TokenFactory.token3(TokenType.OPEN_PAREN), condition, TokenFactory.token3(TokenType.CLOSE_PAREN), TokenFactory.token3(TokenType.SEMICOLON));
  static AssignmentExpression assignmentExpression(Expression leftHandSide, TokenType operator, Expression rightHandSide) => new AssignmentExpression.full(leftHandSide, TokenFactory.token3(operator), rightHandSide);
  static BinaryExpression binaryExpression(Expression leftOperand, TokenType operator, Expression rightOperand) => new BinaryExpression.full(leftOperand, TokenFactory.token3(operator), rightOperand);
  static Block block(List<Statement> statements) => new Block.full(TokenFactory.token3(TokenType.OPEN_CURLY_BRACKET), list(statements), TokenFactory.token3(TokenType.CLOSE_CURLY_BRACKET));
  static BlockFunctionBody blockFunctionBody(List<Statement> statements) => new BlockFunctionBody.full(block(statements));
  static BooleanLiteral booleanLiteral(bool value) => new BooleanLiteral.full(value ? TokenFactory.token(Keyword.TRUE) : TokenFactory.token(Keyword.FALSE), value);
  static BreakStatement breakStatement() => new BreakStatement.full(TokenFactory.token(Keyword.BREAK), null, TokenFactory.token3(TokenType.SEMICOLON));
  static BreakStatement breakStatement2(String label) => new BreakStatement.full(TokenFactory.token(Keyword.BREAK), identifier3(label), TokenFactory.token3(TokenType.SEMICOLON));
  static IndexExpression cascadedIndexExpression(Expression index) => new IndexExpression.forCascade_full(TokenFactory.token3(TokenType.PERIOD_PERIOD), TokenFactory.token3(TokenType.OPEN_SQUARE_BRACKET), index, TokenFactory.token3(TokenType.CLOSE_SQUARE_BRACKET));
  static MethodInvocation cascadedMethodInvocation(String methodName, List<Expression> arguments) => new MethodInvocation.full(null, TokenFactory.token3(TokenType.PERIOD_PERIOD), identifier3(methodName), argumentList(arguments));
  static PropertyAccess cascadedPropertyAccess(String propertyName) => new PropertyAccess.full(null, TokenFactory.token3(TokenType.PERIOD_PERIOD), identifier3(propertyName));
  static CascadeExpression cascadeExpression(Expression target, List<Expression> cascadeSections) => new CascadeExpression.full(target, list(cascadeSections));
  static CatchClause catchClause(String exceptionParameter, List<Statement> statements) => catchClause5(null, exceptionParameter, null, statements);
  static CatchClause catchClause2(String exceptionParameter, String stackTraceParameter, List<Statement> statements) => catchClause5(null, exceptionParameter, stackTraceParameter, statements);
  static CatchClause catchClause3(TypeName exceptionType, List<Statement> statements) => catchClause5(exceptionType, null, null, statements);
  static CatchClause catchClause4(TypeName exceptionType, String exceptionParameter, List<Statement> statements) => catchClause5(exceptionType, exceptionParameter, null, statements);
  static CatchClause catchClause5(TypeName exceptionType, String exceptionParameter, String stackTraceParameter, List<Statement> statements) => new CatchClause.full(exceptionType == null ? null : TokenFactory.token4(TokenType.IDENTIFIER, "on"), exceptionType, exceptionParameter == null ? null : TokenFactory.token(Keyword.CATCH), exceptionParameter == null ? null : TokenFactory.token3(TokenType.OPEN_PAREN), identifier3(exceptionParameter), stackTraceParameter == null ? null : TokenFactory.token3(TokenType.COMMA), stackTraceParameter == null ? null : identifier3(stackTraceParameter), exceptionParameter == null ? null : TokenFactory.token3(TokenType.CLOSE_PAREN), block(statements));
  static ClassDeclaration classDeclaration(Keyword abstractKeyword, String name, TypeParameterList typeParameters, ExtendsClause extendsClause, WithClause withClause, ImplementsClause implementsClause, List<ClassMember> members) => new ClassDeclaration.full(null, null, abstractKeyword == null ? null : TokenFactory.token(abstractKeyword), TokenFactory.token(Keyword.CLASS), identifier3(name), typeParameters, extendsClause, withClause, implementsClause, TokenFactory.token3(TokenType.OPEN_CURLY_BRACKET), list(members), TokenFactory.token3(TokenType.CLOSE_CURLY_BRACKET));
  static ClassTypeAlias classTypeAlias(String name, TypeParameterList typeParameters, Keyword abstractKeyword, TypeName superclass, WithClause withClause, ImplementsClause implementsClause) => new ClassTypeAlias.full(null, null, TokenFactory.token(Keyword.TYPEDEF), identifier3(name), typeParameters, TokenFactory.token3(TokenType.EQ), abstractKeyword == null ? null : TokenFactory.token(abstractKeyword), superclass, withClause, implementsClause, TokenFactory.token3(TokenType.SEMICOLON));
  static CompilationUnit compilationUnit() => compilationUnit8(null, null, null);
  static CompilationUnit compilationUnit2(List<CompilationUnitMember> declarations) => compilationUnit8(null, null, list(declarations));
  static CompilationUnit compilationUnit3(List<Directive> directives) => compilationUnit8(null, list(directives), null);
  static CompilationUnit compilationUnit4(List<Directive> directives, List<CompilationUnitMember> declarations) => compilationUnit8(null, directives, declarations);
  static CompilationUnit compilationUnit5(String scriptTag) => compilationUnit8(scriptTag, null, null);
  static CompilationUnit compilationUnit6(String scriptTag, List<CompilationUnitMember> declarations) => compilationUnit8(scriptTag, null, list(declarations));
  static CompilationUnit compilationUnit7(String scriptTag, List<Directive> directives) => compilationUnit8(scriptTag, list(directives), null);
  static CompilationUnit compilationUnit8(String scriptTag4, List<Directive> directives, List<CompilationUnitMember> declarations) => new CompilationUnit.full(TokenFactory.token3(TokenType.EOF), scriptTag4 == null ? null : scriptTag(scriptTag4), directives == null ? new List<Directive>() : directives, declarations == null ? new List<CompilationUnitMember>() : declarations, TokenFactory.token3(TokenType.EOF));
  static ConditionalExpression conditionalExpression(Expression condition, Expression thenExpression, Expression elseExpression) => new ConditionalExpression.full(condition, TokenFactory.token3(TokenType.QUESTION), thenExpression, TokenFactory.token3(TokenType.COLON), elseExpression);
  static ConstructorDeclaration constructorDeclaration(Identifier returnType, String name, FormalParameterList parameters, List<ConstructorInitializer> initializers) => new ConstructorDeclaration.full(null, null, TokenFactory.token(Keyword.EXTERNAL), null, null, returnType, name == null ? null : TokenFactory.token3(TokenType.PERIOD), name == null ? null : identifier3(name), parameters, initializers == null || initializers.isEmpty ? null : TokenFactory.token3(TokenType.PERIOD), initializers == null ? new List<ConstructorInitializer>() : initializers, null, emptyFunctionBody());
  static ConstructorDeclaration constructorDeclaration2(Keyword constKeyword, Keyword factoryKeyword, Identifier returnType, String name, FormalParameterList parameters, List<ConstructorInitializer> initializers, FunctionBody body) => new ConstructorDeclaration.full(null, null, null, constKeyword == null ? null : TokenFactory.token(constKeyword), factoryKeyword == null ? null : TokenFactory.token(factoryKeyword), returnType, name == null ? null : TokenFactory.token3(TokenType.PERIOD), name == null ? null : identifier3(name), parameters, initializers == null || initializers.isEmpty ? null : TokenFactory.token3(TokenType.PERIOD), initializers == null ? new List<ConstructorInitializer>() : initializers, null, body);
  static ConstructorFieldInitializer constructorFieldInitializer(bool prefixedWithThis, String fieldName, Expression expression) => new ConstructorFieldInitializer.full(prefixedWithThis ? TokenFactory.token(Keyword.THIS) : null, prefixedWithThis ? TokenFactory.token3(TokenType.PERIOD) : null, identifier3(fieldName), TokenFactory.token3(TokenType.EQ), expression);
  static ConstructorName constructorName(TypeName type, String name) => new ConstructorName.full(type, name == null ? null : TokenFactory.token3(TokenType.PERIOD), name == null ? null : identifier3(name));
  static ContinueStatement continueStatement() => new ContinueStatement.full(TokenFactory.token(Keyword.CONTINUE), null, TokenFactory.token3(TokenType.SEMICOLON));
  static ContinueStatement continueStatement2(String label) => new ContinueStatement.full(TokenFactory.token(Keyword.CONTINUE), identifier3(label), TokenFactory.token3(TokenType.SEMICOLON));
  static DeclaredIdentifier declaredIdentifier(Keyword keyword, String identifier) => declaredIdentifier2(keyword, null, identifier);
  static DeclaredIdentifier declaredIdentifier2(Keyword keyword, TypeName type, String identifier) => new DeclaredIdentifier.full(null, null, keyword == null ? null : TokenFactory.token(keyword), type, identifier3(identifier));
  static DeclaredIdentifier declaredIdentifier3(String identifier) => declaredIdentifier2(null, null, identifier);
  static DeclaredIdentifier declaredIdentifier4(TypeName type, String identifier) => declaredIdentifier2(null, type, identifier);
  static DoStatement doStatement(Statement body, Expression condition) => new DoStatement.full(TokenFactory.token(Keyword.DO), body, TokenFactory.token(Keyword.WHILE), TokenFactory.token3(TokenType.OPEN_PAREN), condition, TokenFactory.token3(TokenType.CLOSE_PAREN), TokenFactory.token3(TokenType.SEMICOLON));
  static DoubleLiteral doubleLiteral(double value) => new DoubleLiteral.full(TokenFactory.token2(value.toString()), value);
  static EmptyFunctionBody emptyFunctionBody() => new EmptyFunctionBody.full(TokenFactory.token3(TokenType.SEMICOLON));
  static EmptyStatement emptyStatement() => new EmptyStatement.full(TokenFactory.token3(TokenType.SEMICOLON));
  static ExportDirective exportDirective(List<Annotation> metadata, String uri, List<Combinator> combinators) => new ExportDirective.full(null, metadata, TokenFactory.token(Keyword.EXPORT), string2(uri), list(combinators), TokenFactory.token3(TokenType.SEMICOLON));
  static ExportDirective exportDirective2(String uri, List<Combinator> combinators) => exportDirective(new List<Annotation>(), uri, combinators);
  static ExpressionFunctionBody expressionFunctionBody(Expression expression) => new ExpressionFunctionBody.full(TokenFactory.token3(TokenType.FUNCTION), expression, TokenFactory.token3(TokenType.SEMICOLON));
  static ExpressionStatement expressionStatement(Expression expression) => new ExpressionStatement.full(expression, TokenFactory.token3(TokenType.SEMICOLON));
  static ExtendsClause extendsClause(TypeName type) => new ExtendsClause.full(TokenFactory.token(Keyword.EXTENDS), type);
  static FieldDeclaration fieldDeclaration(bool isStatic, Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new FieldDeclaration.full(null, null, isStatic ? TokenFactory.token(Keyword.STATIC) : null, variableDeclarationList(keyword, type, variables), TokenFactory.token3(TokenType.SEMICOLON));
  static FieldDeclaration fieldDeclaration2(bool isStatic, Keyword keyword, List<VariableDeclaration> variables) => fieldDeclaration(isStatic, keyword, null, variables);
  static FieldFormalParameter fieldFormalParameter(Keyword keyword, TypeName type, String identifier) => new FieldFormalParameter.full(null, null, keyword == null ? null : TokenFactory.token(keyword), type, TokenFactory.token(Keyword.THIS), TokenFactory.token3(TokenType.PERIOD), identifier3(identifier));
  static FieldFormalParameter fieldFormalParameter2(String identifier) => fieldFormalParameter(null, null, identifier);
  static ForEachStatement forEachStatement(DeclaredIdentifier loopVariable, Expression iterator, Statement body) => new ForEachStatement.full(TokenFactory.token(Keyword.FOR), TokenFactory.token3(TokenType.OPEN_PAREN), loopVariable, TokenFactory.token(Keyword.IN), iterator, TokenFactory.token3(TokenType.CLOSE_PAREN), body);
  static FormalParameterList formalParameterList(List<FormalParameter> parameters) => new FormalParameterList.full(TokenFactory.token3(TokenType.OPEN_PAREN), list(parameters), null, null, TokenFactory.token3(TokenType.CLOSE_PAREN));
  static ForStatement forStatement(Expression initialization, Expression condition, List<Expression> updaters, Statement body) => new ForStatement.full(TokenFactory.token(Keyword.FOR), TokenFactory.token3(TokenType.OPEN_PAREN), null, initialization, TokenFactory.token3(TokenType.SEMICOLON), condition, TokenFactory.token3(TokenType.SEMICOLON), updaters, TokenFactory.token3(TokenType.CLOSE_PAREN), body);
  static ForStatement forStatement2(VariableDeclarationList variableList, Expression condition, List<Expression> updaters, Statement body) => new ForStatement.full(TokenFactory.token(Keyword.FOR), TokenFactory.token3(TokenType.OPEN_PAREN), variableList, null, TokenFactory.token3(TokenType.SEMICOLON), condition, TokenFactory.token3(TokenType.SEMICOLON), updaters, TokenFactory.token3(TokenType.CLOSE_PAREN), body);
  static FunctionDeclaration functionDeclaration(TypeName type, Keyword keyword, String name, FunctionExpression functionExpression) => new FunctionDeclaration.full(null, null, null, type, keyword == null ? null : TokenFactory.token(keyword), identifier3(name), functionExpression);
  static FunctionDeclarationStatement functionDeclarationStatement(TypeName type, Keyword keyword, String name, FunctionExpression functionExpression) => new FunctionDeclarationStatement.full(functionDeclaration(type, keyword, name, functionExpression));
  static FunctionExpression functionExpression() => new FunctionExpression.full(formalParameterList([]), blockFunctionBody([]));
  static FunctionExpression functionExpression2(FormalParameterList parameters, FunctionBody body) => new FunctionExpression.full(parameters, body);
  static FunctionExpressionInvocation functionExpressionInvocation(Expression function, List<Expression> arguments) => new FunctionExpressionInvocation.full(function, argumentList(arguments));
  static FunctionTypedFormalParameter functionTypedFormalParameter(TypeName returnType, String identifier, List<FormalParameter> parameters) => new FunctionTypedFormalParameter.full(null, null, returnType, identifier3(identifier), formalParameterList(parameters));
  static HideCombinator hideCombinator(List<SimpleIdentifier> identifiers) => new HideCombinator.full(TokenFactory.token2("hide"), list(identifiers));
  static HideCombinator hideCombinator2(List<String> identifiers) {
    List<SimpleIdentifier> identifierList = new List<SimpleIdentifier>();
    for (String identifier in identifiers) {
      identifierList.add(identifier3(identifier));
    }
    return new HideCombinator.full(TokenFactory.token2("hide"), identifierList);
  }
  static PrefixedIdentifier identifier(SimpleIdentifier prefix, SimpleIdentifier identifier11) => new PrefixedIdentifier.full(prefix, TokenFactory.token3(TokenType.PERIOD), identifier11);
  static SimpleIdentifier identifier3(String lexeme) => new SimpleIdentifier.full(TokenFactory.token4(TokenType.IDENTIFIER, lexeme));
  static PrefixedIdentifier identifier4(String prefix, SimpleIdentifier identifier) => new PrefixedIdentifier.full(identifier3(prefix), TokenFactory.token3(TokenType.PERIOD), identifier);
  static PrefixedIdentifier identifier5(String prefix, String identifier) => new PrefixedIdentifier.full(identifier3(prefix), TokenFactory.token3(TokenType.PERIOD), identifier3(identifier));
  static IfStatement ifStatement(Expression condition, Statement thenStatement) => ifStatement2(condition, thenStatement, null);
  static IfStatement ifStatement2(Expression condition, Statement thenStatement, Statement elseStatement) => new IfStatement.full(TokenFactory.token(Keyword.IF), TokenFactory.token3(TokenType.OPEN_PAREN), condition, TokenFactory.token3(TokenType.CLOSE_PAREN), thenStatement, elseStatement == null ? null : TokenFactory.token(Keyword.ELSE), elseStatement);
  static ImplementsClause implementsClause(List<TypeName> types) => new ImplementsClause.full(TokenFactory.token(Keyword.IMPLEMENTS), list(types));
  static ImportDirective importDirective(List<Annotation> metadata, String uri, String prefix, List<Combinator> combinators) => new ImportDirective.full(null, metadata, TokenFactory.token(Keyword.IMPORT), string2(uri), prefix == null ? null : TokenFactory.token(Keyword.AS), prefix == null ? null : identifier3(prefix), list(combinators), TokenFactory.token3(TokenType.SEMICOLON));
  static ImportDirective importDirective2(String uri, String prefix, List<Combinator> combinators) => importDirective(new List<Annotation>(), uri, prefix, combinators);
  static IndexExpression indexExpression(Expression array, Expression index) => new IndexExpression.forTarget_full(array, TokenFactory.token3(TokenType.OPEN_SQUARE_BRACKET), index, TokenFactory.token3(TokenType.CLOSE_SQUARE_BRACKET));
  static InstanceCreationExpression instanceCreationExpression(Keyword keyword, ConstructorName name, List<Expression> arguments) => new InstanceCreationExpression.full(keyword == null ? null : TokenFactory.token(keyword), name, argumentList(arguments));
  static InstanceCreationExpression instanceCreationExpression2(Keyword keyword, TypeName type, List<Expression> arguments) => instanceCreationExpression3(keyword, type, null, arguments);
  static InstanceCreationExpression instanceCreationExpression3(Keyword keyword, TypeName type, String identifier, List<Expression> arguments) => instanceCreationExpression(keyword, new ConstructorName.full(type, identifier == null ? null : TokenFactory.token3(TokenType.PERIOD), identifier == null ? null : identifier3(identifier)), arguments);
  static IntegerLiteral integer(int value) => new IntegerLiteral.full(TokenFactory.token4(TokenType.INT, value.toString()), value);
  static InterpolationExpression interpolationExpression(Expression expression) => new InterpolationExpression.full(TokenFactory.token3(TokenType.STRING_INTERPOLATION_EXPRESSION), expression, TokenFactory.token3(TokenType.CLOSE_CURLY_BRACKET));
  static InterpolationExpression interpolationExpression2(String identifier) => new InterpolationExpression.full(TokenFactory.token3(TokenType.STRING_INTERPOLATION_IDENTIFIER), identifier3(identifier), null);
  static InterpolationString interpolationString(String contents, String value) => new InterpolationString.full(TokenFactory.token2(contents), value);
  static IsExpression isExpression(Expression expression, bool negated, TypeName type) => new IsExpression.full(expression, TokenFactory.token(Keyword.IS), negated ? TokenFactory.token3(TokenType.BANG) : null, type);
  static Label label(SimpleIdentifier label5) => new Label.full(label5, TokenFactory.token3(TokenType.COLON));
  static Label label2(String label6) => label(identifier3(label6));
  static LabeledStatement labeledStatement(List<Label> labels, Statement statement) => new LabeledStatement.full(labels, statement);
  static LibraryDirective libraryDirective(List<Annotation> metadata, LibraryIdentifier libraryName) => new LibraryDirective.full(null, metadata, TokenFactory.token(Keyword.LIBRARY), libraryName, TokenFactory.token3(TokenType.SEMICOLON));
  static LibraryDirective libraryDirective2(String libraryName) => libraryDirective(new List<Annotation>(), libraryIdentifier2([libraryName]));
  static LibraryIdentifier libraryIdentifier(List<SimpleIdentifier> components) => new LibraryIdentifier.full(list(components));
  static LibraryIdentifier libraryIdentifier2(List<String> components) {
    List<SimpleIdentifier> componentList = new List<SimpleIdentifier>();
    for (String component in components) {
      componentList.add(identifier3(component));
    }
    return new LibraryIdentifier.full(componentList);
  }
  static List list(List<Object> elements) {
    List elementList = new List();
    for (Object element in elements) {
      elementList.add(element);
    }
    return elementList;
  }
  static ListLiteral listLiteral(List<Expression> elements) => listLiteral2(null, null, elements);
  static ListLiteral listLiteral2(Keyword keyword, TypeArgumentList typeArguments, List<Expression> elements) => new ListLiteral.full(keyword == null ? null : TokenFactory.token(keyword), null, TokenFactory.token3(TokenType.OPEN_SQUARE_BRACKET), list(elements), TokenFactory.token3(TokenType.CLOSE_SQUARE_BRACKET));
  static MapLiteral mapLiteral(Keyword keyword, TypeArgumentList typeArguments, List<MapLiteralEntry> entries) => new MapLiteral.full(keyword == null ? null : TokenFactory.token(keyword), typeArguments, TokenFactory.token3(TokenType.OPEN_CURLY_BRACKET), list(entries), TokenFactory.token3(TokenType.CLOSE_CURLY_BRACKET));
  static MapLiteral mapLiteral2(List<MapLiteralEntry> entries) => mapLiteral(null, null, entries);
  static MapLiteralEntry mapLiteralEntry(String key, Expression value) => new MapLiteralEntry.full(string2(key), TokenFactory.token3(TokenType.COLON), value);
  static MethodDeclaration methodDeclaration(Keyword modifier, TypeName returnType, Keyword property, Keyword operator, SimpleIdentifier name, FormalParameterList parameters) => new MethodDeclaration.full(null, null, TokenFactory.token(Keyword.EXTERNAL), modifier == null ? null : TokenFactory.token(modifier), returnType, property == null ? null : TokenFactory.token(property), operator == null ? null : TokenFactory.token(operator), name, parameters, emptyFunctionBody());
  static MethodDeclaration methodDeclaration2(Keyword modifier, TypeName returnType, Keyword property, Keyword operator, SimpleIdentifier name, FormalParameterList parameters, FunctionBody body) => new MethodDeclaration.full(null, null, null, modifier == null ? null : TokenFactory.token(modifier), returnType, property == null ? null : TokenFactory.token(property), operator == null ? null : TokenFactory.token(operator), name, parameters, body);
  static MethodInvocation methodInvocation(Expression target, String methodName, List<Expression> arguments) => new MethodInvocation.full(target, target == null ? null : TokenFactory.token3(TokenType.PERIOD), identifier3(methodName), argumentList(arguments));
  static MethodInvocation methodInvocation2(String methodName, List<Expression> arguments) => methodInvocation(null, methodName, arguments);
  static NamedExpression namedExpression(Label label, Expression expression) => new NamedExpression.full(label, expression);
  static NamedExpression namedExpression2(String label, Expression expression) => namedExpression(label2(label), expression);
  static DefaultFormalParameter namedFormalParameter(NormalFormalParameter parameter, Expression expression) => new DefaultFormalParameter.full(parameter, ParameterKind.NAMED, expression == null ? null : TokenFactory.token3(TokenType.COLON), expression);
  static NativeFunctionBody nativeFunctionBody(String nativeMethodName) => new NativeFunctionBody.full(TokenFactory.token2("native"), string2(nativeMethodName), TokenFactory.token3(TokenType.SEMICOLON));
  static NullLiteral nullLiteral() => new NullLiteral.full(TokenFactory.token(Keyword.NULL));
  static ParenthesizedExpression parenthesizedExpression(Expression expression) => new ParenthesizedExpression.full(TokenFactory.token3(TokenType.OPEN_PAREN), expression, TokenFactory.token3(TokenType.CLOSE_PAREN));
  static PartDirective partDirective(List<Annotation> metadata, String url) => new PartDirective.full(null, metadata, TokenFactory.token(Keyword.PART), string2(url), TokenFactory.token3(TokenType.SEMICOLON));
  static PartDirective partDirective2(String url) => partDirective(new List<Annotation>(), url);
  static PartOfDirective partOfDirective(LibraryIdentifier libraryName) => partOfDirective2(new List<Annotation>(), libraryName);
  static PartOfDirective partOfDirective2(List<Annotation> metadata, LibraryIdentifier libraryName) => new PartOfDirective.full(null, metadata, TokenFactory.token(Keyword.PART), TokenFactory.token2("of"), libraryName, TokenFactory.token3(TokenType.SEMICOLON));
  static DefaultFormalParameter positionalFormalParameter(NormalFormalParameter parameter, Expression expression) => new DefaultFormalParameter.full(parameter, ParameterKind.POSITIONAL, expression == null ? null : TokenFactory.token3(TokenType.EQ), expression);
  static PostfixExpression postfixExpression(Expression expression, TokenType operator) => new PostfixExpression.full(expression, TokenFactory.token3(operator));
  static PrefixExpression prefixExpression(TokenType operator, Expression expression) => new PrefixExpression.full(TokenFactory.token3(operator), expression);
  static PropertyAccess propertyAccess(Expression target, SimpleIdentifier propertyName) => new PropertyAccess.full(target, TokenFactory.token3(TokenType.PERIOD), propertyName);
  static PropertyAccess propertyAccess2(Expression target, String propertyName) => new PropertyAccess.full(target, TokenFactory.token3(TokenType.PERIOD), identifier3(propertyName));
  static RedirectingConstructorInvocation redirectingConstructorInvocation(List<Expression> arguments) => redirectingConstructorInvocation2(null, arguments);
  static RedirectingConstructorInvocation redirectingConstructorInvocation2(String constructorName, List<Expression> arguments) => new RedirectingConstructorInvocation.full(TokenFactory.token(Keyword.THIS), constructorName == null ? null : TokenFactory.token3(TokenType.PERIOD), constructorName == null ? null : identifier3(constructorName), argumentList(arguments));
  static ReturnStatement returnStatement() => returnStatement2(null);
  static ReturnStatement returnStatement2(Expression expression) => new ReturnStatement.full(TokenFactory.token(Keyword.RETURN), expression, TokenFactory.token3(TokenType.SEMICOLON));
  static ScriptTag scriptTag(String scriptTag5) => new ScriptTag.full(TokenFactory.token2(scriptTag5));
  static ShowCombinator showCombinator(List<SimpleIdentifier> identifiers) => new ShowCombinator.full(TokenFactory.token2("show"), list(identifiers));
  static ShowCombinator showCombinator2(List<String> identifiers) {
    List<SimpleIdentifier> identifierList = new List<SimpleIdentifier>();
    for (String identifier in identifiers) {
      identifierList.add(identifier3(identifier));
    }
    return new ShowCombinator.full(TokenFactory.token2("show"), identifierList);
  }
  static SimpleFormalParameter simpleFormalParameter(Keyword keyword, String parameterName) => simpleFormalParameter2(keyword, null, parameterName);
  static SimpleFormalParameter simpleFormalParameter2(Keyword keyword, TypeName type, String parameterName) => new SimpleFormalParameter.full(null, null, keyword == null ? null : TokenFactory.token(keyword), type, identifier3(parameterName));
  static SimpleFormalParameter simpleFormalParameter3(String parameterName) => simpleFormalParameter2(null, null, parameterName);
  static SimpleFormalParameter simpleFormalParameter4(TypeName type, String parameterName) => simpleFormalParameter2(null, type, parameterName);
  static StringInterpolation string(List<InterpolationElement> elements) => new StringInterpolation.full(list(elements));
  static SimpleStringLiteral string2(String content) => new SimpleStringLiteral.full(TokenFactory.token2("'${content}'"), content);
  static SuperConstructorInvocation superConstructorInvocation(List<Expression> arguments) => superConstructorInvocation2(null, arguments);
  static SuperConstructorInvocation superConstructorInvocation2(String name, List<Expression> arguments) => new SuperConstructorInvocation.full(TokenFactory.token(Keyword.SUPER), name == null ? null : TokenFactory.token3(TokenType.PERIOD), name == null ? null : identifier3(name), argumentList(arguments));
  static SuperExpression superExpression() => new SuperExpression.full(TokenFactory.token(Keyword.SUPER));
  static SwitchCase switchCase(Expression expression, List<Statement> statements) => switchCase2(new List<Label>(), expression, statements);
  static SwitchCase switchCase2(List<Label> labels, Expression expression, List<Statement> statements) => new SwitchCase.full(labels, TokenFactory.token(Keyword.CASE), expression, TokenFactory.token3(TokenType.COLON), list(statements));
  static SwitchDefault switchDefault(List<Label> labels, List<Statement> statements) => new SwitchDefault.full(labels, TokenFactory.token(Keyword.DEFAULT), TokenFactory.token3(TokenType.COLON), list(statements));
  static SwitchDefault switchDefault2(List<Statement> statements) => switchDefault(new List<Label>(), statements);
  static SwitchStatement switchStatement(Expression expression, List<SwitchMember> members) => new SwitchStatement.full(TokenFactory.token(Keyword.SWITCH), TokenFactory.token3(TokenType.OPEN_PAREN), expression, TokenFactory.token3(TokenType.CLOSE_PAREN), TokenFactory.token3(TokenType.OPEN_CURLY_BRACKET), list(members), TokenFactory.token3(TokenType.CLOSE_CURLY_BRACKET));
  static ThisExpression thisExpression() => new ThisExpression.full(TokenFactory.token(Keyword.THIS));
  static ThrowExpression throwExpression() => throwExpression2(null);
  static ThrowExpression throwExpression2(Expression expression) => new ThrowExpression.full(TokenFactory.token(Keyword.THROW), expression);
  static TopLevelVariableDeclaration topLevelVariableDeclaration(Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new TopLevelVariableDeclaration.full(null, null, variableDeclarationList(keyword, type, variables), TokenFactory.token3(TokenType.SEMICOLON));
  static TopLevelVariableDeclaration topLevelVariableDeclaration2(Keyword keyword, List<VariableDeclaration> variables) => new TopLevelVariableDeclaration.full(null, null, variableDeclarationList(keyword, null, variables), TokenFactory.token3(TokenType.SEMICOLON));
  static TryStatement tryStatement(Block body, Block finallyClause) => tryStatement3(body, new List<CatchClause>(), finallyClause);
  static TryStatement tryStatement2(Block body, List<CatchClause> catchClauses) => tryStatement3(body, list(catchClauses), null);
  static TryStatement tryStatement3(Block body, List<CatchClause> catchClauses, Block finallyClause) => new TryStatement.full(TokenFactory.token(Keyword.TRY), body, catchClauses, finallyClause == null ? null : TokenFactory.token(Keyword.FINALLY), finallyClause);
  static FunctionTypeAlias typeAlias(TypeName returnType, String name, TypeParameterList typeParameters, FormalParameterList parameters) => new FunctionTypeAlias.full(null, null, TokenFactory.token(Keyword.TYPEDEF), returnType, identifier3(name), typeParameters, parameters, TokenFactory.token3(TokenType.SEMICOLON));
  static TypeArgumentList typeArgumentList(List<TypeName> typeNames) => new TypeArgumentList.full(TokenFactory.token3(TokenType.LT), list(typeNames), TokenFactory.token3(TokenType.GT));
  /**
   * Create a type name whose name has been resolved to the given element and whose type has been
   * resolved to the type of the given element.
   * <p>
   * <b>Note:</b> This method does not correctly handle class elements that have type parameters.
   * @param element the element defining the type represented by the type name
   * @return the type name that was created
   */
  static TypeName typeName(ClassElement element70, List<TypeName> arguments) {
    SimpleIdentifier name25 = identifier3(element70.name);
    name25.element = element70;
    TypeName typeName = typeName3(name25, arguments);
    typeName.type = element70.type;
    return typeName;
  }
  static TypeName typeName3(Identifier name, List<TypeName> arguments) {
    if (arguments.length == 0) {
      return new TypeName.full(name, null);
    }
    return new TypeName.full(name, typeArgumentList(arguments));
  }
  static TypeName typeName4(String name, List<TypeName> arguments) {
    if (arguments.length == 0) {
      return new TypeName.full(identifier3(name), null);
    }
    return new TypeName.full(identifier3(name), typeArgumentList(arguments));
  }
  static TypeParameter typeParameter(String name) => new TypeParameter.full(null, null, identifier3(name), null, null);
  static TypeParameter typeParameter2(String name, TypeName bound) => new TypeParameter.full(null, null, identifier3(name), TokenFactory.token(Keyword.EXTENDS), bound);
  static TypeParameterList typeParameterList(List<String> typeNames) {
    List<TypeParameter> typeParameters = new List<TypeParameter>();
    for (String typeName in typeNames) {
      typeParameters.add(typeParameter(typeName));
    }
    return new TypeParameterList.full(TokenFactory.token3(TokenType.LT), typeParameters, TokenFactory.token3(TokenType.GT));
  }
  static VariableDeclaration variableDeclaration(String name) => new VariableDeclaration.full(null, null, identifier3(name), null, null);
  static VariableDeclaration variableDeclaration2(String name, Expression initializer) => new VariableDeclaration.full(null, null, identifier3(name), TokenFactory.token3(TokenType.EQ), initializer);
  static VariableDeclarationList variableDeclarationList(Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new VariableDeclarationList.full(null, null, keyword == null ? null : TokenFactory.token(keyword), type, list(variables));
  static VariableDeclarationList variableDeclarationList2(Keyword keyword, List<VariableDeclaration> variables) => variableDeclarationList(keyword, null, variables);
  static VariableDeclarationStatement variableDeclarationStatement(Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new VariableDeclarationStatement.full(variableDeclarationList(keyword, type, variables), TokenFactory.token3(TokenType.SEMICOLON));
  static VariableDeclarationStatement variableDeclarationStatement2(Keyword keyword, List<VariableDeclaration> variables) => variableDeclarationStatement(keyword, null, variables);
  static WhileStatement whileStatement(Expression condition, Statement body) => new WhileStatement.full(TokenFactory.token(Keyword.WHILE), TokenFactory.token3(TokenType.OPEN_PAREN), condition, TokenFactory.token3(TokenType.CLOSE_PAREN), body);
  static WithClause withClause(List<TypeName> types) => new WithClause.full(TokenFactory.token(Keyword.WITH), list(types));
  /**
   * Prevent the creation of instances of this class.
   */
  ASTFactory() {
  }
}
class SimpleIdentifierTest extends ParserTestCase {
  void test_inDeclarationContext_argumentDefinition() {
    SimpleIdentifier identifier16 = ASTFactory.argumentDefinitionTest("p").identifier;
    JUnitTestCase.assertFalse(identifier16.inDeclarationContext());
  }
  void test_inDeclarationContext_catch_exception() {
    SimpleIdentifier identifier = ASTFactory.catchClause("e", []).exceptionParameter;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_catch_stack() {
    SimpleIdentifier identifier = ASTFactory.catchClause2("e", "s", []).stackTraceParameter;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_classDeclaration() {
    SimpleIdentifier identifier = ASTFactory.classDeclaration(null, "C", null, null, null, null, []).name;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_classTypeAlias() {
    SimpleIdentifier identifier = ASTFactory.classTypeAlias("C", null, null, null, null, null).name;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_constructorDeclaration() {
    SimpleIdentifier identifier = ASTFactory.constructorDeclaration(ASTFactory.identifier3("C"), "c", null, null).name;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_fieldFormalParameter() {
    SimpleIdentifier identifier17 = ASTFactory.fieldFormalParameter2("p").identifier;
    JUnitTestCase.assertFalse(identifier17.inDeclarationContext());
  }
  void test_inDeclarationContext_functionDeclaration() {
    SimpleIdentifier identifier = ASTFactory.functionDeclaration(null, null, "f", null).name;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_functionTypeAlias() {
    SimpleIdentifier identifier = ASTFactory.typeAlias(null, "F", null, null).name;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_label_false() {
    SimpleIdentifier identifier = ASTFactory.namedExpression2("l", ASTFactory.integer(0)).name.label;
    JUnitTestCase.assertFalse(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_label_true() {
    Label label = ASTFactory.label2("l");
    SimpleIdentifier identifier = label.label;
    ASTFactory.labeledStatement(ASTFactory.list([label]), ASTFactory.emptyStatement());
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_methodDeclaration() {
    SimpleIdentifier identifier = ASTFactory.identifier3("m");
    ASTFactory.methodDeclaration2(null, null, null, null, identifier, null, null);
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_simpleFormalParameter() {
    SimpleIdentifier identifier18 = ASTFactory.simpleFormalParameter3("p").identifier;
    JUnitTestCase.assertTrue(identifier18.inDeclarationContext());
  }
  void test_inDeclarationContext_typeParameter_bound() {
    TypeName bound = ASTFactory.typeName4("A", []);
    SimpleIdentifier identifier = bound.name as SimpleIdentifier;
    ASTFactory.typeParameter2("E", bound);
    JUnitTestCase.assertFalse(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_typeParameter_name() {
    SimpleIdentifier identifier = ASTFactory.typeParameter("E").name;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inDeclarationContext_variableDeclaration() {
    SimpleIdentifier identifier = ASTFactory.variableDeclaration("v").name;
    JUnitTestCase.assertTrue(identifier.inDeclarationContext());
  }
  void test_inGetterContext() {
    for (WrapperKind wrapper in WrapperKind.values) {
      for (AssignmentKind assignment in AssignmentKind.values) {
        SimpleIdentifier identifier = createIdentifier(wrapper, assignment);
        if (identical(assignment, AssignmentKind.SIMPLE_LEFT) && wrapper != WrapperKind.PREFIXED_LEFT && wrapper != WrapperKind.PROPERTY_LEFT) {
          if (identifier.inGetterContext()) {
            JUnitTestCase.fail("Expected ${topMostNode(identifier).toSource()} to be false");
          }
        } else {
          if (!identifier.inGetterContext()) {
            JUnitTestCase.fail("Expected ${topMostNode(identifier).toSource()} to be true");
          }
        }
      }
    }
  }
  void test_inReferenceContext() {
    SimpleIdentifier identifier = ASTFactory.identifier3("id");
    ASTFactory.namedExpression(ASTFactory.label(identifier), ASTFactory.identifier3("_"));
    JUnitTestCase.assertFalse(identifier.inGetterContext());
    JUnitTestCase.assertFalse(identifier.inSetterContext());
  }
  void test_inSetterContext() {
    for (WrapperKind wrapper in WrapperKind.values) {
      for (AssignmentKind assignment in AssignmentKind.values) {
        SimpleIdentifier identifier = createIdentifier(wrapper, assignment);
        if (identical(wrapper, WrapperKind.PREFIXED_LEFT) || identical(wrapper, WrapperKind.PROPERTY_LEFT) || identical(assignment, AssignmentKind.BINARY) || identical(assignment, AssignmentKind.COMPOUND_RIGHT) || identical(assignment, AssignmentKind.PREFIX_NOT) || identical(assignment, AssignmentKind.SIMPLE_RIGHT) || identical(assignment, AssignmentKind.NONE)) {
          if (identifier.inSetterContext()) {
            JUnitTestCase.fail("Expected ${topMostNode(identifier).toSource()} to be false");
          }
        } else {
          if (!identifier.inSetterContext()) {
            JUnitTestCase.fail("Expected ${topMostNode(identifier).toSource()} to be true");
          }
        }
      }
    }
  }
  SimpleIdentifier createIdentifier(WrapperKind wrapper, AssignmentKind assignment) {
    SimpleIdentifier identifier = ASTFactory.identifier3("a");
    Expression expression = identifier;
    while (true) {
      if (wrapper == WrapperKind.PREFIXED_LEFT) {
        expression = ASTFactory.identifier(identifier, ASTFactory.identifier3("_"));
      } else if (wrapper == WrapperKind.PREFIXED_RIGHT) {
        expression = ASTFactory.identifier(ASTFactory.identifier3("_"), identifier);
      } else if (wrapper == WrapperKind.PROPERTY_LEFT) {
        expression = ASTFactory.propertyAccess2(expression, "_");
      } else if (wrapper == WrapperKind.PROPERTY_RIGHT) {
        expression = ASTFactory.propertyAccess(ASTFactory.identifier3("_"), identifier);
      }
      break;
    }
    while (true) {
      if (assignment == AssignmentKind.BINARY) {
        ASTFactory.binaryExpression(expression, TokenType.PLUS, ASTFactory.identifier3("_"));
      } else if (assignment == AssignmentKind.COMPOUND_LEFT) {
        ASTFactory.assignmentExpression(expression, TokenType.PLUS_EQ, ASTFactory.identifier3("_"));
      } else if (assignment == AssignmentKind.COMPOUND_RIGHT) {
        ASTFactory.assignmentExpression(ASTFactory.identifier3("_"), TokenType.PLUS_EQ, expression);
      } else if (assignment == AssignmentKind.POSTFIX_INC) {
        ASTFactory.postfixExpression(expression, TokenType.PLUS_PLUS);
      } else if (assignment == AssignmentKind.PREFIX_DEC) {
        ASTFactory.prefixExpression(TokenType.MINUS_MINUS, expression);
      } else if (assignment == AssignmentKind.PREFIX_INC) {
        ASTFactory.prefixExpression(TokenType.PLUS_PLUS, expression);
      } else if (assignment == AssignmentKind.PREFIX_NOT) {
        ASTFactory.prefixExpression(TokenType.BANG, expression);
      } else if (assignment == AssignmentKind.SIMPLE_LEFT) {
        ASTFactory.assignmentExpression(expression, TokenType.EQ, ASTFactory.identifier3("_"));
      } else if (assignment == AssignmentKind.SIMPLE_RIGHT) {
        ASTFactory.assignmentExpression(ASTFactory.identifier3("_"), TokenType.EQ, expression);
      }
      break;
    }
    return identifier;
  }
  /**
   * Return the top-most node in the AST structure containing the given identifier.
   * @param identifier the identifier in the AST structure being traversed
   * @return the root of the AST structure containing the identifier
   */
  ASTNode topMostNode(SimpleIdentifier identifier) {
    ASTNode child = identifier;
    ASTNode parent19 = identifier.parent;
    while (parent19 != null) {
      child = parent19;
      parent19 = parent19.parent;
    }
    return child;
  }
  static dartSuite() {
    _ut.group('SimpleIdentifierTest', () {
      _ut.test('test_inDeclarationContext_argumentDefinition', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_argumentDefinition);
      });
      _ut.test('test_inDeclarationContext_catch_exception', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_catch_exception);
      });
      _ut.test('test_inDeclarationContext_catch_stack', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_catch_stack);
      });
      _ut.test('test_inDeclarationContext_classDeclaration', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_classDeclaration);
      });
      _ut.test('test_inDeclarationContext_classTypeAlias', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_classTypeAlias);
      });
      _ut.test('test_inDeclarationContext_constructorDeclaration', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_constructorDeclaration);
      });
      _ut.test('test_inDeclarationContext_fieldFormalParameter', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_fieldFormalParameter);
      });
      _ut.test('test_inDeclarationContext_functionDeclaration', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_functionDeclaration);
      });
      _ut.test('test_inDeclarationContext_functionTypeAlias', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_functionTypeAlias);
      });
      _ut.test('test_inDeclarationContext_label_false', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_label_false);
      });
      _ut.test('test_inDeclarationContext_label_true', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_label_true);
      });
      _ut.test('test_inDeclarationContext_methodDeclaration', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_methodDeclaration);
      });
      _ut.test('test_inDeclarationContext_simpleFormalParameter', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_simpleFormalParameter);
      });
      _ut.test('test_inDeclarationContext_typeParameter_bound', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_typeParameter_bound);
      });
      _ut.test('test_inDeclarationContext_typeParameter_name', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_typeParameter_name);
      });
      _ut.test('test_inDeclarationContext_variableDeclaration', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inDeclarationContext_variableDeclaration);
      });
      _ut.test('test_inGetterContext', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inGetterContext);
      });
      _ut.test('test_inReferenceContext', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inReferenceContext);
      });
      _ut.test('test_inSetterContext', () {
        final __test = new SimpleIdentifierTest();
        runJUnitTest(__test, __test.test_inSetterContext);
      });
    });
  }
}
class AssignmentKind implements Comparable<AssignmentKind> {
  static final AssignmentKind BINARY = new AssignmentKind('BINARY', 0);
  static final AssignmentKind COMPOUND_LEFT = new AssignmentKind('COMPOUND_LEFT', 1);
  static final AssignmentKind COMPOUND_RIGHT = new AssignmentKind('COMPOUND_RIGHT', 2);
  static final AssignmentKind POSTFIX_INC = new AssignmentKind('POSTFIX_INC', 3);
  static final AssignmentKind PREFIX_DEC = new AssignmentKind('PREFIX_DEC', 4);
  static final AssignmentKind PREFIX_INC = new AssignmentKind('PREFIX_INC', 5);
  static final AssignmentKind PREFIX_NOT = new AssignmentKind('PREFIX_NOT', 6);
  static final AssignmentKind SIMPLE_LEFT = new AssignmentKind('SIMPLE_LEFT', 7);
  static final AssignmentKind SIMPLE_RIGHT = new AssignmentKind('SIMPLE_RIGHT', 8);
  static final AssignmentKind NONE = new AssignmentKind('NONE', 9);
  static final List<AssignmentKind> values = [BINARY, COMPOUND_LEFT, COMPOUND_RIGHT, POSTFIX_INC, PREFIX_DEC, PREFIX_INC, PREFIX_NOT, SIMPLE_LEFT, SIMPLE_RIGHT, NONE];
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
  AssignmentKind(this.__name, this.__ordinal) {
  }
  int compareTo(AssignmentKind other) => __ordinal - other.__ordinal;
  String toString() => __name;
}
class WrapperKind implements Comparable<WrapperKind> {
  static final WrapperKind PREFIXED_LEFT = new WrapperKind('PREFIXED_LEFT', 0);
  static final WrapperKind PREFIXED_RIGHT = new WrapperKind('PREFIXED_RIGHT', 1);
  static final WrapperKind PROPERTY_LEFT = new WrapperKind('PROPERTY_LEFT', 2);
  static final WrapperKind PROPERTY_RIGHT = new WrapperKind('PROPERTY_RIGHT', 3);
  static final WrapperKind NONE = new WrapperKind('NONE', 4);
  static final List<WrapperKind> values = [PREFIXED_LEFT, PREFIXED_RIGHT, PROPERTY_LEFT, PROPERTY_RIGHT, NONE];
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
  WrapperKind(this.__name, this.__ordinal) {
  }
  int compareTo(WrapperKind other) => __ordinal - other.__ordinal;
  String toString() => __name;
}
class ConstantEvaluatorTest extends ParserTestCase {
  void fail_constructor() {
    Object value = getConstantValue("?");
    JUnitTestCase.assertEquals(null, value);
  }
  void fail_identifier_class() {
    Object value = getConstantValue("?");
    JUnitTestCase.assertEquals(null, value);
  }
  void fail_identifier_function() {
    Object value = getConstantValue("?");
    JUnitTestCase.assertEquals(null, value);
  }
  void fail_identifier_static() {
    Object value = getConstantValue("?");
    JUnitTestCase.assertEquals(null, value);
  }
  void fail_identifier_staticMethod() {
    Object value = getConstantValue("?");
    JUnitTestCase.assertEquals(null, value);
  }
  void fail_identifier_topLevel() {
    Object value = getConstantValue("?");
    JUnitTestCase.assertEquals(null, value);
  }
  void fail_identifier_typeVariable() {
    Object value = getConstantValue("?");
    JUnitTestCase.assertEquals(null, value);
  }
  void test_binary_bitAnd() {
    Object value = getConstantValue("74 & 42");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(74 & 42, ((value as int)));
  }
  void test_binary_bitOr() {
    Object value = getConstantValue("74 | 42");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(74 | 42, ((value as int)));
  }
  void test_binary_bitXor() {
    Object value = getConstantValue("74 ^ 42");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(74 ^ 42, ((value as int)));
  }
  void test_binary_divide_double() {
    Object value = getConstantValue("3.2 / 2.3");
    EngineTestCase.assertInstanceOf(double, value);
    JUnitTestCase.assertEquals(3.2 / 2.3, ((value as double)));
  }
  void test_binary_divide_integer() {
    Object value = getConstantValue("3 / 2");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(1, ((value as int)));
  }
  void test_binary_equal_boolean() {
    Object value = getConstantValue("true == false");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_binary_equal_integer() {
    Object value = getConstantValue("2 == 3");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_binary_equal_invalidLeft() {
    Object value = getConstantValue("a == 3");
    JUnitTestCase.assertEquals(ConstantEvaluator.NOT_A_CONSTANT, value);
  }
  void test_binary_equal_invalidRight() {
    Object value = getConstantValue("2 == a");
    JUnitTestCase.assertEquals(ConstantEvaluator.NOT_A_CONSTANT, value);
  }
  void test_binary_equal_string() {
    Object value = getConstantValue("'a' == 'b'");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_binary_greaterThan() {
    Object value = getConstantValue("2 > 3");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_binary_greaterThanOrEqual() {
    Object value = getConstantValue("2 >= 3");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_binary_leftShift() {
    Object value = getConstantValue("16 << 2");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(64, ((value as int)));
  }
  void test_binary_lessThan() {
    Object value = getConstantValue("2 < 3");
    JUnitTestCase.assertEquals(true, value);
  }
  void test_binary_lessThanOrEqual() {
    Object value = getConstantValue("2 <= 3");
    JUnitTestCase.assertEquals(true, value);
  }
  void test_binary_logicalAnd() {
    Object value = getConstantValue("true && false");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_binary_logicalOr() {
    Object value = getConstantValue("true || false");
    JUnitTestCase.assertEquals(true, value);
  }
  void test_binary_minus_double() {
    Object value = getConstantValue("3.2 - 2.3");
    EngineTestCase.assertInstanceOf(double, value);
    JUnitTestCase.assertEquals(3.2 - 2.3, ((value as double)));
  }
  void test_binary_minus_integer() {
    Object value = getConstantValue("3 - 2");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(1, ((value as int)));
  }
  void test_binary_notEqual_boolean() {
    Object value = getConstantValue("true != false");
    JUnitTestCase.assertEquals(true, value);
  }
  void test_binary_notEqual_integer() {
    Object value = getConstantValue("2 != 3");
    JUnitTestCase.assertEquals(true, value);
  }
  void test_binary_notEqual_invalidLeft() {
    Object value = getConstantValue("a != 3");
    JUnitTestCase.assertEquals(ConstantEvaluator.NOT_A_CONSTANT, value);
  }
  void test_binary_notEqual_invalidRight() {
    Object value = getConstantValue("2 != a");
    JUnitTestCase.assertEquals(ConstantEvaluator.NOT_A_CONSTANT, value);
  }
  void test_binary_notEqual_string() {
    Object value = getConstantValue("'a' != 'b'");
    JUnitTestCase.assertEquals(true, value);
  }
  void test_binary_plus_double() {
    Object value = getConstantValue("2.3 + 3.2");
    EngineTestCase.assertInstanceOf(double, value);
    JUnitTestCase.assertEquals(2.3 + 3.2, ((value as double)));
  }
  void test_binary_plus_integer() {
    Object value = getConstantValue("2 + 3");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(5, ((value as int)));
  }
  void test_binary_remainder_double() {
    Object value = getConstantValue("3.2 % 2.3");
    EngineTestCase.assertInstanceOf(double, value);
    JUnitTestCase.assertEquals(3.2 % 2.3, ((value as double)));
  }
  void test_binary_remainder_integer() {
    Object value = getConstantValue("8 % 3");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(2, ((value as int)));
  }
  void test_binary_rightShift() {
    Object value = getConstantValue("64 >> 2");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(16, ((value as int)));
  }
  void test_binary_times_double() {
    Object value = getConstantValue("2.3 * 3.2");
    EngineTestCase.assertInstanceOf(double, value);
    JUnitTestCase.assertEquals(2.3 * 3.2, ((value as double)));
  }
  void test_binary_times_integer() {
    Object value = getConstantValue("2 * 3");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(6, ((value as int)));
  }
  void test_binary_truncatingDivide_double() {
    Object value = getConstantValue("3.2 ~/ 2.3");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(1, ((value as int)));
  }
  void test_binary_truncatingDivide_integer() {
    Object value = getConstantValue("10 ~/ 3");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(3, ((value as int)));
  }
  void test_literal_boolean_false() {
    Object value = getConstantValue("false");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_literal_boolean_true() {
    Object value = getConstantValue("true");
    JUnitTestCase.assertEquals(true, value);
  }
  void test_literal_list() {
    Object value = getConstantValue("['a', 'b', 'c']");
    EngineTestCase.assertInstanceOf(List, value);
    List<Object> list = value as List<Object>;
    JUnitTestCase.assertEquals(3, list.length);
    JUnitTestCase.assertEquals("a", list[0]);
    JUnitTestCase.assertEquals("b", list[1]);
    JUnitTestCase.assertEquals("c", list[2]);
  }
  void test_literal_map() {
    Object value = getConstantValue("{'a' : 'm', 'b' : 'n', 'c' : 'o'}");
    EngineTestCase.assertInstanceOf(Map, value);
    Map<Object, Object> map = value as Map<Object, Object>;
    JUnitTestCase.assertEquals(3, map.length);
    JUnitTestCase.assertEquals("m", map["a"]);
    JUnitTestCase.assertEquals("n", map["b"]);
    JUnitTestCase.assertEquals("o", map["c"]);
  }
  void test_literal_null() {
    Object value = getConstantValue("null");
    JUnitTestCase.assertEquals(null, value);
  }
  void test_literal_number_double() {
    Object value = getConstantValue("3.45");
    EngineTestCase.assertInstanceOf(double, value);
    JUnitTestCase.assertEquals(3.45, ((value as double)));
  }
  void test_literal_number_integer() {
    Object value = getConstantValue("42");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(42, ((value as int)));
  }
  void test_literal_string_adjacent() {
    Object value = getConstantValue("'abc' 'def'");
    JUnitTestCase.assertEquals("abcdef", value);
  }
  void test_literal_string_interpolation_invalid() {
    Object value = getConstantValue("'a\${f()}c'");
    JUnitTestCase.assertEquals(ConstantEvaluator.NOT_A_CONSTANT, value);
  }
  void test_literal_string_interpolation_valid() {
    Object value = getConstantValue("'a\${3}c'");
    JUnitTestCase.assertEquals("a3c", value);
  }
  void test_literal_string_simple() {
    Object value = getConstantValue("'abc'");
    JUnitTestCase.assertEquals("abc", value);
  }
  void test_parenthesizedExpression() {
    Object value = getConstantValue("('a')");
    JUnitTestCase.assertEquals("a", value);
  }
  void test_unary_bitNot() {
    Object value = getConstantValue("~42");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(~42, ((value as int)));
  }
  void test_unary_logicalNot() {
    Object value = getConstantValue("!true");
    JUnitTestCase.assertEquals(false, value);
  }
  void test_unary_negated_double() {
    Object value = getConstantValue("-42.3");
    EngineTestCase.assertInstanceOf(double, value);
    JUnitTestCase.assertEquals(-42.3, ((value as double)));
  }
  void test_unary_negated_integer() {
    Object value = getConstantValue("-42");
    EngineTestCase.assertInstanceOf(int, value);
    JUnitTestCase.assertEquals(-42, ((value as int)));
  }
  Object getConstantValue(String source) => ParserTestCase.parseExpression(source, []).accept(new ConstantEvaluator());
  static dartSuite() {
    _ut.group('ConstantEvaluatorTest', () {
      _ut.test('test_binary_bitAnd', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_bitAnd);
      });
      _ut.test('test_binary_bitOr', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_bitOr);
      });
      _ut.test('test_binary_bitXor', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_bitXor);
      });
      _ut.test('test_binary_divide_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_divide_double);
      });
      _ut.test('test_binary_divide_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_divide_integer);
      });
      _ut.test('test_binary_equal_boolean', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_equal_boolean);
      });
      _ut.test('test_binary_equal_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_equal_integer);
      });
      _ut.test('test_binary_equal_invalidLeft', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_equal_invalidLeft);
      });
      _ut.test('test_binary_equal_invalidRight', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_equal_invalidRight);
      });
      _ut.test('test_binary_equal_string', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_equal_string);
      });
      _ut.test('test_binary_greaterThan', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_greaterThan);
      });
      _ut.test('test_binary_greaterThanOrEqual', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_greaterThanOrEqual);
      });
      _ut.test('test_binary_leftShift', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_leftShift);
      });
      _ut.test('test_binary_lessThan', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_lessThan);
      });
      _ut.test('test_binary_lessThanOrEqual', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_lessThanOrEqual);
      });
      _ut.test('test_binary_logicalAnd', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_logicalAnd);
      });
      _ut.test('test_binary_logicalOr', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_logicalOr);
      });
      _ut.test('test_binary_minus_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_minus_double);
      });
      _ut.test('test_binary_minus_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_minus_integer);
      });
      _ut.test('test_binary_notEqual_boolean', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_notEqual_boolean);
      });
      _ut.test('test_binary_notEqual_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_notEqual_integer);
      });
      _ut.test('test_binary_notEqual_invalidLeft', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_notEqual_invalidLeft);
      });
      _ut.test('test_binary_notEqual_invalidRight', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_notEqual_invalidRight);
      });
      _ut.test('test_binary_notEqual_string', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_notEqual_string);
      });
      _ut.test('test_binary_plus_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_plus_double);
      });
      _ut.test('test_binary_plus_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_plus_integer);
      });
      _ut.test('test_binary_remainder_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_remainder_double);
      });
      _ut.test('test_binary_remainder_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_remainder_integer);
      });
      _ut.test('test_binary_rightShift', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_rightShift);
      });
      _ut.test('test_binary_times_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_times_double);
      });
      _ut.test('test_binary_times_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_times_integer);
      });
      _ut.test('test_binary_truncatingDivide_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_truncatingDivide_double);
      });
      _ut.test('test_binary_truncatingDivide_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_binary_truncatingDivide_integer);
      });
      _ut.test('test_literal_boolean_false', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_boolean_false);
      });
      _ut.test('test_literal_boolean_true', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_boolean_true);
      });
      _ut.test('test_literal_list', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_list);
      });
      _ut.test('test_literal_map', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_map);
      });
      _ut.test('test_literal_null', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_null);
      });
      _ut.test('test_literal_number_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_number_double);
      });
      _ut.test('test_literal_number_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_number_integer);
      });
      _ut.test('test_literal_string_adjacent', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_string_adjacent);
      });
      _ut.test('test_literal_string_interpolation_invalid', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_string_interpolation_invalid);
      });
      _ut.test('test_literal_string_interpolation_valid', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_string_interpolation_valid);
      });
      _ut.test('test_literal_string_simple', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_literal_string_simple);
      });
      _ut.test('test_parenthesizedExpression', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_parenthesizedExpression);
      });
      _ut.test('test_unary_bitNot', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_unary_bitNot);
      });
      _ut.test('test_unary_logicalNot', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_unary_logicalNot);
      });
      _ut.test('test_unary_negated_double', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_unary_negated_double);
      });
      _ut.test('test_unary_negated_integer', () {
        final __test = new ConstantEvaluatorTest();
        runJUnitTest(__test, __test.test_unary_negated_integer);
      });
    });
  }
}
class ToSourceVisitorTest extends EngineTestCase {
  void test_visitAdjacentStrings() {
    assertSource("'a' 'b'", ASTFactory.adjacentStrings([ASTFactory.string2("a"), ASTFactory.string2("b")]));
  }
  void test_visitAnnotation_constant() {
    assertSource("@A", ASTFactory.annotation(ASTFactory.identifier3("A")));
  }
  void test_visitAnnotation_constructor() {
    assertSource("@A.c()", ASTFactory.annotation2(ASTFactory.identifier3("A"), ASTFactory.identifier3("c"), ASTFactory.argumentList([])));
  }
  void test_visitArgumentDefinitionTest() {
    assertSource("?a", ASTFactory.argumentDefinitionTest("a"));
  }
  void test_visitArgumentList() {
    assertSource("(a, b)", ASTFactory.argumentList([ASTFactory.identifier3("a"), ASTFactory.identifier3("b")]));
  }
  void test_visitAsExpression() {
    assertSource("e as T", ASTFactory.asExpression(ASTFactory.identifier3("e"), ASTFactory.typeName4("T", [])));
  }
  void test_visitAssertStatement() {
    assertSource("assert (a);", ASTFactory.assertStatement(ASTFactory.identifier3("a")));
  }
  void test_visitAssignmentExpression() {
    assertSource("a = b", ASTFactory.assignmentExpression(ASTFactory.identifier3("a"), TokenType.EQ, ASTFactory.identifier3("b")));
  }
  void test_visitBinaryExpression() {
    assertSource("a + b", ASTFactory.binaryExpression(ASTFactory.identifier3("a"), TokenType.PLUS, ASTFactory.identifier3("b")));
  }
  void test_visitBlock_empty() {
    assertSource("{}", ASTFactory.block([]));
  }
  void test_visitBlock_nonEmpty() {
    assertSource("{break; break;}", ASTFactory.block([ASTFactory.breakStatement(), ASTFactory.breakStatement()]));
  }
  void test_visitBlockFunctionBody() {
    assertSource("{}", ASTFactory.blockFunctionBody([]));
  }
  void test_visitBooleanLiteral_false() {
    assertSource("false", ASTFactory.booleanLiteral(false));
  }
  void test_visitBooleanLiteral_true() {
    assertSource("true", ASTFactory.booleanLiteral(true));
  }
  void test_visitBreakStatement_label() {
    assertSource("break l;", ASTFactory.breakStatement2("l"));
  }
  void test_visitBreakStatement_noLabel() {
    assertSource("break;", ASTFactory.breakStatement());
  }
  void test_visitCascadeExpression_field() {
    assertSource("a..b..c", ASTFactory.cascadeExpression(ASTFactory.identifier3("a"), [ASTFactory.cascadedPropertyAccess("b"), ASTFactory.cascadedPropertyAccess("c")]));
  }
  void test_visitCascadeExpression_index() {
    assertSource("a..[0]..[1]", ASTFactory.cascadeExpression(ASTFactory.identifier3("a"), [ASTFactory.cascadedIndexExpression(ASTFactory.integer(0)), ASTFactory.cascadedIndexExpression(ASTFactory.integer(1))]));
  }
  void test_visitCascadeExpression_method() {
    assertSource("a..b()..c()", ASTFactory.cascadeExpression(ASTFactory.identifier3("a"), [ASTFactory.cascadedMethodInvocation("b", []), ASTFactory.cascadedMethodInvocation("c", [])]));
  }
  void test_visitCatchClause_catch_noStack() {
    assertSource("catch (e) {}", ASTFactory.catchClause("e", []));
  }
  void test_visitCatchClause_catch_stack() {
    assertSource("catch (e, s) {}", ASTFactory.catchClause2("e", "s", []));
  }
  void test_visitCatchClause_on() {
    assertSource("on E {}", ASTFactory.catchClause3(ASTFactory.typeName4("E", []), []));
  }
  void test_visitCatchClause_on_catch() {
    assertSource("on E catch (e) {}", ASTFactory.catchClause4(ASTFactory.typeName4("E", []), "e", []));
  }
  void test_visitClassDeclaration_abstract() {
    assertSource("abstract class C {}", ASTFactory.classDeclaration(Keyword.ABSTRACT, "C", null, null, null, null, []));
  }
  void test_visitClassDeclaration_empty() {
    assertSource("class C {}", ASTFactory.classDeclaration(null, "C", null, null, null, null, []));
  }
  void test_visitClassDeclaration_extends() {
    assertSource("class C extends A {}", ASTFactory.classDeclaration(null, "C", null, ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), null, null, []));
  }
  void test_visitClassDeclaration_extends_implements() {
    assertSource("class C extends A implements B {}", ASTFactory.classDeclaration(null, "C", null, ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), null, ASTFactory.implementsClause([ASTFactory.typeName4("B", [])]), []));
  }
  void test_visitClassDeclaration_extends_with() {
    assertSource("class C extends A with M {}", ASTFactory.classDeclaration(null, "C", null, ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), ASTFactory.withClause([ASTFactory.typeName4("M", [])]), null, []));
  }
  void test_visitClassDeclaration_extends_with_implements() {
    assertSource("class C extends A with M implements B {}", ASTFactory.classDeclaration(null, "C", null, ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), ASTFactory.withClause([ASTFactory.typeName4("M", [])]), ASTFactory.implementsClause([ASTFactory.typeName4("B", [])]), []));
  }
  void test_visitClassDeclaration_implements() {
    assertSource("class C implements B {}", ASTFactory.classDeclaration(null, "C", null, null, null, ASTFactory.implementsClause([ASTFactory.typeName4("B", [])]), []));
  }
  void test_visitClassDeclaration_multipleMember() {
    assertSource("class C {var a; var b;}", ASTFactory.classDeclaration(null, "C", null, null, null, null, [ASTFactory.fieldDeclaration2(false, Keyword.VAR, [ASTFactory.variableDeclaration("a")]), ASTFactory.fieldDeclaration2(false, Keyword.VAR, [ASTFactory.variableDeclaration("b")])]));
  }
  void test_visitClassDeclaration_parameters() {
    assertSource("class C<E> {}", ASTFactory.classDeclaration(null, "C", ASTFactory.typeParameterList(["E"]), null, null, null, []));
  }
  void test_visitClassDeclaration_parameters_extends() {
    assertSource("class C<E> extends A {}", ASTFactory.classDeclaration(null, "C", ASTFactory.typeParameterList(["E"]), ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), null, null, []));
  }
  void test_visitClassDeclaration_parameters_extends_implements() {
    assertSource("class C<E> extends A implements B {}", ASTFactory.classDeclaration(null, "C", ASTFactory.typeParameterList(["E"]), ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), null, ASTFactory.implementsClause([ASTFactory.typeName4("B", [])]), []));
  }
  void test_visitClassDeclaration_parameters_extends_with() {
    assertSource("class C<E> extends A with M {}", ASTFactory.classDeclaration(null, "C", ASTFactory.typeParameterList(["E"]), ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), ASTFactory.withClause([ASTFactory.typeName4("M", [])]), null, []));
  }
  void test_visitClassDeclaration_parameters_extends_with_implements() {
    assertSource("class C<E> extends A with M implements B {}", ASTFactory.classDeclaration(null, "C", ASTFactory.typeParameterList(["E"]), ASTFactory.extendsClause(ASTFactory.typeName4("A", [])), ASTFactory.withClause([ASTFactory.typeName4("M", [])]), ASTFactory.implementsClause([ASTFactory.typeName4("B", [])]), []));
  }
  void test_visitClassDeclaration_parameters_implements() {
    assertSource("class C<E> implements B {}", ASTFactory.classDeclaration(null, "C", ASTFactory.typeParameterList(["E"]), null, null, ASTFactory.implementsClause([ASTFactory.typeName4("B", [])]), []));
  }
  void test_visitClassDeclaration_singleMember() {
    assertSource("class C {var a;}", ASTFactory.classDeclaration(null, "C", null, null, null, null, [ASTFactory.fieldDeclaration2(false, Keyword.VAR, [ASTFactory.variableDeclaration("a")])]));
  }
  void test_visitClassTypeAlias_abstract() {
    assertSource("typedef C = abstract S with M1;", ASTFactory.classTypeAlias("C", null, Keyword.ABSTRACT, ASTFactory.typeName4("S", []), ASTFactory.withClause([ASTFactory.typeName4("M1", [])]), null));
  }
  void test_visitClassTypeAlias_abstract_implements() {
    assertSource("typedef C = abstract S with M1 implements I;", ASTFactory.classTypeAlias("C", null, Keyword.ABSTRACT, ASTFactory.typeName4("S", []), ASTFactory.withClause([ASTFactory.typeName4("M1", [])]), ASTFactory.implementsClause([ASTFactory.typeName4("I", [])])));
  }
  void test_visitClassTypeAlias_generic() {
    assertSource("typedef C<E> = S<E> with M1<E>;", ASTFactory.classTypeAlias("C", ASTFactory.typeParameterList(["E"]), null, ASTFactory.typeName4("S", [ASTFactory.typeName4("E", [])]), ASTFactory.withClause([ASTFactory.typeName4("M1", [ASTFactory.typeName4("E", [])])]), null));
  }
  void test_visitClassTypeAlias_implements() {
    assertSource("typedef C = S with M1 implements I;", ASTFactory.classTypeAlias("C", null, null, ASTFactory.typeName4("S", []), ASTFactory.withClause([ASTFactory.typeName4("M1", [])]), ASTFactory.implementsClause([ASTFactory.typeName4("I", [])])));
  }
  void test_visitClassTypeAlias_minimal() {
    assertSource("typedef C = S with M1;", ASTFactory.classTypeAlias("C", null, null, ASTFactory.typeName4("S", []), ASTFactory.withClause([ASTFactory.typeName4("M1", [])]), null));
  }
  void test_visitClassTypeAlias_parameters_abstract() {
    assertSource("typedef C<E> = abstract S with M1;", ASTFactory.classTypeAlias("C", ASTFactory.typeParameterList(["E"]), Keyword.ABSTRACT, ASTFactory.typeName4("S", []), ASTFactory.withClause([ASTFactory.typeName4("M1", [])]), null));
  }
  void test_visitClassTypeAlias_parameters_abstract_implements() {
    assertSource("typedef C<E> = abstract S with M1 implements I;", ASTFactory.classTypeAlias("C", ASTFactory.typeParameterList(["E"]), Keyword.ABSTRACT, ASTFactory.typeName4("S", []), ASTFactory.withClause([ASTFactory.typeName4("M1", [])]), ASTFactory.implementsClause([ASTFactory.typeName4("I", [])])));
  }
  void test_visitClassTypeAlias_parameters_implements() {
    assertSource("typedef C<E> = S with M1 implements I;", ASTFactory.classTypeAlias("C", ASTFactory.typeParameterList(["E"]), null, ASTFactory.typeName4("S", []), ASTFactory.withClause([ASTFactory.typeName4("M1", [])]), ASTFactory.implementsClause([ASTFactory.typeName4("I", [])])));
  }
  void test_visitComment() {
    assertSource("", Comment.createBlockComment(<Token> [TokenFactory.token2("/* comment */")]));
  }
  void test_visitCommentReference() {
    assertSource("", new CommentReference.full(null, ASTFactory.identifier3("a")));
  }
  void test_visitCompilationUnit_declaration() {
    assertSource("var a;", ASTFactory.compilationUnit2([ASTFactory.topLevelVariableDeclaration2(Keyword.VAR, [ASTFactory.variableDeclaration("a")])]));
  }
  void test_visitCompilationUnit_directive() {
    assertSource("library l;", ASTFactory.compilationUnit3([ASTFactory.libraryDirective2("l")]));
  }
  void test_visitCompilationUnit_directive_declaration() {
    assertSource("library l; var a;", ASTFactory.compilationUnit4(ASTFactory.list([(ASTFactory.libraryDirective2("l") as Directive)]), ASTFactory.list([(ASTFactory.topLevelVariableDeclaration2(Keyword.VAR, [ASTFactory.variableDeclaration("a")]) as CompilationUnitMember)])));
  }
  void test_visitCompilationUnit_empty() {
    assertSource("", ASTFactory.compilationUnit());
  }
  void test_visitCompilationUnit_script() {
    assertSource("!#/bin/dartvm", ASTFactory.compilationUnit5("!#/bin/dartvm"));
  }
  void test_visitCompilationUnit_script_declaration() {
    assertSource("!#/bin/dartvm var a;", ASTFactory.compilationUnit6("!#/bin/dartvm", [ASTFactory.topLevelVariableDeclaration2(Keyword.VAR, [ASTFactory.variableDeclaration("a")])]));
  }
  void test_visitCompilationUnit_script_directive() {
    assertSource("!#/bin/dartvm library l;", ASTFactory.compilationUnit7("!#/bin/dartvm", [ASTFactory.libraryDirective2("l")]));
  }
  void test_visitCompilationUnit_script_directives_declarations() {
    assertSource("!#/bin/dartvm library l; var a;", ASTFactory.compilationUnit8("!#/bin/dartvm", ASTFactory.list([(ASTFactory.libraryDirective2("l") as Directive)]), ASTFactory.list([(ASTFactory.topLevelVariableDeclaration2(Keyword.VAR, [ASTFactory.variableDeclaration("a")]) as CompilationUnitMember)])));
  }
  void test_visitConditionalExpression() {
    assertSource("a ? b : c", ASTFactory.conditionalExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("b"), ASTFactory.identifier3("c")));
  }
  void test_visitConstructorDeclaration_const() {
    assertSource("const C() {}", ASTFactory.constructorDeclaration2(Keyword.CONST, null, ASTFactory.identifier3("C"), null, ASTFactory.formalParameterList([]), null, ASTFactory.blockFunctionBody([])));
  }
  void test_visitConstructorDeclaration_external() {
    assertSource("external C();", ASTFactory.constructorDeclaration(ASTFactory.identifier3("C"), null, ASTFactory.formalParameterList([]), null));
  }
  void test_visitConstructorDeclaration_minimal() {
    assertSource("C() {}", ASTFactory.constructorDeclaration2(null, null, ASTFactory.identifier3("C"), null, ASTFactory.formalParameterList([]), null, ASTFactory.blockFunctionBody([])));
  }
  void test_visitConstructorDeclaration_multipleInitializers() {
    assertSource("C() : a = b, c = d {}", ASTFactory.constructorDeclaration2(null, null, ASTFactory.identifier3("C"), null, ASTFactory.formalParameterList([]), ASTFactory.list([(ASTFactory.constructorFieldInitializer(false, "a", ASTFactory.identifier3("b")) as ConstructorInitializer), ASTFactory.constructorFieldInitializer(false, "c", ASTFactory.identifier3("d"))]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitConstructorDeclaration_multipleParameters() {
    assertSource("C(var a, var b) {}", ASTFactory.constructorDeclaration2(null, null, ASTFactory.identifier3("C"), null, ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter(Keyword.VAR, "a"), ASTFactory.simpleFormalParameter(Keyword.VAR, "b")]), null, ASTFactory.blockFunctionBody([])));
  }
  void test_visitConstructorDeclaration_named() {
    assertSource("C.m() {}", ASTFactory.constructorDeclaration2(null, null, ASTFactory.identifier3("C"), "m", ASTFactory.formalParameterList([]), null, ASTFactory.blockFunctionBody([])));
  }
  void test_visitConstructorDeclaration_singleInitializer() {
    assertSource("C() : a = b {}", ASTFactory.constructorDeclaration2(null, null, ASTFactory.identifier3("C"), null, ASTFactory.formalParameterList([]), ASTFactory.list([(ASTFactory.constructorFieldInitializer(false, "a", ASTFactory.identifier3("b")) as ConstructorInitializer)]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitConstructorFieldInitializer_withoutThis() {
    assertSource("a = b", ASTFactory.constructorFieldInitializer(false, "a", ASTFactory.identifier3("b")));
  }
  void test_visitConstructorFieldInitializer_withThis() {
    assertSource("this.a = b", ASTFactory.constructorFieldInitializer(true, "a", ASTFactory.identifier3("b")));
  }
  void test_visitConstructorName_named_prefix() {
    assertSource("p.C.n", ASTFactory.constructorName(ASTFactory.typeName4("p.C.n", []), null));
  }
  void test_visitConstructorName_unnamed_noPrefix() {
    assertSource("C", ASTFactory.constructorName(ASTFactory.typeName4("C", []), null));
  }
  void test_visitConstructorName_unnamed_prefix() {
    assertSource("p.C", ASTFactory.constructorName(ASTFactory.typeName3(ASTFactory.identifier5("p", "C"), []), null));
  }
  void test_visitContinueStatement_label() {
    assertSource("continue l;", ASTFactory.continueStatement2("l"));
  }
  void test_visitContinueStatement_noLabel() {
    assertSource("continue;", ASTFactory.continueStatement());
  }
  void test_visitDefaultFormalParameter_named_noValue() {
    assertSource("p", ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p"), null));
  }
  void test_visitDefaultFormalParameter_named_value() {
    assertSource("p : 0", ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p"), ASTFactory.integer(0)));
  }
  void test_visitDefaultFormalParameter_positional_noValue() {
    assertSource("p", ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p"), null));
  }
  void test_visitDefaultFormalParameter_positional_value() {
    assertSource("p = 0", ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p"), ASTFactory.integer(0)));
  }
  void test_visitDoStatement() {
    assertSource("do {} while (c);", ASTFactory.doStatement(ASTFactory.block([]), ASTFactory.identifier3("c")));
  }
  void test_visitDoubleLiteral() {
    assertSource("4.2", ASTFactory.doubleLiteral(4.2));
  }
  void test_visitEmptyFunctionBody() {
    assertSource(";", ASTFactory.emptyFunctionBody());
  }
  void test_visitEmptyStatement() {
    assertSource(";", ASTFactory.emptyStatement());
  }
  void test_visitExportDirective_combinator() {
    assertSource("export 'a.dart' show A;", ASTFactory.exportDirective2("a.dart", [(ASTFactory.showCombinator([ASTFactory.identifier3("A")]) as Combinator)]));
  }
  void test_visitExportDirective_combinators() {
    assertSource("export 'a.dart' show A hide B;", ASTFactory.exportDirective2("a.dart", [ASTFactory.showCombinator([ASTFactory.identifier3("A")]), ASTFactory.hideCombinator([ASTFactory.identifier3("B")])]));
  }
  void test_visitExportDirective_minimal() {
    assertSource("export 'a.dart';", ASTFactory.exportDirective2("a.dart", []));
  }
  void test_visitExpressionFunctionBody() {
    assertSource("=> a;", ASTFactory.expressionFunctionBody(ASTFactory.identifier3("a")));
  }
  void test_visitExpressionStatement() {
    assertSource("a;", ASTFactory.expressionStatement(ASTFactory.identifier3("a")));
  }
  void test_visitExtendsClause() {
    assertSource("extends C", ASTFactory.extendsClause(ASTFactory.typeName4("C", [])));
  }
  void test_visitFieldDeclaration_instance() {
    assertSource("var a;", ASTFactory.fieldDeclaration2(false, Keyword.VAR, [ASTFactory.variableDeclaration("a")]));
  }
  void test_visitFieldDeclaration_static() {
    assertSource("static var a;", ASTFactory.fieldDeclaration2(true, Keyword.VAR, [ASTFactory.variableDeclaration("a")]));
  }
  void test_visitFieldFormalParameter_keyword() {
    assertSource("var this.a", ASTFactory.fieldFormalParameter(Keyword.VAR, null, "a"));
  }
  void test_visitFieldFormalParameter_keywordAndType() {
    assertSource("final A this.a", ASTFactory.fieldFormalParameter(Keyword.FINAL, ASTFactory.typeName4("A", []), "a"));
  }
  void test_visitFieldFormalParameter_type() {
    assertSource("A this.a", ASTFactory.fieldFormalParameter(null, ASTFactory.typeName4("A", []), "a"));
  }
  void test_visitForEachStatement() {
    assertSource("for (a in b) {}", ASTFactory.forEachStatement(ASTFactory.declaredIdentifier3("a"), ASTFactory.identifier3("b"), ASTFactory.block([])));
  }
  void test_visitFormalParameterList_empty() {
    assertSource("()", ASTFactory.formalParameterList([]));
  }
  void test_visitFormalParameterList_n() {
    assertSource("({a : 0})", ASTFactory.formalParameterList([ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("a"), ASTFactory.integer(0))]));
  }
  void test_visitFormalParameterList_nn() {
    assertSource("({a : 0, b : 1})", ASTFactory.formalParameterList([ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("a"), ASTFactory.integer(0)), ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("b"), ASTFactory.integer(1))]));
  }
  void test_visitFormalParameterList_p() {
    assertSource("([a = 0])", ASTFactory.formalParameterList([ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("a"), ASTFactory.integer(0))]));
  }
  void test_visitFormalParameterList_pp() {
    assertSource("([a = 0, b = 1])", ASTFactory.formalParameterList([ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("a"), ASTFactory.integer(0)), ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("b"), ASTFactory.integer(1))]));
  }
  void test_visitFormalParameterList_r() {
    assertSource("(a)", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a")]));
  }
  void test_visitFormalParameterList_rn() {
    assertSource("(a, {b : 1})", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("b"), ASTFactory.integer(1))]));
  }
  void test_visitFormalParameterList_rnn() {
    assertSource("(a, {b : 1, c : 2})", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("b"), ASTFactory.integer(1)), ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("c"), ASTFactory.integer(2))]));
  }
  void test_visitFormalParameterList_rp() {
    assertSource("(a, [b = 1])", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("b"), ASTFactory.integer(1))]));
  }
  void test_visitFormalParameterList_rpp() {
    assertSource("(a, [b = 1, c = 2])", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("b"), ASTFactory.integer(1)), ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("c"), ASTFactory.integer(2))]));
  }
  void test_visitFormalParameterList_rr() {
    assertSource("(a, b)", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.simpleFormalParameter3("b")]));
  }
  void test_visitFormalParameterList_rrn() {
    assertSource("(a, b, {c : 3})", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.simpleFormalParameter3("b"), ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("c"), ASTFactory.integer(3))]));
  }
  void test_visitFormalParameterList_rrnn() {
    assertSource("(a, b, {c : 3, d : 4})", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.simpleFormalParameter3("b"), ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("c"), ASTFactory.integer(3)), ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("d"), ASTFactory.integer(4))]));
  }
  void test_visitFormalParameterList_rrp() {
    assertSource("(a, b, [c = 3])", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.simpleFormalParameter3("b"), ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("c"), ASTFactory.integer(3))]));
  }
  void test_visitFormalParameterList_rrpp() {
    assertSource("(a, b, [c = 3, d = 4])", ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter3("a"), ASTFactory.simpleFormalParameter3("b"), ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("c"), ASTFactory.integer(3)), ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("d"), ASTFactory.integer(4))]));
  }
  void test_visitForStatement_c() {
    assertSource("for (; c;) {}", ASTFactory.forStatement((null as Expression), ASTFactory.identifier3("c"), null, ASTFactory.block([])));
  }
  void test_visitForStatement_cu() {
    assertSource("for (; c; u) {}", ASTFactory.forStatement((null as Expression), ASTFactory.identifier3("c"), ASTFactory.list([(ASTFactory.identifier3("u") as Expression)]), ASTFactory.block([])));
  }
  void test_visitForStatement_e() {
    assertSource("for (e;;) {}", ASTFactory.forStatement(ASTFactory.identifier3("e"), null, null, ASTFactory.block([])));
  }
  void test_visitForStatement_ec() {
    assertSource("for (e; c;) {}", ASTFactory.forStatement(ASTFactory.identifier3("e"), ASTFactory.identifier3("c"), null, ASTFactory.block([])));
  }
  void test_visitForStatement_ecu() {
    assertSource("for (e; c; u) {}", ASTFactory.forStatement(ASTFactory.identifier3("e"), ASTFactory.identifier3("c"), ASTFactory.list([(ASTFactory.identifier3("u") as Expression)]), ASTFactory.block([])));
  }
  void test_visitForStatement_eu() {
    assertSource("for (e;; u) {}", ASTFactory.forStatement(ASTFactory.identifier3("e"), null, ASTFactory.list([(ASTFactory.identifier3("u") as Expression)]), ASTFactory.block([])));
  }
  void test_visitForStatement_i() {
    assertSource("for (var i;;) {}", ASTFactory.forStatement2(ASTFactory.variableDeclarationList2(Keyword.VAR, [ASTFactory.variableDeclaration("i")]), null, null, ASTFactory.block([])));
  }
  void test_visitForStatement_ic() {
    assertSource("for (var i; c;) {}", ASTFactory.forStatement2(ASTFactory.variableDeclarationList2(Keyword.VAR, [ASTFactory.variableDeclaration("i")]), ASTFactory.identifier3("c"), null, ASTFactory.block([])));
  }
  void test_visitForStatement_icu() {
    assertSource("for (var i; c; u) {}", ASTFactory.forStatement2(ASTFactory.variableDeclarationList2(Keyword.VAR, [ASTFactory.variableDeclaration("i")]), ASTFactory.identifier3("c"), ASTFactory.list([(ASTFactory.identifier3("u") as Expression)]), ASTFactory.block([])));
  }
  void test_visitForStatement_iu() {
    assertSource("for (var i;; u) {}", ASTFactory.forStatement2(ASTFactory.variableDeclarationList2(Keyword.VAR, [ASTFactory.variableDeclaration("i")]), null, ASTFactory.list([(ASTFactory.identifier3("u") as Expression)]), ASTFactory.block([])));
  }
  void test_visitForStatement_u() {
    assertSource("for (;; u) {}", ASTFactory.forStatement((null as Expression), null, ASTFactory.list([(ASTFactory.identifier3("u") as Expression)]), ASTFactory.block([])));
  }
  void test_visitFunctionDeclaration_getter() {
    assertSource("get f() {}", ASTFactory.functionDeclaration(null, Keyword.GET, "f", ASTFactory.functionExpression()));
  }
  void test_visitFunctionDeclaration_normal() {
    assertSource("f() {}", ASTFactory.functionDeclaration(null, null, "f", ASTFactory.functionExpression()));
  }
  void test_visitFunctionDeclaration_setter() {
    assertSource("set f() {}", ASTFactory.functionDeclaration(null, Keyword.SET, "f", ASTFactory.functionExpression()));
  }
  void test_visitFunctionDeclarationStatement() {
    assertSource("f() {};", ASTFactory.functionDeclarationStatement(null, null, "f", ASTFactory.functionExpression()));
  }
  void test_visitFunctionExpression() {
    assertSource("() {}", ASTFactory.functionExpression());
  }
  void test_visitFunctionExpressionInvocation() {
    assertSource("f()", ASTFactory.functionExpressionInvocation(ASTFactory.identifier3("f"), []));
  }
  void test_visitFunctionTypedFormalParameter_noType() {
    assertSource("f()", ASTFactory.functionTypedFormalParameter(null, "f", []));
  }
  void test_visitFunctionTypedFormalParameter_type() {
    assertSource("T f()", ASTFactory.functionTypedFormalParameter(ASTFactory.typeName4("T", []), "f", []));
  }
  void test_visitIfStatement_withElse() {
    assertSource("if (c) {} else {}", ASTFactory.ifStatement2(ASTFactory.identifier3("c"), ASTFactory.block([]), ASTFactory.block([])));
  }
  void test_visitIfStatement_withoutElse() {
    assertSource("if (c) {}", ASTFactory.ifStatement(ASTFactory.identifier3("c"), ASTFactory.block([])));
  }
  void test_visitImplementsClause_multiple() {
    assertSource("implements A, B", ASTFactory.implementsClause([ASTFactory.typeName4("A", []), ASTFactory.typeName4("B", [])]));
  }
  void test_visitImplementsClause_single() {
    assertSource("implements A", ASTFactory.implementsClause([ASTFactory.typeName4("A", [])]));
  }
  void test_visitImportDirective_combinator() {
    assertSource("import 'a.dart' show A;", ASTFactory.importDirective2("a.dart", null, [ASTFactory.showCombinator([ASTFactory.identifier3("A")])]));
  }
  void test_visitImportDirective_combinators() {
    assertSource("import 'a.dart' show A hide B;", ASTFactory.importDirective2("a.dart", null, [ASTFactory.showCombinator([ASTFactory.identifier3("A")]), ASTFactory.hideCombinator([ASTFactory.identifier3("B")])]));
  }
  void test_visitImportDirective_minimal() {
    assertSource("import 'a.dart';", ASTFactory.importDirective2("a.dart", null, []));
  }
  void test_visitImportDirective_prefix() {
    assertSource("import 'a.dart' as p;", ASTFactory.importDirective2("a.dart", "p", []));
  }
  void test_visitImportDirective_prefix_combinator() {
    assertSource("import 'a.dart' as p show A;", ASTFactory.importDirective2("a.dart", "p", [ASTFactory.showCombinator([ASTFactory.identifier3("A")])]));
  }
  void test_visitImportDirective_prefix_combinators() {
    assertSource("import 'a.dart' as p show A hide B;", ASTFactory.importDirective2("a.dart", "p", [ASTFactory.showCombinator([ASTFactory.identifier3("A")]), ASTFactory.hideCombinator([ASTFactory.identifier3("B")])]));
  }
  void test_visitImportHideCombinator_multiple() {
    assertSource("hide a, b", ASTFactory.hideCombinator([ASTFactory.identifier3("a"), ASTFactory.identifier3("b")]));
  }
  void test_visitImportHideCombinator_single() {
    assertSource("hide a", ASTFactory.hideCombinator([ASTFactory.identifier3("a")]));
  }
  void test_visitImportShowCombinator_multiple() {
    assertSource("show a, b", ASTFactory.showCombinator([ASTFactory.identifier3("a"), ASTFactory.identifier3("b")]));
  }
  void test_visitImportShowCombinator_single() {
    assertSource("show a", ASTFactory.showCombinator([ASTFactory.identifier3("a")]));
  }
  void test_visitIndexExpression() {
    assertSource("a[i]", ASTFactory.indexExpression(ASTFactory.identifier3("a"), ASTFactory.identifier3("i")));
  }
  void test_visitInstanceCreationExpression_const() {
    assertSource("const C()", ASTFactory.instanceCreationExpression2(Keyword.CONST, ASTFactory.typeName4("C", []), []));
  }
  void test_visitInstanceCreationExpression_named() {
    assertSource("new C.c()", ASTFactory.instanceCreationExpression3(Keyword.NEW, ASTFactory.typeName4("C", []), "c", []));
  }
  void test_visitInstanceCreationExpression_unnamed() {
    assertSource("new C()", ASTFactory.instanceCreationExpression2(Keyword.NEW, ASTFactory.typeName4("C", []), []));
  }
  void test_visitIntegerLiteral() {
    assertSource("42", ASTFactory.integer(42));
  }
  void test_visitInterpolationExpression_expression() {
    assertSource("\${a}", ASTFactory.interpolationExpression(ASTFactory.identifier3("a")));
  }
  void test_visitInterpolationExpression_identifier() {
    assertSource("\$a", ASTFactory.interpolationExpression2("a"));
  }
  void test_visitInterpolationString() {
    assertSource("'x", ASTFactory.interpolationString("'x", "x"));
  }
  void test_visitIsExpression_negated() {
    assertSource("a is! C", ASTFactory.isExpression(ASTFactory.identifier3("a"), true, ASTFactory.typeName4("C", [])));
  }
  void test_visitIsExpression_normal() {
    assertSource("a is C", ASTFactory.isExpression(ASTFactory.identifier3("a"), false, ASTFactory.typeName4("C", [])));
  }
  void test_visitLabel() {
    assertSource("a:", ASTFactory.label2("a"));
  }
  void test_visitLabeledStatement_multiple() {
    assertSource("a: b: return;", ASTFactory.labeledStatement(ASTFactory.list([ASTFactory.label2("a"), ASTFactory.label2("b")]), ASTFactory.returnStatement()));
  }
  void test_visitLabeledStatement_single() {
    assertSource("a: return;", ASTFactory.labeledStatement(ASTFactory.list([ASTFactory.label2("a")]), ASTFactory.returnStatement()));
  }
  void test_visitLibraryDirective() {
    assertSource("library l;", ASTFactory.libraryDirective2("l"));
  }
  void test_visitLibraryIdentifier_multiple() {
    assertSource("a.b.c", ASTFactory.libraryIdentifier([ASTFactory.identifier3("a"), ASTFactory.identifier3("b"), ASTFactory.identifier3("c")]));
  }
  void test_visitLibraryIdentifier_single() {
    assertSource("a", ASTFactory.libraryIdentifier([ASTFactory.identifier3("a")]));
  }
  void test_visitListLiteral_const() {
    assertSource("const []", ASTFactory.listLiteral2(Keyword.CONST, null, []));
  }
  void test_visitListLiteral_empty() {
    assertSource("[]", ASTFactory.listLiteral([]));
  }
  void test_visitListLiteral_nonEmpty() {
    assertSource("[a, b, c]", ASTFactory.listLiteral([ASTFactory.identifier3("a"), ASTFactory.identifier3("b"), ASTFactory.identifier3("c")]));
  }
  void test_visitMapLiteral_const() {
    assertSource("const {}", ASTFactory.mapLiteral(Keyword.CONST, null, []));
  }
  void test_visitMapLiteral_empty() {
    assertSource("{}", ASTFactory.mapLiteral2([]));
  }
  void test_visitMapLiteral_nonEmpty() {
    assertSource("{'a' : a, 'b' : b, 'c' : c}", ASTFactory.mapLiteral2([ASTFactory.mapLiteralEntry("a", ASTFactory.identifier3("a")), ASTFactory.mapLiteralEntry("b", ASTFactory.identifier3("b")), ASTFactory.mapLiteralEntry("c", ASTFactory.identifier3("c"))]));
  }
  void test_visitMapLiteralEntry() {
    assertSource("'a' : b", ASTFactory.mapLiteralEntry("a", ASTFactory.identifier3("b")));
  }
  void test_visitMethodDeclaration_external() {
    assertSource("external m();", ASTFactory.methodDeclaration(null, null, null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([])));
  }
  void test_visitMethodDeclaration_external_returnType() {
    assertSource("external T m();", ASTFactory.methodDeclaration(null, ASTFactory.typeName4("T", []), null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([])));
  }
  void test_visitMethodDeclaration_getter() {
    assertSource("get m {}", ASTFactory.methodDeclaration2(null, null, Keyword.GET, null, ASTFactory.identifier3("m"), null, ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_getter_returnType() {
    assertSource("T get m {}", ASTFactory.methodDeclaration2(null, ASTFactory.typeName4("T", []), Keyword.GET, null, ASTFactory.identifier3("m"), null, ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_getter_seturnType() {
    assertSource("T set m(var v) {}", ASTFactory.methodDeclaration2(null, ASTFactory.typeName4("T", []), Keyword.SET, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter(Keyword.VAR, "v")]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_minimal() {
    assertSource("m() {}", ASTFactory.methodDeclaration2(null, null, null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_multipleParameters() {
    assertSource("m(var a, var b) {}", ASTFactory.methodDeclaration2(null, null, null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter(Keyword.VAR, "a"), ASTFactory.simpleFormalParameter(Keyword.VAR, "b")]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_operator() {
    assertSource("operator +() {}", ASTFactory.methodDeclaration2(null, null, null, Keyword.OPERATOR, ASTFactory.identifier3("+"), ASTFactory.formalParameterList([]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_operator_returnType() {
    assertSource("T operator +() {}", ASTFactory.methodDeclaration2(null, ASTFactory.typeName4("T", []), null, Keyword.OPERATOR, ASTFactory.identifier3("+"), ASTFactory.formalParameterList([]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_returnType() {
    assertSource("T m() {}", ASTFactory.methodDeclaration2(null, ASTFactory.typeName4("T", []), null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_setter() {
    assertSource("set m(var v) {}", ASTFactory.methodDeclaration2(null, null, Keyword.SET, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([ASTFactory.simpleFormalParameter(Keyword.VAR, "v")]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_static() {
    assertSource("static m() {}", ASTFactory.methodDeclaration2(Keyword.STATIC, null, null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodDeclaration_static_returnType() {
    assertSource("static T m() {}", ASTFactory.methodDeclaration2(Keyword.STATIC, ASTFactory.typeName4("T", []), null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([]), ASTFactory.blockFunctionBody([])));
  }
  void test_visitMethodInvocation_noTarget() {
    assertSource("m()", ASTFactory.methodInvocation2("m", []));
  }
  void test_visitMethodInvocation_target() {
    assertSource("t.m()", ASTFactory.methodInvocation(ASTFactory.identifier3("t"), "m", []));
  }
  void test_visitNamedExpression() {
    assertSource("a: b", ASTFactory.namedExpression2("a", ASTFactory.identifier3("b")));
  }
  void test_visitNamedFormalParameter() {
    assertSource("var a : 0", ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter(Keyword.VAR, "a"), ASTFactory.integer(0)));
  }
  void test_visitNativeFunctionBody() {
    assertSource("native 'str';", ASTFactory.nativeFunctionBody("str"));
  }
  void test_visitNullLiteral() {
    assertSource("null", ASTFactory.nullLiteral());
  }
  void test_visitParenthesizedExpression() {
    assertSource("(a)", ASTFactory.parenthesizedExpression(ASTFactory.identifier3("a")));
  }
  void test_visitPartDirective() {
    assertSource("part 'a.dart';", ASTFactory.partDirective2("a.dart"));
  }
  void test_visitPartOfDirective() {
    assertSource("part of l;", ASTFactory.partOfDirective(ASTFactory.libraryIdentifier2(["l"])));
  }
  void test_visitPositionalFormalParameter() {
    assertSource("var a = 0", ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter(Keyword.VAR, "a"), ASTFactory.integer(0)));
  }
  void test_visitPostfixExpression() {
    assertSource("a++", ASTFactory.postfixExpression(ASTFactory.identifier3("a"), TokenType.PLUS_PLUS));
  }
  void test_visitPrefixedIdentifier() {
    assertSource("a.b", ASTFactory.identifier5("a", "b"));
  }
  void test_visitPrefixExpression() {
    assertSource("-a", ASTFactory.prefixExpression(TokenType.MINUS, ASTFactory.identifier3("a")));
  }
  void test_visitPropertyAccess() {
    assertSource("a.b", ASTFactory.propertyAccess2(ASTFactory.identifier3("a"), "b"));
  }
  void test_visitRedirectingConstructorInvocation_named() {
    assertSource("this.c()", ASTFactory.redirectingConstructorInvocation2("c", []));
  }
  void test_visitRedirectingConstructorInvocation_unnamed() {
    assertSource("this()", ASTFactory.redirectingConstructorInvocation([]));
  }
  void test_visitReturnStatement_expression() {
    assertSource("return a;", ASTFactory.returnStatement2(ASTFactory.identifier3("a")));
  }
  void test_visitReturnStatement_noExpression() {
    assertSource("return;", ASTFactory.returnStatement());
  }
  void test_visitScriptTag() {
    String scriptTag = "!#/bin/dart.exe";
    assertSource(scriptTag, ASTFactory.scriptTag(scriptTag));
  }
  void test_visitSimpleFormalParameter_keyword() {
    assertSource("var a", ASTFactory.simpleFormalParameter(Keyword.VAR, "a"));
  }
  void test_visitSimpleFormalParameter_keyword_type() {
    assertSource("final A a", ASTFactory.simpleFormalParameter2(Keyword.FINAL, ASTFactory.typeName4("A", []), "a"));
  }
  void test_visitSimpleFormalParameter_type() {
    assertSource("A a", ASTFactory.simpleFormalParameter4(ASTFactory.typeName4("A", []), "a"));
  }
  void test_visitSimpleIdentifier() {
    assertSource("a", ASTFactory.identifier3("a"));
  }
  void test_visitSimpleStringLiteral() {
    assertSource("'a'", ASTFactory.string2("a"));
  }
  void test_visitStringInterpolation() {
    assertSource("'a\${e}b'", ASTFactory.string([ASTFactory.interpolationString("'a", "a"), ASTFactory.interpolationExpression(ASTFactory.identifier3("e")), ASTFactory.interpolationString("b'", "b")]));
  }
  void test_visitSuperConstructorInvocation() {
    assertSource("super()", ASTFactory.superConstructorInvocation([]));
  }
  void test_visitSuperConstructorInvocation_named() {
    assertSource("super.c()", ASTFactory.superConstructorInvocation2("c", []));
  }
  void test_visitSuperExpression() {
    assertSource("super", ASTFactory.superExpression());
  }
  void test_visitSwitchCase_multipleLabels() {
    assertSource("l1: l2: case a: {}", ASTFactory.switchCase2(ASTFactory.list([ASTFactory.label2("l1"), ASTFactory.label2("l2")]), ASTFactory.identifier3("a"), [ASTFactory.block([])]));
  }
  void test_visitSwitchCase_multipleStatements() {
    assertSource("case a: {} {}", ASTFactory.switchCase(ASTFactory.identifier3("a"), [ASTFactory.block([]), ASTFactory.block([])]));
  }
  void test_visitSwitchCase_noLabels() {
    assertSource("case a: {}", ASTFactory.switchCase(ASTFactory.identifier3("a"), [ASTFactory.block([])]));
  }
  void test_visitSwitchCase_singleLabel() {
    assertSource("l1: case a: {}", ASTFactory.switchCase2(ASTFactory.list([ASTFactory.label2("l1")]), ASTFactory.identifier3("a"), [ASTFactory.block([])]));
  }
  void test_visitSwitchDefault_multipleLabels() {
    assertSource("l1: l2: default: {}", ASTFactory.switchDefault(ASTFactory.list([ASTFactory.label2("l1"), ASTFactory.label2("l2")]), [ASTFactory.block([])]));
  }
  void test_visitSwitchDefault_multipleStatements() {
    assertSource("default: {} {}", ASTFactory.switchDefault2([ASTFactory.block([]), ASTFactory.block([])]));
  }
  void test_visitSwitchDefault_noLabels() {
    assertSource("default: {}", ASTFactory.switchDefault2([ASTFactory.block([])]));
  }
  void test_visitSwitchDefault_singleLabel() {
    assertSource("l1: default: {}", ASTFactory.switchDefault(ASTFactory.list([ASTFactory.label2("l1")]), [ASTFactory.block([])]));
  }
  void test_visitSwitchStatement() {
    assertSource("switch (a) {case 'b': {} default: {}}", ASTFactory.switchStatement(ASTFactory.identifier3("a"), [ASTFactory.switchCase(ASTFactory.string2("b"), [ASTFactory.block([])]), ASTFactory.switchDefault2([ASTFactory.block([])])]));
  }
  void test_visitThisExpression() {
    assertSource("this", ASTFactory.thisExpression());
  }
  void test_visitThrowStatement() {
    assertSource("throw e", ASTFactory.throwExpression2(ASTFactory.identifier3("e")));
  }
  void test_visitTopLevelVariableDeclaration_multiple() {
    assertSource("var a;", ASTFactory.topLevelVariableDeclaration2(Keyword.VAR, [ASTFactory.variableDeclaration("a")]));
  }
  void test_visitTopLevelVariableDeclaration_single() {
    assertSource("var a, b;", ASTFactory.topLevelVariableDeclaration2(Keyword.VAR, [ASTFactory.variableDeclaration("a"), ASTFactory.variableDeclaration("b")]));
  }
  void test_visitTryStatement_catch() {
    assertSource("try {} on E {}", ASTFactory.tryStatement2(ASTFactory.block([]), [ASTFactory.catchClause3(ASTFactory.typeName4("E", []), [])]));
  }
  void test_visitTryStatement_catches() {
    assertSource("try {} on E {} on F {}", ASTFactory.tryStatement2(ASTFactory.block([]), [ASTFactory.catchClause3(ASTFactory.typeName4("E", []), []), ASTFactory.catchClause3(ASTFactory.typeName4("F", []), [])]));
  }
  void test_visitTryStatement_catchFinally() {
    assertSource("try {} on E {} finally {}", ASTFactory.tryStatement3(ASTFactory.block([]), ASTFactory.list([ASTFactory.catchClause3(ASTFactory.typeName4("E", []), [])]), ASTFactory.block([])));
  }
  void test_visitTryStatement_finally() {
    assertSource("try {} finally {}", ASTFactory.tryStatement(ASTFactory.block([]), ASTFactory.block([])));
  }
  void test_visitTypeAlias_generic() {
    assertSource("typedef A F<B>();", ASTFactory.typeAlias(ASTFactory.typeName4("A", []), "F", ASTFactory.typeParameterList(["B"]), ASTFactory.formalParameterList([])));
  }
  void test_visitTypeAlias_nonGeneric() {
    assertSource("typedef A F();", ASTFactory.typeAlias(ASTFactory.typeName4("A", []), "F", null, ASTFactory.formalParameterList([])));
  }
  void test_visitTypeArgumentList_multiple() {
    assertSource("<E, F>", ASTFactory.typeArgumentList([ASTFactory.typeName4("E", []), ASTFactory.typeName4("F", [])]));
  }
  void test_visitTypeArgumentList_single() {
    assertSource("<E>", ASTFactory.typeArgumentList([ASTFactory.typeName4("E", [])]));
  }
  void test_visitTypeName_multipleArgs() {
    assertSource("C<D, E>", ASTFactory.typeName4("C", [ASTFactory.typeName4("D", []), ASTFactory.typeName4("E", [])]));
  }
  void test_visitTypeName_nestedArg() {
    assertSource("C<D<E>>", ASTFactory.typeName4("C", [ASTFactory.typeName4("D", [ASTFactory.typeName4("E", [])])]));
  }
  void test_visitTypeName_noArgs() {
    assertSource("C", ASTFactory.typeName4("C", []));
  }
  void test_visitTypeName_singleArg() {
    assertSource("C<D>", ASTFactory.typeName4("C", [ASTFactory.typeName4("D", [])]));
  }
  void test_visitTypeParameter_withExtends() {
    assertSource("E extends C", ASTFactory.typeParameter2("E", ASTFactory.typeName4("C", [])));
  }
  void test_visitTypeParameter_withoutExtends() {
    assertSource("E", ASTFactory.typeParameter("E"));
  }
  void test_visitTypeParameterList_multiple() {
    assertSource("<E, F>", ASTFactory.typeParameterList(["E", "F"]));
  }
  void test_visitTypeParameterList_single() {
    assertSource("<E>", ASTFactory.typeParameterList(["E"]));
  }
  void test_visitVariableDeclaration_initialized() {
    assertSource("a = b", ASTFactory.variableDeclaration2("a", ASTFactory.identifier3("b")));
  }
  void test_visitVariableDeclaration_uninitialized() {
    assertSource("a", ASTFactory.variableDeclaration("a"));
  }
  void test_visitVariableDeclarationList_const_type() {
    assertSource("const C a, b", ASTFactory.variableDeclarationList(Keyword.CONST, ASTFactory.typeName4("C", []), [ASTFactory.variableDeclaration("a"), ASTFactory.variableDeclaration("b")]));
  }
  void test_visitVariableDeclarationList_final_noType() {
    assertSource("final a, b", ASTFactory.variableDeclarationList2(Keyword.FINAL, [ASTFactory.variableDeclaration("a"), ASTFactory.variableDeclaration("b")]));
  }
  void test_visitVariableDeclarationList_type() {
    assertSource("C a, b", ASTFactory.variableDeclarationList(null, ASTFactory.typeName4("C", []), [ASTFactory.variableDeclaration("a"), ASTFactory.variableDeclaration("b")]));
  }
  void test_visitVariableDeclarationList_var() {
    assertSource("var a, b", ASTFactory.variableDeclarationList2(Keyword.VAR, [ASTFactory.variableDeclaration("a"), ASTFactory.variableDeclaration("b")]));
  }
  void test_visitVariableDeclarationStatement() {
    assertSource("C c;", ASTFactory.variableDeclarationStatement(null, ASTFactory.typeName4("C", []), [ASTFactory.variableDeclaration("c")]));
  }
  void test_visitWhileStatement() {
    assertSource("while (c) {}", ASTFactory.whileStatement(ASTFactory.identifier3("c"), ASTFactory.block([])));
  }
  void test_visitWithClause_multiple() {
    assertSource("with A, B, C", ASTFactory.withClause([ASTFactory.typeName4("A", []), ASTFactory.typeName4("B", []), ASTFactory.typeName4("C", [])]));
  }
  void test_visitWithClause_single() {
    assertSource("with A", ASTFactory.withClause([ASTFactory.typeName4("A", [])]));
  }
  /**
   * Assert that a {@code ToSourceVisitor} will produce the expected source when visiting the given
   * node.
   * @param expectedSource the source string that the visitor is expected to produce
   * @param node the AST node being visited to produce the actual source
   * @throws AFE if the visitor does not produce the expected source for the given node
   */
  void assertSource(String expectedSource, ASTNode node) {
    PrintStringWriter writer = new PrintStringWriter();
    node.accept(new ToSourceVisitor(writer));
    JUnitTestCase.assertEquals(expectedSource, writer.toString());
  }
  static dartSuite() {
    _ut.group('ToSourceVisitorTest', () {
      _ut.test('test_visitAdjacentStrings', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitAdjacentStrings);
      });
      _ut.test('test_visitAnnotation_constant', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitAnnotation_constant);
      });
      _ut.test('test_visitAnnotation_constructor', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitAnnotation_constructor);
      });
      _ut.test('test_visitArgumentDefinitionTest', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitArgumentDefinitionTest);
      });
      _ut.test('test_visitArgumentList', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitArgumentList);
      });
      _ut.test('test_visitAsExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitAsExpression);
      });
      _ut.test('test_visitAssertStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitAssertStatement);
      });
      _ut.test('test_visitAssignmentExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitAssignmentExpression);
      });
      _ut.test('test_visitBinaryExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression);
      });
      _ut.test('test_visitBlockFunctionBody', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBlockFunctionBody);
      });
      _ut.test('test_visitBlock_empty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBlock_empty);
      });
      _ut.test('test_visitBlock_nonEmpty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBlock_nonEmpty);
      });
      _ut.test('test_visitBooleanLiteral_false', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBooleanLiteral_false);
      });
      _ut.test('test_visitBooleanLiteral_true', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBooleanLiteral_true);
      });
      _ut.test('test_visitBreakStatement_label', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBreakStatement_label);
      });
      _ut.test('test_visitBreakStatement_noLabel', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitBreakStatement_noLabel);
      });
      _ut.test('test_visitCascadeExpression_field', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCascadeExpression_field);
      });
      _ut.test('test_visitCascadeExpression_index', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCascadeExpression_index);
      });
      _ut.test('test_visitCascadeExpression_method', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCascadeExpression_method);
      });
      _ut.test('test_visitCatchClause_catch_noStack', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_catch_noStack);
      });
      _ut.test('test_visitCatchClause_catch_stack', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_catch_stack);
      });
      _ut.test('test_visitCatchClause_on', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_on);
      });
      _ut.test('test_visitCatchClause_on_catch', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_on_catch);
      });
      _ut.test('test_visitClassDeclaration_abstract', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_abstract);
      });
      _ut.test('test_visitClassDeclaration_empty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_empty);
      });
      _ut.test('test_visitClassDeclaration_extends', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_extends);
      });
      _ut.test('test_visitClassDeclaration_extends_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_extends_implements);
      });
      _ut.test('test_visitClassDeclaration_extends_with', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_extends_with);
      });
      _ut.test('test_visitClassDeclaration_extends_with_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_extends_with_implements);
      });
      _ut.test('test_visitClassDeclaration_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_implements);
      });
      _ut.test('test_visitClassDeclaration_multipleMember', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_multipleMember);
      });
      _ut.test('test_visitClassDeclaration_parameters', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_parameters);
      });
      _ut.test('test_visitClassDeclaration_parameters_extends', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_parameters_extends);
      });
      _ut.test('test_visitClassDeclaration_parameters_extends_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_parameters_extends_implements);
      });
      _ut.test('test_visitClassDeclaration_parameters_extends_with', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_parameters_extends_with);
      });
      _ut.test('test_visitClassDeclaration_parameters_extends_with_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_parameters_extends_with_implements);
      });
      _ut.test('test_visitClassDeclaration_parameters_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_parameters_implements);
      });
      _ut.test('test_visitClassDeclaration_singleMember', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration_singleMember);
      });
      _ut.test('test_visitClassTypeAlias_abstract', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_abstract);
      });
      _ut.test('test_visitClassTypeAlias_abstract_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_abstract_implements);
      });
      _ut.test('test_visitClassTypeAlias_generic', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_generic);
      });
      _ut.test('test_visitClassTypeAlias_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_implements);
      });
      _ut.test('test_visitClassTypeAlias_minimal', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_minimal);
      });
      _ut.test('test_visitClassTypeAlias_parameters_abstract', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_parameters_abstract);
      });
      _ut.test('test_visitClassTypeAlias_parameters_abstract_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_parameters_abstract_implements);
      });
      _ut.test('test_visitClassTypeAlias_parameters_implements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias_parameters_implements);
      });
      _ut.test('test_visitComment', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitComment);
      });
      _ut.test('test_visitCommentReference', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCommentReference);
      });
      _ut.test('test_visitCompilationUnit_declaration', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_declaration);
      });
      _ut.test('test_visitCompilationUnit_directive', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_directive);
      });
      _ut.test('test_visitCompilationUnit_directive_declaration', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_directive_declaration);
      });
      _ut.test('test_visitCompilationUnit_empty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_empty);
      });
      _ut.test('test_visitCompilationUnit_script', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_script);
      });
      _ut.test('test_visitCompilationUnit_script_declaration', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_script_declaration);
      });
      _ut.test('test_visitCompilationUnit_script_directive', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_script_directive);
      });
      _ut.test('test_visitCompilationUnit_script_directives_declarations', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitCompilationUnit_script_directives_declarations);
      });
      _ut.test('test_visitConditionalExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConditionalExpression);
      });
      _ut.test('test_visitConstructorDeclaration_const', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorDeclaration_const);
      });
      _ut.test('test_visitConstructorDeclaration_external', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorDeclaration_external);
      });
      _ut.test('test_visitConstructorDeclaration_minimal', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorDeclaration_minimal);
      });
      _ut.test('test_visitConstructorDeclaration_multipleInitializers', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorDeclaration_multipleInitializers);
      });
      _ut.test('test_visitConstructorDeclaration_multipleParameters', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorDeclaration_multipleParameters);
      });
      _ut.test('test_visitConstructorDeclaration_named', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorDeclaration_named);
      });
      _ut.test('test_visitConstructorDeclaration_singleInitializer', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorDeclaration_singleInitializer);
      });
      _ut.test('test_visitConstructorFieldInitializer_withThis', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorFieldInitializer_withThis);
      });
      _ut.test('test_visitConstructorFieldInitializer_withoutThis', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorFieldInitializer_withoutThis);
      });
      _ut.test('test_visitConstructorName_named_prefix', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorName_named_prefix);
      });
      _ut.test('test_visitConstructorName_unnamed_noPrefix', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorName_unnamed_noPrefix);
      });
      _ut.test('test_visitConstructorName_unnamed_prefix', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitConstructorName_unnamed_prefix);
      });
      _ut.test('test_visitContinueStatement_label', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitContinueStatement_label);
      });
      _ut.test('test_visitContinueStatement_noLabel', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitContinueStatement_noLabel);
      });
      _ut.test('test_visitDefaultFormalParameter_named_noValue', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitDefaultFormalParameter_named_noValue);
      });
      _ut.test('test_visitDefaultFormalParameter_named_value', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitDefaultFormalParameter_named_value);
      });
      _ut.test('test_visitDefaultFormalParameter_positional_noValue', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitDefaultFormalParameter_positional_noValue);
      });
      _ut.test('test_visitDefaultFormalParameter_positional_value', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitDefaultFormalParameter_positional_value);
      });
      _ut.test('test_visitDoStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitDoStatement);
      });
      _ut.test('test_visitDoubleLiteral', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitDoubleLiteral);
      });
      _ut.test('test_visitEmptyFunctionBody', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitEmptyFunctionBody);
      });
      _ut.test('test_visitEmptyStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitEmptyStatement);
      });
      _ut.test('test_visitExportDirective_combinator', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitExportDirective_combinator);
      });
      _ut.test('test_visitExportDirective_combinators', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitExportDirective_combinators);
      });
      _ut.test('test_visitExportDirective_minimal', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitExportDirective_minimal);
      });
      _ut.test('test_visitExpressionFunctionBody', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitExpressionFunctionBody);
      });
      _ut.test('test_visitExpressionStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitExpressionStatement);
      });
      _ut.test('test_visitExtendsClause', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitExtendsClause);
      });
      _ut.test('test_visitFieldDeclaration_instance', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFieldDeclaration_instance);
      });
      _ut.test('test_visitFieldDeclaration_static', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFieldDeclaration_static);
      });
      _ut.test('test_visitFieldFormalParameter_keyword', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFieldFormalParameter_keyword);
      });
      _ut.test('test_visitFieldFormalParameter_keywordAndType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFieldFormalParameter_keywordAndType);
      });
      _ut.test('test_visitFieldFormalParameter_type', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFieldFormalParameter_type);
      });
      _ut.test('test_visitForEachStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForEachStatement);
      });
      _ut.test('test_visitForStatement_c', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_c);
      });
      _ut.test('test_visitForStatement_cu', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_cu);
      });
      _ut.test('test_visitForStatement_e', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_e);
      });
      _ut.test('test_visitForStatement_ec', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_ec);
      });
      _ut.test('test_visitForStatement_ecu', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_ecu);
      });
      _ut.test('test_visitForStatement_eu', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_eu);
      });
      _ut.test('test_visitForStatement_i', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_i);
      });
      _ut.test('test_visitForStatement_ic', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_ic);
      });
      _ut.test('test_visitForStatement_icu', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_icu);
      });
      _ut.test('test_visitForStatement_iu', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_iu);
      });
      _ut.test('test_visitForStatement_u', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitForStatement_u);
      });
      _ut.test('test_visitFormalParameterList_empty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_empty);
      });
      _ut.test('test_visitFormalParameterList_n', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_n);
      });
      _ut.test('test_visitFormalParameterList_nn', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_nn);
      });
      _ut.test('test_visitFormalParameterList_p', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_p);
      });
      _ut.test('test_visitFormalParameterList_pp', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_pp);
      });
      _ut.test('test_visitFormalParameterList_r', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_r);
      });
      _ut.test('test_visitFormalParameterList_rn', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rn);
      });
      _ut.test('test_visitFormalParameterList_rnn', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rnn);
      });
      _ut.test('test_visitFormalParameterList_rp', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rp);
      });
      _ut.test('test_visitFormalParameterList_rpp', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rpp);
      });
      _ut.test('test_visitFormalParameterList_rr', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rr);
      });
      _ut.test('test_visitFormalParameterList_rrn', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rrn);
      });
      _ut.test('test_visitFormalParameterList_rrnn', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rrnn);
      });
      _ut.test('test_visitFormalParameterList_rrp', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rrp);
      });
      _ut.test('test_visitFormalParameterList_rrpp', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFormalParameterList_rrpp);
      });
      _ut.test('test_visitFunctionDeclarationStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionDeclarationStatement);
      });
      _ut.test('test_visitFunctionDeclaration_getter', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionDeclaration_getter);
      });
      _ut.test('test_visitFunctionDeclaration_normal', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionDeclaration_normal);
      });
      _ut.test('test_visitFunctionDeclaration_setter', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionDeclaration_setter);
      });
      _ut.test('test_visitFunctionExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression);
      });
      _ut.test('test_visitFunctionExpressionInvocation', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionExpressionInvocation);
      });
      _ut.test('test_visitFunctionTypedFormalParameter_noType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionTypedFormalParameter_noType);
      });
      _ut.test('test_visitFunctionTypedFormalParameter_type', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitFunctionTypedFormalParameter_type);
      });
      _ut.test('test_visitIfStatement_withElse', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitIfStatement_withElse);
      });
      _ut.test('test_visitIfStatement_withoutElse', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitIfStatement_withoutElse);
      });
      _ut.test('test_visitImplementsClause_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImplementsClause_multiple);
      });
      _ut.test('test_visitImplementsClause_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImplementsClause_single);
      });
      _ut.test('test_visitImportDirective_combinator', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportDirective_combinator);
      });
      _ut.test('test_visitImportDirective_combinators', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportDirective_combinators);
      });
      _ut.test('test_visitImportDirective_minimal', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportDirective_minimal);
      });
      _ut.test('test_visitImportDirective_prefix', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportDirective_prefix);
      });
      _ut.test('test_visitImportDirective_prefix_combinator', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportDirective_prefix_combinator);
      });
      _ut.test('test_visitImportDirective_prefix_combinators', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportDirective_prefix_combinators);
      });
      _ut.test('test_visitImportHideCombinator_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportHideCombinator_multiple);
      });
      _ut.test('test_visitImportHideCombinator_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportHideCombinator_single);
      });
      _ut.test('test_visitImportShowCombinator_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportShowCombinator_multiple);
      });
      _ut.test('test_visitImportShowCombinator_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitImportShowCombinator_single);
      });
      _ut.test('test_visitIndexExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitIndexExpression);
      });
      _ut.test('test_visitInstanceCreationExpression_const', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_const);
      });
      _ut.test('test_visitInstanceCreationExpression_named', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_named);
      });
      _ut.test('test_visitInstanceCreationExpression_unnamed', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_unnamed);
      });
      _ut.test('test_visitIntegerLiteral', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitIntegerLiteral);
      });
      _ut.test('test_visitInterpolationExpression_expression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitInterpolationExpression_expression);
      });
      _ut.test('test_visitInterpolationExpression_identifier', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitInterpolationExpression_identifier);
      });
      _ut.test('test_visitInterpolationString', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitInterpolationString);
      });
      _ut.test('test_visitIsExpression_negated', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitIsExpression_negated);
      });
      _ut.test('test_visitIsExpression_normal', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitIsExpression_normal);
      });
      _ut.test('test_visitLabel', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitLabel);
      });
      _ut.test('test_visitLabeledStatement_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitLabeledStatement_multiple);
      });
      _ut.test('test_visitLabeledStatement_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitLabeledStatement_single);
      });
      _ut.test('test_visitLibraryDirective', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitLibraryDirective);
      });
      _ut.test('test_visitLibraryIdentifier_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitLibraryIdentifier_multiple);
      });
      _ut.test('test_visitLibraryIdentifier_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitLibraryIdentifier_single);
      });
      _ut.test('test_visitListLiteral_const', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitListLiteral_const);
      });
      _ut.test('test_visitListLiteral_empty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitListLiteral_empty);
      });
      _ut.test('test_visitListLiteral_nonEmpty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitListLiteral_nonEmpty);
      });
      _ut.test('test_visitMapLiteralEntry', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMapLiteralEntry);
      });
      _ut.test('test_visitMapLiteral_const', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMapLiteral_const);
      });
      _ut.test('test_visitMapLiteral_empty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMapLiteral_empty);
      });
      _ut.test('test_visitMapLiteral_nonEmpty', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMapLiteral_nonEmpty);
      });
      _ut.test('test_visitMethodDeclaration_external', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_external);
      });
      _ut.test('test_visitMethodDeclaration_external_returnType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_external_returnType);
      });
      _ut.test('test_visitMethodDeclaration_getter', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_getter);
      });
      _ut.test('test_visitMethodDeclaration_getter_returnType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_getter_returnType);
      });
      _ut.test('test_visitMethodDeclaration_getter_seturnType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_getter_seturnType);
      });
      _ut.test('test_visitMethodDeclaration_minimal', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_minimal);
      });
      _ut.test('test_visitMethodDeclaration_multipleParameters', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_multipleParameters);
      });
      _ut.test('test_visitMethodDeclaration_operator', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_operator);
      });
      _ut.test('test_visitMethodDeclaration_operator_returnType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_operator_returnType);
      });
      _ut.test('test_visitMethodDeclaration_returnType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_returnType);
      });
      _ut.test('test_visitMethodDeclaration_setter', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_setter);
      });
      _ut.test('test_visitMethodDeclaration_static', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_static);
      });
      _ut.test('test_visitMethodDeclaration_static_returnType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodDeclaration_static_returnType);
      });
      _ut.test('test_visitMethodInvocation_noTarget', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodInvocation_noTarget);
      });
      _ut.test('test_visitMethodInvocation_target', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitMethodInvocation_target);
      });
      _ut.test('test_visitNamedExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitNamedExpression);
      });
      _ut.test('test_visitNamedFormalParameter', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitNamedFormalParameter);
      });
      _ut.test('test_visitNativeFunctionBody', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitNativeFunctionBody);
      });
      _ut.test('test_visitNullLiteral', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitNullLiteral);
      });
      _ut.test('test_visitParenthesizedExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitParenthesizedExpression);
      });
      _ut.test('test_visitPartDirective', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitPartDirective);
      });
      _ut.test('test_visitPartOfDirective', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitPartOfDirective);
      });
      _ut.test('test_visitPositionalFormalParameter', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitPositionalFormalParameter);
      });
      _ut.test('test_visitPostfixExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitPostfixExpression);
      });
      _ut.test('test_visitPrefixExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression);
      });
      _ut.test('test_visitPrefixedIdentifier', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitPrefixedIdentifier);
      });
      _ut.test('test_visitPropertyAccess', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitPropertyAccess);
      });
      _ut.test('test_visitRedirectingConstructorInvocation_named', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitRedirectingConstructorInvocation_named);
      });
      _ut.test('test_visitRedirectingConstructorInvocation_unnamed', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitRedirectingConstructorInvocation_unnamed);
      });
      _ut.test('test_visitReturnStatement_expression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitReturnStatement_expression);
      });
      _ut.test('test_visitReturnStatement_noExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitReturnStatement_noExpression);
      });
      _ut.test('test_visitScriptTag', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitScriptTag);
      });
      _ut.test('test_visitSimpleFormalParameter_keyword', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSimpleFormalParameter_keyword);
      });
      _ut.test('test_visitSimpleFormalParameter_keyword_type', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSimpleFormalParameter_keyword_type);
      });
      _ut.test('test_visitSimpleFormalParameter_type', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSimpleFormalParameter_type);
      });
      _ut.test('test_visitSimpleIdentifier', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSimpleIdentifier);
      });
      _ut.test('test_visitSimpleStringLiteral', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSimpleStringLiteral);
      });
      _ut.test('test_visitStringInterpolation', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitStringInterpolation);
      });
      _ut.test('test_visitSuperConstructorInvocation', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSuperConstructorInvocation);
      });
      _ut.test('test_visitSuperConstructorInvocation_named', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSuperConstructorInvocation_named);
      });
      _ut.test('test_visitSuperExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSuperExpression);
      });
      _ut.test('test_visitSwitchCase_multipleLabels', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchCase_multipleLabels);
      });
      _ut.test('test_visitSwitchCase_multipleStatements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchCase_multipleStatements);
      });
      _ut.test('test_visitSwitchCase_noLabels', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchCase_noLabels);
      });
      _ut.test('test_visitSwitchCase_singleLabel', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchCase_singleLabel);
      });
      _ut.test('test_visitSwitchDefault_multipleLabels', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchDefault_multipleLabels);
      });
      _ut.test('test_visitSwitchDefault_multipleStatements', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchDefault_multipleStatements);
      });
      _ut.test('test_visitSwitchDefault_noLabels', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchDefault_noLabels);
      });
      _ut.test('test_visitSwitchDefault_singleLabel', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchDefault_singleLabel);
      });
      _ut.test('test_visitSwitchStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitSwitchStatement);
      });
      _ut.test('test_visitThisExpression', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitThisExpression);
      });
      _ut.test('test_visitThrowStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitThrowStatement);
      });
      _ut.test('test_visitTopLevelVariableDeclaration_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTopLevelVariableDeclaration_multiple);
      });
      _ut.test('test_visitTopLevelVariableDeclaration_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTopLevelVariableDeclaration_single);
      });
      _ut.test('test_visitTryStatement_catch', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTryStatement_catch);
      });
      _ut.test('test_visitTryStatement_catchFinally', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTryStatement_catchFinally);
      });
      _ut.test('test_visitTryStatement_catches', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTryStatement_catches);
      });
      _ut.test('test_visitTryStatement_finally', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTryStatement_finally);
      });
      _ut.test('test_visitTypeAlias_generic', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeAlias_generic);
      });
      _ut.test('test_visitTypeAlias_nonGeneric', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeAlias_nonGeneric);
      });
      _ut.test('test_visitTypeArgumentList_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeArgumentList_multiple);
      });
      _ut.test('test_visitTypeArgumentList_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeArgumentList_single);
      });
      _ut.test('test_visitTypeName_multipleArgs', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_multipleArgs);
      });
      _ut.test('test_visitTypeName_nestedArg', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_nestedArg);
      });
      _ut.test('test_visitTypeName_noArgs', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_noArgs);
      });
      _ut.test('test_visitTypeName_singleArg', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_singleArg);
      });
      _ut.test('test_visitTypeParameterList_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeParameterList_multiple);
      });
      _ut.test('test_visitTypeParameterList_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeParameterList_single);
      });
      _ut.test('test_visitTypeParameter_withExtends', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeParameter_withExtends);
      });
      _ut.test('test_visitTypeParameter_withoutExtends', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeParameter_withoutExtends);
      });
      _ut.test('test_visitVariableDeclarationList_const_type', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitVariableDeclarationList_const_type);
      });
      _ut.test('test_visitVariableDeclarationList_final_noType', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitVariableDeclarationList_final_noType);
      });
      _ut.test('test_visitVariableDeclarationList_type', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitVariableDeclarationList_type);
      });
      _ut.test('test_visitVariableDeclarationList_var', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitVariableDeclarationList_var);
      });
      _ut.test('test_visitVariableDeclarationStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitVariableDeclarationStatement);
      });
      _ut.test('test_visitVariableDeclaration_initialized', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitVariableDeclaration_initialized);
      });
      _ut.test('test_visitVariableDeclaration_uninitialized', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitVariableDeclaration_uninitialized);
      });
      _ut.test('test_visitWhileStatement', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitWhileStatement);
      });
      _ut.test('test_visitWithClause_multiple', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitWithClause_multiple);
      });
      _ut.test('test_visitWithClause_single', () {
        final __test = new ToSourceVisitorTest();
        runJUnitTest(__test, __test.test_visitWithClause_single);
      });
    });
  }
}
main() {
  ConstantEvaluatorTest.dartSuite();
  NodeLocatorTest.dartSuite();
  ToSourceVisitorTest.dartSuite();
  IndexExpressionTest.dartSuite();
  SimpleIdentifierTest.dartSuite();
}