// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show AbstractScanner;
import 'package:_fe_analyzer_shared/src/scanner/errors.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerResult, scanString;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart'
    show InstanceCreationExpressionImpl;
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'test_support.dart';

main() {
  // The fasta parser has a parallel set of tests in parser_fasta_test.dart
  if (Parser.useFasta) {
    test('useFasta', () => true);
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest);
    defineReflectiveTests(ComplexParserTest);
    defineReflectiveTests(ErrorParserTest);
    defineReflectiveTests(ExpressionParserTest);
    defineReflectiveTests(FormalParameterParserTest);
    defineReflectiveTests(NonErrorParserTest);
    defineReflectiveTests(RecoveryParserTest);
    defineReflectiveTests(SimpleParserTest);
    defineReflectiveTests(StatementParserTest);
    defineReflectiveTests(TopLevelParserTest);
  });
}

/// Abstract base class for parser tests, which does not make assumptions about
/// which parser is used.
abstract class AbstractParserTestCase implements ParserTestHelpers {
  bool get allowNativeClause;

  set allowNativeClause(bool value);

  /// Set a flag indicating whether the parser should parse instance creation
  /// expressions that lack either the `new` or `const` keyword.
  set enableOptionalNewAndConst(bool value);

  /// Set a flag indicating whether the parser is to parse part-of directives
  /// that specify a URI rather than a library name.
  set enableUriInPartOf(bool value);

  /// The error listener to which scanner and parser errors will be reported.
  ///
  /// This field is typically initialized by invoking [createParser].
  GatheringErrorListener get listener;

  /// Get the parser used by the test.
  ///
  /// Caller must first invoke [createParser].
  Parser get parser;

  /// Flag indicating whether the fasta parser is being used.
  bool get usingFastaParser;

  /// Assert that the number and codes of errors occurred during parsing is the
  /// same as the [expectedErrorCodes].
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes);

  /// Asserts that no errors occurred during parsing.
  void assertNoErrors();

  /// Prepares to parse using tokens scanned from the given [content] string.
  ///
  /// [expectedEndOffset] is the expected offset of the next token to be parsed
  /// after the parser has finished parsing,
  /// or `null` (the default) if EOF is expected.
  /// In general, the analyzer tests do not assert that the last token is EOF,
  /// but the fasta parser adapter tests do assert this.
  /// For any analyzer test where the last token is not EOF, set this value.
  /// It is ignored when not using the fasta parser.
  void createParser(
    String content, {
    int expectedEndOffset,
    FeatureSet featureSet,
  });

  ExpectedError expectedError(ErrorCode code, int offset, int length);

  void expectNotNullIfNoErrors(Object result);

  Expression parseAdditiveExpression(String code);

  Expression parseAssignableExpression(String code, bool primaryAllowed);

  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional = true});

  AwaitExpression parseAwaitExpression(String code);

  Expression parseBitwiseAndExpression(String code);

  Expression parseBitwiseOrExpression(String code);

  Expression parseBitwiseXorExpression(String code);

  Expression parseCascadeSection(String code);

  CommentReference parseCommentReference(
      String referenceSource, int sourceOffset);

  CompilationUnit parseCompilationUnit(String source,
      {List<ErrorCode> codes, List<ExpectedError> errors});

  ConditionalExpression parseConditionalExpression(String code);

  Expression parseConstExpression(String code);

  ConstructorInitializer parseConstructorInitializer(String code);

  /// Parse the given source as a compilation unit.
  ///
  /// @param source the source to be parsed
  /// @param errorCodes the error codes of the errors that are expected to be
  ///          found
  /// @return the compilation unit that was parsed
  /// @throws Exception if the source could not be parsed, if the compilation
  ///           errors in the source do not match those that are expected, or if
  ///           the result would have been `null`
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]);

  BinaryExpression parseEqualityExpression(String code);

  Expression parseExpression(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset});

  List<Expression> parseExpressionList(String code);

  Expression parseExpressionWithoutCascade(String code);

  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes = const <ErrorCode>[]});

  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[],
      List<ExpectedError> errors});

  /// Parses a single top level member of a compilation unit (other than a
  /// directive), including any comment and/or metadata that precedes it.
  CompilationUnitMember parseFullCompilationUnitMember();

  /// Parses a single top level directive, including any comment and/or metadata
  /// that precedes it.
  Directive parseFullDirective();

  FunctionExpression parseFunctionExpression(String code);

  InstanceCreationExpression parseInstanceCreationExpression(
      String code, Token newToken);

  ListLiteral parseListLiteral(
      Token token, String typeArgumentsCode, String code);

  TypedLiteral parseListOrMapLiteral(Token modifier, String code);

  Expression parseLogicalAndExpression(String code);

  Expression parseLogicalOrExpression(String code);

  SetOrMapLiteral parseMapLiteral(
      Token token, String typeArgumentsCode, String code);

  MapLiteralEntry parseMapLiteralEntry(String code);

  Expression parseMultiplicativeExpression(String code);

  InstanceCreationExpression parseNewExpression(String code);

  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[]});

  Expression parsePostfixExpression(String code);

  Identifier parsePrefixedIdentifier(String code);

  Expression parsePrimaryExpression(String code,
      {int expectedEndOffset, List<ExpectedError> errors});

  Expression parseRelationalExpression(String code);

  RethrowExpression parseRethrowExpression(String code);

  BinaryExpression parseShiftExpression(String code);

  SimpleIdentifier parseSimpleIdentifier(String code);

  Statement parseStatement(String source, {int expectedEndOffset});

  Expression parseStringLiteral(String code);

  SymbolLiteral parseSymbolLiteral(String code);

  Expression parseThrowExpression(String code);

  Expression parseThrowExpressionWithoutCascade(String code);

  PrefixExpression parseUnaryExpression(String code);

  VariableDeclarationList parseVariableDeclarationList(String source);
}

/// Instances of the class `AstValidator` are used to validate the correct
/// construction of an AST structure.
class AstValidator extends UnifyingAstVisitor<void> {
  /// A list containing the errors found while traversing the AST structure.
  final List<String> _errors = <String>[];

  /// Assert that no errors were found while traversing any of the AST
  /// structures that have been visited.
  void assertValid() {
    if (_errors.isNotEmpty) {
      StringBuffer buffer = StringBuffer();
      buffer.write("Invalid AST structure:");
      for (String message in _errors) {
        buffer.write("\r\n   ");
        buffer.write(message);
      }
      fail(buffer.toString());
    }
  }

  @override
  void visitNode(AstNode node) {
    _validate(node);
    super.visitNode(node);
  }

  /// Validate that the given AST node is correctly constructed.
  ///
  /// @param node the AST node being validated
  void _validate(AstNode node) {
    AstNode parent = node.parent;
    if (node is CompilationUnit) {
      if (parent != null) {
        _errors.add("Compilation units should not have a parent");
      }
    } else {
      if (parent == null) {
        _errors.add("No parent for ${node.runtimeType}");
      }
    }
    if (node.beginToken == null) {
      _errors.add("No begin token for ${node.runtimeType}");
    }
    if (node.endToken == null) {
      _errors.add("No end token for ${node.runtimeType}");
    }
    int nodeStart = node.offset;
    int nodeLength = node.length;
    if (nodeStart < 0 || nodeLength < 0) {
      _errors.add("No source info for ${node.runtimeType}");
    }
    if (parent != null) {
      int nodeEnd = nodeStart + nodeLength;
      int parentStart = parent.offset;
      int parentEnd = parentStart + parent.length;
      if (nodeStart < parentStart) {
        _errors.add(
            "Invalid source start ($nodeStart) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
      }
      if (nodeEnd > parentEnd) {
        _errors.add(
            "Invalid source end ($nodeEnd) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
      }
    }
  }
}

@reflectiveTest
class ClassMemberParserTest extends ParserTestCase
    with ClassMemberParserTestMixin {
  @failingTest
  @override
  void test_parseAwaitExpression_inSync() {
    super.test_parseAwaitExpression_inSync();
  }
}

/// Tests which exercise the parser using a class member.
mixin ClassMemberParserTestMixin implements AbstractParserTestCase {
  void test_parseAwaitExpression_asStatement_inAsync() {
    createParser('m() async { await x; }');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    FunctionBody body = method.body;
    expect(body, isBlockFunctionBody);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    expect(statement, isExpressionStatement);
    Expression expression = (statement as ExpressionStatement).expression;
    expect(expression, isAwaitExpression);
    expect((expression as AwaitExpression).awaitKeyword, isNotNull);
    expect((expression as AwaitExpression).expression, isNotNull);
  }

  void test_parseAwaitExpression_asStatement_inSync() {
    createParser('m() { await x; }');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    FunctionBody body = method.body;
    expect(body, isBlockFunctionBody);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    expect(statement, isVariableDeclarationStatement);
  }

  void test_parseAwaitExpression_inSync() {
    createParser('m() { return await x + await y; }');
    MethodDeclaration method = parser.parseClassMember('C');
    expect(method, isNotNull);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 13, 5),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 23, 5)
          ]
        : [
            // This test requires better error recovery than we currently have.
            // In particular, we need to be able to distinguish
            // between an await expression in the wrong context,
            // and the use of 'await' as an identifier.
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 5),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 29, 1)
          ]);
    FunctionBody body = method.body;
    expect(body, isBlockFunctionBody);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    expect(statement, isReturnStatement);
    Expression expression = (statement as ReturnStatement).expression;
    expect(expression, isBinaryExpression);
    if (!usingFastaParser) {
      // TODO(danrubel): capture `await` keywords in fasta generated AST
      expect((expression as BinaryExpression).leftOperand, isAwaitExpression);
      expect((expression as BinaryExpression).rightOperand, isAwaitExpression);
    }
  }

  void test_parseClassMember_constructor_withDocComment() {
    createParser('/// Doc\nC();');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    expectCommentText(constructor.documentationComment, '/// Doc');
  }

  void test_parseClassMember_constructor_withInitializers() {
    // TODO(brianwilkerson) Test other kinds of class members: fields, getters
    // and setters.
    createParser('C(_, _\$, this.__) : _a = _ + _\$ {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member;
    expect(constructor.body, isNotNull);
    expect(constructor.separator, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.period, isNull);
    expect(constructor.returnType, isNotNull);
    expect(constructor.initializers, hasLength(1));
  }

  void test_parseClassMember_field_covariant() {
    createParser('covariant T f;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNotNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_generic() {
    createParser('List<List<N>> _allComponents = new List<List<N>>();');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    TypeName type = list.type;
    expect(type.name.name, 'List');
    NodeList typeArguments = type.typeArguments.arguments;
    expect(typeArguments, hasLength(1));
    TypeName type2 = typeArguments[0];
    expect(type2.name.name, 'List');
    NodeList typeArguments2 = type2.typeArguments.arguments;
    expect(typeArguments2, hasLength(1));
    TypeName type3 = typeArguments2[0];
    expect(type3.name.name, 'N');
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_gftType_gftReturnType() {
    createParser('''
Function(int) Function(String) v;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isFieldDeclaration);
    VariableDeclarationList fields = (member as FieldDeclaration).fields;
    expect(fields.type, isGenericFunctionType);
  }

  void test_parseClassMember_field_gftType_noReturnType() {
    createParser('''
Function(int, String) v;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isFieldDeclaration);
    VariableDeclarationList fields = (member as FieldDeclaration).fields;
    expect(fields.type, isGenericFunctionType);
  }

  void test_parseClassMember_field_instance_prefixedType() {
    createParser('p.A f;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
    _assertIsDeclarationName(variable.name);
  }

  void test_parseClassMember_field_namedGet() {
    createParser('var get;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_namedOperator() {
    createParser('var operator;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_namedOperator_withAssignment() {
    createParser('var operator = (5);');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
    expect(variable.initializer, isNotNull);
  }

  void test_parseClassMember_field_namedSet() {
    createParser('var set;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_nameKeyword() {
    createParser('var for;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 3)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 3),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 4, 3)
          ]);
  }

  void test_parseClassMember_field_nameMissing() {
    createParser('var ;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)]);
  }

  void test_parseClassMember_field_nameMissing2() {
    createParser('var "";');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 2)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 2),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 4, 2)
          ]);
  }

  void test_parseClassMember_field_static() {
    createParser('static A f;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNotNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isFalse);
    expect(list.lateKeyword, isNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_getter_functionType() {
    createParser('int Function(int) get g {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.body, isNotNull);
    expect(method.parameters, isNull);
  }

  void test_parseClassMember_getter_void() {
    createParser('void get g {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    _assertIsDeclarationName(method.name);
    expect(method.operatorKeyword, isNull);
    expect(method.body, isNotNull);
    expect(method.parameters, isNull);
  }

  void test_parseClassMember_method_external() {
    createParser('external m();');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    _assertIsDeclarationName(method.name);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);

    var body = method.body as EmptyFunctionBody;
    expect(body.keyword, isNull);
    expect(body.star, isNull);
    expect(body.semicolon.type, TokenType.SEMICOLON);
  }

  void test_parseClassMember_method_external_withTypeAndArgs() {
    createParser('external int m(int a);');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.body, isNotNull);
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
  }

  void test_parseClassMember_method_generic_noReturnType() {
    createParser('m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_parameterType() {
    createParser('m<T>(T p) => null;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);

    FormalParameterList parameters = method.parameters;
    expect(parameters, isNotNull);
    expect(parameters.parameters, hasLength(1));
    var parameter = parameters.parameters[0] as SimpleFormalParameter;
    var parameterType = parameter.type as TypeName;
    expect(parameterType.name.name, 'T');

    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType() {
    createParser('T m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType_bound() {
    createParser('T m<T extends num>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect((method.returnType as TypeName).name.name, 'T');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    TypeParameter tp = method.typeParameters.typeParameters[0];
    expect(tp.name.name, 'T');
    expect(tp.extendsKeyword, isNotNull);
    expect((tp.bound as TypeName).name.name, 'num');
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType_complex() {
    createParser('Map<int, T> m<T>() => null;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);

    {
      var returnType = method.returnType as TypeName;
      expect(returnType, isNotNull);
      expect(returnType.name.name, 'Map');

      List<TypeAnnotation> typeArguments = returnType.typeArguments.arguments;
      expect(typeArguments, hasLength(2));
      expect((typeArguments[0] as TypeName).name.name, 'int');
      expect((typeArguments[1] as TypeName).name.name, 'T');
    }

    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType_static() {
    createParser('static T m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect((method.returnType as TypeName).name.name, 'T');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_void() {
    createParser('void m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_noType() {
    createParser('get() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_static_namedAsClass() {
    createParser('static int get C => 0;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 15, 1),
      ]);
    } else {
      assertNoErrors();
    }
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_type() {
    createParser('int get() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_void() {
    createParser('void get() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_gftReturnType_noReturnType() {
    createParser('''
Function<A>(core.List<core.int> x) m() => null;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isMethodDeclaration);
    expect((member as MethodDeclaration).body, isExpressionFunctionBody);
  }

  void test_parseClassMember_method_gftReturnType_voidReturnType() {
    createParser('''
void Function<A>(core.List<core.int> x) m() => null;
''');
    ClassMember member = parser.parseClassMember('C');
    assertNoErrors();
    expect(member, isMethodDeclaration);
    expect((member as MethodDeclaration).body, isExpressionFunctionBody);
  }

  void test_parseClassMember_method_native_allowed() {
    allowNativeClause = true;
    _parseClassMember_method_native();
    assertNoErrors();
  }

  void test_parseClassMember_method_native_missing_literal_allowed() {
    allowNativeClause = true;
    _parseClassMember_method_native_missing_literal();
    assertNoErrors();
  }

  void test_parseClassMember_method_native_missing_literal_not_allowed() {
    allowNativeClause = false;
    _parseClassMember_method_native_missing_literal();
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, 4, 6),
      ]);
    } else {
      assertNoErrors();
    }
  }

  void test_parseClassMember_method_native_not_allowed() {
    allowNativeClause = false;
    _parseClassMember_method_native();
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, 4, 6),
      ]);
    } else {
      assertNoErrors();
    }
  }

  void test_parseClassMember_method_native_with_body_allowed() {
    allowNativeClause = true;
    _parseClassMember_method_native_with_body();
    if (usingFastaParser) {
      // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
      assertErrorsWithCodes([
        ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
      ]);
//      listener.assertErrors([
//        expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 17, 2),
//      ]);
    } else {
      assertErrorsWithCodes([
        ParserErrorCode.EXPECTED_TOKEN,
      ]);
    }
  }

  void test_parseClassMember_method_native_with_body_not_allowed() {
    allowNativeClause = false;
    _parseClassMember_method_native_with_body();
    if (usingFastaParser) {
      // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
        ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
      ]);
//      listener.assertErrors([
//        expectedError(ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, 4, 6),
//        expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 17, 2),
//      ]);
    } else {
      assertErrorsWithCodes([
        ParserErrorCode.EXPECTED_TOKEN,
      ]);
    }
  }

  void test_parseClassMember_method_operator_noType() {
    createParser('operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_type() {
    createParser('int operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_void() {
    createParser('void operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_returnType_functionType() {
    createParser('int Function(String) m() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.name.name, 'm');
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_returnType_parameterized() {
    createParser('p.A m() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_noType() {
    createParser('set() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_static_namedAsClass() {
    createParser('static void set C(_) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
      ]);
    } else {
      assertNoErrors();
    }
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_type() {
    createParser('int set() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_void() {
    createParser('void set() {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_static_class() {
    var unit = parseCompilationUnit('class C { static void m() {} }');

    ClassDeclaration c = unit.declarations[0];
    MethodDeclaration method = c.members[0];
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_static_mixin() {
    if (!usingFastaParser) return;
    var unit = parseCompilationUnit('mixin C { static void m() {} }');
    MixinDeclaration c = unit.declarations[0];
    MethodDeclaration method = c.members[0];
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_trailing_commas() {
    createParser('void f(int x, int y,) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_functionType() {
    createParser('int Function() operator +(int Function() f) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isGenericFunctionType);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    NodeList<FormalParameter> parameters = method.parameters.parameters;
    expect(parameters, hasLength(1));
    expect(
        (parameters[0] as SimpleFormalParameter).type, isGenericFunctionType);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_index() {
    createParser('int operator [](int i) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_indexAssign() {
    createParser('int operator []=(int i) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_lessThan() {
    createParser('bool operator <(other) => false;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.name, '<');
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_redirectingFactory_const() {
    createParser('const factory C() = prefix.B.foo;');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword.keyword, Keyword.CONST);
    expect(constructor.factoryKeyword.keyword, Keyword.FACTORY);
    expect(constructor.returnType.name, 'C');
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    _assertIsDeclarationName(constructor.returnType, false);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator.type, TokenType.EQ);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNotNull);
    expect(constructor.redirectedConstructor.type.name.name, 'prefix.B');
    expect(constructor.redirectedConstructor.period.type, TokenType.PERIOD);
    expect(constructor.redirectedConstructor.name.name, 'foo');
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseClassMember_redirectingFactory_expressionBody() {
    createParser('factory C() => throw 0;');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword.keyword, Keyword.FACTORY);
    expect(constructor.returnType.name, 'C');
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);

    var body = constructor.body as ExpressionFunctionBody;
    expect(body.keyword, isNull);
    expect(body.star, isNull);
    expect(body.functionDefinition.type, TokenType.FUNCTION);
    expect(body.expression, isNotNull);
    expect(body.semicolon, isNotNull);
  }

  void test_parseClassMember_redirectingFactory_nonConst() {
    createParser('factory C() = B;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member;
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword.keyword, Keyword.FACTORY);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType, false);
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator.type, TokenType.EQ);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNotNull);
    expect(constructor.redirectedConstructor.type.name.name, 'B');
    expect(constructor.redirectedConstructor.period, isNull);
    expect(constructor.redirectedConstructor.name, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_assert() {
    createParser('C(x, y) : _x = x, assert (x < y), _y = y;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(3));
    ConstructorInitializer initializer = initializers[1];
    expect(initializer, isAssertInitializer);
    AssertInitializer assertInitializer = initializer;
    expect(assertInitializer.condition, isNotNull);
    expect(assertInitializer.message, isNull);
  }

  void test_parseConstructor_factory_const_external() {
    // Although the spec does not allow external const factory,
    // there are several instances of this in the Dart SDK.
    // For example `external const factory bool.fromEnvironment(...)`.
    createParser('external const factory C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    assertNoErrors();
  }

  void test_parseConstructor_factory_named() {
    createParser('factory C.foo() => throw 0;');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNotNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType, false);
    expect(constructor.period.type, TokenType.PERIOD);
    expect(constructor.name.name, 'foo');
    _assertIsDeclarationName(constructor.name);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isExpressionFunctionBody);
  }

  void test_parseConstructor_initializers_field() {
    createParser('C(x, y) : _x = x, this._y = y;');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(2));

    {
      var initializer = initializers[0] as ConstructorFieldInitializer;
      expect(initializer.thisKeyword, isNull);
      expect(initializer.period, isNull);
      expect(initializer.fieldName.name, '_x');
      expect(initializer.expression, isNotNull);
    }

    {
      var initializer = initializers[1] as ConstructorFieldInitializer;
      expect(initializer.thisKeyword, isNotNull);
      expect(initializer.period, isNotNull);
      expect(initializer.fieldName.name, '_y');
      expect(initializer.expression, isNotNull);
    }
  }

  void test_parseConstructor_named() {
    createParser('C.foo();');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType, false);
    expect(constructor.period.type, TokenType.PERIOD);
    expect(constructor.name.name, 'foo');
    _assertIsDeclarationName(constructor.name);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_superIndexed() {
    createParser('C() : super()[];');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    listener.assertErrors([
      expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 6, 5),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 14, 1),
    ]);
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType, false);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator.lexeme, ':');
    expect(constructor.initializers, hasLength(1));
    SuperConstructorInvocation initializer = constructor.initializers[0];
    expect(initializer.argumentList.arguments, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_thisIndexed() {
    createParser('C() : this()[];');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    listener.assertErrors([
      expectedError(ParserErrorCode.INVALID_THIS_IN_INITIALIZER, 6, 4),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
    ]);
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType, false);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator.lexeme, ':');
    expect(constructor.initializers, hasLength(1));
    RedirectingConstructorInvocation initializer = constructor.initializers[0];
    expect(initializer.argumentList.arguments, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_unnamed() {
    createParser('C();');
    var constructor = parser.parseClassMember('C') as ConstructorDeclaration;
    assertNoErrors();
    expect(constructor, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.returnType.name, 'C');
    _assertIsDeclarationName(constructor.returnType, false);
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, isEmpty);
    expect(constructor.separator, isNull);
    expect(constructor.initializers, isEmpty);
    expect(constructor.redirectedConstructor, isNull);
    expect(constructor.body, isEmptyFunctionBody);
  }

  void test_parseConstructor_with_pseudo_function_literal() {
    // "(b) {}" should not be misinterpreted as a function literal even though
    // it looks like one.
    createParser('C() : a = (b) {}');
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isConstructorDeclaration);
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(1));
    ConstructorInitializer initializer = initializers[0];
    expect(initializer, isConstructorFieldInitializer);
    expect((initializer as ConstructorFieldInitializer).expression,
        isParenthesizedExpression);
    expect(constructor.body, isBlockFunctionBody);
  }

  void test_parseConstructorFieldInitializer_qualified() {
    var initializer = parseConstructorInitializer('this.a = b')
        as ConstructorFieldInitializer;
    expect(initializer, isNotNull);
    assertNoErrors();
    expect(initializer.equals, isNotNull);
    expect(initializer.expression, isNotNull);
    expect(initializer.fieldName, isNotNull);
    expect(initializer.thisKeyword, isNotNull);
    expect(initializer.period, isNotNull);
  }

  void test_parseConstructorFieldInitializer_unqualified() {
    var initializer =
        parseConstructorInitializer('a = b') as ConstructorFieldInitializer;
    expect(initializer, isNotNull);
    assertNoErrors();
    expect(initializer.equals, isNotNull);
    expect(initializer.expression, isNotNull);
    expect(initializer.fieldName, isNotNull);
    expect(initializer.thisKeyword, isNull);
    expect(initializer.period, isNull);
  }

  void test_parseGetter_identifier_colon_issue_36961() {
    createParser('get a:');
    ConstructorDeclaration constructor = parser.parseClassMember('C');
    expect(constructor, isNotNull);
    listener.assertErrors([
      expectedError(ParserErrorCode.GETTER_CONSTRUCTOR, 0, 3),
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 4, 1),
      expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 4, 1),
      expectedError(ParserErrorCode.MISSING_INITIALIZER, 5, 1),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 6, 0),
    ]);
    expect(constructor.body, isNotNull);
    expect(constructor.documentationComment, isNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.returnType, isNotNull);
  }

  void test_parseGetter_nonStatic() {
    createParser('/// Doc\nT get a;');
    MethodDeclaration method = parser.parseClassMember('C');
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as TypeName).name.name, 'T');
  }

  void test_parseGetter_static() {
    createParser('/// Doc\nstatic T get a => 42;');
    MethodDeclaration method = parser.parseClassMember('C');
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword.lexeme, 'static');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as TypeName).name.name, 'T');
  }

  void test_parseInitializedIdentifierList_type() {
    createParser("/// Doc\nstatic T a = 1, b, c = 3;");
    FieldDeclaration declaration = parser.parseClassMember('C');
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    VariableDeclarationList fields = declaration.fields;
    expect(fields, isNotNull);
    expect(fields.keyword, isNull);
    expect((fields.type as TypeName).name.name, 'T');
    expect(fields.variables, hasLength(3));
    expect(declaration.staticKeyword.lexeme, 'static');
    expect(declaration.semicolon, isNotNull);
  }

  void test_parseInitializedIdentifierList_var() {
    createParser('/// Doc\nstatic var a = 1, b, c = 3;');
    FieldDeclaration declaration = parser.parseClassMember('C');
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    VariableDeclarationList fields = declaration.fields;
    expect(fields, isNotNull);
    expect(fields.keyword.lexeme, 'var');
    expect(fields.type, isNull);
    expect(fields.variables, hasLength(3));
    expect(declaration.staticKeyword.lexeme, 'static');
    expect(declaration.semicolon, isNotNull);
  }

  void test_parseOperator() {
    createParser('/// Doc\nT operator +(A a);');
    MethodDeclaration method = parser.parseClassMember('C');
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect((method.returnType as TypeName).name.name, 'T');
  }

  void test_parseSetter_nonStatic() {
    createParser('/// Doc\nT set a(var x);');
    MethodDeclaration method = parser.parseClassMember('C');
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as TypeName).name.name, 'T');
  }

  void test_parseSetter_static() {
    createParser('/// Doc\nstatic T set a(var x) {}');
    MethodDeclaration method = parser.parseClassMember('C');
    expect(method, isNotNull);
    assertNoErrors();
    expect(method.body, isNotNull);
    expectCommentText(method.documentationComment, '/// Doc');
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword.lexeme, 'static');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect((method.returnType as TypeName).name.name, 'T');
  }

  void test_simpleFormalParameter_withDocComment() {
    createParser('''
int f(
    /// Doc
    int x) {}
''');
    var function = parseFullCompilationUnitMember() as FunctionDeclaration;
    var parameter = function.functionExpression.parameters.parameters[0]
        as NormalFormalParameter;
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  /// Assert that the given [name] is in declaration context.
  void _assertIsDeclarationName(SimpleIdentifier name, [bool expected = true]) {
    expect(name.inDeclarationContext(), expected);
  }

  void _parseClassMember_method_native() {
    createParser('m() native "str";');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    var body = method.body as NativeFunctionBody;
    expect(body.nativeKeyword, isNotNull);
    expect(body.stringLiteral, isNotNull);
    expect(body.stringLiteral?.stringValue, "str");
    expect(body.semicolon, isNotNull);
  }

  void _parseClassMember_method_native_missing_literal() {
    createParser('m() native;');
    var method = parser.parseClassMember('C') as MethodDeclaration;
    var body = method.body as NativeFunctionBody;
    expect(body.nativeKeyword, isNotNull);
    expect(body.stringLiteral, isNull);
    expect(body.semicolon, isNotNull);
  }

  void _parseClassMember_method_native_with_body() {
    createParser('m() native "str" {}');
    parser.parseClassMember('C') as MethodDeclaration;
  }
}

/// Tests of the analyzer parser based on [ComplexParserTestMixin].
@reflectiveTest
class ComplexParserTest extends ParserTestCase with ComplexParserTestMixin {}

/// The class `ComplexParserTest` defines parser tests that test the parsing of
/// more complex code fragments or the interactions between multiple parsing
/// methods. For example, tests to ensure that the precedence of operations is
/// being handled correctly should be defined in this class.
///
/// Simpler tests should be defined in the class [SimpleParserTest].
mixin ComplexParserTestMixin implements AbstractParserTestCase {
  void test_additiveExpression_normal() {
    BinaryExpression expression = parseExpression("x + y - z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_noSpaces() {
    BinaryExpression expression = parseExpression("i+1");
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.rightOperand, isIntegerLiteral);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = parseExpression("x * y + z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    BinaryExpression expression = parseExpression("super * y - z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = parseExpression("x + y * z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_additiveExpression_super() {
    BinaryExpression expression = parseExpression("super + y - z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_assignableExpression_arguments_normal_chain() {
    PropertyAccess propertyAccess1 = parseExpression("a(b)(c).d(e).f");
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a(b)(c).d(e)
    //
    MethodInvocation invocation2 = propertyAccess1.target;
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a(b)(c)
    //
    FunctionExpressionInvocation invocation3 = invocation2.target;
    expect(invocation3.typeArguments, isNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    MethodInvocation invocation4 = invocation3.function;
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }

  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    _validate_assignableExpression_arguments_normal_chain_typeArguments(
        "a<E>(b)<F>(c).d<G>(e).f");
  }

  void test_assignmentExpression_compound() {
    AssignmentExpression expression = parseExpression("x = y = 0");
    expect(expression.leftHandSide, isSimpleIdentifier);
    expect(expression.rightHandSide, isAssignmentExpression);
  }

  void test_assignmentExpression_indexExpression() {
    AssignmentExpression expression = parseExpression("x[1] = 0");
    expect(expression.leftHandSide, isIndexExpression);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_assignmentExpression_prefixedIdentifier() {
    AssignmentExpression expression = parseExpression("x.y = 0");
    expect(expression.leftHandSide, isPrefixedIdentifier);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_assignmentExpression_propertyAccess() {
    AssignmentExpression expression = parseExpression("super.y = 0");
    expect(expression.leftHandSide, isPropertyAccess);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_bitwiseAndExpression_normal() {
    BinaryExpression expression = parseExpression("x & y & z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = parseExpression("x == y && z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = parseExpression("x && y == z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = parseExpression("super & y & z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_normal() {
    BinaryExpression expression = parseExpression("x | y | z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = parseExpression("x ^ y | z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = parseExpression("x | y ^ z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = parseExpression("super | y | z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_normal() {
    BinaryExpression expression = parseExpression("x ^ y ^ z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = parseExpression("x & y ^ z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = parseExpression("x ^ y & z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = parseExpression("super ^ y ^ z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_cascade_withAssignment() {
    CascadeExpression cascade =
        parseExpression("new Map()..[3] = 4 ..[0] = 11");
    Expression target = cascade.target;
    for (Expression section in cascade.cascadeSections) {
      expect(section, isAssignmentExpression);
      Expression lhs = (section as AssignmentExpression).leftHandSide;
      expect(lhs, isIndexExpression);
      IndexExpression index = lhs as IndexExpression;
      expect(index.isCascaded, isTrue);
      expect(index.realTarget, same(target));
    }
  }

  void test_conditionalExpression_precedence_ifNullExpression() {
    ConditionalExpression expression = parseExpression('a ?? b ? y : z');
    expect(expression.condition, isBinaryExpression);
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    ConditionalExpression expression = parseExpression("a | b ? y : z");
    expect(expression.condition, isBinaryExpression);
  }

  void test_conditionalExpression_precedence_nullableType_as() {
    ExpressionStatement statement = parseStatement('x as bool ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, isAsExpression);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_conditionalExpression_precedence_nullableType_is() {
    ExpressionStatement statement =
        parseStatement('x is String ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, isIsExpression);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1_is() {
    ExpressionStatement statement =
        parseStatement('x is String<S> ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1GFT_is() {
    ExpressionStatement statement =
        parseStatement('x is String<S> Function() ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg2_is() {
    ExpressionStatement statement =
        parseStatement('x is String<S,T> ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_prefixedNullableType_is() {
    ExpressionStatement statement = parseStatement('x is p.A ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;

    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_withAssignment() {
    ExpressionStatement statement = parseStatement('b ? c = true : g();');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<SimpleIdentifier>());
    expect(expression.thenExpression, TypeMatcher<AssignmentExpression>());
  }

  void test_conditionalExpression_precedence_withAssignment2() {
    ExpressionStatement statement = parseStatement('b.x ? c = true : g();');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<AssignmentExpression>());
  }

  void test_conditionalExpression_prefixedValue() {
    ExpressionStatement statement = parseStatement('a.b ? y : z;');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_prefixedValue2() {
    ExpressionStatement statement = parseStatement('a.b ? x.y : z;');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<PrefixedIdentifier>());
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  C() :
    this.a = (b == null ? c : d) {
  }
}''');
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
  }

  void test_equalityExpression_normal() {
    BinaryExpression expression = parseExpression("x == y != z",
        codes: [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = parseExpression("x is y == z");
    expect(expression.leftOperand, isIsExpression);
  }

  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = parseExpression("x == y is z");
    expect(expression.rightOperand, isIsExpression);
  }

  void test_equalityExpression_super() {
    BinaryExpression expression = parseExpression("super == y != z",
        codes: [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression() {
    BinaryExpression expression = parseExpression('x ?? y ?? z');
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression_precedence_logicalOr_left() {
    BinaryExpression expression = parseExpression('x || y ?? z');
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression_precedence_logicalOr_right() {
    BinaryExpression expression = parseExpression('x ?? y || z');
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalAndExpression() {
    BinaryExpression expression = parseExpression("x && y && z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = parseExpression("x | y < z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = parseExpression("x < y | z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalAndExpressionStatement() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("C<T && T>U;");
    BinaryExpression expression = statement.expression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression() {
    BinaryExpression expression = parseExpression("x || y || z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = parseExpression("x && y || z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = parseExpression("x || y && z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_methodInvocation1() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("f(a < b, c > 3);");
    assertNoErrors();
    MethodInvocation method = statement.expression;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_methodInvocation2() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("f(a < b, c >> 3);");
    assertNoErrors();
    MethodInvocation method = statement.expression;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_methodInvocation3() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("f(a < b, c < d >> 3);");
    assertNoErrors();
    MethodInvocation method = statement.expression;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_multipleLabels_statement() {
    LabeledStatement statement = parseStatement("a: b: c: return x;");
    expect(statement.labels, hasLength(3));
    expect(statement.statement, isReturnStatement);
  }

  void test_multiplicativeExpression_normal() {
    BinaryExpression expression = parseExpression("x * y / z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression = parseExpression("-x * y");
    expect(expression.leftOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression = parseExpression("x * -y");
    expect(expression.rightOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_super() {
    BinaryExpression expression = parseExpression("super * y / z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = parseExpression("x << y is z");
    expect(expression.expression, isBinaryExpression);
  }

  void test_shiftExpression_normal() {
    BinaryExpression expression = parseExpression("x >> 4 << 3");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_additive_left() {
    BinaryExpression expression = parseExpression("x + y << z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_additive_right() {
    BinaryExpression expression = parseExpression("x << y + z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_shiftExpression_super() {
    BinaryExpression expression = parseExpression("super >> 4 << 3");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_topLevelFunction_nestedGenericFunction() {
    parseCompilationUnit('''
void f() {
  void g<T>() {
  }
}
''');
  }

  void _validate_assignableExpression_arguments_normal_chain_typeArguments(
      String code,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    PropertyAccess propertyAccess1 = parseExpression(code, codes: errorCodes);
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a<E>(b)<F>(c).d<G>(e)
    //
    MethodInvocation invocation2 = propertyAccess1.target;
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNotNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a<E>(b)<F>(c)
    //
    FunctionExpressionInvocation invocation3 = invocation2.target;
    expect(invocation3.typeArguments, isNotNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    MethodInvocation invocation4 = invocation3.function;
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNotNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }
}

/// The class `ErrorParserTest` defines parser tests that test the parsing
/// of code to ensure that errors are correctly reported,
/// and in some cases, not reported.
@reflectiveTest
class ErrorParserTest extends ParserTestCase with ErrorParserTestMixin {
  void test_missingIdentifier_number() {
    createParser('1');
    SimpleIdentifier expression = parser.parseSimpleIdentifier();
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 1)]);
    expect(expression.isSynthetic, isTrue);
  }
}

mixin ErrorParserTestMixin implements AbstractParserTestCase {
  void test_abstractClassMember_constructor() {
    createParser('abstract C.c();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.ABSTRACT_CLASS_MEMBER, 0, 8)]);
  }

  void test_abstractClassMember_field() {
    createParser('abstract C f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.ABSTRACT_CLASS_MEMBER, 0, 8)]);
  }

  void test_abstractClassMember_getter() {
    createParser('abstract get m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.ABSTRACT_CLASS_MEMBER, 0, 8)]);
  }

  void test_abstractClassMember_method() {
    createParser('abstract m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.ABSTRACT_CLASS_MEMBER, 0, 8)]);
  }

  void test_abstractClassMember_setter() {
    createParser('abstract set m(v);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.ABSTRACT_CLASS_MEMBER, 0, 8)]);
  }

  void test_abstractEnum() {
    parseCompilationUnit("abstract enum E {ONE}",
        errors: [expectedError(ParserErrorCode.ABSTRACT_ENUM, 0, 8)]);
  }

  void test_abstractTopLevelFunction_function() {
    parseCompilationUnit("abstract f(v) {}", errors: [
      expectedError(ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION, 0, 8)
    ]);
  }

  void test_abstractTopLevelFunction_getter() {
    parseCompilationUnit("abstract get m {}", errors: [
      expectedError(ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION, 0, 8)
    ]);
  }

  void test_abstractTopLevelFunction_setter() {
    parseCompilationUnit("abstract set m(v) {}", errors: [
      expectedError(ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION, 0, 8)
    ]);
  }

  void test_abstractTopLevelVariable() {
    parseCompilationUnit("abstract C f;", errors: [
      expectedError(ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE, 0, 8)
    ]);
  }

  void test_abstractTypeDef() {
    parseCompilationUnit("abstract typedef F();",
        errors: [expectedError(ParserErrorCode.ABSTRACT_TYPEDEF, 0, 8)]);
  }

  void test_breakOutsideOfLoop_breakInDoStatement() {
    DoStatement statement = parseStatement('do {break;} while (x);');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInForStatement() {
    Statement statement = parseStatement('for (; x;) {break;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInIfStatement() {
    IfStatement statement = parseStatement('if (x) {break;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(
        [expectedError(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, 8, 5)]);
  }

  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    SwitchStatement statement = parseStatement('switch (x) {case 1: break;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInWhileStatement() {
    WhileStatement statement = parseStatement('while (x) {break;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    parseStatement("for(; x;) {() {break;};}");
    listener.assertErrors(
        [expectedError(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, 15, 5)]);
  }

  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    parseStatement("() {for (; x;) {break;}};");
  }

  void test_classInClass_abstract() {
    parseCompilationUnit("class C { abstract class B {} }",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.ABSTRACT_CLASS_MEMBER, 10, 8),
                expectedError(ParserErrorCode.CLASS_IN_CLASS, 19, 5)
              ]
            : [expectedError(ParserErrorCode.CLASS_IN_CLASS, 19, 5)]);
  }

  void test_classInClass_nonAbstract() {
    parseCompilationUnit("class C { class B {} }",
        errors: [expectedError(ParserErrorCode.CLASS_IN_CLASS, 10, 5)]);
  }

  void test_classTypeAlias_abstractAfterEq() {
    // This syntax has been removed from the language in favor of
    // "abstract class A = B with C;" (issue 18098).
    createParser('class A = abstract B with C;', expectedEndOffset: 21);
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(
                CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 10, 8),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 19, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 19, 1)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 0),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 0)
          ]);
  }

  void test_colonInPlaceOfIn() {
    parseStatement("for (var x : list) {}");
    listener.assertErrors(
        [expectedError(ParserErrorCode.COLON_IN_PLACE_OF_IN, 11, 1)]);
  }

  void test_constAndCovariant() {
    createParser('covariant const C f = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.CONST_AND_COVARIANT, 10, 5)]);
  }

  void test_constAndFinal() {
    createParser('const final int x = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.CONST_AND_FINAL, 6, 5)]);
  }

  void test_constAndVar() {
    createParser('const var x = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(ParserErrorCode.CONST_AND_VAR, 6, 3)]);
  }

  void test_constClass() {
    parseCompilationUnit("const class C {}",
        errors: [expectedError(ParserErrorCode.CONST_CLASS, 0, 5)]);
  }

  void test_constConstructorWithBody() {
    createParser('const C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, 10, 1)]);
  }

  void test_constEnum() {
    parseCompilationUnit("const enum E {ONE}",
        errors: usingFastaParser
            ? [
                // Fasta interprets the `const` as a malformed top level const
                // and `enum` as the start of an enum declaration.
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 4),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 4),
              ]
            : [expectedError(ParserErrorCode.CONST_ENUM, 0, 5)]);
  }

  void test_constFactory() {
    createParser('const factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(ParserErrorCode.CONST_FACTORY, 0, 5)]);
  }

  void test_constMethod() {
    createParser('const int m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(ParserErrorCode.CONST_METHOD, 0, 5)]);
  }

  void test_constMethod_noReturnType() {
    createParser('const m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(ParserErrorCode.CONST_METHOD, 0, 5)]);
  }

  void test_constMethod_noReturnType2() {
    createParser('const m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(ParserErrorCode.CONST_METHOD, 0, 5)]);
  }

  void test_constructorPartial() {
    createParser('class C { C< }');
    parser.parseCompilationUnit2();
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.TYPE_PARAMETER_ON_CONSTRUCTOR, 11, 2),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
            expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1),
            expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 13, 1),
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 13, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 1),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 1)
          ]);
  }

  void test_constructorPartial2() {
    createParser('class C { C<@Foo }');
    parser.parseCompilationUnit2();
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.TYPE_PARAMETER_ON_CONSTRUCTOR, 11, 6),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 17, 1),
            expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1),
            expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 17, 1)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 1),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 12, 1),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 17, 1)
          ]);
  }

  void test_constructorPartial3() {
    createParser('class C { C<@Foo @Bar() }');
    parser.parseCompilationUnit2();
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(
                ParserErrorCode.TYPE_PARAMETER_ON_CONSTRUCTOR, 11, 13),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 24, 1),
            expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1),
            expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 24, 1)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 1),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 12, 1),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 24, 1)
          ]);
  }

  void test_constructorWithReturnType() {
    createParser('C C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, 0, 1),
    ]);
  }

  void test_constructorWithReturnType_var() {
    createParser('var C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.VAR_RETURN_TYPE, 0, 3)]
        : [expectedError(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, 0, 3)]);
  }

  void test_constTypedef() {
    parseCompilationUnit("const typedef F();",
        errors: usingFastaParser
            ? [
                // Fasta interprets the `const` as a malformed top level const
                // and `typedef` as the start of an typedef declaration.
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 7),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 7),
              ]
            : [expectedError(ParserErrorCode.CONST_TYPEDEF, 0, 5)]);
  }

  void test_continueOutsideOfLoop_continueInDoStatement() {
    DoStatement statement = parseStatement('do {continue;} while (x);');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInForStatement() {
    Statement statement = parseStatement('for (; x;) {continue;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInIfStatement() {
    IfStatement statement = parseStatement('if (x) {continue;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(
        [expectedError(ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, 8, 8)]);
  }

  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    SwitchStatement statement =
        parseStatement('switch (x) {case 1: continue a;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInWhileStatement() {
    WhileStatement statement = parseStatement('while (x) {continue;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    parseStatement("for(; x;) {() {continue;};}");
    listener.assertErrors(
        [expectedError(ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, 15, 8)]);
  }

  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    parseStatement("() {for (; x;) {continue;}};");
  }

  void test_continueWithoutLabelInCase_error() {
    SwitchStatement statement =
        parseStatement('switch (x) {case 1: continue;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(
        [expectedError(ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE, 20, 8)]);
  }

  void test_continueWithoutLabelInCase_noError() {
    SwitchStatement statement =
        parseStatement('switch (x) {case 1: continue a;}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    WhileStatement statement =
        parseStatement('while (a) { switch (b) {default: continue;}}');
    expectNotNullIfNoErrors(statement);
    assertNoErrors();
  }

  void test_covariantAfterVar() {
    createParser('var covariant f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.COVARIANT_AFTER_VAR, 4, 9)]);
  }

  void test_covariantAndFinal() {
    createParser('covariant final f = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.FINAL_AND_COVARIANT]);
  }

  void test_covariantAndStatic() {
    createParser('covariant static A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.COVARIANT_AND_STATIC, 10, 6)]);
  }

  void test_covariantAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    parseStatement("covariant int x;");
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 0, 9)]
        : [expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 9)]);
  }

  void test_covariantConstructor() {
    createParser('class C { covariant C(); }');
    ClassDeclaration member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.COVARIANT_MEMBER
              : ParserErrorCode.COVARIANT_CONSTRUCTOR,
          10,
          9)
    ]);
  }

  void test_covariantMember_getter_noReturnType() {
    createParser('static covariant get x => 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.COVARIANT_AND_STATIC, 7, 9)]
        : [expectedError(ParserErrorCode.COVARIANT_MEMBER, 7, 9)]);
  }

  void test_covariantMember_getter_returnType() {
    createParser('static covariant int get x => 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.COVARIANT_AND_STATIC, 7, 9)]
        : [expectedError(ParserErrorCode.COVARIANT_MEMBER, 7, 9)]);
  }

  void test_covariantMember_method() {
    createParser('covariant int m() => 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.COVARIANT_MEMBER, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_class() {
    createParser('covariant class C {}');
    ClassDeclaration member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_enum() {
    createParser('covariant enum E { v }');
    EnumDeclaration member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_typedef() {
    parseCompilationUnit("covariant typedef F();", errors: [
      expectedError(ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION, 0, 9)
    ]);
  }

  void test_defaultValueInFunctionType_named_colon() {
    createParser('({int x : 0})');
    FormalParameter parameter =
        parser.parseFormalParameterList(inFunctionType: true).parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 8, 1)]);
  }

  void test_defaultValueInFunctionType_named_equal() {
    createParser('({int x = 0})');
    FormalParameter parameter =
        parser.parseFormalParameterList(inFunctionType: true).parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 8, 1)]);
  }

  void test_defaultValueInFunctionType_positional() {
    createParser('([int x = 0])');
    FormalParameter parameter =
        parser.parseFormalParameterList(inFunctionType: true).parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 8, 1)]);
  }

  void test_directiveAfterDeclaration_classBeforeDirective() {
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    CompilationUnit unit = parseCompilationUnit("class Foo{} library l;",
        codes: usingFastaParser
            ? [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST]
            : [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION],
        errors: usingFastaParser
            ? [
                expectedError(
                    ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, 12, 10)
              ]
            : [
                expectedError(
                    ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, 12, 10)
              ]);
    expect(unit, isNotNull);
  }

  void test_directiveAfterDeclaration_classBetweenDirectives() {
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    CompilationUnit unit =
        parseCompilationUnit("library l;\nclass Foo{}\npart 'a.dart';", codes: [
      ParserErrorCode.DIRECTIVE_AFTER_DECLARATION
    ], errors: [
      expectedError(ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, 23, 14)
    ]);
    expect(unit, isNotNull);
  }

  void test_duplicatedModifier_const() {
    createParser('const const m = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DUPLICATED_MODIFIER, 6, 5)]);
  }

  void test_duplicatedModifier_external() {
    createParser('external external f();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DUPLICATED_MODIFIER, 9, 8)]);
  }

  void test_duplicatedModifier_factory() {
    createParser('factory factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DUPLICATED_MODIFIER, 8, 7)]);
  }

  void test_duplicatedModifier_final() {
    createParser('final final m = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DUPLICATED_MODIFIER, 6, 5)]);
  }

  void test_duplicatedModifier_static() {
    createParser('static static var m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DUPLICATED_MODIFIER, 7, 6)]);
  }

  void test_duplicatedModifier_var() {
    createParser('var var m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.DUPLICATED_MODIFIER, 4, 3)]);
  }

  void test_duplicateLabelInSwitchStatement() {
    SwitchStatement statement =
        parseStatement('switch (e) {l1: case 0: break; l1: case 1: break;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT, 31, 2)
    ]);
  }

  void test_emptyEnumBody() {
    createParser('enum E {}');
    EnumDeclaration declaration = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(declaration);
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.EMPTY_ENUM_BODY]);
//    listener
//        .assertErrors([expectedError(ParserErrorCode.EMPTY_ENUM_BODY, 7, 2),]);
  }

  void test_enumInClass() {
    parseCompilationUnit(r'''
class Foo {
  enum Bar {
    Bar1, Bar2, Bar3
  }
}
''', errors: [expectedError(ParserErrorCode.ENUM_IN_CLASS, 14, 4)]);
  }

  void test_equalityCannotBeEqualityOperand_eq_eq() {
    parseExpression("1 == 2 == 3", errors: [
      expectedError(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 7, 2)
    ]);
  }

  void test_equalityCannotBeEqualityOperand_eq_neq() {
    parseExpression("1 == 2 != 3", errors: [
      expectedError(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 7, 2)
    ]);
  }

  void test_equalityCannotBeEqualityOperand_neq_eq() {
    parseExpression("1 != 2 == 3", errors: [
      expectedError(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 7, 2)
    ]);
  }

  void test_expectedCaseOrDefault() {
    SwitchStatement statement = parseStatement('switch (e) {break;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 5)]
        : [expectedError(ParserErrorCode.EXPECTED_CASE_OR_DEFAULT, 12, 5)]);
  }

  void test_expectedClassMember_inClass_afterType() {
    parseCompilationUnit('class C{ heart 2 heart }',
        errors: usingFastaParser
            ? [
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 9, 5),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 5),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 15, 1),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 17, 5),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 17, 5)
              ]
            : [
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 15, 1),
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 23, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 23, 1)
              ]);
  }

  void test_expectedClassMember_inClass_beforeType() {
    parseCompilationUnit('class C { 4 score }',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 10, 1),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 12, 5),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 5)
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 10, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 10, 1),
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 18, 1)
              ]);
  }

  void test_expectedExecutable_afterAnnotation_atEOF() {
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    parseCompilationUnit('@A',
        codes: [ParserErrorCode.EXPECTED_EXECUTABLE],
        errors: [expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 1, 1)]);
  }

  void test_expectedExecutable_inClass_afterVoid() {
    parseCompilationUnit('class C { void 2 void }',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 17, 4),
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 22, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 22, 1)
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 15, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 22, 1),
              ]);
  }

  void test_expectedExecutable_topLevel_afterType() {
    CompilationUnit unit = parseCompilationUnit('heart 2 heart',
        errors: usingFastaParser
            ? [
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 0, 5),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 5),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 6, 1),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 8, 5),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 5),
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 6, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 6, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 6, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 8, 5)
              ]);
    expect(unit, isNotNull);
  }

  void test_expectedExecutable_topLevel_afterVoid() {
    CompilationUnit unit = parseCompilationUnit('void 2 void',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 5, 1),
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 11, 0),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 0),
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 6, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 6, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 6, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 8, 5)
              ]);
    expect(unit, isNotNull);
  }

  void test_expectedExecutable_topLevel_beforeType() {
    parseCompilationUnit('4 score',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 2, 5),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 2, 5),
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 0, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 2, 5),
              ]);
  }

  void test_expectedExecutable_topLevel_eof() {
    parseCompilationUnit('x',
        errors: usingFastaParser
            ? [
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 0, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 1)
              ]
            : [expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1)]);
  }

  void test_expectedInterpolationIdentifier() {
    StringLiteral literal = parseExpression("'\$x\$'",
        errors: [expectedError(ScannerErrorCode.MISSING_IDENTIFIER, 4, 1)]);
    expectNotNullIfNoErrors(literal);
  }

  void test_expectedInterpolationIdentifier_emptyString() {
    // The scanner inserts an empty string token between the two $'s; we need to
    // make sure that the MISSING_IDENTIFIER error that is generated has a
    // nonzero width so that it will show up in the editor UI.
    StringLiteral literal = parseExpression("'\$\$foo'",
        errors: [expectedError(ScannerErrorCode.MISSING_IDENTIFIER, 2, 1)]);
    expectNotNullIfNoErrors(literal);
  }

  @failingTest
  void test_expectedListOrMapLiteral() {
    // It isn't clear that this test can ever pass. The parser is currently
    // create a synthetic list literal in this case, but isSynthetic() isn't
    // overridden for ListLiteral. The problem is that the synthetic list
    // literals that are being created are not always zero length (because they
    // could have type parameters), which violates the contract of
    // isSynthetic().
    TypedLiteral literal = parseListOrMapLiteral(null, '1');
    expectNotNullIfNoErrors(literal);
    listener.assertErrors(
        [expectedError(ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL, 1, 1)]);
    expect(literal.isSynthetic, isTrue);
  }

  void test_expectedStringLiteral() {
    StringLiteral literal = parseStringLiteral('1');
    expectNotNullIfNoErrors(literal);
    listener.assertErrors(
        [expectedError(ParserErrorCode.EXPECTED_STRING_LITERAL, 0, 1)]);
    expect(literal.isSynthetic, isTrue);
  }

  void test_expectedToken_commaMissingInArgumentList() {
    createParser('(x, y z)');
    ArgumentList list = parser.parseArgumentList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1)]
        : [expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 1)]);
  }

  void test_expectedToken_parseStatement_afterVoid() {
    parseStatement("void}", expectedEndOffset: 4);
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)
    ]);
  }

  void test_expectedToken_semicolonMissingAfterExport() {
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    CompilationUnit unit = parseCompilationUnit("export '' class A {}",
        codes: [ParserErrorCode.EXPECTED_TOKEN],
        errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 2)]);
    ExportDirective directive = unit.directives[0] as ExportDirective;
    expect(directive.uri, isNotNull);
    expect(directive.uri.stringValue, '');
    expect(directive.uri.beginToken.isSynthetic, false);
    expect(directive.uri.isSynthetic, false);
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
    ClassDeclaration clazz = unit.declarations[0] as ClassDeclaration;
    expect(clazz.name.name, 'A');
  }

  void test_expectedToken_semicolonMissingAfterExpression() {
    parseStatement("x");
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_TOKEN]);
//    listener
//        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 1)]);
  }

  void test_expectedToken_semicolonMissingAfterImport() {
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    CompilationUnit unit = parseCompilationUnit("import '' class A {}",
        codes: [ParserErrorCode.EXPECTED_TOKEN],
        errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 2)]);
    ImportDirective directive = unit.directives[0] as ImportDirective;
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
  }

  void test_expectedToken_uriAndSemicolonMissingAfterExport() {
    CompilationUnit unit = parseCompilationUnit("export class A {}", errors: [
      expectedError(ParserErrorCode.EXPECTED_STRING_LITERAL, 7, 5),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 5),
    ]);
    ExportDirective directive = unit.directives[0] as ExportDirective;
    expect(directive.uri, isNotNull);
    expect(directive.uri.stringValue, '');
    expect(directive.uri.beginToken.isSynthetic, true);
    expect(directive.uri.isSynthetic, true);
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
    ClassDeclaration clazz = unit.declarations[0] as ClassDeclaration;
    expect(clazz.name.name, 'A');
  }

  void test_expectedToken_whileMissingInDoStatement() {
    parseStatement("do {} (x);");
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1)]);
  }

  void test_expectedTypeName_as() {
    parseExpression("x as",
        errors: [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 0)]);
  }

  void test_expectedTypeName_as_void() {
    parseExpression("x as void)",
        expectedEndOffset: 9,
        errors: [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 5, 4)]);
  }

  void test_expectedTypeName_is() {
    parseExpression("x is",
        errors: [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 0)]);
  }

  void test_expectedTypeName_is_void() {
    parseExpression("x is void)",
        expectedEndOffset: 9,
        errors: [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 5, 4)]);
  }

  void test_exportAsType() {
    parseCompilationUnit('export<dynamic> foo;',
        errors: usingFastaParser
            ? [
                expectedError(
                    CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 0, 6)
              ]
            : []);
  }

  void test_exportAsType_inClass() {
    parseCompilationUnit('class C { export<dynamic> foo; }',
        errors: usingFastaParser
            ? [
                expectedError(
                    CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 10, 6)
              ]
            : []);
  }

  void test_exportDirectiveAfterPartDirective() {
    parseCompilationUnit("part 'a.dart'; export 'b.dart';", errors: [
      expectedError(
          ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, 15, 6)
    ]);
  }

  void test_externalAfterConst() {
    createParser('const external C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.EXTERNAL_AFTER_CONST, 6, 8)]);
  }

  void test_externalAfterFactory() {
    createParser('factory external C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 8, 8)]);
  }

  void test_externalAfterStatic() {
    createParser('static external int m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.EXTERNAL_AFTER_STATIC, 7, 8)]);
  }

  void test_externalClass() {
    parseCompilationUnit("external class C {}",
        errors: [expectedError(ParserErrorCode.EXTERNAL_CLASS, 0, 8)]);
  }

  void test_externalConstructorWithBody_factory() {
    createParser('external factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.EXTERNAL_FACTORY_WITH_BODY
              : ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY,
          21,
          1)
    ]);
  }

  void test_externalConstructorWithBody_named() {
    createParser('external C.c() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
      listener
          .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
//      listener.assertErrors(
//          [expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 15, 2)]);
    } else {
      listener.assertErrorsWithCodes(
          [ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY]);
    }
  }

  void test_externalEnum() {
    parseCompilationUnit("external enum E {ONE}",
        errors: [expectedError(ParserErrorCode.EXTERNAL_ENUM, 0, 8)]);
  }

  void test_externalField_const() {
    createParser('external const A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.EXTERNAL_FIELD, 0, 8),
        expectedError(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 17, 1)
      ]);
    } else {
      listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_FIELD]);
    }
  }

  void test_externalField_final() {
    createParser('external final A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXTERNAL_FIELD, 0, 8)]);
  }

  void test_externalField_static() {
    createParser('external static A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXTERNAL_FIELD, 0, 8)]);
  }

  void test_externalField_typed() {
    createParser('external A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXTERNAL_FIELD, 0, 8)]);
  }

  void test_externalField_untyped() {
    createParser('external var f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXTERNAL_FIELD, 0, 8)]);
  }

  void test_externalGetterWithBody() {
    createParser('external int get x {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
      listener
          .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
//      listener.assertErrors(
//          [expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 19, 2)]);
    } else {
      listener
          .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_GETTER_WITH_BODY]);
    }
  }

  void test_externalMethodWithBody() {
    createParser('external m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
//    listener.assertErrors(
//        [expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 13, 2)]);
  }

  void test_externalOperatorWithBody() {
    createParser('external operator +(int value) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
      listener
          .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
//      listener.assertErrors(
//          [expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 31, 2)]);
    } else {
      listener
          .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY]);
    }
  }

  void test_externalSetterWithBody() {
    createParser('external set x(int value) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
      listener
          .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
//      listener.assertErrors(
//          [expectedError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, 26, 2)]);
    } else {
      listener
          .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_SETTER_WITH_BODY]);
    }
  }

  void test_externalTypedef() {
    parseCompilationUnit("external typedef F();",
        errors: [expectedError(ParserErrorCode.EXTERNAL_TYPEDEF, 0, 8)]);
  }

  void test_extraCommaInParameterList() {
    createParser('(int a, , int b)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1)
          ]);
  }

  void test_extraCommaTrailingNamedParameterGroup() {
    createParser('({int b},)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 1),
            expectedError(
                ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, 9, 1)
          ]);
  }

  void test_extraCommaTrailingPositionalParameterGroup() {
    createParser('([int b],)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 1),
            expectedError(
                ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, 9, 1)
          ]);
  }

  void test_extraTrailingCommaInParameterList() {
    createParser('(a,,)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 3, 1)]);
  }

  void test_factoryTopLevelDeclaration_class() {
    parseCompilationUnit("factory class C {}", errors: [
      expectedError(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, 0, 7)
    ]);
  }

  void test_factoryTopLevelDeclaration_enum() {
    parseCompilationUnit("factory enum E { v }", errors: [
      expectedError(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, 0, 7)
    ]);
  }

  void test_factoryTopLevelDeclaration_typedef() {
    parseCompilationUnit("factory typedef F();", errors: [
      expectedError(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, 0, 7)
    ]);
  }

  void test_factoryWithInitializers() {
    createParser('factory C() : x = 3 {}', expectedEndOffset: 12);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 12, 1)]
        : [expectedError(ParserErrorCode.FACTORY_WITH_INITIALIZERS, 12, 1)]);
  }

  void test_factoryWithoutBody() {
    createParser('factory C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      listener.assertErrors(
          [expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 11, 1)]);
    } else {
      listener.assertErrorsWithCodes([ParserErrorCode.FACTORY_WITHOUT_BODY]);
    }
  }

  void test_fieldInitializerOutsideConstructor() {
    createParser('void m(this.x);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 7, 4)
    ]);
  }

  void test_finalAndCovariant() {
    createParser('final covariant f = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.COVARIANT_AFTER_FINAL, 6, 9),
            expectedError(ParserErrorCode.FINAL_AND_COVARIANT, 6, 9)
          ]
        : [expectedError(ParserErrorCode.FINAL_AND_COVARIANT, 6, 9)]);
  }

  void test_finalAndVar() {
    createParser('final var x = null;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([expectedError(ParserErrorCode.FINAL_AND_VAR, 6, 3)]);
  }

  void test_finalClass() {
    parseCompilationUnit("final class C {}",
        errors: [expectedError(ParserErrorCode.FINAL_CLASS, 0, 5)]);
  }

  void test_finalClassMember_modifierOnly() {
    createParser('final');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 0),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 0)
    ]);
  }

  void test_finalConstructor() {
    createParser('final C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      listener.assertErrors(
          [expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 0, 5)]);
    } else {
      listener.assertErrorsWithCodes([ParserErrorCode.FINAL_CONSTRUCTOR]);
    }
  }

  void test_finalEnum() {
    parseCompilationUnit("final enum E {ONE}",
        errors: usingFastaParser
            ? [
                // Fasta interprets the `final` as a malformed top level final
                // and `enum` as the start of a enum declaration.
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 4),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 4),
              ]
            : [expectedError(ParserErrorCode.FINAL_ENUM, 0, 5)]);
  }

  void test_finalMethod() {
    createParser('final int m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      listener.assertErrors(
          [expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 0, 5)]);
    } else {
      listener.assertErrorsWithCodes([ParserErrorCode.FINAL_METHOD]);
    }
  }

  void test_finalTypedef() {
    parseCompilationUnit("final typedef F();",
        errors: usingFastaParser
            ? [
                // Fasta interprets the `final` as a malformed top level final
                // and `typedef` as the start of an typedef declaration.
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 7),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 7),
              ]
            : [expectedError(ParserErrorCode.FINAL_TYPEDEF, 0, 5)]);
  }

  void test_functionTypedField_invalidType_abstract() {
    if (usingFastaParser) {
      parseCompilationUnit("Function(abstract) x = null;", errors: [
        expectedError(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 9, 8)
      ]);
    }
  }

  void test_functionTypedField_invalidType_class() {
    if (usingFastaParser) {
      parseCompilationUnit("Function(class) x = null;",
          errors: usingFastaParser
              ? [
                  expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 9, 5),
                  expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 5)
                ]
              : [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 9, 5)]);
    }
  }

  void test_functionTypedParameter_const() {
    parseCompilationUnit("void f(const x()) {}",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 7, 5),
                expectedError(
                    ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, 7, 5)
              ]
            : [
                expectedError(
                    ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, 7, 5)
              ]);
  }

  void test_functionTypedParameter_final() {
    parseCompilationUnit("void f(final x()) {}", errors: [
      expectedError(ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, 7, 5)
    ]);
  }

  void test_functionTypedParameter_incomplete1() {
    parseCompilationUnit("void f(int Function(",
        errors: usingFastaParser
            ? [
                expectedError(ScannerErrorCode.EXPECTED_TOKEN, 20, 1),
                expectedError(ScannerErrorCode.EXPECTED_TOKEN, 20, 1),
                expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 20, 0),
              ]
            : [
                expectedError(ScannerErrorCode.EXPECTED_TOKEN, 20, 0),
                expectedError(ScannerErrorCode.EXPECTED_TOKEN, 20, 0),
                expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 20, 0),
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 20, 0),
              ]);
  }

  void test_functionTypedParameter_var() {
    parseCompilationUnit("void f(var x()) {}", errors: [
      expectedError(ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, 7, 3)
    ]);
  }

  void test_genericFunctionType_asIdentifier() {
    createParser('final int Function = 0;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors([]);
  }

  void test_genericFunctionType_asIdentifier2() {
    if (usingFastaParser) {
      createParser('int Function() {}');
      CompilationUnit unit = parser.parseCompilationUnit2();
      expectNotNullIfNoErrors(unit);
      listener.assertErrors([]);
    }
  }

  void test_genericFunctionType_asIdentifier3() {
    if (usingFastaParser) {
      createParser('int Function() => 0;');
      CompilationUnit unit = parser.parseCompilationUnit2();
      expectNotNullIfNoErrors(unit);
      listener.assertErrors([]);
    }
  }

  void test_genericFunctionType_extraLessThan() {
    createParser('''
class Wrong<T> {
  T Function(<List<int> foo) bar;
}''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 30, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 30, 1)
          ]
        : [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 30, 1)]);
  }

  void test_getterInFunction_block_noReturnType() {
    Statement result =
        parseStatement("get x { return _x; }", expectedEndOffset: 4);
    if (usingFastaParser) {
      // Fasta considers `get` to be an identifier in this situation.
      // TODO(danrubel): Investigate better recovery.
      ExpressionStatement statement = result;
      listener
          .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 3)]);
      expect(statement.expression.toSource(), 'get');
    } else {
      FunctionDeclarationStatement statement = result;
      listener.assertErrors(
          [expectedError(ParserErrorCode.GETTER_IN_FUNCTION, 0, 3)]);
      expect(
          statement.functionDeclaration.functionExpression.parameters, isNull);
    }
  }

  void test_getterInFunction_block_returnType() {
    // Fasta considers `get` to be an identifier in this situation.
    parseStatement("int get x { return _x; }", expectedEndOffset: 8);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 3)]
        : [expectedError(ParserErrorCode.GETTER_IN_FUNCTION, 4, 3)]);
  }

  void test_getterInFunction_expression_noReturnType() {
    // Fasta considers `get` to be an identifier in this situation.
    parseStatement("get x => _x;", expectedEndOffset: 4);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 3)]
        : [expectedError(ParserErrorCode.GETTER_IN_FUNCTION, 0, 3)]);
  }

  void test_getterInFunction_expression_returnType() {
    // Fasta considers `get` to be an identifier in this situation.
    parseStatement("int get x => _x;", expectedEndOffset: 8);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 3)]
        : [expectedError(ParserErrorCode.GETTER_IN_FUNCTION, 4, 3)]);
  }

  void test_getterWithParameters() {
    createParser('int get x() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.GETTER_WITH_PARAMETERS]);
//    listener.assertErrors(
//        [expectedError(ParserErrorCode.GETTER_WITH_PARAMETERS, 9, 2)]);
  }

  void test_illegalAssignmentToNonAssignable_assign_int() {
    parseStatement("0 = 1;");
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 0, 1),
            expectedError(
                ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 0, 1),
          ]
        : [
            expectedError(
                ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 4, 1)
          ]);
  }

  void test_illegalAssignmentToNonAssignable_assign_this() {
    parseStatement("this = 1;");
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 0, 4),
            expectedError(
                ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 0, 4)
          ]
        : [
            expectedError(
                ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 7, 1)
          ]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    parseExpression("0--", errors: [
      expectedError(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 1, 2)
    ]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    parseExpression("0++", errors: [
      expectedError(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 1, 2)
    ]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    parseExpression("(x)++", errors: [
      expectedError(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 3, 2)
    ]);
  }

  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    parseExpression("x(y)(z)++", errors: [
      expectedError(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 7, 2)
    ]);
  }

  void test_illegalAssignmentToNonAssignable_superAssigned() {
    parseStatement("super = x;");
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 0, 5),
      expectedError(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 0, 5)
    ]);
  }

  void test_implementsBeforeExtends() {
    parseCompilationUnit("class A implements B extends C {}", errors: [
      expectedError(ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS, 21, 7)
    ]);
  }

  void test_implementsBeforeWith() {
    parseCompilationUnit("class A extends B implements C with D {}",
        errors: [expectedError(ParserErrorCode.IMPLEMENTS_BEFORE_WITH, 31, 4)]);
  }

  void test_importDirectiveAfterPartDirective() {
    parseCompilationUnit("part 'a.dart'; import 'b.dart';", errors: [
      expectedError(
          ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, 15, 6)
    ]);
  }

  void test_initializedVariableInForEach() {
    Statement statement = parseStatement('for (int a = 0 in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH, 11, 1)
    ]);
  }

  void test_initializedVariableInForEach_annotation() {
    Statement statement = parseStatement('for (@Foo var a = 0 in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH, 16, 1)
    ]);
  }

  void test_initializedVariableInForEach_localFunction() {
    Statement statement = parseStatement('for (f()) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1)
          ]);
  }

  void test_initializedVariableInForEach_localFunction2() {
    Statement statement = parseStatement('for (T f()) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 1)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 1)
          ]);
  }

  void test_initializedVariableInForEach_var() {
    Statement statement = parseStatement('for (var a = 0 in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH, 11, 1)
    ]);
  }

  void test_invalidAwaitInFor() {
    Statement statement = parseStatement('await for (; ;) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_AWAIT_IN_FOR, 0, 5)]);
  }

  void test_invalidCodePoint() {
    StringLiteral literal = parseExpression("'begin \\u{110000}'",
        errors: [expectedError(ParserErrorCode.INVALID_CODE_POINT, 7, 9)]);
    expectNotNullIfNoErrors(literal);
  }

  @failingTest
  void test_invalidCommentReference__new_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    createParser('');
    CommentReference reference = parseCommentReference('new 42', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_COMMENT_REFERENCE, 0, 6)]);
  }

  @failingTest
  void test_invalidCommentReference__new_tooMuch() {
    createParser('');
    CommentReference reference = parseCommentReference('new a.b.c.d', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_COMMENT_REFERENCE, 0, 11)]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    createParser('');
    CommentReference reference = parseCommentReference('42', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_COMMENT_REFERENCE, 0, 2)]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_tooMuch() {
    createParser('');
    CommentReference reference = parseCommentReference('a.b.c.d', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_COMMENT_REFERENCE, 0, 7)]);
  }

  void test_invalidConstructorName_star() {
    createParser("C.*();");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 2, 1)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 2, 1),
            expectedError(ParserErrorCode.MISSING_KEYWORD_OPERATOR, 2, 1)
          ]);
  }

  void test_invalidConstructorName_with() {
    createParser("C.with();");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      usingFastaParser
          ? expectedError(ParserErrorCode.MISSING_IDENTIFIER, 2, 4)
          : expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 0, 1)
    ]);
  }

  void test_invalidConstructorSuperAssignment() {
    createParser("C() : super = 42;");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 6, 5)]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 14, 1),
            expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 16, 2),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 16, 2),
            expectedError(
                ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR, 16, 0),
          ]);
  }

  void test_invalidConstructorSuperFieldAssignment() {
    createParser("C() : super.a = 42;");
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(
                ParserErrorCode.FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS,
                12,
                1)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 14, 1),
            expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 16, 2),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 16, 2),
            expectedError(
                ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR, 16, 0),
          ]);
  }

  void test_invalidHexEscape_invalidDigit() {
    StringLiteral literal = parseExpression("'not \\x0 a'",
        errors: [expectedError(ParserErrorCode.INVALID_HEX_ESCAPE, 5, 3)]);
    expectNotNullIfNoErrors(literal);
  }

  void test_invalidHexEscape_tooFewDigits() {
    StringLiteral literal = parseExpression("'\\x0'",
        errors: [expectedError(ParserErrorCode.INVALID_HEX_ESCAPE, 1, 3)]);
    expectNotNullIfNoErrors(literal);
  }

  void test_invalidInlineFunctionType() {
    parseCompilationUnit(
      'typedef F = int Function(int a());',
      errors: usingFastaParser
          ? [
              expectedError(
                  CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE, 30, 1)
            ]
          : [],
    );
  }

  void test_invalidInterpolation_missingClosingBrace_issue35900() {
    parseCompilationUnit(r"main () { print('${x' '); }",
        errors: usingFastaParser
            ? [
                expectedError(ScannerErrorCode.EXPECTED_TOKEN, 23, 1),
                expectedError(
                    ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 26, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 3),
                expectedError(ParserErrorCode.EXPECTED_STRING_LITERAL, 23, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 27, 0),
              ]
            : [
                expectedError(ScannerErrorCode.EXPECTED_TOKEN, 23, 1),
                expectedError(
                    ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 26, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 3),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 23, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 23, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 23, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 23, 1),
              ]);
  }

  void test_invalidInterpolationIdentifier_startWithDigit() {
    StringLiteral literal = parseExpression("'\$1'",
        errors: [expectedError(ScannerErrorCode.MISSING_IDENTIFIER, 2, 1)]);
    expectNotNullIfNoErrors(literal);
  }

  void test_invalidLiteralInConfiguration() {
    createParser("if (a == 'x \$y z') 'a.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    listener.assertErrors([
      expectedError(ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION, 12, 2)
    ]);
  }

  void test_invalidOperator() {
    CompilationUnit unit =
        parseCompilationUnit('class C { void operator ===(x) { } }',
            errors: usingFastaParser
                ? [expectedError(ScannerErrorCode.UNSUPPORTED_OPERATOR, 24, 1)]
                : [
                    expectedError(ScannerErrorCode.UNSUPPORTED_OPERATOR, 24, 1),
                    expectedError(ParserErrorCode.INVALID_OPERATOR, 24, 3)
                  ]);
    expect(unit, isNotNull);
  }

  void test_invalidOperator_unary() {
    createParser('class C { int operator unary- => 0; }');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 23, 5),
            expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 28, 1)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 14, 8),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 28, 1),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 28, 1),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 28, 1),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 30, 2),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 30, 2),
            expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 33, 1),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 33, 1),
            expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 34, 1)
          ]);
  }

  void test_invalidOperatorAfterSuper_assignableExpression() {
    Expression expression = parseAssignableExpression('super?.v', false);
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
              : ParserErrorCode.INVALID_OPERATOR_FOR_SUPER,
          5,
          2)
    ]);
  }

  void test_invalidOperatorAfterSuper_primaryExpression() {
    Expression expression = parseExpression('super?.v', errors: [
      expectedError(
          usingFastaParser
              ? ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
              : ParserErrorCode.INVALID_OPERATOR_FOR_SUPER,
          5,
          2)
    ]);
    expectNotNullIfNoErrors(expression);
  }

  void test_invalidOperatorForSuper() {
    createParser('++super');
    Expression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrors([
      usingFastaParser
          ? expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 2, 5)
          : expectedError(ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, 0, 2)
    ]);
  }

  void test_invalidPropertyAccess_this() {
    parseExpression('x.this',
        errors: [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 2, 4)]);
  }

  void test_invalidStarAfterAsync() {
    createParser('foo() async* => 0;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors(usingFastaParser
        ? [expectedError(CompileTimeErrorCode.RETURN_IN_GENERATOR, 13, 2)]
        : [expectedError(ParserErrorCode.INVALID_STAR_AFTER_ASYNC, 11, 1)]);
  }

  void test_invalidSync() {
    createParser('foo() sync* => 0;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertErrors(usingFastaParser
        ? [expectedError(CompileTimeErrorCode.RETURN_IN_GENERATOR, 12, 2)]
        : [expectedError(ParserErrorCode.INVALID_SYNC, 0, 4)]);
  }

  void test_invalidTopLevelSetter() {
    parseCompilationUnit("var set foo; main(){}", errors: [
      expectedError(ParserErrorCode.VAR_RETURN_TYPE, 0, 3),
      usingFastaParser
          ? expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 8, 3)
          : expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 11, 1),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 11, 1)
    ]);
  }

  void test_invalidTopLevelVar() {
    parseCompilationUnit("var Function(var arg);",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.VAR_RETURN_TYPE, 0, 3),
                expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 21, 1),
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 21, 2),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 21, 2),
              ]);
  }

  void test_invalidTypedef() {
    parseCompilationUnit("typedef var Function(var arg);",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 3),
                expectedError(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, 8, 3),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 3),
                expectedError(ParserErrorCode.VAR_RETURN_TYPE, 8, 3),
                expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 29, 1),
              ]
            : [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 3),
                expectedError(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, 8, 3),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 29, 2),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 29, 2),
              ]);
  }

  void test_invalidTypedef2() {
    // https://github.com/dart-lang/sdk/issues/31171
    parseCompilationUnit(
        "typedef T = typedef F = Map<String, dynamic> Function();",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 7),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 7),
                expectedError(
                    ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE, 10, 1),
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 7),
                expectedError(
                    ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE, 20, 1),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 20, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 36, 7),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 43, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 43, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 55, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 55, 1),
              ]);
  }

  void test_invalidUnicodeEscape_incomplete_noDigits() {
    Expression expression = parseStringLiteral("'\\u{'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_UNICODE_ESCAPE, 1, 3)]);
  }

  void test_invalidUnicodeEscape_incomplete_someDigits() {
    Expression expression = parseStringLiteral("'\\u{0A'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_UNICODE_ESCAPE, 1, 5)]);
  }

  void test_invalidUnicodeEscape_invalidDigit() {
    Expression expression = parseStringLiteral("'\\u0 and some more'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_UNICODE_ESCAPE, 1, 3)]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    Expression expression = parseStringLiteral("'\\u04'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_UNICODE_ESCAPE, 1, 4)]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    Expression expression = parseStringLiteral("'\\u{}'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.INVALID_UNICODE_ESCAPE, 1, 4)]);
  }

  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    Expression expression = parseStringLiteral("'\\u{12345678}'");
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.INVALID_CODE_POINT, 1, 9)]
        : [
            expectedError(ParserErrorCode.INVALID_UNICODE_ESCAPE, 1, 12),
            expectedError(ParserErrorCode.INVALID_CODE_POINT, 1, 12)
          ]);
  }

  void test_libraryDirectiveNotFirst() {
    parseCompilationUnit("import 'x.dart'; library l;", errors: [
      expectedError(ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, 17, 7)
    ]);
  }

  void test_libraryDirectiveNotFirst_afterPart() {
    CompilationUnit unit = parseCompilationUnit("part 'a.dart';\nlibrary l;",
        errors: [
          expectedError(ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, 15, 7)
        ]);
    expect(unit, isNotNull);
  }

  void test_localFunction_annotation() {
    CompilationUnit unit =
        parseCompilationUnit("class C { m() { @Foo f() {} } }");
    expect(unit.declarations, hasLength(1));
    ClassDeclaration declaration = unit.declarations[0];
    expect(declaration.members, hasLength(1));
    MethodDeclaration member = declaration.members[0];
    BlockFunctionBody body = member.body;
    expect(body.block.statements, hasLength(1));
    FunctionDeclarationStatement statement = body.block.statements[0];
    if (usingFastaParser) {
      expect(statement.functionDeclaration.metadata, hasLength(1));
      Annotation metadata = statement.functionDeclaration.metadata[0];
      expect(metadata.name.name, 'Foo');
    }
  }

  void test_localFunctionDeclarationModifier_abstract() {
    parseCompilationUnit("class C { m() { abstract f() {} } }",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 16, 8)]
            : [
                expectedError(
                    ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, 16, 8)
              ]);
  }

  void test_localFunctionDeclarationModifier_external() {
    parseCompilationUnit("class C { m() { external f() {} } }",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 16, 8)]
            : [
                expectedError(
                    ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, 16, 8)
              ]);
  }

  void test_localFunctionDeclarationModifier_factory() {
    parseCompilationUnit("class C { m() { factory f() {} } }",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 16, 7)]
            : [
                expectedError(
                    ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, 16, 7)
              ]);
  }

  void test_localFunctionDeclarationModifier_static() {
    parseCompilationUnit("class C { m() { static f() {} } }",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 16, 6)]
            : [
                expectedError(
                    ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, 16, 6)
              ]);
  }

  void test_method_invalidTypeParameterExtends() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25739.

    // TODO(jmesserly): ideally we'd be better at parser recovery here.
    createParser('f<E>(E extends num p);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 7)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0,
                0), // `extends` is a keyword
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 0), // comma
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 0), // close paren
            expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 0, 0)
          ]);
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(
        method.parameters.toString(), usingFastaParser ? '(E)' : '(E, extends)',
        reason: 'parser recovers what it can');
  }

  void test_method_invalidTypeParameters() {
    createParser('void m<E, hello!>() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 5)]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 0) /*>*/,
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 0),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 0) /*(*/,
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 0) /*)*/,
            expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 0, 0)
          ]);
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.typeParameters.toString(), '<E, hello>',
        reason: 'parser recovers what it can');
  }

  void test_missingAssignableSelector_identifiersAssigned() {
    parseExpression("x.y = y;", expectedEndOffset: 7);
  }

  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    parseExpression("--0", errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 2, 1)
    ]);
  }

  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    parseExpression("++0", errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 2, 1)
    ]);
  }

  void test_missingAssignableSelector_selector() {
    parseExpression("x(y)(z).a++");
  }

  void test_missingAssignableSelector_superPrimaryExpression() {
    CompilationUnit unit = parseCompilationUnit('main() {super;}', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 8, 5)
    ]);
    FunctionDeclaration declaration = unit.declarations.first;
    BlockFunctionBody blockBody = declaration.functionExpression.body;
    ExpressionStatement statement = blockBody.block.statements.first;
    Expression expression = statement.expression;
    expect(expression, isSuperExpression);
    SuperExpression superExpression = expression;
    expect(superExpression.superKeyword, isNotNull);
  }

  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    parseExpression("super.x = x;", expectedEndOffset: 11);
  }

  void test_missingCatchOrFinally() {
    TryStatement statement = parseStatement('try {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_CATCH_OR_FINALLY, 0, 3)]);
    expect(statement, isNotNull);
  }

  void test_missingClassBody() {
    parseCompilationUnit("class A class B {}",
        errors: [expectedError(ParserErrorCode.MISSING_CLASS_BODY, 6, 1)]);
  }

  void test_missingClosingParenthesis() {
    createParser('(int a, int b ;',
        expectedEndOffset: 14 /* parsing ends at synthetic ')' */);
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.errors
        .contains(expectedError(ParserErrorCode.EXPECTED_TOKEN, 14, 1));
  }

  void test_missingConstFinalVarOrType_static() {
    parseCompilationUnit("class A { static f; }", errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 17, 1)
    ]);
  }

  void test_missingConstFinalVarOrType_topLevel() {
    parseCompilationUnit('a;', errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 0, 1)
    ]);
  }

  void test_missingEnumBody() {
    createParser('enum E;', expectedEndOffset: 6);
    EnumDeclaration declaration = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(declaration);
    listener
        .assertErrors([expectedError(ParserErrorCode.MISSING_ENUM_BODY, 6, 1)]);
  }

  void test_missingEnumComma() {
    createParser('enum E {one two}');
    EnumDeclaration declaration = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(declaration);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 3)]);
  }

  void test_missingExpressionInThrow() {
    ThrowExpression expression =
        (parseStatement('throw;') as ExpressionStatement).expression;
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_EXPRESSION_IN_THROW, 5, 1)]);
  }

  void test_missingFunctionBody_emptyNotAllowed() {
    createParser(';');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 0, 1)]);
  }

  void test_missingFunctionBody_invalid() {
    createParser('return 0;');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 0, 6)]);
  }

  void test_missingFunctionParameters_local_nonVoid_block() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    parseStatement("int f { return x;}", expectedEndOffset: 6);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 1)]);
  }

  void test_missingFunctionParameters_local_nonVoid_expression() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    parseStatement("int f => x;");
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 6, 2)]
        : [expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 3)]);
  }

  void test_missingFunctionParameters_local_void_block() {
    parseStatement("void f { return x;}", expectedEndOffset: 7);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 1)]
        : [expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 5, 1)]);
  }

  void test_missingFunctionParameters_local_void_expression() {
    parseStatement("void f => x;");
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 7, 2)]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    parseCompilationUnit("int f { return x;}", errors: [
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 4, 1)
    ]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    parseCompilationUnit("int f => x;", errors: [
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 4, 1)
    ]);
  }

  void test_missingFunctionParameters_topLevel_void_block() {
    CompilationUnit unit = parseCompilationUnit("void f { return x;}", errors: [
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 5, 1)
    ]);
    FunctionDeclaration funct = unit.declarations[0];
    expect(funct.functionExpression.parameters, hasLength(0));
  }

  void test_missingFunctionParameters_topLevel_void_expression() {
    CompilationUnit unit = parseCompilationUnit("void f => x;", errors: [
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 5, 1)
    ]);
    FunctionDeclaration funct = unit.declarations[0];
    expect(funct.functionExpression.parameters, hasLength(0));
  }

  void test_missingIdentifier_afterOperator() {
    createParser('1 *');
    BinaryExpression expression = parser.parseMultiplicativeExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 3, 0)]);
  }

  void test_missingIdentifier_beforeClosingCurly() {
    createParser('int}', expectedEndOffset: 3);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(
                ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 0, 3),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 3)
          ]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 3, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 1)
          ]);
  }

  void test_missingIdentifier_inEnum() {
    createParser('enum E {, TWO}');
    EnumDeclaration declaration = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(declaration);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1)]);
  }

  void test_missingIdentifier_inParameterGroupNamed() {
    createParser('(a, {})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 1)]);
  }

  void test_missingIdentifier_inParameterGroupOptional() {
    createParser('(a, [])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    if (usingFastaParser) {
      listener.assertErrors(
          [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 1)]);
    } else {
      listener.assertErrors([
        expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 1),
        expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 1)
      ]);
    }
  }

  void test_missingIdentifier_inSymbol_afterPeriod() {
    SymbolLiteral literal = parseSymbolLiteral('#a.');
    expectNotNullIfNoErrors(literal);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 3, 1)]);
  }

  void test_missingIdentifier_inSymbol_first() {
    SymbolLiteral literal = parseSymbolLiteral('#');
    expectNotNullIfNoErrors(literal);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 1, 1)]);
  }

  void test_missingIdentifierForParameterGroup() {
    createParser('(,)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 1, 1)]);
  }

  void test_missingKeywordOperator() {
    createParser('+(x) {}');
    MethodDeclaration method = parser.parseClassMember('C');
    expectNotNullIfNoErrors(method);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_KEYWORD_OPERATOR, 0, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember() {
    createParser('+() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_KEYWORD_OPERATOR, 0, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    createParser('int +() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_KEYWORD_OPERATOR, 4, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    createParser('void +() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_KEYWORD_OPERATOR, 5, 1)]);
  }

  void test_missingMethodParameters_void_block() {
    createParser('void m {} }', expectedEndOffset: 10);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS,
          usingFastaParser ? 5 : 7, 1)
    ]);
    expect(member, isMethodDeclaration);
    MethodDeclaration method = member;
    expect(method.parameters, hasLength(0));
  }

  void test_missingMethodParameters_void_expression() {
    createParser('void m => null; }', expectedEndOffset: 16);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS,
          usingFastaParser ? 5 : 7, 1)
    ]);
  }

  void test_missingNameForNamedParameter_colon() {
    createParser('({int : 0})');
    FormalParameter parameter =
        parser.parseFormalParameterList(inFunctionType: true).parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1),
            expectedError(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 6, 1)
          ]
        : [
            expectedError(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 8, 1),
            expectedError(
                ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER, 7, 1)
          ]);
    expect(parameter.identifier, isNotNull);
  }

  void test_missingNameForNamedParameter_equals() {
    createParser('({int = 0})');
    FormalParameter parameter =
        parser.parseFormalParameterList(inFunctionType: true).parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1),
            expectedError(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 6, 1)
          ]
        : [
            expectedError(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 8, 1),
            expectedError(
                ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER, 7, 1)
          ]);
    expect(parameter.identifier, isNotNull);
  }

  void test_missingNameForNamedParameter_noDefault() {
    createParser('({int})');
    FormalParameter parameter =
        parser.parseFormalParameterList(inFunctionType: true).parameters[0];
    expectNotNullIfNoErrors(parameter);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 1)]
        : [
            expectedError(
                ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER, 5, 1)
          ]);
    expect(parameter.identifier, isNotNull);
  }

  void test_missingNameInLibraryDirective() {
    CompilationUnit unit = parseCompilationUnit("library;", errors: [
      expectedError(
          usingFastaParser
              ? ParserErrorCode.MISSING_IDENTIFIER
              : ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE,
          7,
          1)
    ]);
    expect(unit, isNotNull);
  }

  void test_missingNameInPartOfDirective() {
    CompilationUnit unit = parseCompilationUnit("part of;", errors: [
      expectedError(
          usingFastaParser
              ? ParserErrorCode.EXPECTED_STRING_LITERAL
              : ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE,
          7,
          1)
    ]);
    expect(unit, isNotNull);
  }

  void test_missingPrefixInDeferredImport() {
    parseCompilationUnit("import 'foo.dart' deferred;", errors: [
      expectedError(ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT, 18, 8)
    ]);
  }

  void test_missingStartAfterSync() {
    createParser('sync {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_STAR_AFTER_SYNC, 0, 4)]);
  }

  void test_missingStatement() {
    parseStatement("is");
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 2),
            expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 2, 0),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 2, 0)
          ]
        : [expectedError(ParserErrorCode.MISSING_STATEMENT, 2, 0)]);
  }

  void test_missingStatement_afterVoid() {
    parseStatement("void;");
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)]
        : [expectedError(ParserErrorCode.MISSING_STATEMENT, 4, 1)]);
  }

  void test_missingTerminatorForParameterGroup_named() {
    createParser('(a, {b: 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener
        .assertErrors([expectedError(ScannerErrorCode.EXPECTED_TOKEN, 9, 1)]);
  }

  void test_missingTerminatorForParameterGroup_optional() {
    createParser('(a, [b = 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener
        .assertErrors([expectedError(ScannerErrorCode.EXPECTED_TOKEN, 10, 1)]);
  }

  void test_missingTypedefParameters_nonVoid() {
    parseCompilationUnit("typedef int F;", errors: [
      expectedError(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, 13, 1)
    ]);
  }

  void test_missingTypedefParameters_typeParameters() {
    parseCompilationUnit("typedef F<E>;", errors: [
      expectedError(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, 12, 1)
    ]);
  }

  void test_missingTypedefParameters_void() {
    parseCompilationUnit("typedef void F;", errors: [
      expectedError(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, 14, 1)
    ]);
  }

  void test_missingVariableInForEach() {
    Statement statement = parseStatement('for (a < b in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 1)]
        : [expectedError(ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH, 5, 5)]);
  }

  void test_mixedParameterGroups_namedPositional() {
    createParser('(a, {b}, [c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]
        : [expectedError(ParserErrorCode.MIXED_PARAMETER_GROUPS, 9, 3)]);
  }

  void test_mixedParameterGroups_positionalNamed() {
    createParser('(a, [b], {c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]
        : [expectedError(ParserErrorCode.MIXED_PARAMETER_GROUPS, 9, 3)]);
  }

  void test_mixin_application_lacks_with_clause() {
    parseCompilationUnit("class Foo = Bar;",
        errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 15, 1)]);
  }

  void test_multipleExtendsClauses() {
    parseCompilationUnit("class A extends B extends C {}", errors: [
      expectedError(ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES, 18, 7)
    ]);
  }

  void test_multipleImplementsClauses() {
    parseCompilationUnit("class A implements B implements C {}", errors: [
      expectedError(ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES, 21, 10)
    ]);
  }

  void test_multipleLibraryDirectives() {
    parseCompilationUnit("library l; library m;", errors: [
      expectedError(ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES, 11, 7)
    ]);
  }

  void test_multipleNamedParameterGroups() {
    createParser('(a, {b}, {c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]
        : [
            expectedError(ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS, 9, 3)
          ]);
  }

  void test_multiplePartOfDirectives() {
    parseCompilationUnit("part of l; part of m;", errors: [
      expectedError(ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES, 11, 4)
    ]);
  }

  void test_multiplePositionalParameterGroups() {
    createParser('(a, [b], [c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]
        : [
            expectedError(
                ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS, 9, 3)
          ]);
  }

  void test_multipleVariablesInForEach() {
    Statement statement = parseStatement('for (int a, b in foo) {}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 10, 1)]
        : [
            expectedError(ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH, 12, 1)
          ]);
  }

  void test_multipleWithClauses() {
    parseCompilationUnit("class A extends B with C with D {}",
        errors: [expectedError(ParserErrorCode.MULTIPLE_WITH_CLAUSES, 25, 4)]);
  }

  void test_namedFunctionExpression() {
    Expression expression;
    if (usingFastaParser) {
      createParser('f() {}');
      expression = parser.parsePrimaryExpression();
      listener.assertErrors(
          [expectedError(ParserErrorCode.NAMED_FUNCTION_EXPRESSION, 0, 1)]);
      expect(expression, isFunctionExpression);
    } else {
      expression = parsePrimaryExpression('f() {}');
      expectNotNullIfNoErrors(expression);
      // Should generate an error.
      //listener.assertErrors(
      //    [expectedError(ParserErrorCode.NAMED_FUNCTION_EXPRESSION, 0, 1)]);
      //expect(expression, isFunctionExpression);
    }
  }

  void test_namedParameterOutsideGroup() {
    createParser('(a, b : 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(
        [expectedError(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, 6, 1)]);
    expect(list.parameters[0].isRequired, isTrue);
    expect(list.parameters[1].isNamed, isTrue);
  }

  void test_nonConstructorFactory_field() {
    createParser('factory int x;', expectedEndOffset: 12);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 12, 1),
            expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 12, 1)
          ]
        : [expectedError(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, 0, 7)]);
  }

  void test_nonConstructorFactory_method() {
    createParser('factory int m() {}', expectedEndOffset: 12);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 12, 1),
            expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 12, 1)
          ]
        : [expectedError(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, 0, 7)]);
  }

  void test_nonIdentifierLibraryName_library() {
    CompilationUnit unit = parseCompilationUnit("library 'lib';", errors: [
      usingFastaParser
          ? expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 5)
          : expectedError(ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME, 8, 5)
    ]);
    expect(unit, isNotNull);
  }

  void test_nonIdentifierLibraryName_partOf() {
    CompilationUnit unit = parseCompilationUnit("part of 3;",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.EXPECTED_STRING_LITERAL, 8, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 8, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 9, 1)
              ]
            : [
                expectedError(
                    ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE, 8, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 8, 1)
              ]);
    expect(unit, isNotNull);
  }

  void test_nonPartOfDirectiveInPart_after() {
    parseCompilationUnit("part of l; part 'f.dart';", errors: [
      expectedError(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, 11, 4)
    ]);
  }

  void test_nonPartOfDirectiveInPart_before() {
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    parseCompilationUnit("part 'f.dart'; part of m;", codes: [
      ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART
    ], errors: [
      expectedError(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, 0, 4)
    ]);
  }

  void test_nonUserDefinableOperator() {
    createParser('operator +=(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.INVALID_OPERATOR
              : ParserErrorCode.NON_USER_DEFINABLE_OPERATOR,
          9,
          2)
    ]);
  }

  void test_optionalAfterNormalParameters_named() {
    parseCompilationUnit("f({a}, b) {}",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 1)]
            : [
                expectedError(
                    ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, 7, 1)
              ]);
  }

  void test_optionalAfterNormalParameters_positional() {
    parseCompilationUnit("f([a], b) {}",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 1)]
            : [
                expectedError(
                    ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, 7, 1)
              ]);
  }

  void test_parseCascadeSection_missingIdentifier() {
    MethodInvocation methodInvocation = parseCascadeSection('..()');
    expectNotNullIfNoErrors(methodInvocation);
    listener.assertErrors([
      // Cascade section is preceded by `null` in this test
      // and error is reported on '('.
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1)
    ]);
    expect(methodInvocation.target, isNull);
    expect(methodInvocation.methodName.name, "");
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList.arguments, hasLength(0));
  }

  void test_parseCascadeSection_missingIdentifier_typeArguments() {
    MethodInvocation methodInvocation = parseCascadeSection('..<E>()');
    expectNotNullIfNoErrors(methodInvocation);
    listener.assertErrors([
      // Cascade section is preceded by `null` in this test
      // and error is reported on '<'.
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1)
    ]);
    expect(methodInvocation.target, isNull);
    expect(methodInvocation.methodName.name, "");
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList.arguments, hasLength(0));
  }

  void test_positionalAfterNamedArgument() {
    createParser('(x: 1, 2)');
    ArgumentList list = parser.parseArgumentList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(
        [expectedError(ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT, 7, 1)]);
  }

  void test_positionalParameterOutsideGroup() {
    createParser('(a, b = 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, 6, 1)]
        : [
            expectedError(
                ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP, 4, 1)
          ]);
    expect(list.parameters[0].isRequired, isTrue);
    if (usingFastaParser) {
      expect(list.parameters[1].isNamed, isTrue);
    } else {
      expect(list.parameters[1].isOptionalPositional, isTrue);
    }
  }

  void test_redirectingConstructorWithBody_named() {
    createParser('C.x() : this() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY, 15,
          usingFastaParser ? 1 : 2)
    ]);
  }

  void test_redirectingConstructorWithBody_unnamed() {
    createParser('C() : this.x() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY, 15,
          usingFastaParser ? 1 : 2)
    ]);
  }

  void test_redirectionInNonFactoryConstructor() {
    createParser('C() = D;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(
          ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR, 4, 1)
    ]);
  }

  void test_setterInFunction_block() {
    parseStatement("set x(v) {_x = v;}");
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 0, 3)]
        : [expectedError(ParserErrorCode.SETTER_IN_FUNCTION, 0, 3)]);
  }

  void test_setterInFunction_expression() {
    parseStatement("set x(v) => _x = v;");
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 0, 3)]
        : [expectedError(ParserErrorCode.SETTER_IN_FUNCTION, 0, 3)]);
  }

  void test_staticAfterConst() {
    createParser('final static int f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.STATIC_AFTER_FINAL, 6, 6)]);
  }

  void test_staticAfterFinal() {
    createParser('const static int f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.STATIC_AFTER_CONST, 6, 6),
        expectedError(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 17, 1)
      ]);
    } else {
      listener.assertErrorsWithCodes([ParserErrorCode.STATIC_AFTER_CONST]);
    }
  }

  void test_staticAfterVar() {
    createParser('var static f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.STATIC_AFTER_VAR, 4, 6)]);
  }

  void test_staticConstructor() {
    createParser('static C.m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.STATIC_CONSTRUCTOR, 0, 6)]);
  }

  void test_staticGetterWithoutBody() {
    createParser('static get m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.MISSING_FUNCTION_BODY
              : ParserErrorCode.STATIC_GETTER_WITHOUT_BODY,
          12,
          1)
    ]);
  }

  void test_staticOperator_noReturnType() {
    createParser('static operator +(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.STATIC_OPERATOR, 0, 6)]);
  }

  void test_staticOperator_returnType() {
    createParser('static int operator +(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.STATIC_OPERATOR, 0, 6)]);
  }

  void test_staticSetterWithoutBody() {
    createParser('static set m(x);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.MISSING_FUNCTION_BODY
              : ParserErrorCode.STATIC_SETTER_WITHOUT_BODY,
          15,
          1)
    ]);
  }

  void test_staticTopLevelDeclaration_class() {
    parseCompilationUnit("static class C {}", errors: [
      expectedError(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, 0, 6)
    ]);
  }

  void test_staticTopLevelDeclaration_enum() {
    parseCompilationUnit("static enum E { v }", errors: [
      expectedError(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, 0, 6)
    ]);
  }

  void test_staticTopLevelDeclaration_function() {
    parseCompilationUnit("static f() {}", errors: [
      expectedError(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, 0, 6)
    ]);
  }

  void test_staticTopLevelDeclaration_typedef() {
    parseCompilationUnit("static typedef F();", errors: [
      expectedError(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, 0, 6)
    ]);
  }

  void test_staticTopLevelDeclaration_variable() {
    parseCompilationUnit("static var x;", errors: [
      expectedError(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, 0, 6)
    ]);
  }

  void test_string_unterminated_interpolation_block() {
    parseCompilationUnit(r'''
m() {
 {
 '${${
''',
        codes: usingFastaParser
            ? [
                ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
                ScannerErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ]
            : [
                ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
                ScannerErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.UNEXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_EXECUTABLE,
              ]);
  }

  void test_switchCase_missingColon() {
    SwitchStatement statement = parseStatement('switch (a) {case 1 return 0;}');
    expect(statement, isNotNull);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 19, 6)]);
  }

  void test_switchDefault_missingColon() {
    SwitchStatement statement =
        parseStatement('switch (a) {default return 0;}');
    expect(statement, isNotNull);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 6)]);
  }

  void test_switchHasCaseAfterDefaultCase() {
    SwitchStatement statement =
        parseStatement('switch (a) {default: return 0; case 1: return 1;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, 31, 4)
    ]);
  }

  void test_switchHasCaseAfterDefaultCase_repeated() {
    SwitchStatement statement = parseStatement(
        'switch (a) {default: return 0; case 1: return 1; case 2: return 2;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, 31, 4),
      expectedError(ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, 49, 4)
    ]);
  }

  void test_switchHasMultipleDefaultCases() {
    SwitchStatement statement =
        parseStatement('switch (a) {default: return 0; default: return 1;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, 31, 7)
    ]);
  }

  void test_switchHasMultipleDefaultCases_repeated() {
    SwitchStatement statement = parseStatement(
        'switch (a) {default: return 0; default: return 1; default: return 2;}');
    expectNotNullIfNoErrors(statement);
    listener.assertErrors([
      expectedError(ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, 31, 7),
      expectedError(ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, 50, 7)
    ]);
  }

  void test_switchMissingBlock() {
    SwitchStatement statement =
        parseStatement('switch (a) return;', expectedEndOffset: 11);
    expect(statement, isNotNull);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_BODY, 9, 1)]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 6),
            expectedError(ParserErrorCode.EXPECTED_CASE_OR_DEFAULT, 11, 6),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 6)
          ]);
  }

  void test_topLevel_getter() {
    createParser('get x => 7;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration function = member;
    expect(function.functionExpression.parameters, isNull);
  }

  void test_topLevelFactory_withFunction() {
    parseCompilationUnit('factory Function() x = null;', errors: [
      expectedError(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, 0, 7)
    ]);
  }

  void test_topLevelOperator_withFunction() {
    parseCompilationUnit('operator Function() x = null;',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.TOP_LEVEL_OPERATOR, 0, 8)]
            : [
                // Should be generating an error here.
              ]);
  }

  void test_topLevelOperator_withoutOperator() {
    createParser('+(bool x, bool y) => x | y;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.TOP_LEVEL_OPERATOR, 0, 1)]
        : [expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1)]);
  }

  void test_topLevelOperator_withoutType() {
    parseCompilationUnit('operator +(bool x, bool y) => x | y;',
        errors: [expectedError(ParserErrorCode.TOP_LEVEL_OPERATOR, 0, 8)]);
  }

  void test_topLevelOperator_withType() {
    parseCompilationUnit('bool operator +(bool x, bool y) => x | y;',
        errors: [expectedError(ParserErrorCode.TOP_LEVEL_OPERATOR, 5, 8)]);
  }

  void test_topLevelOperator_withVoid() {
    parseCompilationUnit('void operator +(bool x, bool y) => x | y;',
        errors: [expectedError(ParserErrorCode.TOP_LEVEL_OPERATOR, 5, 8)]);
  }

  void test_topLevelVariable_withMetadata() {
    parseCompilationUnit("String @A string;",
        codes: usingFastaParser
            ? [
                ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
              ]
            : [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
              ]);
  }

  void test_typedef_incomplete() {
    // TODO(brianwilkerson) Improve recovery for this case.
    parseCompilationUnit('''
class A {}
class B extends A {}

typedef T

main() {
  Function<
}
''',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 49, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 51, 1),
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 51, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 51, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 55, 8)
              ]);
  }

  void test_typedef_namedFunction() {
    parseCompilationUnit('typedef void Function();',
        codes: usingFastaParser
            ? [ParserErrorCode.MISSING_IDENTIFIER]
            : [
                ParserErrorCode.UNEXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_EXECUTABLE,
                ParserErrorCode.MISSING_TYPEDEF_PARAMETERS
              ]);
  }

  void test_typedefInClass_withoutReturnType() {
    parseCompilationUnit("class C { typedef F(x); }",
        errors: [expectedError(ParserErrorCode.TYPEDEF_IN_CLASS, 10, 7)]);
  }

  void test_typedefInClass_withReturnType() {
    parseCompilationUnit("class C { typedef int F(int x); }",
        errors: [expectedError(ParserErrorCode.TYPEDEF_IN_CLASS, 10, 7)]);
  }

  void test_unexpectedCommaThenInterpolation() {
    // https://github.com/Dart-Code/Dart-Code/issues/1548
    parseCompilationUnit(r"main() { String s = 'a' 'b', 'c$foo'; return s; }",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 29, 2),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 29, 2),
              ]
            : [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 29, 2),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 29, 1),
              ]);
  }

  void test_unexpectedTerminatorForParameterGroup_named() {
    createParser('(a, b})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.EXPECTED_TOKEN
              : ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP,
          5,
          1)
    ]);
  }

  void test_unexpectedTerminatorForParameterGroup_optional() {
    createParser('(a, b])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 1)]
        : [
            expectedError(
                ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, 5, 1)
          ]);
  }

  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    parseStatement("String s = (null));", expectedEndOffset: 17);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 16, 1)]
        : [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 17, 1)]);
  }

  void test_unexpectedToken_invalidPostfixExpression() {
    parseExpression("f()++", errors: [
      expectedError(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 3, 2)
    ]);
  }

  void test_unexpectedToken_invalidPrefixExpression() {
    parseExpression("++f()", errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 4, 1)
    ]);
  }

  void test_unexpectedToken_returnInExpressionFunctionBody() {
    parseCompilationUnit("f() => return null;",
        errors: [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 6)]);
  }

  void test_unexpectedToken_semicolonBetweenClassMembers() {
    createParser('class C { int x; ; int y;}');
    ClassDeclaration declaration = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(declaration);
    listener.assertErrors([
      expectedError(
          usingFastaParser
              ? ParserErrorCode.EXPECTED_CLASS_MEMBER
              : ParserErrorCode.UNEXPECTED_TOKEN,
          17,
          1)
    ]);
  }

  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    parseCompilationUnit("int x; ; int y;",
        errors: [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 1)]);
  }

  void test_unterminatedString_at_eof() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    parseCompilationUnit(r'''
void main() {
  var x = "''', errors: [
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 24, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 25, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 24, 1)
    ]);
  }

  void test_unterminatedString_at_eol() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    parseCompilationUnit(r'''
void main() {
  var x = "
;
}
''', errors: [
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 24, 1)
    ]);
  }

  void test_unterminatedString_multiline_at_eof_3_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    parseCompilationUnit(r'''
void main() {
  var x = """''', codes: [
      ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
      ScannerErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN
    ], errors: [
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 24, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 30, 0),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 30, 0)
    ]);
  }

  void test_unterminatedString_multiline_at_eof_4_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    parseCompilationUnit(r'''
void main() {
  var x = """"''', codes: [
      ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
      ScannerErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN
    ], errors: [
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 24, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 31, 0),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 31, 0)
    ]);
  }

  void test_unterminatedString_multiline_at_eof_5_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson) Remove codes when highlighting is fixed.
    parseCompilationUnit(r'''
void main() {
  var x = """""''', codes: [
      ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
      ScannerErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN
    ], errors: [
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 28, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 32, 0),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 32, 0)
    ]);
  }

  void test_useOfUnaryPlusOperator() {
    createParser('+x');
    Expression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 1)]);
    if (usingFastaParser) {
      BinaryExpression binaryExpression = expression;
      expect(binaryExpression.leftOperand.isSynthetic, isTrue);
      expect(binaryExpression.rightOperand.isSynthetic, isFalse);
      SimpleIdentifier identifier = binaryExpression.rightOperand;
      expect(identifier.name, 'x');
    } else {
      var identifier = expression as SimpleIdentifier;
      expect(identifier.isSynthetic, isTrue);
    }
  }

  void test_varAndType_field() {
    parseCompilationUnit("class C { var int x; }",
        errors: [expectedError(ParserErrorCode.VAR_AND_TYPE, 10, 3)]);
  }

  void test_varAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    parseStatement("var int x;");
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.VAR_AND_TYPE, 0, 3)]
        : [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 8, 1)]);
  }

  void test_varAndType_parameter() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    createParser('(var int x)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.VAR_AND_TYPE, 1, 3)]
        : [expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 1)]);
  }

  void test_varAndType_topLevelVariable() {
    parseCompilationUnit("var int x;",
        errors: [expectedError(ParserErrorCode.VAR_AND_TYPE, 0, 3)]);
  }

  void test_varAsTypeName_as() {
    parseExpression("x as var",
        expectedEndOffset: 5,
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 5, 3)]
            : [expectedError(ParserErrorCode.VAR_AS_TYPE_NAME, 7, 3)]);
  }

  void test_varClass() {
    parseCompilationUnit("var class C {}",
        errors: usingFastaParser
            ? [
                // Fasta interprets the `var` as a malformed top level var
                // and `class` as the start of a class declaration.
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 5),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 5),
              ]
            : [expectedError(ParserErrorCode.VAR_CLASS, 0, 3)]);
  }

  void test_varEnum() {
    parseCompilationUnit("var enum E {ONE}",
        errors: usingFastaParser
            ? [
                // Fasta interprets the `var` as a malformed top level var
                // and `enum` as the start of an enum declaration.
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 4),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 4),
              ]
            : [expectedError(ParserErrorCode.VAR_ENUM, 0, 3)]);
  }

  void test_varReturnType() {
    createParser('var m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrors([expectedError(ParserErrorCode.VAR_RETURN_TYPE, 0, 3)]);
  }

  void test_varTypedef() {
    parseCompilationUnit("var typedef F();",
        errors: usingFastaParser
            ? [
                // Fasta interprets the `var` as a malformed top level var
                // and `typedef` as the start of an typedef declaration.
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 7),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 7),
              ]
            : [expectedError(ParserErrorCode.VAR_TYPEDEF, 0, 3)]);
  }

  void test_voidParameter() {
    NormalFormalParameter parameter =
        parseFormalParameterList('(void a)').parameters[0];
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
    parseCompilationUnit("class A with B extends C {}",
        errors: [expectedError(ParserErrorCode.WITH_BEFORE_EXTENDS, 15, 7)]);
  }

  void test_withWithoutExtends() {
    createParser('class A with B, C {}');
    ClassDeclaration declaration = parseFullCompilationUnitMember();
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
  }

  void test_wrongSeparatorForPositionalParameter() {
    createParser('(a, [b : 0])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrors([
      expectedError(
          ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER, 7, 1)
    ]);
  }

  void test_wrongTerminatorForParameterGroup_named() {
    createParser('(a, {b, c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    // fasta scanner generates '(a, {b, c]})' where '}' is synthetic
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 1),
        expectedError(ScannerErrorCode.EXPECTED_TOKEN, 10, 1)
      ]);
    } else {
      listener.assertErrors([
        expectedError(ScannerErrorCode.EXPECTED_TOKEN, 9, 1),
        expectedError(
            ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, 9, 1)
      ]);
    }
  }

  void test_wrongTerminatorForParameterGroup_optional() {
    createParser('(a, [b, c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    // fasta scanner generates '(a, [b, c}])' where ']' is synthetic
    if (usingFastaParser) {
      listener.assertErrors([
        expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 1),
        expectedError(ScannerErrorCode.EXPECTED_TOKEN, 10, 1)
      ]);
    } else {
      listener.assertErrors([
        expectedError(ScannerErrorCode.EXPECTED_TOKEN, 4, 1),
        expectedError(
            ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, 10, 1)
      ]);
    }
  }
}

@reflectiveTest
class ExpressionParserTest extends ParserTestCase
    with ExpressionParserTestMixin {}

mixin ExpressionParserTestMixin implements AbstractParserTestCase {
  void test_namedArgument() {
    var invocation = parseExpression('m(a: 1, b: 2)') as MethodInvocation;
    List<Expression> arguments = invocation.argumentList.arguments;

    var a = arguments[0] as NamedExpression;
    expect(a.name.label.name, 'a');
    expect(a.expression, isNotNull);

    var b = arguments[1] as NamedExpression;
    expect(b.name.label.name, 'b');
    expect(b.expression, isNotNull);
  }

  void test_parseAdditiveExpression_normal() {
    Expression expression = parseAdditiveExpression('x + y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.PLUS);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseAdditiveExpression_super() {
    Expression expression = parseAdditiveExpression('super + y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.PLUS);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseAssignableExpression_expression_args_dot() {
    Expression expression = parseAssignableExpression('(x)(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    FunctionExpressionInvocation invocation =
        propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    expect(invocation.typeArguments, isNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_args_dot_typeArguments() {
    Expression expression = parseAssignableExpression('(x)<F>(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    FunctionExpressionInvocation invocation =
        propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_dot() {
    Expression expression = parseAssignableExpression('(x).y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_index() {
    Expression expression = parseAssignableExpression('(x)[y]', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_expression_question_dot() {
    Expression expression = parseAssignableExpression('(x)?.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier() {
    Expression expression = parseAssignableExpression('x', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as SimpleIdentifier;
    expect(identifier, isNotNull);
  }

  void test_parseAssignableExpression_identifier_args_dot() {
    Expression expression = parseAssignableExpression('x(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    expect(invocation.typeArguments, isNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_args_dot_typeArguments() {
    Expression expression = parseAssignableExpression('x<E>(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_dot() {
    Expression expression = parseAssignableExpression('x.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as PrefixedIdentifier;
    expect(identifier.prefix.name, 'x');
    expect(identifier.period, isNotNull);
    expect(identifier.period.type, TokenType.PERIOD);
    expect(identifier.identifier.name, 'y');
  }

  void test_parseAssignableExpression_identifier_index() {
    Expression expression = parseAssignableExpression('x[y]', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_identifier_question_dot() {
    Expression expression = parseAssignableExpression('x?.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_super_dot() {
    Expression expression = parseAssignableExpression('super.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isSuperExpression);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_super_index() {
    Expression expression = parseAssignableExpression('super[y]', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isSuperExpression);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_dot() {
    Expression expression = parseAssignableSelector('.x', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableSelector_index() {
    Expression expression = parseAssignableSelector('[x]', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_none() {
    Expression expression = parseAssignableSelector('', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as SimpleIdentifier;
    expect(identifier, isNotNull);
  }

  void test_parseAssignableSelector_question_dot() {
    Expression expression = parseAssignableSelector('?.x', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAwaitExpression() {
    AwaitExpression expression = parseAwaitExpression('await x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.awaitKeyword, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseBitwiseAndExpression_normal() {
    Expression expression = parseBitwiseAndExpression('x & y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseAndExpression_super() {
    Expression expression = parseBitwiseAndExpression('super & y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_normal() {
    Expression expression = parseBitwiseOrExpression('x | y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_super() {
    Expression expression = parseBitwiseOrExpression('super | y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_normal() {
    Expression expression = parseBitwiseXorExpression('x ^ y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.CARET);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_super() {
    Expression expression = parseBitwiseXorExpression('super ^ y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.CARET);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseCascadeSection_i() {
    Expression expression = parseCascadeSection('..[i]');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as IndexExpression;
    expect(section.target, isNull);
    expect(section.leftBracket, isNotNull);
    expect(section.index, isNotNull);
    expect(section.rightBracket, isNotNull);
  }

  void test_parseCascadeSection_ia() {
    Expression expression = parseCascadeSection('..[i](b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isIndexExpression);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ia_typeArguments() {
    Expression expression = parseCascadeSection('..[i]<E>(b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isIndexExpression);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ii() {
    Expression expression = parseCascadeSection('..a(b).c(d)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isMethodInvocation);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_ii_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b).c<F>(d)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isMethodInvocation);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_p() {
    Expression expression = parseCascadeSection('..a');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_p_assign() {
    Expression expression = parseCascadeSection('..a = 3');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as AssignmentExpression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isNotNull);
  }

  void test_parseCascadeSection_p_assign_withCascade() {
    Expression expression = parseCascadeSection('..a = 3..m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as AssignmentExpression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isIntegerLiteral);
  }

  void test_parseCascadeSection_p_assign_withCascade_typeArguments() {
    Expression expression = parseCascadeSection('..a = 3..m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as AssignmentExpression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isIntegerLiteral);
  }

  void test_parseCascadeSection_p_builtIn() {
    Expression expression = parseCascadeSection('..as');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pa() {
    Expression expression = parseCascadeSection('..a(b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pa_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa() {
    Expression expression = parseCascadeSection('..a(b)(c)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b)<F>(c)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa() {
    Expression expression = parseCascadeSection('..a(b)(c).d(e)(f)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa_typeArguments() {
    Expression expression =
        parseCascadeSection('..a<E>(b)<F>(c).d<G>(e)<H>(f)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pap() {
    Expression expression = parseCascadeSection('..a(b).c');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pap_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b).c');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseConditionalExpression() {
    ConditionalExpression expression = parseConditionalExpression('x ? y : z');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.condition, isNotNull);
    expect(expression.question, isNotNull);
    expect(expression.thenExpression, isNotNull);
    expect(expression.colon, isNotNull);
    expect(expression.elseExpression, isNotNull);
  }

  void test_parseConstExpression_instanceCreation() {
    Expression expression = parseConstExpression('const A()');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isInstanceCreationExpression);
    InstanceCreationExpression instanceCreation = expression;
    expect(instanceCreation.keyword, isNotNull);
    ConstructorName name = instanceCreation.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(instanceCreation.argumentList, isNotNull);
  }

  void test_parseConstExpression_listLiteral_typed() {
    Expression expression = parseConstExpression('const <A> []');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_listLiteral_untyped() {
    Expression expression = parseConstExpression('const []');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_typed() {
    Expression expression = parseConstExpression('const <A, B> {}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_typed_missingGt() {
    Expression expression = parseExpression('const <A, B {}',
        errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1)]);
    expect(expression, isNotNull);
    var literal = expression as SetOrMapLiteral;
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_untyped() {
    Expression expression = parseConstExpression('const {}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNull);
  }

  void test_parseEqualityExpression_normal() {
    BinaryExpression expression = parseEqualityExpression('x == y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseEqualityExpression_super() {
    BinaryExpression expression = parseEqualityExpression('super == y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isSuperExpression);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseExpression_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    Expression expression = parseExpression('x = y');
    var assignmentExpression = expression as AssignmentExpression;
    expect(assignmentExpression.leftHandSide, isNotNull);
    expect(assignmentExpression.operator, isNotNull);
    expect(assignmentExpression.operator.type, TokenType.EQ);
    expect(assignmentExpression.rightHandSide, isNotNull);
  }

  void test_parseExpression_assign_compound() {
    if (usingFastaParser && AbstractScanner.LAZY_ASSIGNMENT_ENABLED) {
      Expression expression = parseExpression('x ||= y');
      var assignmentExpression = expression as AssignmentExpression;
      expect(assignmentExpression.leftHandSide, isNotNull);
      expect(assignmentExpression.operator, isNotNull);
      expect(assignmentExpression.operator.type, TokenType.BAR_BAR_EQ);
      expect(assignmentExpression.rightHandSide, isNotNull);
    }
  }

  void test_parseExpression_comparison() {
    Expression expression = parseExpression('--a.b == c');
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.EQ_EQ);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseExpression_constAndTypeParameters() {
    Expression expression = parseExpression('const <E>',
        codes: usingFastaParser
            ? [
                // TODO(danrubel): Improve this error message.
                ParserErrorCode.EXPECTED_TOKEN
              ]
            : [ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL]);
    expect(expression, isNotNull);
  }

  void test_parseExpression_function_async() {
    Expression expression = parseExpression('() async {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isTrue);
    expect(functionExpression.body.isGenerator, isFalse);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_asyncStar() {
    Expression expression = parseExpression('() async* {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isTrue);
    expect(functionExpression.body.isGenerator, isTrue);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_sync() {
    Expression expression = parseExpression('() {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isFalse);
    expect(functionExpression.body.isGenerator, isFalse);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_syncStar() {
    Expression expression = parseExpression('() sync* {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isFalse);
    expect(functionExpression.body.isGenerator, isTrue);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_invokeFunctionExpression() {
    Expression expression = parseExpression('(a) {return a + a;} (3)');
    var invocation = expression as FunctionExpressionInvocation;
    expect(invocation.function, isFunctionExpression);
    FunctionExpression functionExpression =
        invocation.function as FunctionExpression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
    expect(invocation.typeArguments, isNull);
    ArgumentList list = invocation.argumentList;
    expect(list, isNotNull);
    expect(list.arguments, hasLength(1));
  }

  void test_parseExpression_nonAwait() {
    Expression expression = parseExpression('await()');
    var invocation = expression as MethodInvocation;
    expect(invocation.methodName.name, 'await');
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_sendWithTypeParam_afterIndex() {
    final unit = parseCompilationUnit('main() { factories[C]<num, int>(); }');
    expect(unit.declarations, hasLength(1));
    FunctionDeclaration mainMethod = unit.declarations[0];
    BlockFunctionBody body = mainMethod.functionExpression.body;
    NodeList<Statement> statements = body.block.statements;
    expect(statements, hasLength(1));
    ExpressionStatement statement = statements[0];
    FunctionExpressionInvocation expression = statement.expression;

    IndexExpression function = expression.function;
    SimpleIdentifier target = function.target;
    expect(target.name, 'factories');
    SimpleIdentifier index = function.index;
    expect(index.name, 'C');

    NodeList<TypeAnnotation> typeArguments = expression.typeArguments.arguments;
    expect(typeArguments, hasLength(2));
    expect((typeArguments[0] as NamedType).name.name, 'num');
    expect((typeArguments[1] as NamedType).name.name, 'int');

    expect(expression.argumentList.arguments, hasLength(0));
  }

  void test_parseExpression_sendWithTypeParam_afterSend() {
    final unit = parseCompilationUnit('main() { factories(C)<num, int>(); }');
    expect(unit.declarations, hasLength(1));
    FunctionDeclaration mainMethod = unit.declarations[0];
    BlockFunctionBody body = mainMethod.functionExpression.body;
    NodeList<Statement> statements = body.block.statements;
    expect(statements, hasLength(1));
    ExpressionStatement statement = statements[0];
    FunctionExpressionInvocation expression = statement.expression;

    MethodInvocation invocation = expression.function;
    expect(invocation.methodName.name, 'factories');
    NodeList<Expression> invocationArguments =
        invocation.argumentList.arguments;
    expect(invocationArguments, hasLength(1));
    SimpleIdentifier index = invocationArguments[0];
    expect(index.name, 'C');

    NodeList<TypeAnnotation> typeArguments = expression.typeArguments.arguments;
    expect(typeArguments, hasLength(2));
    expect((typeArguments[0] as NamedType).name.name, 'num');
    expect((typeArguments[1] as NamedType).name.name, 'int');

    expect(expression.argumentList.arguments, hasLength(0));
  }

  void test_parseExpression_superMethodInvocation() {
    Expression expression = parseExpression('super.m()');
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_superMethodInvocation_typeArguments() {
    Expression expression = parseExpression('super.m<E>()');
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_superMethodInvocation_typeArguments_chained() {
    Expression expression = parseExpression('super.b.c<D>()');
    MethodInvocation invocation = expression as MethodInvocation;
    Expression target = invocation.target;
    expect(target, isPropertyAccess);
    expect(invocation.methodName, isNotNull);
    expect(invocation.methodName.name, 'c');
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpressionList_multiple() {
    List<Expression> result = parseExpressionList('1, 2, 3');
    expect(result, isNotNull);
    assertNoErrors();
    expect(result, hasLength(3));
  }

  void test_parseExpressionList_single() {
    List<Expression> result = parseExpressionList('1');
    expect(result, isNotNull);
    assertNoErrors();
    expect(result, hasLength(1));
  }

  void test_parseExpressionWithoutCascade_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    Expression expression = parseExpressionWithoutCascade('x = y');
    expect(expression, isNotNull);
    assertNoErrors();
    var assignmentExpression = expression as AssignmentExpression;
    expect(assignmentExpression.leftHandSide, isNotNull);
    expect(assignmentExpression.operator, isNotNull);
    expect(assignmentExpression.operator.type, TokenType.EQ);
    expect(assignmentExpression.rightHandSide, isNotNull);
  }

  void test_parseExpressionWithoutCascade_comparison() {
    Expression expression = parseExpressionWithoutCascade('--a.b == c');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.EQ_EQ);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    Expression expression = parseExpressionWithoutCascade('super.m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void
      test_parseExpressionWithoutCascade_superMethodInvocation_typeArguments() {
    Expression expression = parseExpressionWithoutCascade('super.m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseFunctionExpression_body_inExpression() {
    FunctionExpression expression = parseFunctionExpression('(int i) => i++');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseFunctionExpression_constAndTypeParameters2() {
    FunctionExpression expression =
        parseFunctionExpression('const <E>(E i) => i++');
    expect(expression, isNotNull);
    assertErrorsWithCodes(usingFastaParser
        ? [ParserErrorCode.UNEXPECTED_TOKEN]
        : [
            ParserErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR,
            ParserErrorCode.MISSING_CLOSING_PARENTHESIS,
          ]);
    expect(expression.body, isNotNull);
    if (usingFastaParser) {
      expect(expression.typeParameters, isNotNull);
      expect(expression.parameters, isNotNull);
      expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
    }
  }

  void test_parseFunctionExpression_functionInPlaceOfTypeName() {
    Expression expression = parseExpression('<test(' ', (){});>[0, 1, 2]',
        codes: usingFastaParser
            ? [ParserErrorCode.EXPECTED_TOKEN]
            : [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL,
              ]);
    expect(expression, isNotNull);
    if (usingFastaParser) {
      ListLiteral literal = expression;
      expect(literal.typeArguments.arguments, hasLength(1));
    }
  }

  void test_parseFunctionExpression_typeParameters() {
    FunctionExpression expression = parseFunctionExpression('<E>(E i) => i++');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type.name.name, 'A.B');
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B.c()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void
      test_parseInstanceCreationExpression_qualifiedType_named_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B<E>.c()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B<E>()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.c()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpressionImpl expression =
        parseInstanceCreationExpression('A<B>.c()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
    expect(expression.typeArguments, isNull);
  }

  void test_parseInstanceCreationExpression_type_named_typeArguments_34403() {
    if (!usingFastaParser) {
      return;
    }
    InstanceCreationExpressionImpl expression =
        parseExpression('new a.b.c<C>()', errors: [
      expectedError(
          StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          8,
          1)
    ]);
    expect(expression, isNotNull);
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
    expect(expression.typeArguments.arguments, hasLength(1));
  }

  void test_parseInstanceCreationExpression_type_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A<B>()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseListLiteral_empty_oneToken() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    ListLiteral literal = parseListLiteral(token, null, '[]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword.keyword, Keyword.CONST);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_empty_oneToken_withComment() {
    ListLiteral literal = parseListLiteral(null, null, '/* 0 */ []');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    Token leftBracket = literal.leftBracket;
    expect(leftBracket, isNotNull);
    expect(leftBracket.precedingComments, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_empty_twoTokens() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    ListLiteral literal = parseListLiteral(token, null, '[ ]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword.keyword, Keyword.CONST);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_multiple() {
    ListLiteral literal = parseListLiteral(null, null, '[1, 2, 3]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(3));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_single() {
    ListLiteral literal = parseListLiteral(null, null, '[1]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_single_withTypeArgument() {
    ListLiteral literal = parseListLiteral(null, '<int>', '[1]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_noType() {
    TypedLiteral literal = parseListOrMapLiteral(null, '[1]');
    expect(literal, isNotNull);
    assertNoErrors();
    var listLiteral = literal as ListLiteral;
    expect(listLiteral.constKeyword, isNull);
    expect(listLiteral.typeArguments, isNull);
    expect(listLiteral.leftBracket, isNotNull);
    expect(listLiteral.elements, hasLength(1));
    expect(listLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_type() {
    TypedLiteral literal = parseListOrMapLiteral(null, '<int> [1]');
    expect(literal, isNotNull);
    assertNoErrors();
    var listLiteral = literal as ListLiteral;
    expect(listLiteral.constKeyword, isNull);
    expect(listLiteral.typeArguments, isNotNull);
    expect(listLiteral.leftBracket, isNotNull);
    expect(listLiteral.elements, hasLength(1));
    expect(listLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_noType() {
    TypedLiteral literal = parseListOrMapLiteral(null, "{'1' : 1}");
    expect(literal, isNotNull);
    assertNoErrors();
    var mapLiteral = literal as SetOrMapLiteral;
    expect(mapLiteral.constKeyword, isNull);
    expect(mapLiteral.typeArguments, isNull);
    expect(mapLiteral.leftBracket, isNotNull);
    expect(mapLiteral.elements, hasLength(1));
    expect(mapLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_type() {
    TypedLiteral literal =
        parseListOrMapLiteral(null, "<String, int> {'1' : 1}");
    expect(literal, isNotNull);
    assertNoErrors();
    var mapLiteral = literal as SetOrMapLiteral;
    expect(mapLiteral.constKeyword, isNull);
    expect(mapLiteral.typeArguments, isNotNull);
    expect(mapLiteral.leftBracket, isNotNull);
    expect(mapLiteral.elements, hasLength(1));
    expect(mapLiteral.rightBracket, isNotNull);
  }

  void test_parseLogicalAndExpression() {
    Expression expression = parseLogicalAndExpression('x && y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND_AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseLogicalOrExpression() {
    Expression expression = parseLogicalOrExpression('x || y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR_BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseMapLiteral_empty() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    SetOrMapLiteral literal = parseMapLiteral(token, '<String, int>', '{}');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword.keyword, Keyword.CONST);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_multiple() {
    SetOrMapLiteral literal = parseMapLiteral(null, null, "{'a' : b, 'x' : y}");
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(2));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_multiple_trailing_comma() {
    SetOrMapLiteral literal =
        parseMapLiteral(null, null, "{'a' : b, 'x' : y,}");
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(2));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_single() {
    SetOrMapLiteral literal = parseMapLiteral(null, null, "{'x' : y}");
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteralEntry_complex() {
    MapLiteralEntry entry = parseMapLiteralEntry('2 + 2 : y');
    expect(entry, isNotNull);
    assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_int() {
    MapLiteralEntry entry = parseMapLiteralEntry('0 : y');
    expect(entry, isNotNull);
    assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_string() {
    MapLiteralEntry entry = parseMapLiteralEntry("'x' : y");
    expect(entry, isNotNull);
    assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMultiplicativeExpression_normal() {
    Expression expression = parseMultiplicativeExpression('x * y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.STAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseMultiplicativeExpression_super() {
    Expression expression = parseMultiplicativeExpression('super * y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.STAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseNewExpression() {
    InstanceCreationExpression expression = parseNewExpression('new A()');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword, isNotNull);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_decrement() {
    Expression expression = parsePostfixExpression('i--');
    expect(expression, isNotNull);
    assertNoErrors();
    var postfixExpression = expression as PostfixExpression;
    expect(postfixExpression.operand, isNotNull);
    expect(postfixExpression.operator, isNotNull);
    expect(postfixExpression.operator.type, TokenType.MINUS_MINUS);
  }

  void test_parsePostfixExpression_increment() {
    Expression expression = parsePostfixExpression('i++');
    expect(expression, isNotNull);
    assertNoErrors();
    var postfixExpression = expression as PostfixExpression;
    expect(postfixExpression.operand, isNotNull);
    expect(postfixExpression.operator, isNotNull);
    expect(postfixExpression.operator.type, TokenType.PLUS_PLUS);
  }

  void test_parsePostfixExpression_none_indexExpression() {
    Expression expression = parsePostfixExpression('a[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.index, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation() {
    Expression expression = parsePostfixExpression('a.m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation_question_dot() {
    Expression expression = parsePostfixExpression('a?.m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.QUESTION_PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void
      test_parsePostfixExpression_none_methodInvocation_question_dot_typeArguments() {
    Expression expression = parsePostfixExpression('a?.m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.QUESTION_PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation_typeArguments() {
    Expression expression = parsePostfixExpression('a.m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_propertyAccess() {
    Expression expression = parsePostfixExpression('a.b');
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as PrefixedIdentifier;
    expect(identifier.prefix, isNotNull);
    expect(identifier.identifier, isNotNull);
  }

  void test_parsePrefixedIdentifier_noPrefix() {
    String lexeme = "bar";
    Identifier identifier = parsePrefixedIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    var simpleIdentifier = identifier as SimpleIdentifier;
    expect(simpleIdentifier.token, isNotNull);
    expect(simpleIdentifier.name, lexeme);
  }

  void test_parsePrefixedIdentifier_prefix() {
    String lexeme = "foo.bar";
    Identifier identifier = parsePrefixedIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    var prefixedIdentifier = identifier as PrefixedIdentifier;
    expect(prefixedIdentifier.prefix.name, "foo");
    expect(prefixedIdentifier.period, isNotNull);
    expect(prefixedIdentifier.identifier.name, "bar");
  }

  void test_parsePrimaryExpression_const() {
    Expression expression = parsePrimaryExpression('const A()');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isNotNull);
  }

  void test_parsePrimaryExpression_double() {
    String doubleLiteral = "3.2e4";
    Expression expression = parsePrimaryExpression(doubleLiteral);
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as DoubleLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, double.parse(doubleLiteral));
  }

  void test_parsePrimaryExpression_false() {
    Expression expression = parsePrimaryExpression('false');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as BooleanLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, isFalse);
  }

  void test_parsePrimaryExpression_function_arguments() {
    Expression expression = parsePrimaryExpression('(int i) => i + 1');
    expect(expression, isNotNull);
    assertNoErrors();
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
  }

  void test_parsePrimaryExpression_function_noArguments() {
    Expression expression = parsePrimaryExpression('() => 42');
    expect(expression, isNotNull);
    assertNoErrors();
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
  }

  void test_parsePrimaryExpression_genericFunctionExpression() {
    Expression expression =
        parsePrimaryExpression('<X, Y>(Map<X, Y> m, X x) => m[x]');
    expect(expression, isNotNull);
    assertNoErrors();
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.typeParameters, isNotNull);
  }

  void test_parsePrimaryExpression_hex() {
    String hexLiteral = "3F";
    Expression expression = parsePrimaryExpression('0x$hexLiteral');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as IntegerLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(hexLiteral, radix: 16));
  }

  void test_parsePrimaryExpression_identifier() {
    Expression expression = parsePrimaryExpression('a');
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as SimpleIdentifier;
    expect(identifier, isNotNull);
  }

  void test_parsePrimaryExpression_int() {
    String intLiteral = "472";
    Expression expression = parsePrimaryExpression(intLiteral);
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as IntegerLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(intLiteral));
  }

  void test_parsePrimaryExpression_listLiteral() {
    Expression expression = parsePrimaryExpression('[ ]');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_index() {
    Expression expression = parsePrimaryExpression('[]');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_typed() {
    Expression expression = parsePrimaryExpression('<A>[ ]');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(1));
  }

  void test_parsePrimaryExpression_mapLiteral() {
    Expression expression = parsePrimaryExpression('{}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.typeArguments, isNull);
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_mapLiteral_typed() {
    Expression expression = parsePrimaryExpression('<A, B>{}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(2));
  }

  void test_parsePrimaryExpression_new() {
    Expression expression = parsePrimaryExpression('new A()');
    expect(expression, isNotNull);
    assertNoErrors();
    var creation = expression as InstanceCreationExpression;
    expect(creation, isNotNull);
  }

  void test_parsePrimaryExpression_null() {
    Expression expression = parsePrimaryExpression('null');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isNullLiteral);
    NullLiteral literal = expression;
    expect(literal.literal, isNotNull);
  }

  void test_parsePrimaryExpression_parenthesized() {
    Expression expression = parsePrimaryExpression('(x)');
    expect(expression, isNotNull);
    assertNoErrors();
    var parens = expression as ParenthesizedExpression;
    expect(parens, isNotNull);
  }

  void test_parsePrimaryExpression_string() {
    Expression expression = parsePrimaryExpression('"string"');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_multiline() {
    Expression expression = parsePrimaryExpression("'''string'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.isMultiline, isTrue);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_raw() {
    Expression expression = parsePrimaryExpression("r'string'");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isTrue);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_super() {
    Expression expression = parseExpression('super.x');
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target is SuperExpression, isTrue);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parsePrimaryExpression_this() {
    Expression expression = parsePrimaryExpression('this');
    expect(expression, isNotNull);
    assertNoErrors();
    var thisExpression = expression as ThisExpression;
    expect(thisExpression.thisKeyword, isNotNull);
  }

  void test_parsePrimaryExpression_true() {
    Expression expression = parsePrimaryExpression('true');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as BooleanLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, isTrue);
  }

  void test_parseRedirectingConstructorInvocation_named() {
    var invocation = parseConstructorInitializer('this.a()')
        as RedirectingConstructorInvocation;
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.thisKeyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseRedirectingConstructorInvocation_unnamed() {
    var invocation = parseConstructorInitializer('this()')
        as RedirectingConstructorInvocation;
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.thisKeyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseRelationalExpression_as_chained() {
    AsExpression asExpression = parseExpression('x as Y as Z',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 2)]
            : []);
    expect(asExpression, isNotNull);
    SimpleIdentifier identifier = asExpression.expression;
    expect(identifier.name, 'x');
    expect(asExpression.asOperator, isNotNull);
    TypeName typeName = asExpression.type;
    expect(typeName.name.name, 'Y');
  }

  void test_parseRelationalExpression_as_functionType_noReturnType() {
    Expression expression = parseRelationalExpression('x as Function(int)');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isGenericFunctionType);
  }

  void test_parseRelationalExpression_as_functionType_returnType() {
    Expression expression =
        parseRelationalExpression('x as String Function(int)');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isGenericFunctionType);
  }

  void test_parseRelationalExpression_as_generic() {
    Expression expression = parseRelationalExpression('x as C<D>');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isTypeName);
  }

  void test_parseRelationalExpression_as_simple() {
    Expression expression = parseRelationalExpression('x as Y');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isTypeName);
  }

  void test_parseRelationalExpression_as_simple_function() {
    Expression expression = parseRelationalExpression('x as Function');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isTypeName);
  }

  void test_parseRelationalExpression_is() {
    Expression expression = parseRelationalExpression('x is y');
    expect(expression, isNotNull);
    assertNoErrors();
    var isExpression = expression as IsExpression;
    expect(isExpression.expression, isNotNull);
    expect(isExpression.isOperator, isNotNull);
    expect(isExpression.notOperator, isNull);
    expect(isExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_is_chained() {
    IsExpression isExpression = parseExpression('x is Y is! Z',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 2)]
            : []);
    expect(isExpression, isNotNull);
    SimpleIdentifier identifier = isExpression.expression;
    expect(identifier.name, 'x');
    expect(isExpression.isOperator, isNotNull);
    TypeName typeName = isExpression.type;
    expect(typeName.name.name, 'Y');
  }

  void test_parseRelationalExpression_isNot() {
    Expression expression = parseRelationalExpression('x is! y');
    expect(expression, isNotNull);
    assertNoErrors();
    var isExpression = expression as IsExpression;
    expect(isExpression.expression, isNotNull);
    expect(isExpression.isOperator, isNotNull);
    expect(isExpression.notOperator, isNotNull);
    expect(isExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_normal() {
    Expression expression = parseRelationalExpression('x < y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.LT);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseRelationalExpression_super() {
    Expression expression = parseRelationalExpression('super < y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.LT);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseRethrowExpression() {
    RethrowExpression expression = parseRethrowExpression('rethrow');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.rethrowKeyword, isNotNull);
  }

  void test_parseShiftExpression_normal() {
    BinaryExpression expression = parseShiftExpression('x << y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseShiftExpression_super() {
    BinaryExpression expression = parseShiftExpression('super << y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseSimpleIdentifier1_normalIdentifier() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parseSimpleIdentifier_builtInIdentifier() {
    String lexeme = "as";
    SimpleIdentifier identifier = parseSimpleIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseSimpleIdentifier_normalIdentifier() {
    String lexeme = "foo";
    SimpleIdentifier identifier = parseSimpleIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseStringLiteral_adjacent() {
    Expression expression = parseStringLiteral("'a' 'b'");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as AdjacentStrings;
    NodeList<StringLiteral> strings = literal.strings;
    expect(strings, hasLength(2));
    StringLiteral firstString = strings[0];
    StringLiteral secondString = strings[1];
    expect((firstString as SimpleStringLiteral).value, "a");
    expect((secondString as SimpleStringLiteral).value, "b");
  }

  void test_parseStringLiteral_endsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'x$y'");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, 'x');
    expect(interpolation.elements[1], isInterpolationExpression);
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.leftBracket.lexeme, '\$');
    expect(element1.expression, isSimpleIdentifier);
    expect(element1.rightBracket, isNull);
    expect(interpolation.elements[2], isInterpolationString);
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, '');
  }

  void test_parseStringLiteral_interpolated() {
    Expression expression = parseStringLiteral("'a \${b} c \$this d'");
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isStringInterpolation);
    StringInterpolation literal = expression;
    NodeList<InterpolationElement> elements = literal.elements;
    expect(elements, hasLength(5));
    expect(elements[0] is InterpolationString, isTrue);
    expect(elements[1] is InterpolationExpression, isTrue);
    expect(elements[2] is InterpolationString, isTrue);
    expect(elements[3] is InterpolationExpression, isTrue);
    expect(elements[4] is InterpolationString, isTrue);
    expect((elements[1] as InterpolationExpression).leftBracket.lexeme, '\${');
    expect((elements[1] as InterpolationExpression).rightBracket.lexeme, '}');
    expect((elements[3] as InterpolationExpression).leftBracket.lexeme, '\$');
    expect((elements[3] as InterpolationExpression).rightBracket, isNull);
  }

  void test_parseStringLiteral_multiline_encodedSpace() {
    Expression expression = parseStringLiteral("'''\\x20\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, " \na");
  }

  void test_parseStringLiteral_multiline_endsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'''x$y'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, 'x');
    expect(interpolation.elements[1], isInterpolationExpression);
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, '');
  }

  void test_parseStringLiteral_multiline_escapedBackslash() {
    Expression expression = parseStringLiteral("'''\\\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\\na");
  }

  void test_parseStringLiteral_multiline_escapedBackslash_raw() {
    Expression expression = parseStringLiteral("r'''\\\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\\\\na");
  }

  void test_parseStringLiteral_multiline_escapedEolMarker() {
    Expression expression = parseStringLiteral("'''\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedEolMarker_raw() {
    Expression expression = parseStringLiteral("r'''\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker() {
    Expression expression = parseStringLiteral("'''\\ \\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker_raw() {
    Expression expression = parseStringLiteral("r'''\\ \\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedTab() {
    Expression expression = parseStringLiteral("'''\\t\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\t\na");
  }

  void test_parseStringLiteral_multiline_escapedTab_raw() {
    Expression expression = parseStringLiteral("r'''\\t\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\t\na");
  }

  void test_parseStringLiteral_multiline_quoteAfterInterpolation() {
    Expression expression = parseStringLiteral(r"""'''$x'y'''""");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, "'y");
  }

  void test_parseStringLiteral_multiline_startsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'''${x}y'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, 'y');
  }

  void test_parseStringLiteral_multiline_twoSpaces() {
    Expression expression = parseStringLiteral("'''  \na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_twoSpaces_raw() {
    Expression expression = parseStringLiteral("r'''  \na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_untrimmed() {
    Expression expression = parseStringLiteral("''' a\nb'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, " a\nb");
  }

  void test_parseStringLiteral_quoteAfterInterpolation() {
    Expression expression = parseStringLiteral(r"""'$x"'""");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, '"');
  }

  void test_parseStringLiteral_single() {
    Expression expression = parseStringLiteral("'a'");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_startsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'${x}y'");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, 'y');
  }

  void test_parseSuperConstructorInvocation_named() {
    var invocation =
        parseConstructorInitializer('super.a()') as SuperConstructorInvocation;
    expect(invocation, isNotNull);
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.superKeyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseSuperConstructorInvocation_unnamed() {
    var invocation =
        parseConstructorInitializer('super()') as SuperConstructorInvocation;
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.superKeyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseSymbolLiteral_builtInIdentifier() {
    SymbolLiteral literal = parseSymbolLiteral('#dynamic.static.abstract');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "dynamic");
    expect(components[1].lexeme, "static");
    expect(components[2].lexeme, "abstract");
  }

  void test_parseSymbolLiteral_multiple() {
    SymbolLiteral literal = parseSymbolLiteral('#a.b.c');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "a");
    expect(components[1].lexeme, "b");
    expect(components[2].lexeme, "c");
  }

  void test_parseSymbolLiteral_operator() {
    SymbolLiteral literal = parseSymbolLiteral('#==');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "==");
  }

  void test_parseSymbolLiteral_single() {
    SymbolLiteral literal = parseSymbolLiteral('#a');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "a");
  }

  void test_parseSymbolLiteral_void() {
    SymbolLiteral literal = parseSymbolLiteral('#void');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "void");
  }

  void test_parseThrowExpression() {
    Expression expression = parseThrowExpression('throw x');
    expect(expression, isNotNull);
    assertNoErrors();
    var throwExpression = expression as ThrowExpression;
    expect(throwExpression.throwKeyword, isNotNull);
    expect(throwExpression.expression, isNotNull);
  }

  void test_parseThrowExpressionWithoutCascade() {
    Expression expression = parseThrowExpressionWithoutCascade('throw x');
    expect(expression, isNotNull);
    assertNoErrors();
    var throwExpression = expression as ThrowExpression;
    expect(throwExpression.throwKeyword, isNotNull);
    expect(throwExpression.expression, isNotNull);
  }

  void test_parseUnaryExpression_decrement_identifier_index() {
    PrefixExpression expression = parseExpression('--a[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_decrement_normal() {
    PrefixExpression expression = parseUnaryExpression('--x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_decrement_super() {
    PrefixExpression expression = parseUnaryExpression('--super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    Expression innerExpression = expression.operand;
    expect(innerExpression, isNotNull);
    expect(innerExpression is PrefixExpression, isTrue);
    PrefixExpression operand = innerExpression as PrefixExpression;
    expect(operand.operator, isNotNull);
    expect(operand.operator.type, TokenType.MINUS);
    expect(operand.operand, isNotNull);
  }

  void test_parseUnaryExpression_decrement_super_propertyAccess() {
    PrefixExpression expression = parseUnaryExpression('--super.x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  void test_parseUnaryExpression_decrement_super_withComment() {
    PrefixExpression expression = parseUnaryExpression('/* 0 */ --super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operator.precedingComments, isNotNull);
    Expression innerExpression = expression.operand;
    expect(innerExpression, isNotNull);
    expect(innerExpression is PrefixExpression, isTrue);
    PrefixExpression operand = innerExpression as PrefixExpression;
    expect(operand.operator, isNotNull);
    expect(operand.operator.type, TokenType.MINUS);
    expect(operand.operand, isNotNull);
  }

  void test_parseUnaryExpression_increment_identifier_index() {
    PrefixExpression expression = parseExpression('++a[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_increment_normal() {
    PrefixExpression expression = parseUnaryExpression('++x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_increment_super_index() {
    PrefixExpression expression = parseUnaryExpression('++super[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget is SuperExpression, isTrue);
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_increment_super_propertyAccess() {
    PrefixExpression expression = parseUnaryExpression('++super.x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  void test_parseUnaryExpression_minus_identifier_index() {
    PrefixExpression expression = parseExpression('-a[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_minus_normal() {
    PrefixExpression expression = parseUnaryExpression('-x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_minus_super() {
    PrefixExpression expression = parseUnaryExpression('-super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_normal() {
    PrefixExpression expression = parseUnaryExpression('!x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_super() {
    PrefixExpression expression = parseUnaryExpression('!super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_normal() {
    PrefixExpression expression = parseUnaryExpression('~x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_super() {
    PrefixExpression expression = parseUnaryExpression('~super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilde_identifier_index() {
    PrefixExpression expression = parseExpression('~a[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }
}

/// Tests of the analyzer parser based on [FormalParameterParserTestMixin].
@reflectiveTest
class FormalParameterParserTest extends ParserTestCase
    with FormalParameterParserTestMixin {}

/// The class [FormalParameterParserTestMixin] defines parser tests that test
/// the parsing of formal parameters.
mixin FormalParameterParserTestMixin implements AbstractParserTestCase {
  void test_parseConstructorParameter_this() {
    parseCompilationUnit('''
class C {
  final int field;
  C(this.field);
}''');
  }

  void test_parseConstructorParameter_this_Function() {
    parseCompilationUnit('''
class C {
  final Object Function(int, double) field;
  C(String Function(num, Object) this.field);
}''');
  }

  void test_parseConstructorParameter_this_int() {
    parseCompilationUnit('''
class C {
  final int field;
  C(int this.field);
}''');
  }

  void test_parseFormalParameter_covariant_final_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant final a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_final_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('covariant final a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_final_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant final a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_covariant_final_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant final A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_final_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('covariant final A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_final_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant final A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_covariant_type_function() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('covariant String Function(int) a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isGenericFunctionType);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('covariant A<B<C>> a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_covariant_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant var a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_var_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('covariant var a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_var_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant var a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_final_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('final a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_final_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('final a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_final_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('final a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_final_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('final A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_final_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('final A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_final_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('final A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_type_function() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('String Function(int) a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isGenericFunctionType);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_type_named_noDefault() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNull);
    expect(defaultParameter.defaultValue, isNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_type_positional_noDefault() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNull);
    expect(defaultParameter.defaultValue, isNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('var a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_var_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('var a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_var_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('var a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameterList_empty() {
    FormalParameterList list = parseFormalParameterList('()');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(0));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_multiple() {
    FormalParameterList list =
        parseFormalParameterList('({A a : 1, B b, C c : 3})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_single() {
    FormalParameterList list = parseFormalParameterList('({A a})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_trailing_comma() {
    FormalParameterList list = parseFormalParameterList('(A a, {B b,})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_multiple() {
    FormalParameterList list = parseFormalParameterList('(A a, B b, C c)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_named() {
    FormalParameterList list = parseFormalParameterList('(A a, {B b})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_named_inFunctionType() {
    FormalParameterList list =
        parseFormalParameterList('(A, {B b})', inFunctionType: true);
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
    NodeList<FormalParameter> parameters = list.parameters;
    expect(parameters, hasLength(2));

    expect(parameters[0], isSimpleFormalParameter);
    SimpleFormalParameter required = parameters[0];
    expect(required.identifier, isNull);
    expect(required.type, isTypeName);
    expect((required.type as TypeName).name.name, 'A');

    expect(parameters[1], isDefaultFormalParameter);
    DefaultFormalParameter named = parameters[1];
    expect(named.identifier, isNotNull);
    expect(named.parameter, isSimpleFormalParameter);
    SimpleFormalParameter simple = named.parameter;
    expect(simple.type, isTypeName);
    expect((simple.type as TypeName).name.name, 'B');
  }

  void test_parseFormalParameterList_normal_positional() {
    FormalParameterList list = parseFormalParameterList('(A a, [B b])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single() {
    FormalParameterList list = parseFormalParameterList('(A a)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single_Function() {
    FormalParameterList list = parseFormalParameterList('(Function f)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single_trailing_comma() {
    FormalParameterList list = parseFormalParameterList('(A a,)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_multiple() {
    FormalParameterList list =
        parseFormalParameterList('([A a = null, B b, C c = null])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_single() {
    FormalParameterList list = parseFormalParameterList('([A a = null])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_trailing_comma() {
    FormalParameterList list = parseFormalParameterList('(A a, [B b,])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType() {
    FormalParameterList list = parseFormalParameterList('(io.File f)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.parameters[0].toSource(), 'io.File f');
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_missingName() {
    FormalParameterList list = parseFormalParameterList('(io.File)',
        errors: [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1)]);
    expect(list, isNotNull);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    // TODO(danrubel): Investigate and improve recovery of parameter type/name.
    SimpleFormalParameter parameter = list.parameters[0];
    expect(parameter.toSource(), 'io.File ');
    expect(parameter.identifier.token.isSynthetic, isTrue);
    TypeName type = parameter.type;
    PrefixedIdentifier typeName = type.name;
    expect(typeName.prefix.token.isSynthetic, isFalse);
    expect(typeName.identifier.token.isSynthetic, isFalse);
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_partial() {
    FormalParameterList list = parseFormalParameterList('(io.)', errors: [
      expectedError(
          usingFastaParser
              ? ParserErrorCode.EXPECTED_TYPE_NAME
              : ParserErrorCode.MISSING_IDENTIFIER,
          4,
          1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)
    ]);
    expect(list, isNotNull);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    // TODO(danrubel): Investigate and improve recovery of parameter type/name.
    SimpleFormalParameter parameter = list.parameters[0];
    expect(parameter.toSource(), 'io. ');
    expect(parameter.identifier.token.isSynthetic, isTrue);
    TypeName type = parameter.type;
    PrefixedIdentifier typeName = type.name;
    expect(typeName.prefix.token.isSynthetic, isFalse);
    expect(typeName.identifier.token.isSynthetic, isTrue);
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_partial2() {
    FormalParameterList list = parseFormalParameterList('(io.,a)', errors: [
      expectedError(
          usingFastaParser
              ? ParserErrorCode.EXPECTED_TYPE_NAME
              : ParserErrorCode.MISSING_IDENTIFIER,
          4,
          1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)
    ]);
    expect(list, isNotNull);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(2));
    expect(list.parameters[0].toSource(), 'io. ');
    expect(list.parameters[1].toSource(), 'a');
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseNormalFormalParameter_field_const_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('const this.a',
        errorCodes:
            usingFastaParser ? [ParserErrorCode.EXTRANEOUS_MODIFIER] : []);
    expect(parameter, isNotNull);
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_const_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter(
        'const A this.a',
        errorCodes:
            usingFastaParser ? [ParserErrorCode.EXTRANEOUS_MODIFIER] : []);
    expect(parameter, isNotNull);
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_noType() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('final this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_type() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('final A this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_function_nested() {
    NormalFormalParameter parameter = parseNormalFormalParameter('this.a(B b)');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    FormalParameterList parameterList = fieldParameter.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(1));
  }

  void test_parseNormalFormalParameter_field_function_noNested() {
    NormalFormalParameter parameter = parseNormalFormalParameter('this.a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    FormalParameterList parameterList = fieldParameter.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void test_parseNormalFormalParameter_field_function_withDocComment() {
    var parameter = parseNormalFormalParameter('/// Doc\nthis.f()');
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  void test_parseNormalFormalParameter_field_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_var() {
    NormalFormalParameter parameter = parseNormalFormalParameter('var this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_withDocComment() {
    var parameter = parseNormalFormalParameter('/// Doc\nthis.a');
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  void test_parseNormalFormalParameter_function_named() {
    ParameterKind kind = ParameterKind.NAMED;
    var defaultParameter =
        parseFormalParameter('a() : null', kind) as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    assertNoErrors();
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isNamed, isTrue);
    expect(functionParameter.question, isNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseNormalFormalParameter_function_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_noType_covariant() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('covariant a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.covariantKeyword, isNotNull);
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_noType_typeParameters() {
    NormalFormalParameter parameter = parseNormalFormalParameter('a<E>()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_type_typeParameters() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A a<E>()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_typeVoid_covariant() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('covariant void a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.covariantKeyword, isNotNull);
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_void() {
    NormalFormalParameter parameter = parseNormalFormalParameter('void a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_void_typeParameters() {
    NormalFormalParameter parameter = parseNormalFormalParameter('void a<E>()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_withDocComment() {
    var parameter = parseFormalParameter('/// Doc\nf()', ParameterKind.REQUIRED)
        as FunctionTypedFormalParameter;
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  void test_parseNormalFormalParameter_simple_const_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('const a',
        errorCodes:
            usingFastaParser ? [ParserErrorCode.EXTRANEOUS_MODIFIER] : []);
    expect(parameter, isNotNull);
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_const_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('const A a',
        errorCodes:
            usingFastaParser ? [ParserErrorCode.EXTRANEOUS_MODIFIER] : []);
    expect(parameter, isNotNull);
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('final a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('final A a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_noName() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('a', inFunctionType: true);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.identifier, isNull);
  }

  void test_parseNormalFormalParameter_simple_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_noType_namedCovariant() {
    NormalFormalParameter parameter = parseNormalFormalParameter('covariant');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
  }
}

@reflectiveTest
class NonErrorParserTest extends ParserTestCase {
  void test_annotationOnEnumConstant_first() {
    createParser("enum E { @override C }");
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
  }

  void test_annotationOnEnumConstant_middle() {
    createParser("enum E { C, @override D, E }");
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
  }

  void test_staticMethod_notParsingFunctionBodies() {
    ParserTestCase.parseFunctionBodies = false;
    try {
      createParser('class C { static void m() {} }');
      CompilationUnit unit = parser.parseCompilationUnit2();
      expectNotNullIfNoErrors(unit);
      assertNoErrors();
    } finally {
      ParserTestCase.parseFunctionBodies = true;
    }
  }
}

/// Implementation of [AbstractParserTestCase] specialized for testing the
/// analyzer parser.
class ParserTestCase with ParserTestHelpers implements AbstractParserTestCase {
  /// A flag indicating whether parser is to parse function bodies.
  static bool parseFunctionBodies = true;

  @override
  bool allowNativeClause = true;

  /// A flag indicating whether parser is to parse async.
  bool parseAsync = true;

  /// A flag indicating whether the parser should parse instance creation
  /// expressions that lack either the `new` or `const` keyword.
  bool enableOptionalNewAndConst = false;

  /// A flag indicating whether the parser should parse mixin declarations.
  /// https://github.com/dart-lang/language/issues/12
  bool isMixinSupportEnabled = false;

  /// A flag indicating whether the parser is to parse part-of directives that
  /// specify a URI rather than a library name.
  bool enableUriInPartOf = false;

  @override
  GatheringErrorListener listener;

  /// The parser used by the test.
  ///
  /// This field is typically initialized by invoking [createParser].
  @override
  Parser parser;

  @override
  bool get usingFastaParser => Parser.useFasta;

  @override
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  @override
  void assertNoErrors() {
    listener.assertNoErrors();
  }

  /// Create the [parser] and [listener] used by a test. The [parser] will be
  /// prepared to parse the tokens scanned from the given [content].
  @override
  void createParser(
    String content, {
    int expectedEndOffset,
    LanguageVersionToken languageVersion,
    FeatureSet featureSet,
  }) {
    Source source = TestSource();
    listener = GatheringErrorListener();

    ScannerResult result = scanString(content, includeComments: true);
    listener.setLineInfo(source, result.lineStarts);

    parser = Parser(
      source,
      listener,
      featureSet: featureSet,
    );
    parser.allowNativeClause = allowNativeClause;
    parser.parseFunctionBodies = parseFunctionBodies;
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    parser.currentToken = result.tokens;
  }

  @override
  ExpectedError expectedError(ErrorCode code, int offset, int length) =>
      ExpectedError(code, offset, length);

  @override
  void expectNotNullIfNoErrors(Object result) {
    if (!listener.hasErrors) {
      expect(result, isNotNull);
    }
  }

  @override
  Expression parseAdditiveExpression(String code) {
    createParser(code);
    return parser.parseAdditiveExpression();
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    createParser(code);
    return parser.parseAssignableExpression(primaryAllowed);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional = true}) {
    if (usingFastaParser) {
      if (optional) {
        if (code.isEmpty) {
          createParser('foo');
        } else {
          createParser('(foo)$code');
        }
      } else {
        createParser('foo$code');
      }
      return parser.parseExpression2();
    } else {
      Expression prefix =
          astFactory.simpleIdentifier(StringToken(TokenType.STRING, 'foo', 0));
      createParser(code);
      return parser.parseAssignableSelector(prefix, optional,
          allowConditional: allowConditional);
    }
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    if (usingFastaParser) {
      createParser('() async => $code');
      var function = parser.parseExpression2() as FunctionExpression;
      return (function.body as ExpressionFunctionBody).expression;
    } else {
      createParser(code);
      return parser.parseAwaitExpression();
    }
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    createParser(code);
    return parser.parseBitwiseAndExpression();
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    createParser(code);
    return parser.parseBitwiseOrExpression();
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    createParser(code);
    return parser.parseBitwiseXorExpression();
  }

  @override
  Expression parseCascadeSection(String code) {
    if (usingFastaParser) {
      var statement = parseStatement('null$code;') as ExpressionStatement;
      var cascadeExpression = statement.expression as CascadeExpression;
      return cascadeExpression.cascadeSections.first;
    } else {
      createParser(code);
      return parser.parseCascadeSection();
    }
  }

  @override
  CommentReference parseCommentReference(
      String referenceSource, int sourceOffset) {
    String padding = ' '.padLeft(sourceOffset - 4, 'a');
    String source = '/**$padding[$referenceSource] */ class C { }';
    CompilationUnit unit = parseCompilationUnit(source);
    ClassDeclaration clazz = unit.declarations[0];
    Comment comment = clazz.documentationComment;
    List<CommentReference> references = comment.references;
    if (references.isEmpty) {
      return null;
    } else {
      expect(references, hasLength(1));
      return references[0];
    }
  }

  /// Parse the given source as a compilation unit.
  ///
  /// @param source the source to be parsed
  /// @param errorCodes the error codes of the errors that are expected to be
  ///          found
  /// @return the compilation unit that was parsed
  /// @throws Exception if the source could not be parsed, if the compilation
  ///           errors in the source do not match those that are expected, or if
  ///           the result would have been `null`
  @override
  CompilationUnit parseCompilationUnit(String content,
      {List<ErrorCode> codes, List<ExpectedError> errors}) {
    Source source = TestSource();
    GatheringErrorListener listener = GatheringErrorListener();

    ScannerResult result = scanString(content, includeComments: true);
    listener.setLineInfo(source, result.lineStarts);

    Parser parser = Parser(
      source,
      listener,
      featureSet: FeatureSet.forTesting(),
    );
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    CompilationUnit unit = parser.parseCompilationUnit(result.tokens);
    expect(unit, isNotNull);
    if (codes != null) {
      listener.assertErrorsWithCodes(codes);
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      listener.assertNoErrors();
    }
    return unit;
  }

  /// Parse the given [content] as a compilation unit.
  CompilationUnit parseCompilationUnit2(String content,
      {AnalysisErrorListener listener}) {
    Source source = NonExistingSource.unknown;
    listener ??= AnalysisErrorListener.NULL_LISTENER;

    ScannerResult result = scanString(content, includeComments: true);

    Parser parser = Parser(
      source,
      listener,
      featureSet: FeatureSet.forTesting(),
    );
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    CompilationUnit unit = parser.parseCompilationUnit(result.tokens);
    unit.lineInfo = LineInfo(result.lineStarts);
    return unit;
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    createParser(code);
    return parser.parseConditionalExpression();
  }

  @override
  Expression parseConstExpression(String code) {
    createParser(code);
    return parser.parseConstExpression();
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    createParser('class __Test { __Test() : $code; }');
    CompilationUnit unit = parser.parseCompilationUnit2();
    var clazz = unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    return constructor.initializers.single;
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    CompilationUnit unit = parser.parseDirectives2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(0));
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    createParser(code);
    return parser.parseEqualityExpression();
  }

  /// Parse the given [source] as an expression. If a list of error [codes] is
  /// provided, then assert that the produced errors matches the list.
  /// Otherwise, if a list of [errors] is provided, the assert that the produced
  /// errors matches the list. Otherwise, assert that there are no errors.
  @override
  Expression parseExpression(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset}) {
    createParser(source, expectedEndOffset: expectedEndOffset);
    Expression expression = parser.parseExpression2();
    expectNotNullIfNoErrors(expression);
    if (codes != null) {
      listener.assertErrorsWithCodes(codes);
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      assertNoErrors();
    }
    return expression;
  }

  @override
  List<Expression> parseExpressionList(String code) {
    if (usingFastaParser) {
      createParser('[$code]');
      return (parser.parseExpression2() as ListLiteral)
          .elements
          .toList()
          .cast<Expression>();
    } else {
      createParser(code);
      return parser.parseExpressionList();
    }
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    createParser(code);
    return parser.parseExpressionWithoutCascade();
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes = const <ErrorCode>[]}) {
    if (usingFastaParser) {
      String parametersCode;
      if (kind == ParameterKind.REQUIRED) {
        parametersCode = '($code)';
      } else if (kind == ParameterKind.POSITIONAL) {
        parametersCode = '([$code])';
      } else if (kind == ParameterKind.NAMED) {
        parametersCode = '({$code})';
      } else {
        fail('$kind');
      }
      FormalParameterList list = parseFormalParameterList(parametersCode,
          inFunctionType: false, errorCodes: errorCodes);
      return list.parameters.single;
    } else {
      createParser(code);
      FormalParameter parameter = parser.parseFormalParameter(kind);
      assertErrorsWithCodes(errorCodes);
      return parameter;
    }
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[],
      List<ExpectedError> errors}) {
    createParser(code);
    FormalParameterList list =
        parser.parseFormalParameterList(inFunctionType: inFunctionType);
    if (errors != null) {
      errorCodes = errors.map((e) => e.code).toList();
    }
    assertErrorsWithCodes(errorCodes);
    return list;
  }

  /// Parses a single top level member of a compilation unit (other than a
  /// directive), including any comment and/or metadata that precedes it.
  @override
  CompilationUnitMember parseFullCompilationUnitMember() => usingFastaParser
      ? parser.parseCompilationUnit2().declarations.first
      : parser.parseCompilationUnitMember(parser.parseCommentAndMetadata());

  @override
  Directive parseFullDirective() {
    return usingFastaParser
        ? (parser as ParserAdapter).parseTopLevelDeclaration(true)
        : parser.parseDirective(parser.parseCommentAndMetadata());
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    createParser(code);
    return parser.parseFunctionExpression();
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, Token newToken) {
    if (usingFastaParser) {
      createParser('$newToken $code');
      return parser.parseExpression2();
    } else {
      createParser(code);
      return parser.parseInstanceCreationExpression(newToken);
    }
  }

  @override
  ListLiteral parseListLiteral(
      Token token, String typeArgumentsCode, String code) {
    if (usingFastaParser) {
      String sc = '';
      if (token != null) {
        sc += token.lexeme + ' ';
      }
      if (typeArgumentsCode != null) {
        sc += typeArgumentsCode;
      }
      sc += code;
      createParser(sc);
      return parser.parseExpression2();
    } else {
      TypeArgumentList typeArguments;
      if (typeArgumentsCode != null) {
        createParser(typeArgumentsCode);
        typeArguments = parser.parseTypeArgumentList();
      }
      createParser(code);
      return parser.parseListLiteral(token, typeArguments);
    }
  }

  @override
  TypedLiteral parseListOrMapLiteral(Token modifier, String code) {
    if (usingFastaParser) {
      String literalCode = modifier != null ? '$modifier $code' : code;
      createParser(literalCode);
      return parser.parseExpression2() as TypedLiteral;
    } else {
      createParser(code);
      return parser.parseListOrMapLiteral(modifier);
    }
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    createParser(code);
    return parser.parseLogicalAndExpression();
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    createParser(code);
    return parser.parseLogicalOrExpression();
  }

  @override
  SetOrMapLiteral parseMapLiteral(
      Token token, String typeArgumentsCode, String code) {
    if (usingFastaParser) {
      String sc = '';
      if (token != null) {
        sc += token.lexeme + ' ';
      }
      if (typeArgumentsCode != null) {
        sc += typeArgumentsCode;
      }
      sc += code;
      createParser(sc);
      return parser.parseExpression2() as SetOrMapLiteral;
    } else {
      TypeArgumentList typeArguments;
      if (typeArgumentsCode != null) {
        createParser(typeArgumentsCode);
        typeArguments = parser.parseTypeArgumentList();
      }
      createParser(code);
      return parser.parseMapLiteral(token, typeArguments);
    }
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    if (usingFastaParser) {
      var mapLiteral = parseMapLiteral(null, null, '{ $code }');
      return mapLiteral.elements.single;
    } else {
      createParser(code);
      return parser.parseMapLiteralEntry();
    }
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    createParser(code);
    return parser.parseMultiplicativeExpression();
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    createParser(code);
    return parser.parseNewExpression();
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[]}) {
    if (usingFastaParser) {
      FormalParameterList list = parseFormalParameterList('($code)',
          inFunctionType: inFunctionType, errorCodes: errorCodes);
      return list.parameters.single;
    } else {
      createParser(code);
      FormalParameter parameter =
          parser.parseNormalFormalParameter(inFunctionType: inFunctionType);
      assertErrorsWithCodes(errorCodes);
      return parameter;
    }
  }

  @override
  Expression parsePostfixExpression(String code) {
    createParser(code);
    return parser.parsePostfixExpression();
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    createParser(code);
    return parser.parsePrefixedIdentifier();
  }

  @override
  Expression parsePrimaryExpression(String code,
      {int expectedEndOffset, List<ExpectedError> errors}) {
    createParser(code);
    var expression = parser.parsePrimaryExpression();
    if (errors != null) {
      listener.assertErrors(errors);
    }
    return expression;
  }

  @override
  Expression parseRelationalExpression(String code) {
    createParser(code);
    return parser.parseRelationalExpression();
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    createParser(code);
    return parser.parseRethrowExpression();
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    createParser(code);
    return parser.parseShiftExpression();
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    createParser(code);
    return parser.parseSimpleIdentifier();
  }

  /// Parse the given [content] as a statement. If
  /// [enableLazyAssignmentOperators] is `true`, then lazy assignment operators
  /// should be enabled.
  @override
  Statement parseStatement(String content, {int expectedEndOffset}) {
    Source source = TestSource();
    listener = GatheringErrorListener();

    ScannerResult result = scanString(content, includeComments: true);
    listener.setLineInfo(source, result.lineStarts);

    Parser parser = Parser(
      source,
      listener,
      featureSet: FeatureSet.forTesting(),
    );
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    Statement statement = parser.parseStatement(result.tokens);
    expect(statement, isNotNull);
    return statement;
  }

  /// Parse the given source as a sequence of statements.
  ///
  /// @param source the source to be parsed
  /// @param expectedCount the number of statements that are expected
  /// @param errorCodes the error codes of the errors that are expected to be
  ///          found
  /// @return the statements that were parsed
  /// @throws Exception if the source could not be parsed, if the number of
  ///           statements does not match the expected count, if the compilation
  ///           errors in the source do not match those that are expected, or if
  ///           the result would have been `null`
  List<Statement> parseStatements(String content, int expectedCount,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    Source source = TestSource();
    GatheringErrorListener listener = GatheringErrorListener();

    ScannerResult result = scanString(content);
    listener.setLineInfo(source, result.lineStarts);

    Parser parser = Parser(
      source,
      listener,
      featureSet: FeatureSet.forTesting(),
    );
    parser.enableOptionalNewAndConst = enableOptionalNewAndConst;
    List<Statement> statements = parser.parseStatements(result.tokens);
    expect(statements, hasLength(expectedCount));
    listener.assertErrorsWithCodes(errorCodes);
    return statements;
  }

  @override
  Expression parseStringLiteral(String code) {
    createParser(code);
    return parser.parseStringLiteral();
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    createParser(code);
    return parser.parseSymbolLiteral();
  }

  @override
  Expression parseThrowExpression(String code) {
    createParser(code);
    return parser.parseThrowExpression();
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    createParser(code);
    return parser.parseThrowExpressionWithoutCascade();
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    createParser(code);
    return parser.parseUnaryExpression();
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String code) {
    if (usingFastaParser) {
      var statement = parseStatement('$code;') as VariableDeclarationStatement;
      return statement.variables;
    } else {
      createParser(code);
      CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
      return parser
          .parseVariableDeclarationListAfterMetadata(commentAndMetadata);
    }
  }

  void setUp() {
    parseFunctionBodies = true;
  }
}

/// Helper methods that aid in parser tests.
///
/// Intended to be mixed in to parser test case classes.
mixin ParserTestHelpers {
  void expectCommentText(Comment comment, String expectedText) {
    expect(comment.beginToken, same(comment.endToken));
    expect(comment.beginToken.lexeme, expectedText);
  }

  void expectDottedName(DottedName name, List<String> expectedComponents) {
    int count = expectedComponents.length;
    NodeList<SimpleIdentifier> components = name.components;
    expect(components, hasLength(count));
    for (int i = 0; i < count; i++) {
      SimpleIdentifier component = components[i];
      expect(component, isNotNull);
      expect(component.name, expectedComponents[i]);
    }
  }
}

/// Tests of the analyzer parser based on [RecoveryParserTestMixin].
@reflectiveTest
class RecoveryParserTest extends ParserTestCase with RecoveryParserTestMixin {}

/// The class `RecoveryParserTest` defines parser tests that test the parsing of
/// invalid code sequences to ensure that the correct recovery steps are taken
/// in the parser.
mixin RecoveryParserTestMixin implements AbstractParserTestCase {
  void test_additiveExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("+ y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("+", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x +", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super +", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = parseExpression("* +", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = parseExpression("+ *", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_additiveExpression_super() {
    BinaryExpression expression = parseExpression("super + +", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_assignableSelector() {
    IndexExpression expression =
        parseExpression("a.b[]", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression index = expression.index;
    expect(index, isSimpleIdentifier);
    expect(index.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound1() {
    AssignmentExpression expression =
        parseExpression("= y = 0", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression = expression.leftHandSide;
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound2() {
    AssignmentExpression expression =
        parseExpression("x = = 0", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression =
        (expression.rightHandSide as AssignmentExpression).leftHandSide;
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound3() {
    AssignmentExpression expression =
        parseExpression("x = y =", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression =
        (expression.rightHandSide as AssignmentExpression).rightHandSide;
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_LHS() {
    AssignmentExpression expression =
        parseExpression("= 0", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftHandSide, isSimpleIdentifier);
    expect(expression.leftHandSide.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_RHS() {
    AssignmentExpression expression =
        parseExpression("x =", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftHandSide, isSimpleIdentifier);
    expect(expression.rightHandSide.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("& y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x &", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super &", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = parseExpression("== &&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = parseExpression("&& ==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = parseExpression("super &  &", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("| y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("|", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x |", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super |", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = parseExpression("^ |", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = parseExpression("| ^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = parseExpression("super |  |", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("^ y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x ^", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super ^", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = parseExpression("& ^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = parseExpression("^ &", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = parseExpression("super ^  ^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_classTypeAlias_withBody() {
    parseCompilationUnit(r'''
class A {}
class B = Object with A {}''',
        codes: usingFastaParser
            // TODO(danrubel): Consolidate and improve error message.
            ? [
                ParserErrorCode.EXPECTED_EXECUTABLE,
                ParserErrorCode.EXPECTED_TOKEN
              ]
            : [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_combinator_badIdentifier() {
    createParser('import "/testB.dart" show @');
    parser.parseCompilationUnit2();
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 27, 0),
            expectedError(
                ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 27, 0),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 27, 0)
          ]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 26, 1),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
            expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 27, 1)
          ]);
  }

  void test_combinator_missingIdentifier() {
    createParser('import "/testB.dart" show ;');
    parser.parseCompilationUnit2();
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1)]);
  }

  void test_conditionalExpression_missingElse() {
    Expression expression =
        parseExpression('x ? y :', codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expectNotNullIfNoErrors(expression);
    expect(expression, isConditionalExpression);
    ConditionalExpression conditionalExpression = expression;
    expect(conditionalExpression.elseExpression, isSimpleIdentifier);
    expect(conditionalExpression.elseExpression.isSynthetic, isTrue);
  }

  void test_conditionalExpression_missingThen() {
    Expression expression =
        parseExpression('x ? : z', codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expectNotNullIfNoErrors(expression);
    expect(expression, isConditionalExpression);
    ConditionalExpression conditionalExpression = expression;
    expect(conditionalExpression.thenExpression, isSimpleIdentifier);
    expect(conditionalExpression.thenExpression.isSynthetic, isTrue);
  }

  void test_conditionalExpression_super() {
    parseExpression('x ? super : z', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 4, 5)
    ]);
  }

  void test_conditionalExpression_super2() {
    parseExpression('x ? z : super', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 8, 5)
    ]);
  }

  void test_declarationBeforeDirective() {
    CompilationUnit unit = parseCompilationUnit(
        "class foo { } import 'bar.dart';",
        codes: [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(1));
    ClassDeclaration classDecl = unit.childEntities.first;
    expect(classDecl, isNotNull);
    expect(classDecl.name.name, 'foo');
  }

  void test_equalityExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("== y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x ==", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS_super() {
    BinaryExpression expression = parseExpression("super ==",
        codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = parseExpression("is ==", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    if (!usingFastaParser) {
      expect(expression.leftOperand, isIsExpression);
    }
  }

  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = parseExpression("== is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isIsExpression);
  }

  void test_equalityExpression_super() {
    BinaryExpression expression = parseExpression("super ==  ==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_equalityExpression_superRHS() {
    parseExpression("1 == super", errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 5, 5)
    ]);
  }

  void test_expressionList_multiple_end() {
    List<Expression> result = parseExpressionList(', 2, 3, 4');
    expectNotNullIfNoErrors(result);
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
//    listener.assertErrors(
//        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 1)]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[0];
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_middle() {
    List<Expression> result = parseExpressionList('1, 2, , 4');
    expectNotNullIfNoErrors(result);
    // TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
//    listener.assertErrors(
//        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1)]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[2];
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_start() {
    List<Expression> result = parseExpressionList('1, 2, 3,');
    expectNotNullIfNoErrors(result);
    // The fasta parser does not use parseExpressionList when parsing for loops
    // and instead parseExpressionList is mapped to parseExpression('[$code]')
    // which allows and ignores an optional trailing comma.
    if (usingFastaParser) {
      assertNoErrors();
      expect(result, hasLength(3));
    } else {
      listener.assertErrors(
          [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 0)]);
      expect(result, hasLength(4));
      Expression syntheticExpression = result[3];
      expect(syntheticExpression, isSimpleIdentifier);
      expect(syntheticExpression.isSynthetic, isTrue);
    }
  }

  void test_functionExpression_in_ConstructorFieldInitializer() {
    CompilationUnit unit =
        parseCompilationUnit("class A { A() : a = (){}; var v; }", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      usingFastaParser
          ? ParserErrorCode.EXPECTED_CLASS_MEMBER
          : ParserErrorCode.UNEXPECTED_TOKEN
    ]);
    // Make sure we recovered and parsed "var v" correctly
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = declaration.members;
    ClassMember fieldDecl = members[1];
    expect(fieldDecl, isFieldDeclaration);
    NodeList<VariableDeclaration> vars =
        (fieldDecl as FieldDeclaration).fields.variables;
    expect(vars, hasLength(1));
    expect(vars[0].name.name, "v");
  }

  void test_functionExpression_named() {
    parseExpression("m(f() => 0);", expectedEndOffset: 11, codes: [
      usingFastaParser
          ? ParserErrorCode.NAMED_FUNCTION_EXPRESSION
          : ParserErrorCode.EXPECTED_TOKEN
    ]);
  }

  void test_ifStatement_noElse_statement() {
    parseStatement('if (x v) f(x);');
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1)]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1)
          ]);
  }

  void test_importDirectivePartial_as() {
    CompilationUnit unit = parseCompilationUnit("import 'b.dart' d as b;",
        codes: [ParserErrorCode.UNEXPECTED_TOKEN]);
    ImportDirective importDirective = unit.childEntities.first;
    expect(importDirective.asKeyword, isNotNull);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_importDirectivePartial_hide() {
    CompilationUnit unit = parseCompilationUnit("import 'b.dart' d hide foo;",
        codes: [ParserErrorCode.UNEXPECTED_TOKEN]);
    ImportDirective importDirective = unit.childEntities.first;
    expect(importDirective.combinators, hasLength(1));
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_importDirectivePartial_show() {
    CompilationUnit unit = parseCompilationUnit("import 'b.dart' d show foo;",
        codes: [ParserErrorCode.UNEXPECTED_TOKEN]);
    ImportDirective importDirective = unit.childEntities.first;
    expect(importDirective.combinators, hasLength(1));
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_incomplete_conditionalExpression() {
    parseExpression("x ? 0", codes: [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  void test_incomplete_constructorInitializers_empty() {
    createParser('C() : {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_INITIALIZER, 4, 1)]);
  }

  void test_incomplete_constructorInitializers_missingEquals() {
    createParser('C() : x(3) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 1)
    ]);
    expect(member, isConstructorDeclaration);
    NodeList<ConstructorInitializer> initializers =
        (member as ConstructorDeclaration).initializers;
    expect(initializers, hasLength(1));
    ConstructorInitializer initializer = initializers[0];
    expect(initializer, isConstructorFieldInitializer);
    Expression expression =
        (initializer as ConstructorFieldInitializer).expression;
    expect(expression, isNotNull);
    expect(expression,
        usingFastaParser ? isMethodInvocation : isParenthesizedExpression);
  }

  void test_incomplete_constructorInitializers_this() {
    createParser('C() : this {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(usingFastaParser
        ? [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 1),
            expectedError(
                ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 4)
          ]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 1),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 11, 1),
            expectedError(
                ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 11, 1)
          ]);
  }

  void test_incomplete_constructorInitializers_thisField() {
    createParser('C() : this.g {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 4)
    ]);
  }

  void test_incomplete_constructorInitializers_thisPeriod() {
    createParser('C() : this. {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 12, 1),
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 4)
    ]);
  }

  void test_incomplete_constructorInitializers_variable() {
    createParser('C() : x {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 1)
    ]);
  }

  void test_incomplete_functionExpression() {
    var expression = parseExpression("() a => null",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 3, 1)]
            : [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 2, 1)]);
    if (usingFastaParser) {
      FunctionExpression functionExpression = expression;
      expect(functionExpression.parameters.parameters, hasLength(0));
    }
  }

  void test_incomplete_functionExpression2() {
    var expression = parseExpression("() a {}",
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 3, 1)]
            : [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 2, 1)]);
    if (usingFastaParser) {
      FunctionExpression functionExpression = expression;
      expect(functionExpression.parameters.parameters, hasLength(0));
    }
  }

  void test_incomplete_returnType() {
    if (usingFastaParser) {
      parseCompilationUnit(r'''
Map<Symbol, convertStringToSymbolMap(Map<String, dynamic> map) {
  if (map == null) return null;
  Map<Symbol, dynamic> result = new Map<Symbol, dynamic>();
  map.forEach((name, value) {
    result[new Symbol(name)] = value;
  });
  return result;
}''', errors: [
        expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 24),
        expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 0, 3)
      ]);
    }
  }

  void test_incomplete_topLevelFunction() {
    parseCompilationUnit("foo();",
        codes: [ParserErrorCode.MISSING_FUNCTION_BODY]);
  }

  void test_incomplete_topLevelVariable() {
    CompilationUnit unit = parseCompilationUnit("String",
        errors: usingFastaParser
            ? [
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 0, 6),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 6)
              ]
            : [expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 6)]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    // Analyzer considers 'String' to be the type
    // while fasta considers it to be the name.
    expect(name.isSynthetic, usingFastaParser ? isFalse : isTrue);
  }

  void test_incomplete_topLevelVariable_const() {
    CompilationUnit unit = parseCompilationUnit("const ", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_final() {
    CompilationUnit unit = parseCompilationUnit("final ", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_var() {
    CompilationUnit unit = parseCompilationUnit("var ", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incompleteField_const() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  const
}''', codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword.keyword, Keyword.CONST);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_final() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  final
}''', codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword.keyword, Keyword.FINAL);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_static() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  static c
}''', codes: [
      // Fasta considers the `c` to be the type
      // whereas analyzer considers it to be the identifier.
      usingFastaParser
          ? ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
          : ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    FieldDeclaration declaration = classMember;
    expect(declaration.staticKeyword.lexeme, 'static');
    VariableDeclarationList fieldList = declaration.fields;
    expect(fieldList.keyword, isNull);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, usingFastaParser ? isFalse : isTrue);
  }

  void test_incompleteField_static2() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  static c x
}''', codes: [ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    FieldDeclaration declaration = classMember;
    expect(declaration.staticKeyword.lexeme, 'static');
    VariableDeclarationList fieldList = declaration.fields;
    expect(fieldList.keyword, isNull);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isFalse);
  }

  void test_incompleteField_type() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  A
}''', codes: [
      // Fasta considers the `c` to be the type
      // whereas analyzer considers it to be the identifier.
      usingFastaParser
          ? ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
          : ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    TypeName type = fieldList.type;
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    if (usingFastaParser) {
      expect(type, isNull);
      expect(field.name.name, 'A');
    } else {
      expect(type.name.name, 'A');
      expect(field.name.isSynthetic, isTrue);
    }
  }

  void test_incompleteField_var() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  var
}''', codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword.keyword, Keyword.VAR);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteForEach() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    ForStatement statement = parseStatement('for (String item i) {}');
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 17, 1)
    ]);
    expect(statement, isForStatement);
    expect(statement.toSource(), 'for (String item; i;) {}');
    var forParts = statement.forLoopParts as ForParts;
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.leftSeparator.type, TokenType.SEMICOLON);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.rightSeparator.type, TokenType.SEMICOLON);
  }

  void test_incompleteLocalVariable_atTheEndOfBlock() {
    Statement statement = parseStatement('String v }', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_atTheEndOfBlock_modifierOnly() {
    Statement statement = parseStatement('final }', expectedEndOffset: 6);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1)
    ]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'final ;');
  }

  void test_incompleteLocalVariable_beforeIdentifier() {
    Statement statement =
        parseStatement('String v String v2;', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_beforeKeyword() {
    Statement statement =
        parseStatement('String v if (true) {}', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_beforeNextBlock() {
    Statement statement = parseStatement('String v {}', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_parameterizedType() {
    Statement statement =
        parseStatement('List<String> v {}', expectedEndOffset: 15);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'List<String> v;');
  }

  void test_incompleteTypeArguments_field() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  final List<int f;
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 23, 3)]);
    // one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
    // one field declaration
    List<ClassMember> members = classDecl.members;
    expect(members, hasLength(1));
    FieldDeclaration fieldDecl = members[0] as FieldDeclaration;
    // one field
    VariableDeclarationList fieldList = fieldDecl.fields;
    List<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.name, 'f');
    // validate the type
    TypeArgumentList typeArguments = (fieldList.type as TypeName).typeArguments;
    expect(typeArguments.arguments, hasLength(1));
    // synthetic '>'
    Token token = typeArguments.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_incompleteTypeParameters() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C<K {
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1)]);
    // one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
    // validate the type parameters
    TypeParameterList typeParameters = classDecl.typeParameters;
    expect(typeParameters.typeParameters, hasLength(1));
    // synthetic '>'
    Token token = typeParameters.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_incompleteTypeParameters2() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C<K extends L<T> {
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 21, 1)]);
    // one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
    // validate the type parameters
    TypeParameterList typeParameters = classDecl.typeParameters;
    expect(typeParameters.typeParameters, hasLength(1));
    // synthetic '>'
    Token token = typeParameters.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_incompleteTypeParameters3() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C<K extends L<T {
}''',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 1)]
            : [
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 22, 1)
              ]);
    // one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
    // validate the type parameters
    TypeParameterList typeParameters = classDecl.typeParameters;
    expect(typeParameters.typeParameters, hasLength(1));
    // synthetic '>'
    Token token = typeParameters.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_invalidFunctionBodyModifier() {
    parseCompilationUnit("f() sync {}",
        codes: [ParserErrorCode.MISSING_STAR_AFTER_SYNC]);
  }

  void test_invalidMapLiteral() {
    parseCompilationUnit("class C { var f = Map<A, B> {}; }",
        codes: usingFastaParser
            ? [
                // TODO(danrubel): Improve error message to indicate
                // that "Map" should be removed.
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_KEYWORD_OPERATOR,
                ParserErrorCode.MISSING_METHOD_PARAMETERS,
                ParserErrorCode.EXPECTED_CLASS_MEMBER,
              ]
            : [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_CLASS_MEMBER,
                ParserErrorCode.EXPECTED_CLASS_MEMBER,
                ParserErrorCode.UNEXPECTED_TOKEN,
                ParserErrorCode.UNEXPECTED_TOKEN,
                ParserErrorCode.UNEXPECTED_TOKEN,
                ParserErrorCode.UNEXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_EXECUTABLE,
              ]);
  }

  void test_invalidTypeParameters() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  G<int double> g;
}''',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXPECTED_TOKEN, 18, 6)]
            : [
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 18, 6),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 18, 6),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 24, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 24, 1),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 26, 1)
              ]);
    // one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    // validate members
    if (usingFastaParser) {
      ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
      expect(classDecl.members, hasLength(1));
      FieldDeclaration fields = classDecl.members.first;
      expect(fields.fields.variables, hasLength(1));
      VariableDeclaration field = fields.fields.variables.first;
      expect(field.name.name, 'g');
    }
  }

  void test_isExpression_noType() {
    CompilationUnit unit = parseCompilationUnit(
        "class Bar<T extends Foo> {m(x){if (x is ) return;if (x is !)}}",
        codes: usingFastaParser
            ? [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
              ]
            : [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_STATEMENT
              ]);
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    MethodDeclaration method = declaration.members[0] as MethodDeclaration;
    BlockFunctionBody body = method.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[1] as IfStatement;
    IsExpression expression = ifStatement.condition as IsExpression;
    expect(expression.expression, isNotNull);
    expect(expression.isOperator, isNotNull);
    expect(expression.notOperator, isNotNull);
    TypeAnnotation type = expression.type;
    expect(type, isNotNull);
    expect(type is TypeName && type.name.isSynthetic, isTrue);
    if (usingFastaParser) {
      ExpressionStatement thenStatement = ifStatement.thenStatement;
      expect(thenStatement.semicolon.isSynthetic, isTrue);
      SimpleIdentifier simpleId = thenStatement.expression;
      expect(simpleId.isSynthetic, isTrue);
    } else {
      expect(ifStatement.thenStatement, isEmptyStatement);
    }
  }

  void test_issue_34610_get() {
    final unit = parseCompilationUnit('class C { get C.named => null; }',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.GETTER_CONSTRUCTOR, 10, 3),
                expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 14, 1),
              ]
            : [
                expectedError(
                    ParserErrorCode.STATIC_GETTER_WITHOUT_BODY, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 15, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 22, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 22, 2),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 22, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 25, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 25, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 29, 1),
              ]);
    ClassDeclaration declaration = unit.declarations[0];
    if (usingFastaParser) {
      ConstructorDeclaration method = declaration.members[0];
      expect(method.name.name, 'named');
      expect(method.parameters, isNotNull);
    } else {
      MethodDeclaration method = declaration.members[0];
      expect(method.name.name, 'C');
      expect(method.isGetter, isTrue);
      expect(method.parameters, isNull);
    }
  }

  void test_issue_34610_initializers() {
    final unit = parseCompilationUnit('class C { C.named : super(); }',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1)]
            : [
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 18, 19),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 18, 19),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 18, 19),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 20, 25),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 20, 25),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 25, 26),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 25, 26),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 26, 27),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 26, 27),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 27, 28),
              ]);
    ClassDeclaration declaration = unit.declarations[0];
    if (usingFastaParser) {
      ConstructorDeclaration constructor = declaration.members[0];
      expect(constructor.name.name, 'named');
      expect(constructor.parameters, isNotNull);
      expect(constructor.parameters.parameters, hasLength(0));
    } else {
      FieldDeclaration field = declaration.members[0];
      expect(field.fields.type.toSource(), 'C.named');
    }
  }

  void test_issue_34610_missing_param() {
    final unit = parseCompilationUnit('class C { C => null; }',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1)]
            : [
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 18, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 18, 2),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 18, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 21, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 21, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 25, 1),
              ]);
    ClassDeclaration declaration = unit.declarations[0];
    if (usingFastaParser) {
      ConstructorDeclaration constructor = declaration.members[0];
      expect(constructor.name, isNull);
      expect(constructor.parameters, isNotNull);
      expect(constructor.parameters.parameters, hasLength(0));
    } else {
      FieldDeclaration field = declaration.members[0];
      expect(field.fields.type.toSource(), 'C');
    }
  }

  void test_issue_34610_named_missing_param() {
    final unit = parseCompilationUnit('class C { C.named => null; }',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1)]
            : [
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 18, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 18, 2),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 18, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 21, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 21, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 25, 1),
              ]);
    ClassDeclaration declaration = unit.declarations[0];
    if (usingFastaParser) {
      ConstructorDeclaration constructor = declaration.members[0];
      expect(constructor.name.name, 'named');
      expect(constructor.parameters, isNotNull);
      expect(constructor.parameters.parameters, hasLength(0));
    } else {
      FieldDeclaration field = declaration.members[0];
      expect(field.fields.type.toSource(), 'C.named');
    }
  }

  void test_issue_34610_set() {
    final unit = parseCompilationUnit('class C { set C.named => null; }',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.SETTER_CONSTRUCTOR, 10, 3),
                expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 14, 1),
              ]
            : [
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 15, 1),
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 15, 1),
                expectedError(
                    ParserErrorCode.STATIC_SETTER_WITHOUT_BODY, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 15, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 15, 1),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 22, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 22, 2),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 22, 2),
                expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 25, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 25, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 29, 1),
              ]);
    ClassDeclaration declaration = unit.declarations[0];
    if (usingFastaParser) {
      ConstructorDeclaration method = declaration.members[0];
      expect(method.name.name, 'named');
      expect(method.parameters, isNotNull);
      expect(method.parameters.parameters, hasLength(0));
    } else {
      MethodDeclaration method = declaration.members[0];
      expect(method.name.name, 'C');
      expect(method.isSetter, isTrue);
      expect(method.parameters, isNotNull);
      expect(method.parameters.parameters, hasLength(1));
    }
  }

  void test_keywordInPlaceOfIdentifier() {
    // TODO(brianwilkerson) We could do better with this.
    parseCompilationUnit("do() {}",
        codes: usingFastaParser
            // fasta reports ExpectedIdentifier
            // which gets mapped to MISSING_IDENTIFIER
            ? [ParserErrorCode.MISSING_IDENTIFIER]
            : [
                ParserErrorCode.EXPECTED_EXECUTABLE,
                ParserErrorCode.UNEXPECTED_TOKEN
              ]);
  }

  void test_logicalAndExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("&& y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("&&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x &&", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = parseExpression("| &&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = parseExpression("&& |", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("|| y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("||", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x ||", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = parseExpression("&& ||", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = parseExpression("|| &&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_method_missingBody() {
    parseCompilationUnit("class C { b() }",
        errors: [expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 14, 1)]);
  }

  void test_missing_commaInArgumentList() {
    MethodInvocation expression = parseExpression("f(x: 1 y: 2)",
        errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    NodeList<Expression> arguments = expression.argumentList.arguments;
    expect(arguments, hasLength(2));
  }

  void test_missingComma_beforeNamedArgument() {
    createParser('(a b: c)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 3, 1)]);
    expect(argumentList.arguments, hasLength(2));
  }

  void test_missingGet() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  int length {}
  void foo() {}
}''', errors: [
      expectedError(
          usingFastaParser
              ? ParserErrorCode.MISSING_METHOD_PARAMETERS
              : ParserErrorCode.MISSING_GET,
          16,
          6)
    ]);
    expect(unit, isNotNull);
    ClassDeclaration classDeclaration =
        unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = classDeclaration.members;
    expect(members, hasLength(2));
    expect(members[0], isMethodDeclaration);
    ClassMember member = members[1];
    expect(member, isMethodDeclaration);
    expect((member as MethodDeclaration).name.name, "foo");
  }

  void test_missingIdentifier_afterAnnotation() {
    createParser('@override }', expectedEndOffset: 10);
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 10, 1)]);
    if (usingFastaParser) {
      // TODO(danrubel): Consider generating a sub method so that the
      // existing annotation can be associated with a class member.
      expect(member, isNull);
    } else {
      expect(member, isMethodDeclaration);
      MethodDeclaration method = member;
      expect(method.documentationComment, isNull);
      NodeList<Annotation> metadata = method.metadata;
      expect(metadata, hasLength(1));
      expect(metadata[0].name.name, "override");
    }
  }

  void test_missingSemicolon_varialeDeclarationList() {
    void verify(CompilationUnitMember member, String expectedTypeName,
        String expectedName, String expectedSemicolon) {
      expect(member, isTopLevelVariableDeclaration);
      TopLevelVariableDeclaration declaration = member;
      VariableDeclarationList variableList = declaration.variables;
      expect(variableList, isNotNull);
      NodeList<VariableDeclaration> variables = variableList.variables;
      expect(variables, hasLength(1));
      VariableDeclaration variable = variables[0];
      expect(variableList.type.toString(), expectedTypeName);
      expect(variable.name.name, expectedName);
      if (expectedSemicolon.isEmpty) {
        expect(declaration.semicolon.isSynthetic, isTrue);
      } else {
        expect(declaration.semicolon.lexeme, expectedSemicolon);
      }
    }

    // Fasta considers the `n` an extraneous modifier
    // and parses this as a single top level declaration.
    // TODO(danrubel): A better recovery
    // would be to insert a synthetic comma after the `n`.
    CompilationUnit unit = parseCompilationUnit('String n x = "";', codes: [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
    ]);
    expect(unit, isNotNull);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    verify(declarations[0], 'String', 'n', '');
    verify(declarations[1], 'null', 'x', ';');
  }

  void test_multiplicativeExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("* y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("*", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x *", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super *", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression =
        parseExpression("-x *", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression =
        parseExpression("* -y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_super() {
    BinaryExpression expression = parseExpression("super ==  ==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_namedParameterOutsideGroup() {
    CompilationUnit unit =
        parseCompilationUnit('class A { b(c: 0, Foo d: 0, e){} }', errors: [
      expectedError(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, 13, 1),
      expectedError(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, 23, 1)
    ]);
    expect(unit.declarations, hasLength(1));
    ClassDeclaration classA = unit.declarations[0];
    expect(classA.members, hasLength(1));
    MethodDeclaration method = classA.members[0];
    NodeList<FormalParameter> parameters = method.parameters.parameters;
    expect(parameters, hasLength(3));
    expect(parameters[0].isNamed, isTrue);
    expect(parameters[1].isNamed, isTrue);
    expect(parameters[2].isRequired, isTrue);
  }

  void test_nonStringLiteralUri_import() {
    parseCompilationUnit("import dart:io; class C {}",
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.EXPECTED_STRING_LITERAL, 7, 4),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 4),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 7, 4),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 4),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 11, 1),
                expectedError(
                    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 12, 2)
              ]
            : [expectedError(ParserErrorCode.NON_STRING_LITERAL_AS_URI, 7, 4)]);
  }

  void test_prefixExpression_missing_operand_minus() {
    PrefixExpression expression =
        parseExpression("-", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.operand, isSimpleIdentifier);
    expect(expression.operand.isSynthetic, isTrue);
    expect(expression.operator.type, TokenType.MINUS);
  }

  void test_primaryExpression_argumentDefinitionTest() {
    SimpleIdentifier expression = parsePrimaryExpression('?a',
        expectedEndOffset: 0,
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 1)]
            : [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 0, 1)]);
    expectNotNullIfNoErrors(expression);
    expect(expression.isSynthetic, usingFastaParser);
  }

  void test_propertyAccess_missing_LHS_RHS() {
    Expression result = parseExpression(".", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    if (usingFastaParser) {
      PrefixedIdentifier expression = result;
      expect(expression.prefix.isSynthetic, isTrue);
      expect(expression.period.lexeme, '.');
      expect(expression.identifier.isSynthetic, isTrue);
    } else {
      PropertyAccess expression = result;
      SimpleIdentifier target = expression.target;
      expect(target.isSynthetic, isTrue);
      expect(expression.operator.lexeme, '.');
      expect(expression.propertyName.isSynthetic, isTrue);
    }
  }

  void test_relationalExpression_missing_LHS() {
    IsExpression expression =
        parseExpression("is y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.expression, isSimpleIdentifier);
    expect(expression.expression.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_LHS_RHS() {
    IsExpression expression = parseExpression("is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.expression, isSimpleIdentifier);
    expect(expression.expression.isSynthetic, isTrue);
    expect(expression.type, isTypeName);
    expect(expression.type.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_RHS() {
    IsExpression expression =
        parseExpression("x is", codes: [ParserErrorCode.EXPECTED_TYPE_NAME]);
    expect(expression.type, isTypeName);
    expect(expression.type.isSynthetic, isTrue);
  }

  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = parseExpression("<< is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.expression, isBinaryExpression);
  }

  void test_shiftExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("<< y", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("<<", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x <<", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS_super() {
    BinaryExpression expression = parseExpression("super <<",
        codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_precedence_unary_left() {
    BinaryExpression expression = parseExpression("+ <<", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_unary_right() {
    BinaryExpression expression = parseExpression("<< +", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_shiftExpression_super() {
    BinaryExpression expression = parseExpression("super << <<", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_typedef_eof() {
    CompilationUnit unit = parseCompilationUnit("typedef n", codes: [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_TYPEDEF_PARAMETERS
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isFunctionTypeAlias);
  }

  void test_unaryPlus() {
    parseExpression("+2", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
  }
}

/// Tests of the analyzer parser based on [SimpleParserTestMixin].
@reflectiveTest
class SimpleParserTest extends ParserTestCase with SimpleParserTestMixin {
  void test_computeStringValue_emptyInterpolationPrefix() {
    expect(_computeStringValue("'''", true, false), "");
  }

  void test_computeStringValue_escape_b() {
    expect(_computeStringValue("'\\b'", true, true), "\b");
  }

  void test_computeStringValue_escape_f() {
    expect(_computeStringValue("'\\f'", true, true), "\f");
  }

  void test_computeStringValue_escape_n() {
    expect(_computeStringValue("'\\n'", true, true), "\n");
  }

  void test_computeStringValue_escape_notSpecial() {
    expect(_computeStringValue("'\\:'", true, true), ":");
  }

  void test_computeStringValue_escape_r() {
    expect(_computeStringValue("'\\r'", true, true), "\r");
  }

  void test_computeStringValue_escape_t() {
    expect(_computeStringValue("'\\t'", true, true), "\t");
  }

  void test_computeStringValue_escape_u_fixed() {
    expect(_computeStringValue("'\\u4321'", true, true), "\u4321");
  }

  void test_computeStringValue_escape_u_variable() {
    expect(_computeStringValue("'\\u{123}'", true, true), "\u0123");
  }

  void test_computeStringValue_escape_v() {
    expect(_computeStringValue("'\\v'", true, true), "\u000B");
  }

  void test_computeStringValue_escape_x() {
    expect(_computeStringValue("'\\xFF'", true, true), "\u00FF");
  }

  void test_computeStringValue_noEscape_single() {
    expect(_computeStringValue("'text'", true, true), "text");
  }

  void test_computeStringValue_noEscape_triple() {
    expect(_computeStringValue("'''text'''", true, true), "text");
  }

  void test_computeStringValue_raw_single() {
    expect(_computeStringValue("r'text'", true, true), "text");
  }

  void test_computeStringValue_raw_triple() {
    expect(_computeStringValue("r'''text'''", true, true), "text");
  }

  void test_computeStringValue_raw_withEscape() {
    expect(_computeStringValue("r'two\\nlines'", true, true), "two\\nlines");
  }

  void test_computeStringValue_triple_internalQuote_first_empty() {
    expect(_computeStringValue("''''", true, false), "'");
  }

  void test_computeStringValue_triple_internalQuote_first_nonEmpty() {
    expect(_computeStringValue("''''text", true, false), "'text");
  }

  void test_computeStringValue_triple_internalQuote_last_empty() {
    expect(_computeStringValue("'''", false, true), "");
  }

  void test_computeStringValue_triple_internalQuote_last_nonEmpty() {
    expect(_computeStringValue("text'''", false, true), "text");
  }

  void test_createSyntheticIdentifier() {
    createParser('');
    SimpleIdentifier identifier = parser.createSyntheticIdentifier();
    expectNotNullIfNoErrors(identifier);
    expect(identifier.isSynthetic, isTrue);
  }

  void test_createSyntheticStringLiteral() {
    createParser('');
    SimpleStringLiteral literal = parser.createSyntheticStringLiteral();
    expectNotNullIfNoErrors(literal);
    expect(literal.isSynthetic, isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_block() {
    expect(_isFunctionDeclaration("f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_expression() {
    expect(_isFunctionDeclaration("f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_typeParameters_block() {
    expect(_isFunctionDeclaration("f<E>() {}"), isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_typeParameters_expression() {
    expect(_isFunctionDeclaration("f<E>() => e"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_block() {
    expect(_isFunctionDeclaration("C f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_expression() {
    expect(_isFunctionDeclaration("C f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_typeParameters_block() {
    expect(_isFunctionDeclaration("C f<E>() {}"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_typeParameters_expression() {
    expect(_isFunctionDeclaration("C f<E>() => e"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_block() {
    expect(_isFunctionDeclaration("void f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_expression() {
    expect(_isFunctionDeclaration("void f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_typeParameters_block() {
    expect(_isFunctionDeclaration("void f<E>() {}"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_typeParameters_expression() {
    expect(_isFunctionDeclaration("void f<E>() => e"), isTrue);
  }

  void test_isFunctionExpression_false_noBody() {
    expect(_isFunctionExpression("f();"), isFalse);
  }

  void test_isFunctionExpression_false_notParameters() {
    expect(_isFunctionExpression("(a + b) {"), isFalse);
  }

  void test_isFunctionExpression_noParameters_block() {
    expect(_isFunctionExpression("() {}"), isTrue);
  }

  void test_isFunctionExpression_noParameters_expression() {
    expect(_isFunctionExpression("() => e"), isTrue);
  }

  void test_isFunctionExpression_noParameters_typeParameters_block() {
    expect(_isFunctionExpression("<E>() {}"), isTrue);
  }

  void test_isFunctionExpression_noParameters_typeParameters_expression() {
    expect(_isFunctionExpression("<E>() => e"), isTrue);
  }

  void test_isFunctionExpression_parameter_final() {
    expect(_isFunctionExpression("(final a) {}"), isTrue);
    expect(_isFunctionExpression("(final a, b) {}"), isTrue);
    expect(_isFunctionExpression("(final a, final b) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_final_typed() {
    expect(_isFunctionExpression("(final int a) {}"), isTrue);
    expect(_isFunctionExpression("(final prefix.List a) {}"), isTrue);
    expect(_isFunctionExpression("(final List<int> a) {}"), isTrue);
    expect(_isFunctionExpression("(final prefix.List<int> a) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_multiple() {
    expect(_isFunctionExpression("(a, b) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_named() {
    expect(_isFunctionExpression("({a}) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_optional() {
    expect(_isFunctionExpression("([a]) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_single() {
    expect(_isFunctionExpression("(a) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_typed() {
    expect(_isFunctionExpression("(int a, int b) {}"), isTrue);
  }

  void test_isInitializedVariableDeclaration_assignment() {
    expect(_isInitializedVariableDeclaration("a = null;"), isFalse);
  }

  void test_isInitializedVariableDeclaration_comparison() {
    expect(_isInitializedVariableDeclaration("a < 0;"), isFalse);
  }

  void test_isInitializedVariableDeclaration_conditional() {
    expect(_isInitializedVariableDeclaration("a == null ? init() : update();"),
        isFalse);
  }

  void test_isInitializedVariableDeclaration_const_noType_initialized() {
    expect(_isInitializedVariableDeclaration("const a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_const_noType_uninitialized() {
    expect(_isInitializedVariableDeclaration("const a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_const_simpleType_uninitialized() {
    expect(_isInitializedVariableDeclaration("const A a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_final_noType_initialized() {
    expect(_isInitializedVariableDeclaration("final a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_final_noType_uninitialized() {
    expect(_isInitializedVariableDeclaration("final a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_final_simpleType_initialized() {
    expect(_isInitializedVariableDeclaration("final A a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_functionDeclaration_typed() {
    expect(_isInitializedVariableDeclaration("A f() {};"), isFalse);
  }

  void test_isInitializedVariableDeclaration_functionDeclaration_untyped() {
    expect(_isInitializedVariableDeclaration("f() {};"), isFalse);
  }

  void test_isInitializedVariableDeclaration_noType_initialized() {
    expect(_isInitializedVariableDeclaration("var a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_noType_uninitialized() {
    expect(_isInitializedVariableDeclaration("var a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_parameterizedType_initialized() {
    expect(_isInitializedVariableDeclaration("List<int> a = null;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_parameterizedType_uninitialized() {
    expect(_isInitializedVariableDeclaration("List<int> a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_simpleType_initialized() {
    expect(_isInitializedVariableDeclaration("A a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_simpleType_uninitialized() {
    expect(_isInitializedVariableDeclaration("A a;"), isTrue);
  }

  void test_isSwitchMember_case_labeled() {
    expect(_isSwitchMember("l1: l2: case"), isTrue);
  }

  void test_isSwitchMember_case_unlabeled() {
    expect(_isSwitchMember("case"), isTrue);
  }

  void test_isSwitchMember_default_labeled() {
    expect(_isSwitchMember("l1: l2: default"), isTrue);
  }

  void test_isSwitchMember_default_unlabeled() {
    expect(_isSwitchMember("default"), isTrue);
  }

  void test_isSwitchMember_false() {
    expect(_isSwitchMember("break;"), isFalse);
  }

  void test_parseDottedName_multiple() {
    createParser('a.b.c');
    DottedName name = parser.parseDottedName();
    expectNotNullIfNoErrors(name);
    assertNoErrors();
    expectDottedName(name, ["a", "b", "c"]);
  }

  void test_parseDottedName_single() {
    createParser('a');
    DottedName name = parser.parseDottedName();
    expectNotNullIfNoErrors(name);
    assertNoErrors();
    expectDottedName(name, ["a"]);
  }

  void test_parseFinalConstVarOrType_const_functionType() {
    createParser('const int Function(int) f');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.CONST);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_const_namedType() {
    createParser('const A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.CONST);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_const_noType() {
    createParser('const');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.CONST);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_final_functionType() {
    createParser('final int Function(int) f');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.FINAL);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_final_namedType() {
    createParser('final A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.FINAL);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_final_noType() {
    createParser('final');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.FINAL);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_final_prefixedType() {
    createParser('final p.A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.FINAL);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_function() {
    createParser('int Function(int) f');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_parameterized() {
    createParser('A<B> a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixed() {
    createParser('p.A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixed_noIdentifier() {
    createParser('p.A,');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixedAndParameterized() {
    createParser('p.A<B> a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_simple() {
    createParser('A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_simple_noIdentifier_inFunctionType() {
    createParser('A,');
    FinalConstVarOrType result =
        parser.parseFinalConstVarOrType(false, inFunctionType: true);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_var() {
    createParser('var');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type.isKeyword, true);
    expect(keyword.keyword, Keyword.VAR);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_void() {
    createParser('void f()');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_void_identifier() {
    createParser('void x');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_void_noIdentifier() {
    createParser('void,');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }

  void test_parseFunctionBody_skip_block() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('{}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isEmptyFunctionBody);
  }

  void test_parseFunctionBody_skip_block_invalid() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('{');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrorsWithCodes([ScannerErrorCode.EXPECTED_TOKEN]);
    expect(functionBody, isEmptyFunctionBody);
  }

  void test_parseFunctionBody_skip_blocks() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('{ {} }');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isEmptyFunctionBody);
  }

  void test_parseFunctionBody_skip_expression() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('=> y;');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    assertNoErrors();
    expect(functionBody, isEmptyFunctionBody);
  }

  void test_parseModifiers_abstract() {
    createParser('abstract A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.abstractKeyword, isNotNull);
  }

  void test_parseModifiers_const() {
    createParser('const A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.constKeyword, isNotNull);
  }

  void test_parseModifiers_covariant() {
    createParser('covariant A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.covariantKeyword, isNotNull);
  }

  void test_parseModifiers_external() {
    createParser('external A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.externalKeyword, isNotNull);
  }

  void test_parseModifiers_factory() {
    createParser('factory A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.factoryKeyword, isNotNull);
  }

  void test_parseModifiers_final() {
    createParser('final A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.finalKeyword, isNotNull);
  }

  void test_parseModifiers_static() {
    createParser('static A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.staticKeyword, isNotNull);
  }

  void test_parseModifiers_var() {
    createParser('var A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    assertNoErrors();
    expect(modifiers.varKeyword, isNotNull);
  }

  void test_Parser() {
    expect(
      Parser(
        NonExistingSource.unknown,
        null,
        featureSet: FeatureSet.forTesting(),
      ),
      isNotNull,
    );
  }

  void test_skipPrefixedIdentifier_invalid() {
    createParser('+');
    Token following = parser.skipPrefixedIdentifier(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipPrefixedIdentifier_notPrefixed() {
    createParser('a +');
    Token following = parser.skipPrefixedIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipPrefixedIdentifier_prefixed() {
    createParser('a.b +');
    Token following = parser.skipPrefixedIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipReturnType_invalid() {
    // TODO(eernst): `skipReturnType` eliminated, delete this test?
    createParser('+');
    Token following = parser.skipTypeAnnotation(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipReturnType_type() {
    // TODO(eernst): `skipReturnType` eliminated, delete this test?
    createParser('C +');
    Token following = parser.skipTypeAnnotation(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipReturnType_void() {
    // TODO(eernst): `skipReturnType` eliminated, delete this test?
    createParser('void +');
    Token following = parser.skipTypeAnnotation(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipSimpleIdentifier_identifier() {
    createParser('i +');
    Token following = parser.skipSimpleIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipSimpleIdentifier_invalid() {
    createParser('9 +');
    Token following = parser.skipSimpleIdentifier(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipSimpleIdentifier_pseudoKeyword() {
    createParser('as +');
    Token following = parser.skipSimpleIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_adjacent() {
    createParser("'a' 'b' +");
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_interpolated() {
    createParser("'a\${b}c' +");
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_invalid() {
    createParser('a');
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipStringLiteral_single() {
    createParser("'a' +");
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeArgumentList_invalid() {
    createParser('+');
    Token following = parser.skipTypeArgumentList(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipTypeArgumentList_multiple() {
    createParser('<E, F, G> +');
    Token following = parser.skipTypeArgumentList(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeArgumentList_single() {
    createParser('<E> +');
    Token following = parser.skipTypeArgumentList(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeName_invalid() {
    createParser('+');
    Token following = parser.skipTypeName(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipTypeName_parameterized() {
    createParser('C<E<F<G>>> +');
    Token following = parser.skipTypeName(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeName_simple() {
    createParser('C +');
    Token following = parser.skipTypeName(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  /// Invoke the method [Parser.computeStringValue] with the given argument.
  ///
  /// @param lexeme the argument to the method
  /// @param first `true` if this is the first token in a string literal
  /// @param last `true` if this is the last token in a string literal
  /// @return the result of invoking the method
  /// @throws Exception if the method could not be invoked or throws an
  ///           exception
  String _computeStringValue(String lexeme, bool first, bool last) {
    createParser('');
    String value = parser.computeStringValue(lexeme, first, last);
    assertNoErrors();
    return value;
  }

  /// Invoke the method [Parser.isFunctionDeclaration] with the parser set to
  /// the token stream produced by scanning the given source.
  ///
  /// @param source the source to be scanned to produce the token stream being
  ///          tested
  /// @return the result of invoking the method
  /// @throws Exception if the method could not be invoked or throws an
  ///           exception
  bool _isFunctionDeclaration(String source) {
    createParser(source);
    bool result = parser.isFunctionDeclaration();
    expectNotNullIfNoErrors(result);
    return result;
  }

  /// Invoke the method [Parser.isFunctionExpression] with the parser set to the
  /// token stream produced by scanning the given source.
  ///
  /// @param source the source to be scanned to produce the token stream being
  ///          tested
  /// @return the result of invoking the method
  /// @throws Exception if the method could not be invoked or throws an
  ///           exception
  bool _isFunctionExpression(String source) {
    createParser(source);
    return parser.isFunctionExpression(parser.currentToken);
  }

  /// Invoke the method [Parser.isInitializedVariableDeclaration] with the
  /// parser set to the token stream produced by scanning the given source.
  ///
  /// @param source the source to be scanned to produce the token stream being
  ///          tested
  /// @return the result of invoking the method
  /// @throws Exception if the method could not be invoked or throws an
  ///           exception
  bool _isInitializedVariableDeclaration(String source) {
    createParser(source);
    bool result = parser.isInitializedVariableDeclaration();
    expectNotNullIfNoErrors(result);
    return result;
  }

  /// Invoke the method [Parser.isSwitchMember] with the parser set to the token
  /// stream produced by scanning the given source.
  ///
  /// @param source the source to be scanned to produce the token stream being
  ///          tested
  /// @return the result of invoking the method
  /// @throws Exception if the method could not be invoked or throws an
  ///           exception
  bool _isSwitchMember(String source) {
    createParser(source);
    bool result = parser.isSwitchMember();
    expectNotNullIfNoErrors(result);
    return result;
  }
}

/// Parser tests that test individual parsing methods. The code fragments should
/// be as minimal as possible in order to test the method, but should not test
/// the interactions between the method under test and other methods.
///
/// More complex tests should be defined in the class [ComplexParserTest].
mixin SimpleParserTestMixin implements AbstractParserTestCase {
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
    expect(body.keyword.lexeme, Parser.ASYNC);
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
    expect(body.keyword.lexeme, Parser.ASYNC);
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
    expect(body.keyword.lexeme, Parser.SYNC);
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
    expect(body.keyword.lexeme, Parser.ASYNC);
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
    // Old parser produces errors
    if (usingFastaParser) {
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
    if (!usingFastaParser) {
      return;
    }
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
    parseCompilationUnit('library <myLibId>;',
        errors: usingFastaParser
            ? [
                expectedError(
                    ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 0, 7),
                expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 17, 1),
              ]
            : [expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 8, 1)]);
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
    if (usingFastaParser) {
      // TODO(danrubel): Consider splitting `<<` and marking the first `<`
      // as an unexpected token.
      expect(parameterList, isNull);
      assertNoErrors();
    } else {
      expectNotNullIfNoErrors(parameterList);
      assertNoErrors();
      expect(parameterList.leftBracket, isNotNull);
      expect(parameterList.rightBracket, isNotNull);
      expect(parameterList.typeParameters, hasLength(1));
    }
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
}

@reflectiveTest
class StatementParserTest extends ParserTestCase with StatementParserTestMixin {
}

/// The class [FormalParameterParserTestMixin] defines parser tests that test
/// the parsing statements.
mixin StatementParserTestMixin implements AbstractParserTestCase {
  void test_invalid_typeParamAnnotation() {
    parseCompilationUnit('main() { C<@Foo T> v; }',
        errors: usingFastaParser
            // TODO(danrubel): Improve this error to indicate that annotations
            // are not valid in this context.
            ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 11, 1)]
            : [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 11, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 1)
              ]);
  }

  void test_invalid_typeParamAnnotation2() {
    parseCompilationUnit('main() { C<@Foo.bar(1) T> v; }',
        errors: usingFastaParser
            // TODO(danrubel): Improve this error to indicate that annotations
            // are not valid in this context.
            ? [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 11, 1)]
            : [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 11, 1),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 1)
              ]);
  }

  void test_invalid_typeParamAnnotation3() {
    if (usingFastaParser) {
      parseCompilationUnit('''
main() {
  C<@Foo.bar(const [], const [1], const{"":r""}, 0xFF + 2, .3, 4.5) T,
    F Function<G>(int, String, {Bar b}),
    void Function<H>(int i, [String j, K]),
    A<B<C>>,
    W<X<Y<Z>>>
  > v;
}''', errors: [
        // TODO(danrubel): Improve this error to indicate that annotations
        // are not valid in this context.
        expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 13, 1)
      ]);
    }
  }

  void test_parseAssertStatement() {
    var statement = parseStatement('assert (x);') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNull);
    expect(statement.message, isNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_messageLowPrecedence() {
    // Using a throw expression as an assert message would be silly in
    // practice, but it's the lowest precedence expression type, so verifying
    // that it works should give us high confidence that other expression types
    // will work as well.
    var statement =
        parseStatement('assert (x, throw "foo");') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_messageString() {
    var statement = parseStatement('assert (x, "foo");') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_trailingComma_message() {
    var statement = parseStatement('assert (x, "m",);') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_trailingComma_noMessage() {
    var statement = parseStatement('assert (x,);') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNull);
    expect(statement.message, isNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseBlock_empty() {
    var block = parseStatement('{}') as Block;
    assertNoErrors();
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(0));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBlock_nonEmpty() {
    var block = parseStatement('{;}') as Block;
    assertNoErrors();
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(1));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBreakStatement_label() {
    LabeledStatement labeledStatement =
        parseStatement('foo: while (true) { break foo; }');
    WhileStatement whileStatement = labeledStatement.statement;
    BreakStatement statement = (whileStatement.body as Block).statements[0];
    assertNoErrors();
    expect(statement.breakKeyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseBreakStatement_noLabel() {
    WhileStatement whileStatement = parseStatement('while (true) { break; }');
    BreakStatement statement = (whileStatement.body as Block).statements[0];
    assertNoErrors();
    expect(statement.breakKeyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseContinueStatement_label() {
    LabeledStatement labeledStatement =
        parseStatement('foo: while (true) { continue foo; }');
    WhileStatement whileStatement = labeledStatement.statement;
    ContinueStatement statement = (whileStatement.body as Block).statements[0];
    assertNoErrors();
    expect(statement.continueKeyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseContinueStatement_noLabel() {
    WhileStatement whileStatement =
        parseStatement('while (true) { continue; }');
    ContinueStatement statement = (whileStatement.body as Block).statements[0];
    assertNoErrors();
    expect(statement.continueKeyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseDoStatement() {
    var statement = parseStatement('do {} while (x);') as DoStatement;
    assertNoErrors();
    expect(statement.doKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.whileKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseElseAlone() {
    parseCompilationUnit('main() { else return 0; } ',
        errors: usingFastaParser
            ? [
                expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 4),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 9, 4),
              ]
            : [
                expectedError(ParserErrorCode.MISSING_STATEMENT, 9, 4),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 9, 4),
              ]);
  }

  void test_parseEmptyStatement() {
    var statement = parseStatement(';') as EmptyStatement;
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
  }

  void test_parseForStatement_each_await() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    String code = 'await for (element in list) {}';
    var forStatement = _parseAsyncStatement(code) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, usingFastaParser ? isNotNull : isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forEachParts.identifier, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_genericFunctionType() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (void Function<T>(T) element in list) {}')
            as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_identifier() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forEachParts.identifier, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_noType_metadata() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (@A var element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.loopVariable.metadata, hasLength(1));
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_type() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (A element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_var() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_c() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement = parseStatement('for (; i < count;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_cu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (; i < count; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ecu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (i--; i < count; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNotNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement = parseStatement('for (var i = 0;;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(0));
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i_withMetadata() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (@A var i = 0;;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(1));
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ic() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var i = 0; i < count;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_icu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var i = 0; i < count; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iicuu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (int i = 0, j = count; i < j; i++, j--) {}')
            as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(2));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(2));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var i = 0;; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_u() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement = parseStatement('for (;; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseFunctionDeclarationStatement() {
    var statement = parseStatement('void f(int p) => p * 2;')
        as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseFunctionDeclarationStatement_typeParameters() {
    var statement =
        parseStatement('E f<E>(E p) => p * 2;') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
    expect(statement.functionDeclaration.functionExpression.typeParameters,
        isNotNull);
  }

  void test_parseFunctionDeclarationStatement_typeParameters_noReturnType() {
    var statement =
        parseStatement('f<E>(E p) => p * 2;') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
    expect(statement.functionDeclaration.functionExpression.typeParameters,
        isNotNull);
  }

  void test_parseIfStatement_else_block() {
    var statement = parseStatement('if (x) {} else {}') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_else_emptyStatements() {
    var statement = parseStatement('if (true) ; else ;') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_else_statement() {
    var statement = parseStatement('if (x) f(x); else f(y);') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_noElse_block() {
    var statement = parseStatement('if (x) {}') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseIfStatement_noElse_statement() {
    var statement = parseStatement('if (x) f(x);') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseNonLabeledStatement_const_list_empty() {
    var statement = parseStatement('const [];') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    var statement = parseStatement('const [1, 2];') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_empty() {
    var statement = parseStatement('const {};') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    // TODO(brianwilkerson) Implement more tests for this method.
    var statement = parseStatement("const {'a' : 1};") as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object() {
    var statement = parseStatement('const A();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    var statement = parseStatement('const A<B>.c();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters_34403() {
    if (!usingFastaParser) {
      return;
    }
    var statement = parseStatement('const A<B>.c<C>();') as ExpressionStatement;
    assertErrorsWithCodes(
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR]);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_constructorInvocation() {
    var statement = parseStatement('new C().m();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_false() {
    var statement = parseStatement('false;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_functionDeclaration() {
    var statement = parseStatement('f() {}') as FunctionDeclarationStatement;
    assertNoErrors();
    var function = statement.functionDeclaration.functionExpression;
    expect(function.parameters.parameters, isEmpty);
    expect(function.body, isNotNull);
  }

  void test_parseNonLabeledStatement_functionDeclaration_arguments() {
    var statement =
        parseStatement('f(void g()) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    var function = statement.functionDeclaration.functionExpression;
    expect(function.parameters.parameters, hasLength(1));
    expect(function.body, isNotNull);
  }

  void test_parseNonLabeledStatement_functionExpressionIndex() {
    var statement = parseStatement('() {}[0] = null;') as ExpressionStatement;
    assertNoErrors();
    expect(statement, isNotNull);
  }

  void test_parseNonLabeledStatement_functionInvocation() {
    var statement = parseStatement('f();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    var statement =
        parseStatement('(a) {return a + a;} (3);') as ExpressionStatement;
    assertNoErrors();
    var invocation = statement.expression as FunctionExpressionInvocation;

    FunctionExpression expression = invocation.function as FunctionExpression;
    expect(expression.parameters, isNotNull);
    expect(expression.body, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList.arguments, hasLength(1));
  }

  void test_parseNonLabeledStatement_localFunction_gftReturnType() {
    var statement = parseStatement('int Function(int) f(String s) => null;')
        as FunctionDeclarationStatement;
    assertNoErrors();
    FunctionDeclaration function = statement.functionDeclaration;
    expect(function.returnType, isGenericFunctionType);
  }

  void test_parseNonLabeledStatement_null() {
    var statement = parseStatement('null;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    var statement = parseStatement('library.getName();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_true() {
    var statement = parseStatement('true;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_typeCast() {
    var statement = parseStatement('double.NAN as num;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_variableDeclaration_final_namedFunction() {
    var statement = parseStatement('final int Function = 0;')
        as VariableDeclarationStatement;
    assertNoErrors();
    List<VariableDeclaration> variables = statement.variables.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'Function');
  }

  void test_parseNonLabeledStatement_variableDeclaration_gftType() {
    var statement =
        parseStatement('int Function(int) v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_functionReturnType() {
    var statement = parseStatement(
            'Function Function(int x1, {Function x}) Function<B extends core.int>(int x) v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType() {
    var statement = parseStatement('Function(int) Function(int) v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType2() {
    var statement = parseStatement('int Function(int) Function(int) v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_noReturnType() {
    var statement =
        parseStatement('Function(int) v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void test_parseNonLabeledStatement_variableDeclaration_gftType_returnType() {
    var statement =
        parseStatement('int Function<T>() v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_voidReturnType() {
    var statement =
        parseStatement('void Function() v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam() {
    VariableDeclarationStatement statement = parseStatement('C<T> v;');
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    TypeName typeName = variableList.type;
    expect(typeName.name.name, 'C');
    expect(typeName.typeArguments.arguments, hasLength(1));
    TypeName typeArgument = typeName.typeArguments.arguments[0];
    expect(typeArgument.name.name, 'T');
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam2() {
    VariableDeclarationStatement statement =
        parseStatement('C<T /* ignored comment */ > v;');
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    TypeName typeName = variableList.type;
    expect(typeName.name.name, 'C');
    expect(typeName.typeArguments.arguments, hasLength(1));
    TypeName typeArgument = typeName.typeArguments.arguments[0];
    expect(typeArgument.name.name, 'T');
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam3() {
    VariableDeclarationStatement statement =
        parseStatement('C<T Function(String s)> v;');
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.name, 'v');
    TypeName typeName = variableList.type;
    expect(typeName.name.name, 'C');
    expect(typeName.typeArguments.arguments, hasLength(1));
    expect(typeName.typeArguments.arguments[0], isGenericFunctionType);
  }

  void test_parseStatement_emptyTypeArgumentList() {
    var declaration = parseStatement('C<> c;') as VariableDeclarationStatement;
    assertErrorsWithCodes([ParserErrorCode.EXPECTED_TYPE_NAME]);
    VariableDeclarationList variables = declaration.variables;
    TypeName type = variables.type;
    TypeArgumentList argumentList = type.typeArguments;
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.arguments[0].isSynthetic, isTrue);
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseStatement_function_gftReturnType() {
    var statement =
        parseStatement('void Function<A>(core.List<core.int> x) m() => null;')
            as FunctionDeclarationStatement;
    expect(statement.functionDeclaration.functionExpression.body,
        isExpressionFunctionBody);
  }

  void test_parseStatement_functionDeclaration_noReturnType() {
    var statement = parseStatement('true;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseStatement_functionDeclaration_noReturnType_typeParameters() {
    var statement =
        parseStatement('f<E>(a, b) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseStatement_functionDeclaration_returnType() {
    // TODO(brianwilkerson) Implement more tests for this method.
    var statement =
        parseStatement('int f(a, b) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseStatement_functionDeclaration_returnType_typeParameters() {
    var statement =
        parseStatement('int f<E>(a, b) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseStatement_multipleLabels() {
    var statement = parseStatement('l: m: return x;') as LabeledStatement;
    expect(statement.labels, hasLength(2));
    expect(statement.statement, isNotNull);
  }

  void test_parseStatement_noLabels() {
    var statement = parseStatement('return x;') as ReturnStatement;
    assertNoErrors();
    expect(statement, isNotNull);
  }

  void test_parseStatement_singleLabel() {
    var statement = parseStatement('l: return x;') as LabeledStatement;
    assertNoErrors();
    expect(statement.labels, hasLength(1));
    expect(statement.labels[0].label.inDeclarationContext(), isTrue);
    expect(statement.statement, isNotNull);
  }

  void test_parseSwitchStatement_case() {
    var statement =
        parseStatement('switch (a) {case 1: return "I";}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_empty() {
    var statement = parseStatement('switch (a) {}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(0));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledCase() {
    var statement =
        parseStatement('switch (a) {l1: l2: l3: case(1):}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(3));
      expect(labels[0].label.inDeclarationContext(), isTrue);
      expect(labels[1].label.inDeclarationContext(), isTrue);
      expect(labels[2].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledCase2() {
    SwitchStatement statement =
        parseStatement('switch (a) {l1: case 0: l2: case 1: return;}');
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(2));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    {
      List<Label> labels = statement.members[1].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledDefault() {
    var statement =
        parseStatement('switch (a) {l1: l2: l3: default:}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(3));
      expect(labels[0].label.inDeclarationContext(), isTrue);
      expect(labels[1].label.inDeclarationContext(), isTrue);
      expect(labels[2].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledDefault2() {
    SwitchStatement statement =
        parseStatement('switch (a) {l1: case 0: l2: default: return;}');
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(2));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    {
      List<Label> labels = statement.members[1].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledStatementInCase() {
    var statement = parseStatement('switch (a) {case 0: f(); l1: g(); break;}')
        as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.members[0].statements, hasLength(3));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseTryStatement_catch() {
    var statement = parseStatement('try {} catch (e) {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_invalidCatchParam() {
    CompilationUnit unit =
        parseCompilationUnit('main() { try {} catch (int e) { } }',
            errors: usingFastaParser
                ? [expectedError(ParserErrorCode.CATCH_SYNTAX, 27, 1)]
                : [
                    expectedError(ParserErrorCode.EXPECTED_TOKEN, 27, 1),
                    expectedError(ParserErrorCode.EXPECTED_TOKEN, 27, 1),
                    expectedError(ParserErrorCode.EXPECTED_TOKEN, 27, 1),
                    expectedError(ParserErrorCode.MISSING_IDENTIFIER, 28, 1),
                    expectedError(ParserErrorCode.EXPECTED_TOKEN, 28, 1),
                    expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 28, 1),
                  ]);
    FunctionDeclaration method = unit.declarations[0];
    BlockFunctionBody body = method.functionExpression.body;
    TryStatement statement = body.block.statements[0];
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    if (usingFastaParser) {
      expect(clause.exceptionParameter.name, 'int');
      expect(clause.comma, isNotNull);
      expect(clause.stackTraceParameter.name, 'e');
    } else {
      expect(clause.exceptionParameter.name, 'int');
      expect(clause.comma, isNull);
      expect(clause.stackTraceParameter, isNull);
    }
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_missingCatchParam() {
    var statement = parseStatement('try {} catch () {}') as TryStatement;
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.CATCH_SYNTAX, 14, 1)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 14, 1),
          ]);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_missingCatchParen() {
    var statement = parseStatement('try {} catch {}') as TryStatement;
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.CATCH_SYNTAX, 13, 1)]
        : [
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 1),
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
            expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 1)
          ]);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_missingCatchTrace() {
    var statement = parseStatement('try {} catch (e,) {}') as TryStatement;
    listener.assertErrors(usingFastaParser
        ? [expectedError(ParserErrorCode.CATCH_SYNTAX, 16, 1)]
        : [
            expectedError(ParserErrorCode.MISSING_IDENTIFIER, 14, 1),
          ]);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_finally() {
    var statement =
        parseStatement('try {} catch (e, s) {} finally {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTryStatement_finally() {
    var statement = parseStatement('try {} finally {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(0));
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTryStatement_multiple() {
    var statement =
        parseStatement('try {} on NPE catch (e) {} on Error {} catch (e) {}')
            as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(3));
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on() {
    var statement = parseStatement('try {} on Error {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNull);
    expect(clause.exceptionParameter, isNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on_catch() {
    var statement =
        parseStatement('try {} on Error catch (e, s) {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on_catch_finally() {
    var statement = parseStatement('try {} on Error catch (e, s) {} finally {}')
        as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseVariableDeclaration_equals_builtIn() {
    VariableDeclarationStatement statement = parseStatement('int set = 0;');
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_const_noType() {
    var declarationList = parseVariableDeclarationList('const a = 0');
    assertNoErrors();
    expect(declarationList.keyword.lexeme, 'const');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_const_type() {
    var declarationList = parseVariableDeclarationList('const A a');
    assertNoErrors();
    expect(declarationList.keyword.lexeme, 'const');
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_noType() {
    var declarationList = parseVariableDeclarationList('final a');
    assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_type() {
    var declarationList = parseVariableDeclarationList('final A a');
    assertNoErrors();
    expect(declarationList.keyword.lexeme, 'final');
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_type_multiple() {
    var declarationList = parseVariableDeclarationList('A a, b, c');
    assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_type_single() {
    var declarationList = parseVariableDeclarationList('A a');
    assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_multiple() {
    var declarationList = parseVariableDeclarationList('var a, b, c');
    assertNoErrors();
    expect(declarationList.keyword.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_single() {
    var declarationList = parseVariableDeclarationList('var a');
    assertNoErrors();
    expect(declarationList.keyword.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_multiple() {
    var statement =
        parseStatement('var x, y, z;') as VariableDeclarationStatement;
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_single() {
    var statement = parseStatement('var x;') as VariableDeclarationStatement;
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(1));
  }

  void test_parseWhileStatement() {
    var statement = parseStatement('while (x) {}') as WhileStatement;
    assertNoErrors();
    expect(statement.whileKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseYieldStatement_each() {
    var statement =
        _parseAsyncStatement('yield* x;', isGenerator: true) as YieldStatement;
    assertNoErrors();
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseYieldStatement_normal() {
    var statement =
        _parseAsyncStatement('yield x;', isGenerator: true) as YieldStatement;
    assertNoErrors();
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  Statement _parseAsyncStatement(String code, {bool isGenerator = false}) {
    var star = isGenerator ? '*' : '';
    var localFunction = parseStatement('wrapper() async$star { $code }')
        as FunctionDeclarationStatement;
    var localBody = localFunction.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    return localBody.block.statements.single;
  }
}

@reflectiveTest
class TopLevelParserTest extends ParserTestCase with TopLevelParserTestMixin {}

/// Tests which exercise the parser using a complete compilation unit or
/// compilation unit member.
mixin TopLevelParserTestMixin implements AbstractParserTestCase {
  void test_function_literal_allowed_at_toplevel() {
    parseCompilationUnit("var x = () {};");
  }

  void
      test_function_literal_allowed_in_ArgumentList_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = f(() {}); }");
  }

  void
      test_function_literal_allowed_in_IndexExpression_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = x[() {}]; }");
  }

  void
      test_function_literal_allowed_in_ListLiteral_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = [() {}]; }");
  }

  void
      test_function_literal_allowed_in_MapLiteral_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = {'key': () {}}; }");
  }

  void
      test_function_literal_allowed_in_ParenthesizedExpression_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = (() {}); }");
  }

  void
      test_function_literal_allowed_in_StringInterpolation_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = \"\${(){}}\"; }");
  }

  void test_import_as_show() {
    parseCompilationUnit("import 'dart:math' as M show E;");
  }

  void test_import_show_hide() {
    parseCompilationUnit(
        "import 'import1_lib.dart' show hide, show hide ugly;");
  }

  void test_import_withDocComment() {
    var compilationUnit = parseCompilationUnit('/// Doc\nimport "foo.dart";');
    var importDirective = compilationUnit.directives[0];
    expectCommentText(importDirective.documentationComment, '/// Doc');
  }

  void test_parseClassDeclaration_abstract() {
    createParser('abstract class A {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNotNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_empty() {
    createParser('class A {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    _assertIsDeclarationName(declaration.name);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extends() {
    createParser('class A extends B {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extendsAndImplements() {
    createParser('class A extends B implements C {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extendsAndWith() {
    createParser('class A extends B with C {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.typeParameters, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.withClause, isNotNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseClassDeclaration_extendsAndWithAndImplements() {
    createParser('class A extends B with C implements D {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.typeParameters, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.withClause, isNotNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseClassDeclaration_implements() {
    createParser('class A implements C {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_metadata() {
    createParser('@A @B(2) @C.foo(3) @d.E.bar(4, 5) class X {}');
    var declaration = parseFullCompilationUnitMember() as ClassDeclaration;
    expect(declaration.metadata, hasLength(4));

    {
      var annotation = declaration.metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'A');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNull);
    }

    {
      var annotation = declaration.metadata[1];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'B');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments.arguments, hasLength(1));
    }

    {
      var annotation = declaration.metadata[2];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'C.foo');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments.arguments, hasLength(1));
    }

    {
      var annotation = declaration.metadata[3];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'd.E');
      expect(annotation.period, isNotNull);
      expect(annotation.constructorName, isNotNull);
      expect(annotation.constructorName.name, 'bar');
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments.arguments, hasLength(2));
    }
  }

  void test_parseClassDeclaration_native() {
    createParser('class A native "nativeValue" {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    if (!allowNativeClause) {
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
      ]);
    } else {
      assertNoErrors();
    }
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    NativeClause nativeClause = declaration.nativeClause;
    expect(nativeClause, isNotNull);
    expect(nativeClause.nativeKeyword, isNotNull);
    expect(nativeClause.name.stringValue, "nativeValue");
    expect(nativeClause.beginToken, same(nativeClause.nativeKeyword));
    expect(nativeClause.endToken, same(nativeClause.name.endToken));
  }

  void test_parseClassDeclaration_nonEmpty() {
    createParser('class A {var f;}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_typeAlias_implementsC() {
    createParser('class A = Object with B implements C;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    _assertIsDeclarationName(typeAlias.name);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.implementsClause.implementsKeyword, isNotNull);
    expect(typeAlias.implementsClause.interfaces.length, 1);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeAlias_withB() {
    createParser('class A = Object with B;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.withClause.withKeyword, isNotNull);
    expect(typeAlias.withClause.mixinTypes.length, 1);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeParameters() {
    createParser('class A<B> {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    _assertIsDeclarationName(declaration.name);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNotNull);
    expect(declaration.typeParameters.typeParameters, hasLength(1));
    _assertIsDeclarationName(declaration.typeParameters.typeParameters[0].name);
  }

  void test_parseClassDeclaration_typeParameters_extends_void() {
    parseCompilationUnit('class C<T extends void>{}',
        errors: usingFastaParser
            ? [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 18, 4)]
            : [
                expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 18, 4),
                expectedError(ParserErrorCode.EXPECTED_TOKEN, 18, 4),
                expectedError(ParserErrorCode.MISSING_CLASS_BODY, 18, 4),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 22, 1),
                expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 22, 1),
                expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 22, 1),
              ]);
  }

  void test_parseClassDeclaration_withDocumentationComment() {
    createParser('/// Doc\nclass C {}');
    var classDeclaration = parseFullCompilationUnitMember() as ClassDeclaration;
    expectCommentText(classDeclaration.documentationComment, '/// Doc');
  }

  void test_parseClassTypeAlias_withDocumentationComment() {
    createParser('/// Doc\nclass C = D with E;');
    var classTypeAlias = parseFullCompilationUnitMember() as ClassTypeAlias;
    expectCommentText(classTypeAlias.documentationComment, '/// Doc');
  }

  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    var errorCodes = <ErrorCode>[];
    if (usingFastaParser) {
      // This used to be deferred to later in the pipeline, but is now being
      // reported by the parser.
      errorCodes.add(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE);
    }
    CompilationUnit unit = parseCompilationUnit(
        'abstract<dynamic> _abstract = new abstract.A();',
        codes: errorCodes);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_builtIn_asFunctionName() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        if (lexeme == 'Function') continue;
        parseCompilationUnit('$lexeme(x) => 0;');
        parseCompilationUnit('class C {$lexeme(x) => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_builtIn_asFunctionName_withTypeParameter() {
    if (usingFastaParser) {
      for (Keyword keyword in Keyword.values) {
        if (keyword.isBuiltIn || keyword.isPseudo) {
          String lexeme = keyword.lexeme;
          if (lexeme == 'Function') continue;
          // The fasta type resolution phase will report an error
          // on type arguments on `dynamic` (e.g. `dynamic<int>`).
          parseCompilationUnit('$lexeme<T>(x) => 0;');
          parseCompilationUnit('class C {$lexeme<T>(x) => 0;}');
        }
      }
    }
  }

  void test_parseCompilationUnit_builtIn_asGetter() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseCompilationUnit('get $lexeme => 0;');
        parseCompilationUnit('class C {get $lexeme => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_directives_multiple() {
    createParser("library l;\npart 'a.dart';");
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_directives_single() {
    createParser('library l;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_empty() {
    createParser('');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
    expect(unit.beginToken, isNotNull);
    expect(unit.endToken, isNotNull);
    expect(unit.endToken.type, TokenType.EOF);
  }

  void test_parseCompilationUnit_exportAsPrefix() {
    createParser('export.A _export = new export.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    createParser('export<dynamic> _export = new export.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    if (usingFastaParser) {
      // This used to be deferred to later in the pipeline, but is now being
      // reported by the parser.
      assertErrorsWithCodes([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    } else {
      assertNoErrors();
    }
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    createParser('operator<dynamic> _operator = new operator.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    if (usingFastaParser) {
      // This used to be deferred to later in the pipeline, but is now being
      // reported by the parser.
      assertErrorsWithCodes([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    } else {
      assertNoErrors();
    }
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_pseudo_asTypeName() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseCompilationUnit('$lexeme f;');
        parseCompilationUnit('class C {$lexeme f;}');
        parseCompilationUnit('f($lexeme g) {}');
        parseCompilationUnit('f() {$lexeme g;}');
      }
    }
  }

  void test_parseCompilationUnit_pseudo_prefixed() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseCompilationUnit('M.$lexeme f;');
        parseCompilationUnit('class C {M.$lexeme f;}');
      }
    }
  }

  void test_parseCompilationUnit_script() {
    createParser('#! /bin/dart');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_skipFunctionBody_withInterpolation() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('f() { "\${n}"; }');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_topLevelDeclaration() {
    createParser('class A {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
    expect(unit.beginToken, isNotNull);
    expect(unit.beginToken.keyword, Keyword.CLASS);
    expect(unit.endToken, isNotNull);
    expect(unit.endToken.type, TokenType.EOF);
  }

  void test_parseCompilationUnit_typedefAsPrefix() {
    createParser('typedef.A _typedef = new typedef.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_abstractAsPrefix() {
    createParser('abstract.A _abstract = new abstract.A();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_class() {
    createParser('class A {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    ClassDeclaration declaration = member;
    expect(declaration.name.name, "A");
    expect(declaration.members, hasLength(0));
  }

  void test_parseCompilationUnitMember_classTypeAlias() {
    createParser('abstract class A = B with C;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    ClassTypeAlias declaration = member;
    expect(declaration.name.name, "A");
    expect(declaration.abstractKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_constVariable() {
    createParser('const int x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.keyword.lexeme, 'const');
    _assertIsDeclarationName(declaration.variables.variables[0].name);
  }

  void test_parseCompilationUnitMember_expressionFunctionBody_tokens() {
    createParser('f() => 0;');
    var f = parseFullCompilationUnitMember() as FunctionDeclaration;
    var body = f.functionExpression.body as ExpressionFunctionBody;
    expect(body.functionDefinition.lexeme, '=>');
    expect(body.semicolon.lexeme, ';');
    _assertIsDeclarationName(f.name);
  }

  void test_parseCompilationUnitMember_finalVariable() {
    createParser('final x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.keyword.lexeme, 'final');
  }

  void test_parseCompilationUnitMember_function_external_noType() {
    createParser('external f();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_external_type() {
    createParser('external int f();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_generic_noReturnType() {
    createParser('f<E>() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void
      test_parseCompilationUnitMember_function_generic_noReturnType_annotated() {
    createParser('f<@a E>() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void test_parseCompilationUnitMember_function_generic_returnType() {
    createParser('E f<E>() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNotNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void test_parseCompilationUnitMember_function_generic_void() {
    createParser('void f<T>(T t) {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_gftReturnType() {
    createParser('''
void Function<A>(core.List<core.int> x) f() => null;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_function_noReturnType() {
    createParser('''
Function<A>(core.List<core.int> x) f() => null;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_function_noType() {
    createParser('f() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_type() {
    createParser('int f() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_void() {
    createParser('void f() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_external_noType() {
    createParser('external get p;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
    _assertIsDeclarationName(declaration.name);
  }

  void test_parseCompilationUnitMember_getter_external_type() {
    createParser('external int get p;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_noType() {
    createParser('get p => 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_type() {
    createParser('int get p => 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_noType() {
    createParser('external set p(v);');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_type() {
    createParser('external void set p(int v);');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_noType() {
    createParser('set p(v) {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
    _assertIsDeclarationName(declaration.name);
  }

  void test_parseCompilationUnitMember_setter_type() {
    createParser('void set p(int v) {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_abstract() {
    createParser('abstract class C = S with M;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    _assertIsDeclarationName(typeAlias.name);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNotNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_generic() {
    createParser('class C<E> = S<E> with M<E> implements I<E>;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    expect(typeAlias.typeParameters.typeParameters, hasLength(1));
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_implements() {
    createParser('class C = S with M implements I;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_noImplements() {
    createParser('class C = S with M;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typedef() {
    createParser('typedef F();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, TypeMatcher<FunctionTypeAlias>());
    FunctionTypeAlias typeAlias = member;
    expect(typeAlias.name.name, "F");
    expect(typeAlias.parameters.parameters, hasLength(0));
    _assertIsDeclarationName(typeAlias.name);
  }

  void test_parseCompilationUnitMember_typedef_withDocComment() {
    createParser('/// Doc\ntypedef F();');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expectCommentText(typeAlias.documentationComment, '/// Doc');
  }

  void test_parseCompilationUnitMember_typedVariable() {
    createParser('int x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.type, isNotNull);
    expect(declaration.variables.keyword, isNull);
    _assertIsDeclarationName(declaration.variables.variables[0].name);
  }

  void test_parseCompilationUnitMember_variable() {
    createParser('var x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.keyword.lexeme, 'var');
  }

  void test_parseCompilationUnitMember_variable_gftType_gftReturnType() {
    createParser('''
Function(int) Function(String) v;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    TopLevelVariableDeclaration declaration =
        unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.variables.type, isGenericFunctionType);
  }

  void test_parseCompilationUnitMember_variable_gftType_noReturnType() {
    createParser('''
Function(int, String) v;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_variable_withDocumentationComment() {
    createParser('/// Doc\nvar x = 0;');
    var declaration =
        parseFullCompilationUnitMember() as TopLevelVariableDeclaration;
    expectCommentText(declaration.documentationComment, '/// Doc');
  }

  void test_parseCompilationUnitMember_variableGet() {
    createParser('String get = null;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_variableSet() {
    createParser('String set = null;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseDirective_export() {
    createParser("export 'lib/lib.dart';");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<ExportDirective>());
    ExportDirective exportDirective = directive;
    expect(exportDirective.keyword, isNotNull);
    expect(exportDirective.uri, isNotNull);
    expect(exportDirective.combinators, hasLength(0));
    expect(exportDirective.semicolon, isNotNull);
  }

  void test_parseDirective_export_withDocComment() {
    createParser("/// Doc\nexport 'foo.dart';");
    var directive = parseFullDirective() as ExportDirective;
    expectCommentText(directive.documentationComment, '/// Doc');
  }

  void test_parseDirective_import() {
    createParser("import 'lib/lib.dart';");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<ImportDirective>());
    ImportDirective importDirective = directive;
    expect(importDirective.keyword, isNotNull);
    expect(importDirective.uri, isNotNull);
    expect(importDirective.asKeyword, isNull);
    expect(importDirective.prefix, isNull);
    expect(importDirective.combinators, hasLength(0));
    expect(importDirective.semicolon, isNotNull);
  }

  void test_parseDirective_library() {
    createParser("library l;");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<LibraryDirective>());
    LibraryDirective libraryDirective = directive;
    expect(libraryDirective.libraryKeyword, isNotNull);
    expect(libraryDirective.name, isNotNull);
    expect(libraryDirective.semicolon, isNotNull);
  }

  void test_parseDirective_library_1_component() {
    createParser("library a;");
    var lib = parseFullDirective() as LibraryDirective;
    expect(lib.name.components, hasLength(1));
    expect(lib.name.components[0].name, 'a');
  }

  void test_parseDirective_library_2_components() {
    createParser("library a.b;");
    var lib = parseFullDirective() as LibraryDirective;
    expect(lib.name.components, hasLength(2));
    expect(lib.name.components[0].name, 'a');
    expect(lib.name.components[1].name, 'b');
  }

  void test_parseDirective_library_3_components() {
    createParser("library a.b.c;");
    var lib = parseFullDirective() as LibraryDirective;
    expect(lib.name.components, hasLength(3));
    expect(lib.name.components[0].name, 'a');
    expect(lib.name.components[1].name, 'b');
    expect(lib.name.components[2].name, 'c');
  }

  void test_parseDirective_library_annotation() {
    createParser("@A library l;");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<LibraryDirective>());
    LibraryDirective libraryDirective = directive;
    expect(libraryDirective.libraryKeyword, isNotNull);
    expect(libraryDirective.name, isNotNull);
    expect(libraryDirective.semicolon, isNotNull);
    expect(libraryDirective.metadata, hasLength(1));
    expect(libraryDirective.metadata[0].name.name, 'A');
  }

  void test_parseDirective_library_annotation2() {
    createParser("@A library l;");
    CompilationUnit unit = parser.parseCompilationUnit2();
    Directive directive = unit.directives[0];
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<LibraryDirective>());
    LibraryDirective libraryDirective = directive;
    expect(libraryDirective.libraryKeyword, isNotNull);
    expect(libraryDirective.name, isNotNull);
    expect(libraryDirective.semicolon, isNotNull);
    expect(libraryDirective.metadata, hasLength(1));
    expect(libraryDirective.metadata[0].name.name, 'A');
  }

  void test_parseDirective_library_withDocumentationComment() {
    createParser('/// Doc\nlibrary l;');
    var directive = parseFullDirective() as LibraryDirective;
    expectCommentText(directive.documentationComment, '/// Doc');
  }

  void test_parseDirective_part() {
    createParser("part 'lib/lib.dart';");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<PartDirective>());
    PartDirective partDirective = directive;
    expect(partDirective.partKeyword, isNotNull);
    expect(partDirective.uri, isNotNull);
    expect(partDirective.semicolon, isNotNull);
  }

  void test_parseDirective_part_of_1_component() {
    createParser("part of a;");
    var partOf = parseFullDirective() as PartOfDirective;
    expect(partOf.libraryName.components, hasLength(1));
    expect(partOf.libraryName.components[0].name, 'a');
  }

  void test_parseDirective_part_of_2_components() {
    createParser("part of a.b;");
    var partOf = parseFullDirective() as PartOfDirective;
    expect(partOf.libraryName.components, hasLength(2));
    expect(partOf.libraryName.components[0].name, 'a');
    expect(partOf.libraryName.components[1].name, 'b');
  }

  void test_parseDirective_part_of_3_components() {
    createParser("part of a.b.c;");
    var partOf = parseFullDirective() as PartOfDirective;
    expect(partOf.libraryName.components, hasLength(3));
    expect(partOf.libraryName.components[0].name, 'a');
    expect(partOf.libraryName.components[1].name, 'b');
    expect(partOf.libraryName.components[2].name, 'c');
  }

  void test_parseDirective_part_of_withDocumentationComment() {
    createParser('/// Doc\npart of a;');
    var partOf = parseFullDirective() as PartOfDirective;
    expectCommentText(partOf.documentationComment, '/// Doc');
  }

  void test_parseDirective_part_withDocumentationComment() {
    createParser("/// Doc\npart 'lib.dart';");
    var directive = parseFullDirective() as PartDirective;
    expectCommentText(directive.documentationComment, '/// Doc');
  }

  void test_parseDirective_partOf() {
    createParser("part of l;");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<PartOfDirective>());
    PartOfDirective partOfDirective = directive;
    expect(partOfDirective.partKeyword, isNotNull);
    expect(partOfDirective.ofKeyword, isNotNull);
    expect(partOfDirective.libraryName, isNotNull);
    expect(partOfDirective.semicolon, isNotNull);
  }

  void test_parseDirectives_annotations() {
    CompilationUnit unit =
        parseDirectives("@A library l; @B import 'foo.dart';");
    expect(unit.directives, hasLength(2));
    expect(unit.directives[0].metadata[0].name.name, 'A');
    expect(unit.directives[1].metadata[0].name.name, 'B');
  }

  void test_parseDirectives_complete() {
    CompilationUnit unit =
        parseDirectives("#! /bin/dart\nlibrary l;\nclass A {}");
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_empty() {
    CompilationUnit unit = parseDirectives("");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_mixed() {
    CompilationUnit unit =
        parseDirectives("library l; class A {} part 'foo.dart';");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_multiple() {
    CompilationUnit unit = parseDirectives("library l;\npart 'a.dart';");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
  }

  void test_parseDirectives_script() {
    CompilationUnit unit = parseDirectives("#! /bin/dart");
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_single() {
    CompilationUnit unit = parseDirectives("library l;");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_topLevelDeclaration() {
    CompilationUnit unit = parseDirectives("class A {}");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseEnumDeclaration_one() {
    createParser("enum E {ONE}");
    EnumDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_trailingComma() {
    createParser("enum E {ONE,}");
    EnumDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_two() {
    createParser("enum E {ONE, TWO}");
    EnumDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(2));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_withDocComment_onEnum() {
    createParser('/// Doc\nenum E {ONE}');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expectCommentText(declaration.documentationComment, '/// Doc');
  }

  void test_parseEnumDeclaration_withDocComment_onValue() {
    createParser('''
enum E {
  /// Doc
  ONE
}''');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    var value = declaration.constants[0];
    expectCommentText(value.documentationComment, '/// Doc');
  }

  void test_parseEnumDeclaration_withDocComment_onValue_annotated() {
    createParser('''
enum E {
  /// Doc
  @annotation
  ONE
}
''');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    var value = declaration.constants[0];
    expectCommentText(value.documentationComment, '/// Doc');
    expect(value.metadata, hasLength(1));
  }

  void test_parseExportDirective_configuration_multiple() {
    createParser("export 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';");
    ExportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(2));
    expectDottedName(directive.configurations[0].name, ['a']);
    expectDottedName(directive.configurations[1].name, ['c']);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_configuration_single() {
    createParser("export 'lib/lib.dart' if (a.b == 'c.dart') '';");
    ExportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(1));
    expectDottedName(directive.configurations[0].name, ['a', 'b']);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_hide() {
    createParser("export 'lib/lib.dart' hide A, B;");
    ExportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_hide_show() {
    createParser("export 'lib/lib.dart' hide A show B;");
    ExportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_noCombinator() {
    createParser("export 'lib/lib.dart';");
    ExportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show() {
    createParser("export 'lib/lib.dart' show A, B;");
    ExportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show_hide() {
    createParser("export 'lib/lib.dart' show B hide A;");
    ExportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseFunctionDeclaration_function() {
    createParser('/// Doc\nT f() {}');
    FunctionDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as TypeName).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_functionWithTypeParameters() {
    createParser('/// Doc\nT f<E>() {}');
    FunctionDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as TypeName).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_getter() {
    createParser('/// Doc\nT get p => 0;');
    FunctionDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as TypeName).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseFunctionDeclaration_metadata() {
    createParser(
        'T f(@A a, @B(2) Foo b, {@C.foo(3) c : 0, @d.E.bar(4, 5) x:0}) {}');
    FunctionDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect((declaration.returnType as TypeName).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    NodeList<FormalParameter> parameters = expression.parameters.parameters;
    expect(parameters, hasLength(4));
    expect(declaration.propertyKeyword, isNull);

    {
      var annotation = parameters[0].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'A');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNull);
    }

    {
      var annotation = parameters[1].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'B');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments.arguments, hasLength(1));
    }

    {
      var annotation = parameters[2].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'C.foo');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments.arguments, hasLength(1));
    }

    {
      var annotation = parameters[3].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'd.E');
      expect(annotation.period, isNotNull);
      expect(annotation.constructorName, isNotNull);
      expect(annotation.constructorName.name, 'bar');
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments.arguments, hasLength(2));
    }
  }

  void test_parseFunctionDeclaration_setter() {
    createParser('/// Doc\nT set p(v) {}');
    FunctionDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as TypeName).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseGenericTypeAlias_noTypeParameters() {
    createParser('typedef F = int Function(int);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters, isNull);
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters() {
    createParser('typedef F<T> = T Function(T);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters2() {
    // The scanner creates a single token for `>=`
    // then the parser must split it into two separate tokens.
    createParser('typedef F<T>= T Function(T);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters3() {
    createParser('typedef F<A,B,C> = Function(A a, B b, C c);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters3_gtEq() {
    // The scanner creates a single token for `>=`
    // then the parser must split it into two separate tokens.
    createParser('typedef F<A,B,C>=Function(A a, B b, C c);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends() {
    createParser('typedef F<A,B,C extends D<E>> = Function(A a, B b, C c);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters.typeParameters[2];
    NamedType type = typeParam.bound;
    expect(type.typeArguments.arguments, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends3() {
    createParser(
        'typedef F<A,B,C extends D<E,G,H>> = Function(A a, B b, C c);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters.typeParameters[2];
    NamedType type = typeParam.bound;
    expect(type.typeArguments.arguments, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends3_gtGtEq() {
    // The scanner creates a single token for `>>=`
    // then the parser must split it into three separate tokens.
    createParser('typedef F<A,B,C extends D<E,G,H>>=Function(A a, B b, C c);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters.typeParameters[2];
    NamedType type = typeParam.bound;
    expect(type.typeArguments.arguments, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends_gtGtEq() {
    // The scanner creates a single token for `>>=`
    // then the parser must split it into three separate tokens.
    createParser('typedef F<A,B,C extends D<E>>=Function(A a, B b, C c);');
    GenericTypeAlias alias = parseFullCompilationUnitMember();
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.name, 'F');
    expect(alias.typeParameters.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters.typeParameters[2];
    NamedType type = typeParam.bound;
    expect(type.typeArguments.arguments, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseImportDirective_configuration_multiple() {
    createParser("import 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(2));
    expectDottedName(directive.configurations[0].name, ['a']);
    expectDottedName(directive.configurations[1].name, ['c']);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_configuration_single() {
    createParser("import 'lib/lib.dart' if (a.b == 'c.dart') '';");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(1));
    expectDottedName(directive.configurations[0].name, ['a', 'b']);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_deferred() {
    createParser("import 'lib/lib.dart' deferred as a;");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNotNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_hide() {
    createParser("import 'lib/lib.dart' hide A, B;");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_noCombinator() {
    createParser("import 'lib/lib.dart';");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix() {
    createParser("import 'lib/lib.dart' as a;");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_hide_show() {
    createParser("import 'lib/lib.dart' as a hide A show B;");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_show_hide() {
    createParser("import 'lib/lib.dart' as a show B hide A;");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_show() {
    createParser("import 'lib/lib.dart' show A, B;");
    ImportDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseLibraryDirective() {
    createParser('library l;');
    LibraryDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.libraryKeyword, isNotNull);
    expect(directive.name, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartDirective() {
    createParser("part 'lib/lib.dart';");
    PartDirective directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.partKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartOfDirective_name() {
    enableUriInPartOf = true;
    createParser("part of l;");
    PartOfDirective directive = parseFullDirective();
    expect(directive.partKeyword, isNotNull);
    expect(directive.ofKeyword, isNotNull);
    expect(directive.libraryName, isNotNull);
    expect(directive.uri, isNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartOfDirective_uri() {
    enableUriInPartOf = true;
    createParser("part of 'lib.dart';");
    PartOfDirective directive = parseFullDirective();
    expect(directive.partKeyword, isNotNull);
    expect(directive.ofKeyword, isNotNull);
    expect(directive.libraryName, isNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseTypeAlias_function_noParameters() {
    createParser('typedef bool F();');
    FunctionTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_noReturnType() {
    createParser('typedef F();');
    FunctionTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameterizedReturnType() {
    createParser('typedef A<B> F();');
    FunctionTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameters() {
    createParser('typedef bool F(Object value);');
    FunctionTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_typeParameters() {
    createParser('typedef bool F<E>();');
    FunctionTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_function_voidReturnType() {
    createParser('typedef void F();');
    FunctionTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_noParameters() {
    createParser('typedef F = bool Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_noReturnType() {
    createParser('typedef F = Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_parameterizedReturnType() {
    createParser('typedef F = A<B> Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_parameters() {
    createParser('typedef F = bool Function(Object value);');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters() {
    createParser('typedef F = bool Function<E>();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_noParameters() {
    createParser('typedef F<T> = bool Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_noReturnType() {
    createParser('typedef F<T> = Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNull);
    expect(functionType.typeParameters, isNull);
  }

  void
      test_parseTypeAlias_genericFunction_typeParameters_parameterizedReturnType() {
    createParser('typedef F<T> = A<B> Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_parameters() {
    createParser('typedef F<T> = bool Function(Object value);');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_typeParameters() {
    createParser('typedef F<T> = bool Function<E>();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_voidReturnType() {
    createParser('typedef F<T> = void Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_voidReturnType() {
    createParser('typedef F = void Function();');
    GenericTypeAlias typeAlias = parseFullCompilationUnitMember();
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    GenericFunctionType functionType = typeAlias.functionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_withDocComment() {
    createParser('/// Doc\ntypedef F = bool Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expectCommentText(typeAlias.documentationComment, '/// Doc');
  }

  void test_parseTypeVariable_withDocumentationComment() {
    createParser('''
class A<
    /// Doc
    B> {}
''');
    var classDeclaration = parseFullCompilationUnitMember() as ClassDeclaration;
    var typeVariable = classDeclaration.typeParameters.typeParameters[0];
    expectCommentText(typeVariable.documentationComment, '/// Doc');
  }

  /// Assert that the given [name] is in declaration context.
  void _assertIsDeclarationName(SimpleIdentifier name) {
    expect(name.inDeclarationContext(), isTrue);
  }
}
