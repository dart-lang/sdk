// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:analyzer/src/fasta/element_store.dart';
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:front_end/src/fasta/fasta_codes.dart' show Message;
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_library_builder.dart';
import 'package:front_end/src/fasta/parser/identifier_context.dart'
    show IdentifierContext;
import 'package:front_end/src/fasta/parser/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_fasta_listener.dart';
import 'parser_test.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest_Fasta);
    defineReflectiveTests(ComplexParserTest_Fasta);
    defineReflectiveTests(ExpressionParserTest_Fasta);
    defineReflectiveTests(FormalParameterParserTest_Fasta);
    defineReflectiveTests(StatementParserTest_Fasta);
    defineReflectiveTests(TopLevelParserTest_Fasta);
  });
}

/**
 * Type of the "parse..." methods defined in the Fasta parser.
 */
typedef analyzer.Token ParseFunction(analyzer.Token token);

/**
 * Proxy implementation of [Builder] used by Fasta parser tests.
 *
 * All undeclared identifiers are presumed to resolve via an instance of this
 * class.
 */
class BuilderProxy implements Builder {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@reflectiveTest
class ClassMemberParserTest_Fasta extends FastaParserTestCase
    with ClassMemberParserTestMixin {
  @override
  @failingTest
  void test_parseConstructor_assert() {
    // TODO(paulberry): Fasta doesn't support asserts in initializers
    super.test_parseConstructor_assert();
  }
}

/**
 * Tests of the fasta parser based on [ComplexParserTestMixin].
 */
@reflectiveTest
class ComplexParserTest_Fasta extends FastaParserTestCase
    with ComplexParserTestMixin {
  @override
  @failingTest
  void test_assignableExpression_arguments_normal_chain_typeArgumentComments() {
    // TODO(paulberry,ahe): Fasta doesn't support generic method comment syntax.
    super
        .test_assignableExpression_arguments_normal_chain_typeArgumentComments();
  }

  @override
  @failingTest
  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // endTypeArguments().
    super.test_assignableExpression_arguments_normal_chain_typeArguments();
  }

  @override
  @failingTest
  void test_conditionalExpression_precedence_nullableType_as() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_conditionalExpression_precedence_nullableType_as();
  }

  @override
  @failingTest
  void test_conditionalExpression_precedence_nullableType_is() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_conditionalExpression_precedence_nullableType_is();
  }

  @override
  @failingTest
  void test_equalityExpression_normal() {
    // TODO(scheglov) error checking is not implemented
    super.test_equalityExpression_normal();
  }

  @override
  @failingTest
  void test_equalityExpression_super() {
    // TODO(scheglov) error checking is not implemented
    super.test_equalityExpression_super();
  }

  @override
  @failingTest
  void test_logicalAndExpression_precedence_nullableType() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_logicalAndExpression_precedence_nullableType();
  }

  @override
  @failingTest
  void test_logicalOrExpression_precedence_nullableType() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_logicalOrExpression_precedence_nullableType();
  }
}

/**
 * Proxy implementation of [KernelClassElement] used by Fasta parser tests.
 *
 * All undeclared identifiers are presumed to resolve to an instance of this
 * class.
 */
class ElementProxy implements KernelClassElement {
  @override
  final KernelInterfaceType rawType = new InterfaceTypeProxy();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Proxy implementation of [KernelClassElement] used by Fasta parser tests.
 *
 * Any request for an element is satisfied by creating an instance of
 * [ElementProxy].
 */
class ElementStoreProxy implements ElementStore {
  final _elements = <Builder, Element>{};

  @override
  Element operator [](Builder builder) =>
      _elements.putIfAbsent(builder, () => new ElementProxy());

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ExpressionParserTest_Fasta extends FastaParserTestCase
    with ExpressionParserTestMixin {
  @override
  @failingTest
  void
      test_parseAssignableExpression_expression_args_dot_typeArgumentComments() {
    super
        .test_parseAssignableExpression_expression_args_dot_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseAssignableExpression_expression_args_dot_typeArguments() {
    super.test_parseAssignableExpression_expression_args_dot_typeArguments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_ia_typeArgumentComments() {
    super.test_parseCascadeSection_ia_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_ia_typeArguments() {
    super.test_parseCascadeSection_ia_typeArguments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paa_typeArgumentComments() {
    super.test_parseCascadeSection_paa_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paa_typeArguments() {
    super.test_parseCascadeSection_paa_typeArguments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paapaa_typeArgumentComments() {
    super.test_parseCascadeSection_paapaa_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paapaa_typeArguments() {
    super.test_parseCascadeSection_paapaa_typeArguments();
  }

  @override
  @failingTest
  void test_parseExpression_assign_compound() {
    super.test_parseExpression_assign_compound();
  }

  @override
  @failingTest
  void test_parseInstanceCreationExpression_type_named_typeArgumentComments() {
    super
        .test_parseInstanceCreationExpression_type_named_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseInstanceCreationExpression_type_typeArguments_nullable() {
    super.test_parseInstanceCreationExpression_type_typeArguments_nullable();
  }

  @override
  void test_parseListLiteral_empty_oneToken_withComment() {
    super.test_parseListLiteral_empty_oneToken_withComment();
  }

  @override
  @failingTest
  void test_parsePrimaryExpression_super() {
    super.test_parsePrimaryExpression_super();
  }

  @override
  @failingTest
  void test_parseRelationalExpression_as_nullable() {
    super.test_parseRelationalExpression_as_nullable();
  }

  @override
  @failingTest
  void test_parseRelationalExpression_is_nullable() {
    super.test_parseRelationalExpression_is_nullable();
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super() {
    super.test_parseUnaryExpression_decrement_super();
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super_withComment() {
    super.test_parseUnaryExpression_decrement_super_withComment();
  }
}

/**
 * Implementation of [AbstractParserTestCase] specialized for testing the
 * Fasta parser.
 */
class FastaParserTestCase extends Object
    with ParserTestHelpers
    implements AbstractParserTestCase {
  ParserProxy _parserProxy;
  analyzer.Token _fastaTokens;

  /**
   * Whether generic method comments should be enabled for the test.
   */
  bool enableGenericMethodComments = false;

  @override
  set enableAssertInitializer(bool value) {
    if (value == true) {
      // TODO(paulberry,ahe): it looks like asserts in initializer lists are not
      // supported by Fasta.
      throw new UnimplementedError();
    }
  }

  @override
  set enableLazyAssignmentOperators(bool value) {
    // TODO: implement enableLazyAssignmentOperators
    if (value == true) {
      throw new UnimplementedError();
    }
  }

  @override
  set enableNnbd(bool value) {
    if (value == true) {
      // TODO(paulberry,ahe): non-null-by-default syntax is not supported by
      // Fasta.
      throw new UnimplementedError();
    }
  }

  @override
  set enableUriInPartOf(bool value) {
    if (value == true) {
      // TODO(paulberry,ahe): URIs in "part of" declarations are not supported
      // by Fasta.
      throw new UnimplementedError();
    }
  }

  @override
  analyzer.Parser get parser => _parserProxy;

  @override
  bool get usingFasta => true;

  @override
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    // TODO(scheglov): implement assertErrorsWithCodes
    fail('Not implemented');
  }

  @override
  void assertNoErrors() {
    // TODO(paulberry): implement assertNoErrors
  }

  @override
  void createParser(String content) {
    var scanner = new StringScanner(content, includeComments: true);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    _fastaTokens = scanner.tokenize();
    _parserProxy = new ParserProxy(_fastaTokens,
        enableGenericMethodComments: enableGenericMethodComments);
  }

  @override
  Expression parseAdditiveExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    return _parseExpression(code);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional: true}) {
    if (optional) {
      if (code.isEmpty) {
        return _parseExpression('foo');
      }
      return _parseExpression('(foo)$code');
    }
    return _parseExpression('foo$code');
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    var function = _parseExpression('() async => $code') as FunctionExpression;
    return (function.body as ExpressionFunctionBody).expression;
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseCascadeSection(String code) {
    var cascadeExpression = _parseExpression('null$code') as CascadeExpression;
    return cascadeExpression.cascadeSections.first;
  }

  @override
  CompilationUnit parseCompilationUnit(String content,
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) {
    // Scan tokens
    var source = new StringSource(content, 'parser_test_StringSource.dart');
    GatheringErrorListener listener = new GatheringErrorListener();
    var scanner = new Scanner.fasta(source, listener);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    _fastaTokens = scanner.tokenize();

    // Run parser
    analyzer.Parser parser =
        new analyzer.Parser(source, listener, useFasta: true);
    CompilationUnit unit = parser.parseCompilationUnit(_fastaTokens);

    // Assert and return result
    listener.assertErrorsWithCodes(expectedErrorCodes);
    expect(unit, isNotNull);
    return unit;
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseConstExpression(String code) {
    return _parseExpression(code);
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    String source = 'class __Test { __Test() : $code; }';
    var unit =
        _runParser(source, (parser) => parser.parseUnit) as CompilationUnit;
    var clazz = unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    return constructor.initializers.single;
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return _runParser(source, (parser) => parser.parseUnit, errorCodes);
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseExpression(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return _runParser(source, (parser) => parser.parseExpression, errorCodes)
        as Expression;
  }

  @override
  List<Expression> parseExpressionList(String code) {
    return (_parseExpression('[$code]') as ListLiteral).elements.toList();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
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
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    return _runParser(
        code,
        (parser) => (analyzer.Token token) {
              return parser.parseFormalParameters(
                  token,
                  inFunctionType
                      ? fasta.MemberKind.GeneralizedFunctionType
                      : fasta.MemberKind.NonStaticMethod);
            },
        errorCodes) as FormalParameterList;
  }

  @override
  CompilationUnitMember parseFullCompilationUnitMember() {
    return _parserProxy._run((parser) => parser.parseTopLevelDeclaration);
  }

  @override
  Directive parseFullDirective() {
    return _parserProxy._run((parser) => parser.parseTopLevelDeclaration);
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    return _parseExpression(code);
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, analyzer.Token newToken) {
    return _parseExpression('$newToken $code');
  }

  @override
  ListLiteral parseListLiteral(
      analyzer.Token token, String typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return _parseExpression(sc);
  }

  @override
  TypedLiteral parseListOrMapLiteral(analyzer.Token modifier, String code) {
    String literalCode = modifier != null ? '$modifier $code' : code;
    return parsePrimaryExpression(literalCode) as TypedLiteral;
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  MapLiteral parseMapLiteral(
      analyzer.Token token, String typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return parsePrimaryExpression(sc) as MapLiteral;
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    var mapLiteral = parseMapLiteral(null, null, '{ $code }');
    return mapLiteral.entries.single;
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    return _parseExpression(code);
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    return _parseExpression(code);
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    FormalParameterList list = parseFormalParameterList('($code)',
        inFunctionType: inFunctionType, errorCodes: errorCodes);
    return list.parameters.single;
  }

  @override
  Expression parsePostfixExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parsePrimaryExpression(String code) {
    return _runParser(
        code,
        (parser) =>
            (token) => parser.parsePrimary(token, IdentifierContext.expression),
        const <ErrorCode>[]) as Expression;
  }

  @override
  Expression parseRelationalExpression(String code) {
    return _parseExpression(code);
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    return _parseExpression(code);
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    return _parseExpression(code);
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    return _parseExpression(code);
  }

  @override
  Statement parseStatement(String source,
      [bool enableLazyAssignmentOperators]) {
    return _runParser(source, (parser) => parser.parseStatement) as Statement;
  }

  @override
  Expression parseStringLiteral(String code) {
    return _parseExpression(code);
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseThrowExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    return _parseExpression(code);
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String code) {
    var statement = parseStatement('$code;') as VariableDeclarationStatement;
    return statement.variables;
  }

  Expression _parseExpression(String code) {
    var statement = parseStatement('$code;') as ExpressionStatement;
    return statement.expression;
  }

  Object _runParser(
      String source, ParseFunction getParseFunction(fasta.Parser parser),
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    if (errorCodes.isNotEmpty) {
      // TODO(paulberry): Check that the parser generates the proper errors.
      throw new UnimplementedError();
    }
    createParser(source);
    return _parserProxy._run(getParseFunction);
  }
}

/**
 * Tests of the fasta parser based on [FormalParameterParserTestMixin].
 */
@reflectiveTest
class FormalParameterParserTest_Fasta extends FastaParserTestCase
    with FormalParameterParserTestMixin {
  @override
  @failingTest
  void test_parseFormalParameterList_prefixedType_partial() {
    // TODO(scheglov): Unimplemented: errors
    super.test_parseFormalParameterList_prefixedType_partial();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_prefixedType_partial2() {
    // TODO(scheglov): Unimplemented: errors
    super.test_parseFormalParameterList_prefixedType_partial2();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_field_const_noType() {
    super.test_parseNormalFormalParameter_field_const_noType();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_field_const_type() {
    super.test_parseNormalFormalParameter_field_const_type();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_noType_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_noType_nullable();
  }

  @override
  @failingTest
  void
      test_parseNormalFormalParameter_function_noType_typeParameters_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super
        .test_parseNormalFormalParameter_function_noType_typeParameters_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_type_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_type_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_type_typeParameters_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super
        .test_parseNormalFormalParameter_function_type_typeParameters_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_void_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_void_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_void_typeParameters_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super
        .test_parseNormalFormalParameter_function_void_typeParameters_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_simple_const_noType() {
    super.test_parseNormalFormalParameter_simple_const_noType();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_simple_const_type() {
    super.test_parseNormalFormalParameter_simple_const_type();
  }
}

/**
 * Proxy implementation of [KernelClassElement] used by Fasta parser tests.
 *
 * Any element used as a type name is presumed to refer to an instance of this
 * class.
 */
class InterfaceTypeProxy implements KernelInterfaceType {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Proxy implementation of [KernelLibraryBuilderProxy] used by Fasta parser
 * tests.
 */
class KernelLibraryBuilderProxy implements KernelLibraryBuilder {
  @override
  final uri = Uri.parse('file:///test.dart');

  @override
  Uri get fileUri => uri;

  @override
  void addCompileTimeError(Message message, int charOffset, Uri uri,
      {bool silent: false, bool wasHandled: false}) {
    fail('${message.message}');
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Proxy implementation of the analyzer parser, implemented in terms of the
 * Fasta parser.
 *
 * This allows many of the analyzer parser tests to be run on Fasta, even if
 * they call into the analyzer parser class directly.
 */
class ParserProxy implements analyzer.Parser {
  /**
   * The token to parse next.
   */
  analyzer.Token _currentFastaToken;

  /**
   * The fasta parser being wrapped.
   */
  final fasta.Parser _fastaParser;

  /**
   * The builder which creates the analyzer AST data structures expected by the
   * analyzer parser tests.
   */
  final AstBuilder _astBuilder;

  /**
   * Creates a [ParserProxy] which is prepared to begin parsing at the given
   * Fasta token.
   */
  factory ParserProxy(analyzer.Token startingToken,
      {bool enableGenericMethodComments: false}) {
    var library = new KernelLibraryBuilderProxy();
    var member = new BuilderProxy();
    var elementStore = new ElementStoreProxy();
    var scope = new ScopeProxy();
    var astBuilder =
        new AstBuilder(null, library, member, elementStore, scope, true);
    astBuilder.parseGenericMethodComments = enableGenericMethodComments;
    var fastaParser = new fasta.Parser(new ForwardingTestListener(astBuilder));
    astBuilder.parser = fastaParser;
    return new ParserProxy._(startingToken, fastaParser, astBuilder);
  }

  ParserProxy._(this._currentFastaToken, this._fastaParser, this._astBuilder);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  ClassMember parseClassMember(String className) {
    _astBuilder.className = className;
    var result = _run((parser) => parser.parseMember) as ClassMember;
    _astBuilder.className = null;
    return result;
  }

  @override
  CompilationUnit parseCompilationUnit2() {
    return _run((parser) => parser.parseUnit) as CompilationUnit;
  }

  /**
   * Runs a single parser function, and returns the result as an analyzer AST.
   */
  Object _run(ParseFunction getParseFunction(fasta.Parser parser)) {
    var parseFunction = getParseFunction(_fastaParser);
    _currentFastaToken = parseFunction(_currentFastaToken);
    expect(_currentFastaToken.isEof, isTrue);
    expect(_astBuilder.stack, hasLength(1));
    return _astBuilder.pop();
  }
}

/**
 * Proxy implementation of [Scope] used by Fasta parser tests.
 *
 * Any name lookup request is satisfied by creating an instance of
 * [BuilderProxy].
 */
class ScopeProxy implements Scope {
  final _locals = <String, Builder>{};

  @override
  Scope createNestedScope({bool isModifiable: true}) {
    return new Scope.nested(this, isModifiable: isModifiable);
  }

  @override
  declare(String name, Builder builder, int charOffset, Uri fileUri) {
    _locals[name] = builder;
    return null;
  }

  @override
  Builder lookup(String name, int charOffset, Uri fileUri,
          {bool isInstanceScope: true}) =>
      _locals.putIfAbsent(name, () => new BuilderProxy());

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Tests of the fasta parser based on [StatementParserTestMixin].
 */
@reflectiveTest
class StatementParserTest_Fasta extends FastaParserTestCase
    with StatementParserTestMixin {
  @override
  @failingTest
  void test_parseAssertStatement_trailingComma_message() {
    super.test_parseAssertStatement_trailingComma_message();
  }

  @override
  @failingTest
  void test_parseAssertStatement_trailingComma_noMessage() {
    super.test_parseAssertStatement_trailingComma_noMessage();
  }

  @override
  @failingTest
  void test_parseBreakStatement_noLabel() {
    super.test_parseBreakStatement_noLabel();
  }

  @override
  @failingTest
  void test_parseContinueStatement_label() {
    super.test_parseContinueStatement_label();
  }

  @override
  @failingTest
  void test_parseContinueStatement_noLabel() {
    super.test_parseContinueStatement_noLabel();
  }

  @override
  @failingTest
  void test_parseStatement_emptyTypeArgumentList() {
    super.test_parseStatement_emptyTypeArgumentList();
  }

  @override
  @failingTest
  void test_parseTryStatement_catch_finally() {
    super.test_parseTryStatement_catch_finally();
  }

  @override
  @failingTest
  void test_parseTryStatement_on_catch() {
    super.test_parseTryStatement_on_catch();
  }

  @override
  @failingTest
  void test_parseTryStatement_on_catch_finally() {
    super.test_parseTryStatement_on_catch_finally();
  }
}

/**
 * Tests of the fasta parser based on [TopLevelParserTestMixin].
 */
@reflectiveTest
class TopLevelParserTest_Fasta extends FastaParserTestCase
    with TopLevelParserTestMixin {
  @override
  @failingTest
  void test_parseClassDeclaration_native() {
    // TODO(paulberry): TODO(paulberry,ahe): Fasta parser doesn't appear to support "native" syntax yet.
    super.test_parseClassDeclaration_native();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_builtIn_asFunctionName() {
    // TODO(paulberry,ahe): Fasta's parser is confused when one of the built-in
    // identifiers `export`, `import`, `library`, `part`, or `typedef` appears
    // as the name of a top level function with an implicit return type.
    super.test_parseCompilationUnit_builtIn_asFunctionName();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_exportAsPrefix() {
    // TODO(paulberry): As of commit 5de9108 this syntax is invalid.
    super.test_parseCompilationUnit_exportAsPrefix();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    // TODO(paulberry): As of commit 5de9108 this syntax is invalid.
    super.test_parseCompilationUnit_exportAsPrefix_parameterized();
  }

  @override
  @failingTest
  void test_parseDirectives_mixed() {
    // TODO(paulberry,ahe): This test verifies the analyzer parser's ability to
    // stop parsing as soon as the first non-directive is encountered; this is
    // useful for quickly traversing an import graph.  Consider adding a similar
    // ability to Fasta's parser.
    super.test_parseDirectives_mixed();
  }

  @override
  @failingTest
  void test_parsePartOfDirective_name() {
    // TODO(paulberry,ahe): Thes test verifies that even if URIs in "part of"
    // declarations are enabled, a construct of the form "part of identifier;"
    // is still properly handled.  URIs in "part of" declarations are not
    // supported by Fasta yet.
    super.test_parsePartOfDirective_name();
  }

  @override
  @failingTest
  void test_parsePartOfDirective_uri() {
    // TODO(paulberry,ahe): URIs in "part of" declarations are not supported by
    // Fasta.
    super.test_parsePartOfDirective_uri();
  }
}
