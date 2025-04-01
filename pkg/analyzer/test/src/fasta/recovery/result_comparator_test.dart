// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/parser_test_base.dart';
import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResultComparatorTest);
  });
}

@reflectiveTest
class ResultComparatorTest extends FastaParserTestCase {
  test_expectedIdentifier_anythingMatchesSynthetic() {
    // Any identifier matches a synthetic identifier.
    // TODO(paulberry): I don't think this behavior is intentional. Fix it.
    _assertMatched(
        actual: parseExpression('f(+x)', errors: [
          error(ParserErrorCode.MISSING_IDENTIFIER, 2, 1),
        ]),
        expected: parseExpression('f(foo+x)'));
  }

  test_expectedIdentifier_s_doesNotMatchNonSynthetic() {
    // `_s_` doesn't match non-synthetic identifiers.
    _assertMismatched(
        actual: parseExpression('f(a+x)'),
        expected: parseExpression('f(_s_+x)'),
        expectedFailureMessage: '''
Expected: f(_s_ + x)
   Found: f(a + x)''');
  }

  test_expectedIdentifier_s_matchesSynthetic() {
    // `_s_` matches a synthetic identifier.
    _assertMatched(
        actual: parseExpression('f(+x)', errors: [
          error(ParserErrorCode.MISSING_IDENTIFIER, 2, 1),
        ]),
        expected: parseExpression('f(_s_+x)'));
  }

  test_expectedNoOptionalNode_notPresent() {
    _assertMatched(
        actual: parseStatement('return;'), expected: parseStatement('return;'));
  }

  test_expectedNoOptionalNode_present() {
    _assertMismatched(
        actual: parseStatement('return 0;'),
        expected: parseStatement('return;'),
        expectedFailureMessage: '''
Expected null; found a IntegerLiteralImpl
  path: ReturnStatementImpl, IntegerLiteralImpl''');
  }

  test_expectedOptionalNode_missing() {
    _assertMismatched(
        actual: parseStatement('return;'),
        expected: parseStatement('return 0;'),
        expectedFailureMessage: '''
Expected a IntegerLiteralImpl; found null
  path: ReturnStatementImpl, IntegerLiteralImpl''');
  }

  test_expectedOptionalNode_notMissing() {
    _assertMatched(
        actual: parseStatement('return 0;'),
        expected: parseStatement('return 0;'));
  }

  test_expectedOptionalToken_missing() {
    _assertMismatched(
        actual: parseExpression('x is int'),
        expected: parseExpression('x is! int'),
        expectedFailureMessage: '''
Expected a SimpleToken; found null
''');
  }

  test_expectedOptionalToken_notMissing() {
    _assertMatched(
        actual: parseExpression('x is! int'),
        expected: parseExpression('x is! int'));
  }

  test_expectedToken_k_doesNotMatchNonKeywordToken() {
    // `_k_` doesn't match non-keyword tokens.
    _assertMismatched(
        actual: parseCompilationUnit('class C {}'),
        expected: parseCompilationUnit('class _k_ {}'),
        expectedFailureMessage: '''
Expected: class _k_ {}
   Found: class C {}''');
  }

  test_expectedToken_k_matchesKeywordToken() {
    // `_k_` matches a keyword token.
    _assertMatched(
        actual: parseCompilationUnit('class C { C(this); }', errors: [
          error(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 12, 4),
        ]),
        expected: parseCompilationUnit('class C { C(_k_); }'));
  }

  test_expectedToken_randomIdentifierDoesNotMatchKeywordToken() {
    _assertMismatched(
        actual: parseCompilationUnit('class C { C(this); }', errors: [
          error(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 12, 4),
        ]),
        expected: parseCompilationUnit('class C { C(foo); }'),
        expectedFailureMessage: '''
Expected: class C {C(foo);}
   Found: class C {C(this);}''');
  }

  test_formalParameterList_namedParameters_matched() {
    _assertMatched(
        actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
        expected: parseFormalParameterList('(int? x, {int? y, int? z})'));
  }

  test_formalParameterList_namedParameters_mismatchedOpenBracketLocation() {
    _assertMismatched(
        actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
        expected: parseFormalParameterList('(int? x, int? y, {int? z})'),
        expectedFailureMessage: '''
Expected a SimpleFormalParameterImpl; found DefaultFormalParameterImpl
  path: FormalParameterListImpl, DefaultFormalParameterImpl''');
  }

  test_formalParameterList_namedParameters_mismatchedParamKind() {
    _assertMismatched(
        actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
        expected: parseFormalParameterList('(int? x, {int? y, int? z()})'),
        expectedFailureMessage: '''
Expected a FunctionTypedFormalParameterImpl; found SimpleFormalParameterImpl
  path: FormalParameterListImpl, DefaultFormalParameterImpl, SimpleFormalParameterImpl''');
  }

  test_formalParameterList_namedParameters_mismatchedParamName() {
    _assertMismatched(
        actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
        expected: parseFormalParameterList('(int? x, {int? y, int? w})'),
        expectedFailureMessage: '''
Expected: (int? x, {int? y, int? w})
   Found: (int? x, {int? y, int? z})''');
  }

  test_formalParameterList_normalParameters_matched() {
    _assertMatched(
        actual: parseFormalParameterList('(int x, int y)'),
        expected: parseFormalParameterList('(int x, int y)'));
  }

  test_formalParameterList_normalParameters_mismatchedParamKind() {
    _assertMismatched(
        actual: parseFormalParameterList('(int x, int y)'),
        expected: parseFormalParameterList('(int x, int y())'),
        expectedFailureMessage: '''
Expected a FunctionTypedFormalParameterImpl; found SimpleFormalParameterImpl
  path: FormalParameterListImpl, SimpleFormalParameterImpl''');
  }

  test_formalParameterList_normalParameters_mismatchedParamName() {
    _assertMismatched(
        actual: parseFormalParameterList('(int x, int y)'),
        expected: parseFormalParameterList('(int x, int z)'),
        expectedFailureMessage: '''
Expected: (int x, int z)
   Found: (int x, int y)''');
  }

  test_formalParameterList_optionalParameters_matched() {
    _assertMatched(
        actual: parseFormalParameterList('(int x, [int y, int z])'),
        expected: parseFormalParameterList('(int x, [int y, int z])'));
  }

  test_formalParameterList_optionalParameters_mismatchedOpenBracketLocation() {
    _assertMismatched(
        actual: parseFormalParameterList('(int x, [int y, int z])'),
        expected: parseFormalParameterList('(int x, int y, [int z])'),
        expectedFailureMessage: '''
Expected a SimpleFormalParameterImpl; found DefaultFormalParameterImpl
  path: FormalParameterListImpl, DefaultFormalParameterImpl''');
  }

  test_formalParameterList_optionalParameters_mismatchedParamKind() {
    _assertMismatched(
        actual: parseFormalParameterList('(int x, [int y, int z])'),
        expected: parseFormalParameterList('(int x, [int y, int z()])'),
        expectedFailureMessage: '''
Expected a FunctionTypedFormalParameterImpl; found SimpleFormalParameterImpl
  path: FormalParameterListImpl, DefaultFormalParameterImpl, SimpleFormalParameterImpl''');
  }

  test_formalParameterList_optionalParameters_mismatchedParamName() {
    _assertMismatched(
        actual: parseFormalParameterList('(int x, [int y, int z])'),
        expected: parseFormalParameterList('(int x, [int y, int w])'),
        expectedFailureMessage: '''
Expected: (int x, [int y, int w])
   Found: (int x, [int y, int z])''');
  }

  test_mismatchedDocumentationComment_reference() {
    // Changes to comment references in documentation comments count as a
    // mismatch.
    _assertMismatched(actual: parseCompilationUnit('''
/// A [Foo]
class C {}
'''), expected: parseCompilationUnit('''
/// A [Bar]
class C {}
'''), expectedFailureMessage: '''
Expected: class C {}
   Found: class C {}''');
  }

  test_mismatchedDocumentationComment_text() {
    // Text-only changes to documentation comments don't count as a mismatch.
    // TODO(paulberry): consider changing this behavior.
    _assertMatched(actual: parseCompilationUnit('''
/// A class
class C {}
'''), expected: parseCompilationUnit('''
/// A clasx
class C {}
'''));
  }

  test_mismatchedListLength_nodeList() {
    _assertMismatched(
        actual: parseExpression('f(x, y, z)'),
        expected: parseExpression('f(x, y, z, w)'),
        expectedFailureMessage: '''
Expected a list of length 4
  [x, y, z, w]
But found a list of length 3
  [x, y, z]
  path: MethodInvocationImpl, ArgumentListImpl''');
  }

  test_mismatchedListLength_nonNodeList() {
    _assertMismatched(
        actual: parseExpression('#x.y.z'),
        expected: parseExpression('#x.y.z.w'),
        expectedFailureMessage: '''
Expected a list of length 4
  [x, y, z, w]
But found a list of length 3
  [x, y, z]
''');
  }

  test_mismatchedNodeType() {
    _assertMismatched(
        actual: parseExpression('f(x)'),
        expected: parseExpression('f(0)'),
        expectedFailureMessage: '''
Expected a IntegerLiteralImpl; found SimpleIdentifierImpl
  path: MethodInvocationImpl, ArgumentListImpl, SimpleIdentifierImpl''');
  }

  test_mismatchedToken() {
    _assertMismatched(
        actual: parseCompilationUnit('class C {}'),
        expected: parseCompilationUnit('class X {}'),
        expectedFailureMessage: '''
Expected: class X {}
   Found: class C {}''');
  }

  test_mismatchedTokenOffsets() {
    // Mismatched token offsets are tolerated.
    _assertMatched(
        actual: parseExpression('f( x)'), expected: parseExpression('f(x)'));
  }

  test_syntheticEmptyString_matchesRegardlessOfQuoteType() {
    // A synthetic empty string matches an expectation of either `''` or `""`.
    _assertMatched(
        actual: parseCompilationUnit('export', errors: [
          error(ParserErrorCode.EXPECTED_TOKEN, 0, 6),
          error(ParserErrorCode.EXPECTED_STRING_LITERAL, 6, 0),
        ]),
        expected: parseCompilationUnit("export '';"));
    _assertMatched(
        actual: parseCompilationUnit('export', errors: [
          error(ParserErrorCode.EXPECTED_TOKEN, 0, 6),
          error(ParserErrorCode.EXPECTED_STRING_LITERAL, 6, 0),
        ]),
        expected: parseCompilationUnit('export "";'));
  }

  void test_syntheticIdentifiers_matchRegardlessOfLexeme() {
    // Parser error recovery inserts a `FunctionDeclaration` whose `name` is a
    // synthetic token; that synthetic token's lexeme is based on the offset of
    // the extra `>` token. So the synthetic tokens produced for `f<T>> ...` and
    // `f<T> >...` are have different lexemes. But `ResultComparator` should
    // treat them as equivalent since they're both synthetic.
    _assertMatched(
        actual: parseCompilationUnit('''
f<T>> () => null;
''', errors: [
          error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 0, 1),
          error(ParserErrorCode.MISSING_FUNCTION_BODY, 4, 1),
          error(ParserErrorCode.TOP_LEVEL_OPERATOR, 4, 1),
        ]),
        expected: parseCompilationUnit('''
f<T> >() => null;
''', errors: [
          error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 0, 1),
          error(ParserErrorCode.MISSING_FUNCTION_BODY, 5, 1),
          error(ParserErrorCode.TOP_LEVEL_OPERATOR, 5, 1),
        ]));
  }

  test_syntheticToken_matchesEquivalentNonSyntheticToken() {
    _assertMatched(
        actual: parseCompilationUnit('''
mixin Foo implements
''', errors: [
          error(ParserErrorCode.EXPECTED_TYPE_NAME, 21, 0),
          error(ParserErrorCode.EXPECTED_MIXIN_BODY, 21, 0),
        ]),
        expected: parseCompilationUnit('''
mixin Foo implements {}
''', errors: [
          error(ParserErrorCode.EXPECTED_TYPE_NAME, 21, 1),
        ]));
  }

  void _assertMatched({required AstNode actual, required AstNode expected}) {
    ResultComparator.compare(actual, expected);
  }

  void _assertMismatched(
      {required AstNode actual,
      required AstNode expected,
      required String expectedFailureMessage}) {
    try {
      ResultComparator.compare(actual, expected);
    } on TestFailure catch (e) {
      expect(e.message, expectedFailureMessage);
      return;
    }
    fail('Failed to find a mismatch');
  }
}
