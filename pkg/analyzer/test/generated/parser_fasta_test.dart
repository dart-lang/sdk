// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:front_end/src/fasta/analyzer/ast_builder.dart';
import 'package:front_end/src/fasta/analyzer/element_store.dart';
import 'package:front_end/src/fasta/builder/scope.dart';
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_library_builder.dart';
import 'package:front_end/src/fasta/parser/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComplexParserTest_Fasta);
    defineReflectiveTests(TopLevelParserTest_Fasta);
  });
}

/**
 * Type of the "parse..." methods defined in the Fasta parser.
 */
typedef fasta.Token ParseFunction(fasta.Token token);

/**
 * Proxy implementation of [Builder] used by Fasta parser tests.
 *
 * All undeclared identifiers are presumed to resolve via an instance of this
 * class.
 */
class BuilderProxy implements Builder {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Tests of the fasta parser based on [ComplexParserTestMixin].
 */
@reflectiveTest
class ComplexParserTest_Fasta extends FastaParserTestCase
    with ComplexParserTestMixin {
  @override
  @failingTest
  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_additiveExpression_precedence_multiplicative_left_withSuper();
  }

  @override
  @failingTest
  void test_additiveExpression_super() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_additiveExpression_super();
  }

  @override
  @failingTest
  void test_assignableExpression_arguments_normal_chain() {
    // TODO(paulberry,ahe): AstBuilder.doInvocation doesn't handle receiver
    // other than SimpleIdentifier.
    super.test_assignableExpression_arguments_normal_chain();
  }

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
  void test_assignmentExpression_prefixedIdentifier() {
    // TODO(paulberry,ahe): Analyzer expects "x.y" to be parsed as a
    // PrefixedIdentifier, even if x is not a prefix.
    super.test_assignmentExpression_prefixedIdentifier();
  }

  @override
  @failingTest
  void test_assignmentExpression_propertyAccess() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_assignmentExpression_propertyAccess();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_super() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_bitwiseAndExpression_super();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_super() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_bitwiseOrExpression_super();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_super() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_bitwiseXorExpression_super();
  }

  @override
  @failingTest
  void test_cascade_withAssignment() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // endConstructorReference().
    super.test_cascade_withAssignment();
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
  void test_constructor_initializer_withParenthesizedExpression() {
    // TODO(paulberry): Implement parseCompilationUnitWithOptions
    super.test_constructor_initializer_withParenthesizedExpression();
  }

  @override
  @failingTest
  void test_equalityExpression_normal() {
    // TODO(paulberry,ahe): bad error recovery
    super.test_equalityExpression_normal();
  }

  @override
  @failingTest
  void test_equalityExpression_super() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
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

  @override
  @failingTest
  void test_multipleLabels_statement() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement handleLabel().
    super.test_multipleLabels_statement();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_super() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_multiplicativeExpression_super();
  }

  @override
  @failingTest
  void test_shiftExpression_super() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // handleSuperExpression().
    super.test_shiftExpression_super();
  }

  @override
  @failingTest
  void test_topLevelFunction_nestedGenericFunction() {
    // TODO(paulberry): Implement parseCompilationUnitWithOptions
    super.test_topLevelFunction_nestedGenericFunction();
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
 * Implementation of [AbstractParserTestCase] specialized for testing the
 * Fasta parser.
 */
class FastaParserTestCase extends Object
    with ParserTestHelpers
    implements AbstractParserTestCase {
  ParserProxy _parserProxy;

  @override
  set enableGenericMethodComments(bool value) {
    if (value == true) {
      // TODO(paulberry,ahe): generic method comment syntax is not supported by
      // Fasta.
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
  void assertNoErrors() {
    // TODO(paulberry): implement assertNoErrors
  }

  @override
  void createParser(String content) {
    var scanner = new StringScanner(content);
    _parserProxy = new ParserProxy(scanner.tokenize());
  }

  @override
  CompilationUnit parseCompilationUnit(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return _runParser(source, (parser) => parser.parseUnit, errorCodes)
        as CompilationUnit;
  }

  @override
  CompilationUnit parseCompilationUnitWithOptions(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    // TODO(paulberry): implement parseCompilationUnitWithOptions
    throw new UnimplementedError();
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return _runParser(source, (parser) => parser.parseUnit, errorCodes);
  }

  @override
  Expression parseExpression(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return _runParser(source, (parser) => parser.parseExpression, errorCodes)
        as Expression;
  }

  @override
  CompilationUnitMember parseFullCompilationUnitMember() {
    return _parserProxy._run((parser) => parser.parseTopLevelDeclaration)
        as CompilationUnitMember;
  }

  @override
  Directive parseFullDirective() {
    return _parserProxy._run((parser) => parser.parseTopLevelDeclaration)
        as Directive;
  }

  @override
  Statement parseStatement(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[],
      bool enableLazyAssignmentOperators]) {
    return _runParser(source, (parser) => parser.parseStatement, errorCodes)
        as Statement;
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
  fasta.Token _currentFastaToken;

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
  factory ParserProxy(fasta.Token startingToken) {
    var library = new KernelLibraryBuilderProxy();
    var member = new BuilderProxy();
    var elementStore = new ElementStoreProxy();
    var scope = new ScopeProxy();
    var astBuilder = new AstBuilder(library, member, elementStore, scope);
    return new ParserProxy._(
        startingToken, new fasta.Parser(astBuilder), astBuilder);
  }

  ParserProxy._(this._currentFastaToken, this._fastaParser, this._astBuilder);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
  void operator []=(String name, Builder member) {
    _locals[name] = member;
  }

  @override
  Scope createNestedScope({bool isModifiable: true}) {
    return new Scope(<String, Builder>{}, this, isModifiable: isModifiable);
  }

  @override
  Builder lookup(String name, int charOffset, Uri fileUri) =>
      _locals.putIfAbsent(name, () => new BuilderProxy());

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Tests of the fasta parser based on [TopLevelParserTestMixin].
 */
@reflectiveTest
class TopLevelParserTest_Fasta extends FastaParserTestCase
    with TopLevelParserTestMixin {
  @override
  @failingTest
  void test_parseClassDeclaration_abstract() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseClassDeclaration_abstract();
  }

  @override
  @failingTest
  void test_parseClassDeclaration_native() {
    // TODO(paulberry): TODO(paulberry,ahe): Fasta parser doesn't appear to support "native" syntax yet.
    super.test_parseClassDeclaration_native();
  }

  @override
  @failingTest
  void test_parseClassDeclaration_nonEmpty() {
    // TODO(paulberry): Unhandled event: NoFieldInitializer
    super.test_parseClassDeclaration_nonEmpty();
  }

  @override
  @failingTest
  void test_parseClassDeclaration_typeAlias_withB() {
    // TODO(paulberry,ahe): capture `with` token.
    super.test_parseClassDeclaration_typeAlias_withB();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    // TODO(paulberry): Unhandled event: Qualified
    super.test_parseCompilationUnit_abstractAsPrefix_parameterized();
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
  void test_parseCompilationUnit_empty() {
    // TODO(paulberry): No objects placed on stack
    super.test_parseCompilationUnit_empty();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_exportAsPrefix() {
    // TODO(paulberry): TODO(paulberry,ahe): Fasta parser doesn't appear to handle this case correctly.
    super.test_parseCompilationUnit_exportAsPrefix();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    // TODO(paulberry): Unhandled event: TypeArguments
    super.test_parseCompilationUnit_exportAsPrefix_parameterized();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    // TODO(paulberry): Unhandled event: Qualified
    super.test_parseCompilationUnit_operatorAsPrefix_parameterized();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_script() {
    // TODO(paulberry): No objects placed on stack
    super.test_parseCompilationUnit_script();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_typedefAsPrefix() {
    // TODO(paulberry): TODO(paulberry,ahe): Fasta parser doesn't appear to handle this case correctly.
    super.test_parseCompilationUnit_typedefAsPrefix();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_abstractAsPrefix() {
    // TODO(paulberry): Unhandled event: Qualified
    super.test_parseCompilationUnitMember_abstractAsPrefix();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_classTypeAlias() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseCompilationUnitMember_classTypeAlias();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_function_external_noType() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseCompilationUnitMember_function_external_noType();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_function_external_type() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseCompilationUnitMember_function_external_type();
  }

  @override
  @failingTest
  void
      test_parseCompilationUnitMember_function_generic_noReturnType_annotated() {
    // TODO(paulberry,ahe): Fasta doesn't appear to support annotated type
    // parameters.
    super
        .test_parseCompilationUnitMember_function_generic_noReturnType_annotated();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_getter_external_noType() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseCompilationUnitMember_getter_external_noType();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_getter_external_type() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseCompilationUnitMember_getter_external_type();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_setter_external_noType() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseCompilationUnitMember_setter_external_noType();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_setter_external_type() {
    // TODO(paulberry): Implement AstBuilder.handleModifier
    super.test_parseCompilationUnitMember_setter_external_type();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_typeAlias_abstract() {
    // TODO(paulberry,ahe): Capture `=` token
    super.test_parseCompilationUnitMember_typeAlias_abstract();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_typeAlias_generic() {
    // TODO(paulberry): Unhandled event: TypeArguments
    super.test_parseCompilationUnitMember_typeAlias_generic();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_typeAlias_implements() {
    // TODO(paulberry,ahe): Capture `=` token
    super.test_parseCompilationUnitMember_typeAlias_implements();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_typeAlias_noImplements() {
    // TODO(paulberry,ahe): Capture `=` token
    super.test_parseCompilationUnitMember_typeAlias_noImplements();
  }

  @override
  @failingTest
  void test_parseDirectives_complete() {
    // TODO(paulberry,ahe): Fasta doesn't support script tags yet.
    super.test_parseDirectives_complete();
  }

  @override
  @failingTest
  void test_parseDirectives_empty() {
    // TODO(paulberry): No objects placed on stack
    super.test_parseDirectives_empty();
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
  void test_parseDirectives_script() {
    // TODO(paulberry): No objects placed on stack
    super.test_parseDirectives_script();
  }

  @override
  @failingTest
  void test_parseEnumDeclaration_one() {
    // TODO(paulberry): Unhandled event: Enum
    super.test_parseEnumDeclaration_one();
  }

  @override
  @failingTest
  void test_parseEnumDeclaration_trailingComma() {
    // TODO(paulberry): Unhandled event: Enum
    super.test_parseEnumDeclaration_trailingComma();
  }

  @override
  @failingTest
  void test_parseEnumDeclaration_two() {
    // TODO(paulberry): Unhandled event: Enum
    super.test_parseEnumDeclaration_two();
  }

  @override
  @failingTest
  void test_parseExportDirective_configuration_multiple() {
    // TODO(paulberry): Implement endConditionalUri
    super.test_parseExportDirective_configuration_multiple();
  }

  @override
  @failingTest
  void test_parseExportDirective_configuration_single() {
    // TODO(paulberry): Implement endConditionalUri
    super.test_parseExportDirective_configuration_single();
  }

  @override
  @failingTest
  void test_parseFunctionDeclaration_function() {
    // TODO(paulberry): handle doc comments
    super.test_parseFunctionDeclaration_function();
  }

  @override
  @failingTest
  void test_parseFunctionDeclaration_functionWithTypeParameters() {
    // TODO(paulberry): handle doc comments
    super.test_parseFunctionDeclaration_functionWithTypeParameters();
  }

  @override
  @failingTest
  void test_parseFunctionDeclaration_functionWithTypeParameters_comment() {
    // TODO(paulberry,ahe): generic method comment syntax is not supported by
    // Fasta.
    super.test_parseFunctionDeclaration_functionWithTypeParameters_comment();
  }

  @override
  @failingTest
  void test_parseFunctionDeclaration_getter() {
    // TODO(paulberry): handle doc comments
    super.test_parseFunctionDeclaration_getter();
  }

  @override
  @failingTest
  void test_parseFunctionDeclaration_setter() {
    // TODO(paulberry): handle doc comments
    super.test_parseFunctionDeclaration_setter();
  }

  @override
  @failingTest
  void test_parseImportDirective_configuration_multiple() {
    // TODO(paulberry): Implement endConditionalUri
    super.test_parseImportDirective_configuration_multiple();
  }

  @override
  @failingTest
  void test_parseImportDirective_configuration_single() {
    // TODO(paulberry): Implement endConditionalUri
    super.test_parseImportDirective_configuration_single();
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

  @override
  @failingTest
  void test_parseTypeAlias_function_parameterizedReturnType() {
    // TODO(paulberry): Unhandled event: TypeArguments
    super.test_parseTypeAlias_function_parameterizedReturnType();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_noParameters() {
    super.test_parseTypeAlias_genericFunction_noParameters();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_noReturnType() {
    super.test_parseTypeAlias_genericFunction_noReturnType();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_parameterizedReturnType() {
    super.test_parseTypeAlias_genericFunction_parameterizedReturnType();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_parameters() {
    super.test_parseTypeAlias_genericFunction_parameters();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_noParameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters_noParameters();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_noReturnType() {
    super.test_parseTypeAlias_genericFunction_typeParameters_noReturnType();
  }

  @override
  @failingTest
  void
      test_parseTypeAlias_genericFunction_typeParameters_parameterizedReturnType() {
    super
        .test_parseTypeAlias_genericFunction_typeParameters_parameterizedReturnType();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_parameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters_parameters();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_typeParameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters_typeParameters();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_voidReturnType() {
    super.test_parseTypeAlias_genericFunction_typeParameters_voidReturnType();
  }

  @override
  @failingTest
  void test_parseTypeAlias_genericFunction_voidReturnType() {
    super.test_parseTypeAlias_genericFunction_voidReturnType();
  }
}
