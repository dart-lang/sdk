// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/fasta/analyzer/ast_builder.dart';
import 'package:front_end/src/fasta/analyzer/element_store.dart';
import 'package:front_end/src/fasta/builder/scope.dart';
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_library_builder.dart';
import 'package:front_end/src/fasta/parser/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/precedence.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest_Fasta);
    defineReflectiveTests(ComplexParserTest_Fasta);
    defineReflectiveTests(FormalParameterParserTest_Fasta);
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

@reflectiveTest
class ClassMemberParserTest_Fasta extends FastaParserTestCase
    with ClassMemberParserTestMixin {
  @override
  @failingTest
  void test_constFactory() {
    // TODO(paulberry): Unhandled event: ConstructorReference
    super.test_constFactory();
  }

  @override
  @failingTest
  void test_parseAwaitExpression_asStatement_inAsync() {
    // TODO(paulberry): Add support for async
    super.test_parseAwaitExpression_asStatement_inAsync();
  }

  @override
  @failingTest
  void test_parseAwaitExpression_asStatement_inSync() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseAwaitExpression_asStatement_inSync();
  }

  @override
  @failingTest
  void test_parseClassMember_constructor_withInitializers() {
    // TODO(paulberry): 'this' can't be used here.
    super.test_parseClassMember_constructor_withInitializers();
  }

  @override
  @failingTest
  void test_parseClassMember_field_covariant() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseClassMember_field_covariant();
  }

  @override
  @failingTest
  void test_parseClassMember_field_instance_prefixedType() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseClassMember_field_instance_prefixedType();
  }

  @override
  @failingTest
  void test_parseClassMember_field_namedGet() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseClassMember_field_namedGet();
  }

  @override
  @failingTest
  void test_parseClassMember_field_namedOperator() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseClassMember_field_namedOperator();
  }

  @override
  @failingTest
  void test_parseClassMember_field_namedOperator_withAssignment() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseClassMember_field_namedOperator_withAssignment();
  }

  @override
  @failingTest
  void test_parseClassMember_field_namedSet() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseClassMember_field_namedSet();
  }

  @override
  @failingTest
  void test_parseClassMember_field_static() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseClassMember_field_static();
  }

  @override
  @failingTest
  void test_parseClassMember_getter_functionType() {
    // TODO(paulberry): InputError: ErrorKind.ExpectedFunctionBody {actual: get}
    super.test_parseClassMember_getter_functionType();
  }

  @override
  @failingTest
  void test_parseClassMember_getter_void() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_getter_void();
  }

  @override
  @failingTest
  void test_parseClassMember_method_external() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_external();
  }

  @override
  @failingTest
  void test_parseClassMember_method_external_withTypeAndArgs() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_external_withTypeAndArgs();
  }

  @override
  @failingTest
  void test_parseClassMember_method_generic_comment_noReturnType() {
    // TODO(paulberry): Fasta doesn't support generic comment syntax
    super.test_parseClassMember_method_generic_comment_noReturnType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_generic_comment_returnType() {
    // TODO(paulberry): Fasta doesn't support generic comment syntax
    super.test_parseClassMember_method_generic_comment_returnType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_generic_comment_returnType_bound() {
    // TODO(paulberry): Fasta doesn't support generic comment syntax
    super.test_parseClassMember_method_generic_comment_returnType_bound();
  }

  @override
  @failingTest
  void test_parseClassMember_method_generic_comment_void() {
    // TODO(paulberry): Fasta doesn't support generic comment syntax
    super.test_parseClassMember_method_generic_comment_void();
  }

  @override
  @failingTest
  void test_parseClassMember_method_generic_noReturnType() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_generic_noReturnType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_generic_returnType() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_generic_returnType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_generic_void() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_generic_void();
  }

  @override
  @failingTest
  void test_parseClassMember_method_get_noType() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_get_noType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_get_type() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_get_type();
  }

  @override
  @failingTest
  void test_parseClassMember_method_get_void() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_get_void();
  }

  @override
  @failingTest
  void test_parseClassMember_method_operator_noType() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_operator_noType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_operator_type() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_operator_type();
  }

  @override
  @failingTest
  void test_parseClassMember_method_operator_void() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_operator_void();
  }

  @override
  @failingTest
  void test_parseClassMember_method_returnType_functionType() {
    // TODO(paulberry): InputError: ErrorKind.ExpectedFunctionBody {actual: m}
    super.test_parseClassMember_method_returnType_functionType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_returnType_parameterized() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_returnType_parameterized();
  }

  @override
  @failingTest
  void test_parseClassMember_method_set_noType() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_set_noType();
  }

  @override
  @failingTest
  void test_parseClassMember_method_set_type() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_set_type();
  }

  @override
  @failingTest
  void test_parseClassMember_method_set_void() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_set_void();
  }

  @override
  @failingTest
  void test_parseClassMember_method_trailing_commas() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseClassMember_method_trailing_commas();
  }

  @override
  @failingTest
  void test_parseClassMember_operator_functionType() {
    // TODO(paulberry): InputError: ErrorKind.ExpectedFunctionBody {actual: operator}
    super.test_parseClassMember_operator_functionType();
  }

  @override
  @failingTest
  void test_parseClassMember_operator_index() {
    // TODO(paulberry): Unhandled event: OperatorName
    super.test_parseClassMember_operator_index();
  }

  @override
  @failingTest
  void test_parseClassMember_operator_indexAssign() {
    // TODO(paulberry): Unhandled event: OperatorName
    super.test_parseClassMember_operator_indexAssign();
  }

  @override
  @failingTest
  void test_parseClassMember_redirectingFactory_const() {
    // TODO(paulberry): Unhandled event: ConstructorReference
    super.test_parseClassMember_redirectingFactory_const();
  }

  @override
  @failingTest
  void test_parseClassMember_redirectingFactory_nonConst() {
    // TODO(paulberry): Unhandled event: ConstructorReference
    super.test_parseClassMember_redirectingFactory_nonConst();
  }

  @override
  @failingTest
  void test_parseConstructor_assert() {
    // TODO(paulberry): Fasta doesn't support asserts in initializers
    super.test_parseConstructor_assert();
  }

  @override
  @failingTest
  void test_parseConstructor_with_pseudo_function_literal() {
    // TODO(paulberry): Expected: an object with length of <1>
    super.test_parseConstructor_with_pseudo_function_literal();
  }

  @override
  @failingTest
  void test_parseConstructorFieldInitializer_qualified() {
    // TODO(paulberry): Unhandled event: ThisExpression
    super.test_parseConstructorFieldInitializer_qualified();
  }

  @override
  @failingTest
  void test_parseConstructorFieldInitializer_unqualified() {
    // TODO(paulberry): Expected: an object with length of <1>
    super.test_parseConstructorFieldInitializer_unqualified();
  }

  @override
  @failingTest
  void test_parseGetter_nonStatic() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseGetter_nonStatic();
  }

  @override
  @failingTest
  void test_parseGetter_static() {
    // TODO(paulberry): Invalid modifier (static). Report an error.
    super.test_parseGetter_static();
  }

  @override
  @failingTest
  void test_parseInitializedIdentifierList_type() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseInitializedIdentifierList_type();
  }

  @override
  @failingTest
  void test_parseInitializedIdentifierList_var() {
    // TODO(paulberry): Unhandled event: Fields
    super.test_parseInitializedIdentifierList_var();
  }

  @override
  @failingTest
  void test_parseOperator() {
    // TODO(paulberry): Unhandled event: OperatorName
    super.test_parseOperator();
  }

  @override
  @failingTest
  void test_parseSetter_nonStatic() {
    // TODO(paulberry): Add support for method declarations
    super.test_parseSetter_nonStatic();
  }

  @override
  @failingTest
  void test_parseSetter_static() {
    // TODO(paulberry): Invalid modifier (static). Report an error.
    super.test_parseSetter_static();
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
  set enableAssertInitializer(bool value) {
    if (value == true) {
      // TODO(paulberry,ahe): it looks like asserts in initializer lists are not
      // supported by Fasta.
      throw new UnimplementedError();
    }
  }

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
            code, (parser) => parser.parseFormalParameters, errorCodes)
        as FormalParameterList;
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
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    FormalParameterList list = parseFormalParameterList('($code)',
        inFunctionType: inFunctionType, errorCodes: errorCodes);
    return list.parameters.single;
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
 * Tests of the fasta parser based on [FormalParameterParserTestMixin].
 */
@reflectiveTest
class FormalParameterParserTest_Fasta extends FastaParserTestCase
    with FormalParameterParserTestMixin {
  @override
  @failingTest
  void test_parseFormalParameter_covariant_type_function() {
    // TODO(scheglov): Unhandled event: FunctionTypedFormalParameter
    super.test_parseFormalParameter_covariant_type_function();
  }

  @override
  @failingTest
  void test_parseFormalParameter_type_function() {
    // TODO(scheglov): Unhandled event: FunctionTypedFormalParameter
    super.test_parseFormalParameter_type_function();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_named_multiple() {
    // TODO(scheglov): Unhandled event: ValuedFormalParameter
    super.test_parseFormalParameterList_named_multiple();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_named_single() {
    // TODO(scheglov): Unhandled event: OptionalFormalParameters
    super.test_parseFormalParameterList_named_single();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_named_trailing_comma() {
    // TODO(scheglov): Unhandled event: OptionalFormalParameters
    super.test_parseFormalParameterList_named_trailing_comma();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_normal_named() {
    // TODO(scheglov): Unhandled event: OptionalFormalParameters
    super.test_parseFormalParameterList_normal_named();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_normal_named_inFunctionType() {
    // TODO(scheglov): Unhandled event: OptionalFormalParameters
    super.test_parseFormalParameterList_normal_named_inFunctionType();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_normal_positional() {
    // TODO(scheglov): Unhandled event: OptionalFormalParameters
    super.test_parseFormalParameterList_normal_positional();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_positional_multiple() {
    // TODO(scheglov): Unhandled event: ValuedFormalParameter
    super.test_parseFormalParameterList_positional_multiple();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_positional_single() {
    // TODO(scheglov): Unhandled event: ValuedFormalParameter
    super.test_parseFormalParameterList_positional_single();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_positional_trailing_comma() {
    // TODO(scheglov): Unhandled event: OptionalFormalParameters
    super.test_parseFormalParameterList_positional_trailing_comma();
  }

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
  void test_parseNormalFormalParameter_field_function_nested() {
    // TODO(scheglov): Unhandled event: FunctionTypedFormalParameter
    super.test_parseNormalFormalParameter_field_function_nested();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_field_function_noNested() {
    // TODO(scheglov): Unhandled event: FunctionTypedFormalParameter
    super.test_parseNormalFormalParameter_field_function_noNested();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_noType() {
    // TODO(scheglov): Unhandled event: FunctionTypedFormalParameter
    super.test_parseNormalFormalParameter_function_noType();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_noType_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_noType_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_noType_typeParameterComments() {
    // TODO(scheglov): Not implemented: enableGenericMethodComments=
    super
        .test_parseNormalFormalParameter_function_noType_typeParameterComments();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_noType_typeParameters() {
    // TODO(scheglov): Unhandled event: TypeVariable
    super.test_parseNormalFormalParameter_function_noType_typeParameters();
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
  void test_parseNormalFormalParameter_function_type() {
    // TODO(scheglov): Unhandled event: FunctionTypedFormalParameter
    super.test_parseNormalFormalParameter_function_type();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_type_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_type_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_type_typeParameterComments() {
    // TODO(scheglov): Not implemented: enableGenericMethodComments=
    super.test_parseNormalFormalParameter_function_type_typeParameterComments();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_type_typeParameters() {
    // TODO(scheglov): Unhandled event: TypeVariable
    super.test_parseNormalFormalParameter_function_type_typeParameters();
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
  void test_parseNormalFormalParameter_function_void() {
    // TODO(scheglov): Unhandled event: VoidKeyword
    super.test_parseNormalFormalParameter_function_void();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_void_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_void_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_void_typeParameterComments() {
    // TODO(scheglov): Not implemented: enableGenericMethodComments=
    super.test_parseNormalFormalParameter_function_void_typeParameterComments();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_void_typeParameters() {
    // TODO(scheglov): Unhandled event: VoidKeyword
    super.test_parseNormalFormalParameter_function_void_typeParameters();
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
  void test_parseNormalFormalParameter_simple_noName() {
    // TODO(scheglov): in function type, type instead of parameter name
    super.test_parseNormalFormalParameter_simple_noName();
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

  @override
  ConstructorFieldInitializer parseConstructorFieldInitializer(bool hasThis) {
    // Fasta's parser doesn't need the [hasThis] hint, so we ignore it.
    var colon = new fasta.SymbolToken(fasta.COLON_INFO, 0);
    colon.next = _currentFastaToken;
    _currentFastaToken = colon;
    var initializers = _run((parser) => parser.parseInitializers) as List;
    return initializers[0] as ConstructorFieldInitializer;
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
    // TODO(paulberry): Unhandled event: ConstructorReference
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
  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    // TODO(paulberry): Unhandled event: ConstructorReference
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
    // TODO(paulberry): As of commit 5de9108 this syntax is invalid.
    super.test_parseCompilationUnit_typedefAsPrefix();
  }

  @override
  @failingTest
  void test_parseCompilationUnitMember_abstractAsPrefix() {
    // TODO(paulberry): Unhandled event: ConstructorReference
    super.test_parseCompilationUnitMember_abstractAsPrefix();
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

  void test_parseCompilationUnitMember_typedef() {
    // TODO(paulberry): Unhandled event: FunctionTypeAlias
    super.test_parseCompilationUnitMember_typedef();
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
