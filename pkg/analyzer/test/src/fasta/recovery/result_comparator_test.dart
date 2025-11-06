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
  test_expectedIdentifier_arbitraryIdentifierDoesNotMatchSynthetic() {
    _assertMismatched(
      actual: parseExpression(
        'f(+x)',
        errors: [error(ParserErrorCode.missingIdentifier, 2, 1)],
      ),
      expected: parseExpression('f(foo+x)'),
      expectedFailureMessage: '''
Expected token "foo"
  type=IDENTIFIER, length=3
But found synthetic token ""
  type=IDENTIFIER, length=0
  path: ((((root as MethodInvocation).argumentList as ArgumentList).arguments[0] as BinaryExpression).leftOperand as SimpleIdentifier).token
''',
    );
  }

  test_expectedIdentifier_s_doesNotMatchNonSynthetic() {
    // `_s_` doesn't match non-synthetic identifiers.
    _assertMismatched(
      actual: parseExpression('f(a+x)'),
      expected: parseExpression('f(_s_+x)'),
      expectedFailureMessage: '''
Expected a synthetic identifier
But found token "a"
  type=IDENTIFIER, length=1
  path: ((((root as MethodInvocation).argumentList as ArgumentList).arguments[0] as BinaryExpression).leftOperand as SimpleIdentifier).token
''',
    );
  }

  test_expectedIdentifier_s_matchesSynthetic() {
    // `_s_` matches a synthetic identifier.
    _assertMatched(
      actual: parseExpression(
        'f(+x)',
        errors: [error(ParserErrorCode.missingIdentifier, 2, 1)],
      ),
      expected: parseExpression('f(_s_+x)'),
    );
  }

  test_expectedNoOptionalNode_notPresent() {
    _assertMatched(
      actual: parseStatement('return;'),
      expected: parseStatement('return;'),
    );
  }

  test_expectedNoOptionalNode_present() {
    _assertMismatched(
      actual: parseStatement('return 0;'),
      expected: parseStatement('return;'),
      expectedFailureMessage: '''
Unexpected IntegerLiteralImpl
  path: (root as ReturnStatement).expression
''',
    );
  }

  test_expectedOptionalNode_missing() {
    _assertMismatched(
      actual: parseStatement('return;'),
      expected: parseStatement('return 0;'),
      expectedFailureMessage: '''
Expected a IntegerLiteralImpl; found nothing
  path: (root as ReturnStatement).expression
''',
    );
  }

  test_expectedOptionalNode_notMissing() {
    _assertMatched(
      actual: parseStatement('return 0;'),
      expected: parseStatement('return 0;'),
    );
  }

  test_expectedOptionalToken_missing() {
    _assertMismatched(
      actual: parseExpression('x is int'),
      expected: parseExpression('x is! int'),
      expectedFailureMessage: '''
Expected a SimpleToken; found nothing
  path: (root as IsExpression).notOperator
''',
    );
  }

  test_expectedOptionalToken_notMissing() {
    _assertMatched(
      actual: parseExpression('x is! int'),
      expected: parseExpression('x is! int'),
    );
  }

  test_expectedToken_k_doesNotMatchNonKeywordToken() {
    // `_k_` doesn't match non-keyword tokens.
    _assertMismatched(
      actual: parseCompilationUnit('class C {}'),
      expected: parseCompilationUnit('class _k_ {}'),
      expectedFailureMessage: '''
Expected a keyword
But found token "C"
  type=IDENTIFIER, length=1
  path: ((root as CompilationUnit).declarations[0] as ClassDeclaration).name
''',
    );
  }

  test_expectedToken_k_matchesKeywordToken() {
    // `_k_` matches a keyword token.
    _assertMatched(
      actual: parseCompilationUnit(
        'class C { C(this); }',
        errors: [error(ParserErrorCode.expectedIdentifierButGotKeyword, 12, 4)],
      ),
      expected: parseCompilationUnit('class C { C(_k_); }'),
    );
  }

  test_expectedToken_randomIdentifierDoesNotMatchKeywordToken() {
    _assertMismatched(
      actual: parseCompilationUnit(
        'class C { C(this); }',
        errors: [error(ParserErrorCode.expectedIdentifierButGotKeyword, 12, 4)],
      ),
      expected: parseCompilationUnit('class C { C(foo); }'),
      expectedFailureMessage: '''
Expected token "foo"
  type=IDENTIFIER, length=3
But found token "this"
  type=THIS, length=4
  path: (((((root as CompilationUnit).declarations[0] as ClassDeclaration).members[0] as ConstructorDeclaration).parameters as FormalParameterList).parameters[0] as SimpleFormalParameter).name
''',
    );
  }

  test_formalParameterList_namedParameters_matched() {
    _assertMatched(
      actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
      expected: parseFormalParameterList('(int? x, {int? y, int? z})'),
    );
  }

  test_formalParameterList_namedParameters_mismatchedOpenBracketLocation() {
    _assertMismatched(
      actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
      expected: parseFormalParameterList('(int? x, int? y, {int? z})'),
      expectedFailureMessage: '''
Expected a SimpleFormalParameterImpl; found DefaultFormalParameterImpl
  path: (root as FormalParameterList).parameters[1]
''',
    );
  }

  test_formalParameterList_namedParameters_mismatchedParamKind() {
    _assertMismatched(
      actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
      expected: parseFormalParameterList('(int? x, {int? y, int? z()})'),
      expectedFailureMessage: '''
Expected a FunctionTypedFormalParameterImpl; found SimpleFormalParameterImpl
  path: ((root as FormalParameterList).parameters[2] as DefaultFormalParameter).parameter
''',
    );
  }

  test_formalParameterList_namedParameters_mismatchedParamName() {
    _assertMismatched(
      actual: parseFormalParameterList('(int? x, {int? y, int? z})'),
      expected: parseFormalParameterList('(int? x, {int? y, int? w})'),
      expectedFailureMessage: '''
Expected token "w"
  type=IDENTIFIER, length=1
But found token "z"
  type=IDENTIFIER, length=1
  path: (((root as FormalParameterList).parameters[2] as DefaultFormalParameter).parameter as SimpleFormalParameter).name
''',
    );
  }

  test_formalParameterList_normalParameters_matched() {
    _assertMatched(
      actual: parseFormalParameterList('(int x, int y)'),
      expected: parseFormalParameterList('(int x, int y)'),
    );
  }

  test_formalParameterList_normalParameters_mismatchedParamKind() {
    _assertMismatched(
      actual: parseFormalParameterList('(int x, int y)'),
      expected: parseFormalParameterList('(int x, int y())'),
      expectedFailureMessage: '''
Expected a FunctionTypedFormalParameterImpl; found SimpleFormalParameterImpl
  path: (root as FormalParameterList).parameters[1]
''',
    );
  }

  test_formalParameterList_normalParameters_mismatchedParamName() {
    _assertMismatched(
      actual: parseFormalParameterList('(int x, int y)'),
      expected: parseFormalParameterList('(int x, int z)'),
      expectedFailureMessage: '''
Expected token "z"
  type=IDENTIFIER, length=1
But found token "y"
  type=IDENTIFIER, length=1
  path: ((root as FormalParameterList).parameters[1] as SimpleFormalParameter).name
''',
    );
  }

  test_formalParameterList_optionalParameters_matched() {
    _assertMatched(
      actual: parseFormalParameterList('(int x, [int y, int z])'),
      expected: parseFormalParameterList('(int x, [int y, int z])'),
    );
  }

  test_formalParameterList_optionalParameters_mismatchedOpenBracketLocation() {
    _assertMismatched(
      actual: parseFormalParameterList('(int x, [int y, int z])'),
      expected: parseFormalParameterList('(int x, int y, [int z])'),
      expectedFailureMessage: '''
Expected a SimpleFormalParameterImpl; found DefaultFormalParameterImpl
  path: (root as FormalParameterList).parameters[1]
''',
    );
  }

  test_formalParameterList_optionalParameters_mismatchedParamKind() {
    _assertMismatched(
      actual: parseFormalParameterList('(int x, [int y, int z])'),
      expected: parseFormalParameterList('(int x, [int y, int z()])'),
      expectedFailureMessage: '''
Expected a FunctionTypedFormalParameterImpl; found SimpleFormalParameterImpl
  path: ((root as FormalParameterList).parameters[2] as DefaultFormalParameter).parameter
''',
    );
  }

  test_formalParameterList_optionalParameters_mismatchedParamName() {
    _assertMismatched(
      actual: parseFormalParameterList('(int x, [int y, int z])'),
      expected: parseFormalParameterList('(int x, [int y, int w])'),
      expectedFailureMessage: '''
Expected token "w"
  type=IDENTIFIER, length=1
But found token "z"
  type=IDENTIFIER, length=1
  path: (((root as FormalParameterList).parameters[2] as DefaultFormalParameter).parameter as SimpleFormalParameter).name
''',
    );
  }

  test_mismatchedDocumentationComment_reference() {
    // Changes to comment references in documentation comments count as a
    // mismatch.
    _assertMismatched(
      actual: parseCompilationUnit('''
/// A [Foo]
class C {}
'''),
      expected: parseCompilationUnit('''
/// A [Bar]
class C {}
'''),
      expectedFailureMessage: '''
Expected token "Bar"
  type=IDENTIFIER, length=3
But found token "Foo"
  type=IDENTIFIER, length=3
  path: (((((root as CompilationUnit).declarations[0] as ClassDeclaration).documentationComment as Comment).references[0] as CommentReference).expression as SimpleIdentifier).token
''',
    );
  }

  test_mismatchedDocumentationComment_text() {
    // Text-only changes to documentation comments count as a mismatch.
    _assertMismatched(
      actual: parseCompilationUnit('''
/// A class
class C {}
'''),
      expected: parseCompilationUnit('''
/// A clasx
class C {}
'''),
      expectedFailureMessage: '''
Expected token "/// A clasx"
  type=SINGLE_LINE_COMMENT, length=11
But found token "/// A class"
  type=SINGLE_LINE_COMMENT, length=11
  path: (((root as CompilationUnit).declarations[0] as ClassDeclaration).documentationComment as Comment).tokens[0]
''',
    );
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
  path: ((root as MethodInvocation).argumentList as ArgumentList).arguments
''',
    );
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
  path: (root as SymbolLiteral).components
''',
    );
  }

  test_mismatchedNodeType() {
    _assertMismatched(
      actual: parseExpression('f(x)'),
      expected: parseExpression('f(0)'),
      expectedFailureMessage: '''
Expected a IntegerLiteralImpl; found SimpleIdentifierImpl
  path: ((root as MethodInvocation).argumentList as ArgumentList).arguments[0]
''',
    );
  }

  test_mismatchedToken() {
    _assertMismatched(
      actual: parseCompilationUnit('class C {}'),
      expected: parseCompilationUnit('class X {}'),
      expectedFailureMessage: '''
Expected token "X"
  type=IDENTIFIER, length=1
But found token "C"
  type=IDENTIFIER, length=1
  path: ((root as CompilationUnit).declarations[0] as ClassDeclaration).name
''',
    );
  }

  test_mismatchedTokenOffsets() {
    // Mismatched token offsets are tolerated.
    _assertMatched(
      actual: parseExpression('f( x)'),
      expected: parseExpression('f(x)'),
    );
  }

  test_syntheticEmptyString_matchesRegardlessOfQuoteType() {
    // A synthetic empty string matches an expectation of either `''` or `""`.
    _assertMatched(
      actual: parseCompilationUnit(
        'export',
        errors: [
          error(ParserErrorCode.expectedToken, 0, 6),
          error(ParserErrorCode.expectedStringLiteral, 6, 0),
        ],
      ),
      expected: parseCompilationUnit("export '';"),
    );
    _assertMatched(
      actual: parseCompilationUnit(
        'export',
        errors: [
          error(ParserErrorCode.expectedToken, 0, 6),
          error(ParserErrorCode.expectedStringLiteral, 6, 0),
        ],
      ),
      expected: parseCompilationUnit('export "";'),
    );
  }

  void test_syntheticIdentifiers_matchRegardlessOfLexeme() {
    // Parser error recovery inserts a `FunctionDeclaration` whose `name` is a
    // synthetic token; that synthetic token's lexeme is based on the offset of
    // the extra `>` token. So the synthetic tokens produced for `f<T>> ...` and
    // `f<T> >...` are have different lexemes. But `ResultComparator` should
    // treat them as equivalent since they're both synthetic.
    _assertMatched(
      actual: parseCompilationUnit(
        '''
f<T>> () => null;
''',
        errors: [
          error(ParserErrorCode.missingFunctionParameters, 0, 1),
          error(ParserErrorCode.missingFunctionBody, 4, 1),
          error(ParserErrorCode.topLevelOperator, 4, 1),
        ],
      ),
      expected: parseCompilationUnit(
        '''
f<T> >() => null;
''',
        errors: [
          error(ParserErrorCode.missingFunctionParameters, 0, 1),
          error(ParserErrorCode.missingFunctionBody, 5, 1),
          error(ParserErrorCode.topLevelOperator, 5, 1),
        ],
      ),
    );
  }

  test_syntheticToken_matchesEquivalentNonSyntheticToken() {
    _assertMatched(
      actual: parseCompilationUnit(
        '''
mixin Foo implements
''',
        errors: [
          error(ParserErrorCode.expectedTypeName, 21, 0),
          error(ParserErrorCode.expectedMixinBody, 21, 0),
        ],
      ),
      expected: parseCompilationUnit(
        '''
mixin Foo implements {}
''',
        errors: [error(ParserErrorCode.expectedTypeName, 21, 1)],
      ),
    );
  }

  void _assertMatched({required AstNode actual, required AstNode expected}) {
    ResultComparator.compare(actual, expected);
  }

  void _assertMismatched({
    required AstNode actual,
    required AstNode expected,
    required String expectedFailureMessage,
  }) {
    try {
      ResultComparator.compare(actual, expected);
    } on TestFailure catch (e) {
      expect(e.message, expectedFailureMessage);
      return;
    }
    fail('Failed to find a mismatch');
  }
}
