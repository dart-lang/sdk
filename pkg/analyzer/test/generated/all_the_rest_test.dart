// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.all_the_rest_test;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/html_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'engine_test.dart';
import 'parser_test.dart';
import 'resolver_test.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ConstantEvaluatorTest);
  runReflectiveTests(ConstantFinderTest);
  runReflectiveTests(ConstantValueComputerTest);
  runReflectiveTests(ConstantVisitorTest);
  runReflectiveTests(ContentCacheTest);
  runReflectiveTests(CustomUriResolverTest);
  runReflectiveTests(DartObjectImplTest);
  runReflectiveTests(DartUriResolverTest);
  runReflectiveTests(DeclaredVariablesTest);
  runReflectiveTests(DirectoryBasedDartSdkTest);
  runReflectiveTests(DirectoryBasedSourceContainerTest);
  runReflectiveTests(ElementBuilderTest);
  runReflectiveTests(ElementLocatorTest);
  runReflectiveTests(EnumMemberBuilderTest);
  runReflectiveTests(ErrorReporterTest);
  runReflectiveTests(ErrorSeverityTest);
  runReflectiveTests(ExitDetectorTest);
  runReflectiveTests(ExitDetectorTest2);
  runReflectiveTests(FileBasedSourceTest);
  runReflectiveTests(FileUriResolverTest);
  if (!AnalysisEngine.instance.useTaskModel) {
    runReflectiveTests(HtmlParserTest);
    runReflectiveTests(HtmlTagInfoBuilderTest);
    runReflectiveTests(HtmlUnitBuilderTest);
    runReflectiveTests(HtmlWarningCodeTest);
  }
  runReflectiveTests(ReferenceFinderTest);
  runReflectiveTests(SDKLibrariesReaderTest);
  runReflectiveTests(ToSourceVisitorTest);
  runReflectiveTests(UriKindTest);
  runReflectiveTests(StringScannerTest);
}

abstract class AbstractScannerTest {
  ht.AbstractScanner newScanner(String input);

  void test_tokenize_attribute() {
    _tokenize("<html bob=\"one two\">", <Object>[
      ht.TokenType.LT,
      "html",
      "bob",
      ht.TokenType.EQ,
      "\"one two\"",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_comment() {
    _tokenize("<!-- foo -->", <Object>["<!-- foo -->"]);
  }

  void test_tokenize_comment_incomplete() {
    _tokenize("<!-- foo", <Object>["<!-- foo"]);
  }

  void test_tokenize_comment_with_gt() {
    _tokenize("<!-- foo > -> -->", <Object>["<!-- foo > -> -->"]);
  }

  void test_tokenize_declaration() {
    _tokenize("<! foo ><html>",
        <Object>["<! foo >", ht.TokenType.LT, "html", ht.TokenType.GT]);
  }

  void test_tokenize_declaration_malformed() {
    _tokenize("<! foo /><html>",
        <Object>["<! foo />", ht.TokenType.LT, "html", ht.TokenType.GT]);
  }

  void test_tokenize_directive_incomplete() {
    _tokenize2("<? \nfoo", <Object>["<? \nfoo"], <int>[0, 4]);
  }

  void test_tokenize_directive_xml() {
    _tokenize("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>",
        <Object>["<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"]);
  }

  void test_tokenize_directives_incomplete_with_newline() {
    _tokenize2("<! \nfoo", <Object>["<! \nfoo"], <int>[0, 4]);
  }

  void test_tokenize_empty() {
    _tokenize("", <Object>[]);
  }

  void test_tokenize_lt() {
    _tokenize("<", <Object>[ht.TokenType.LT]);
  }

  void test_tokenize_script_embedded_tags() {
    _tokenize("<script> <p></p></script>", <Object>[
      ht.TokenType.LT,
      "script",
      ht.TokenType.GT,
      " <p></p>",
      ht.TokenType.LT_SLASH,
      "script",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_script_embedded_tags2() {
    _tokenize("<script> <p></p><</script>", <Object>[
      ht.TokenType.LT,
      "script",
      ht.TokenType.GT,
      " <p></p><",
      ht.TokenType.LT_SLASH,
      "script",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_script_embedded_tags3() {
    _tokenize("<script> <p></p></</script>", <Object>[
      ht.TokenType.LT,
      "script",
      ht.TokenType.GT,
      " <p></p></",
      ht.TokenType.LT_SLASH,
      "script",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_script_partial() {
    _tokenize("<script> <p> ",
        <Object>[ht.TokenType.LT, "script", ht.TokenType.GT, " <p> "]);
  }

  void test_tokenize_script_partial2() {
    _tokenize("<script> <p> <",
        <Object>[ht.TokenType.LT, "script", ht.TokenType.GT, " <p> <"]);
  }

  void test_tokenize_script_partial3() {
    _tokenize("<script> <p> </",
        <Object>[ht.TokenType.LT, "script", ht.TokenType.GT, " <p> </"]);
  }

  void test_tokenize_script_ref() {
    _tokenize("<script source='some.dart'/> <p>", <Object>[
      ht.TokenType.LT,
      "script",
      "source",
      ht.TokenType.EQ,
      "'some.dart'",
      ht.TokenType.SLASH_GT,
      " ",
      ht.TokenType.LT,
      "p",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_script_with_newline() {
    _tokenize2("<script> <p>\n </script>", <Object>[
      ht.TokenType.LT,
      "script",
      ht.TokenType.GT,
      " <p>\n ",
      ht.TokenType.LT_SLASH,
      "script",
      ht.TokenType.GT
    ], <int>[
      0,
      13
    ]);
  }

  void test_tokenize_spaces_and_newlines() {
    ht.Token token = _tokenize2(
        " < html \n bob = 'joe\n' >\n <\np > one \r\n two <!-- \rfoo --> </ p > </ html > ",
        <Object>[
      " ",
      ht.TokenType.LT,
      "html",
      "bob",
      ht.TokenType.EQ,
      "'joe\n'",
      ht.TokenType.GT,
      "\n ",
      ht.TokenType.LT,
      "p",
      ht.TokenType.GT,
      " one \r\n two ",
      "<!-- \rfoo -->",
      " ",
      ht.TokenType.LT_SLASH,
      "p",
      ht.TokenType.GT,
      " ",
      ht.TokenType.LT_SLASH,
      "html",
      ht.TokenType.GT,
      " "
    ],
        <int>[
      0,
      9,
      21,
      25,
      28,
      38,
      49
    ]);
    token = token.next;
    expect(token.offset, 1);
    token = token.next;
    expect(token.offset, 3);
    token = token.next;
    expect(token.offset, 10);
  }

  void test_tokenize_string() {
    _tokenize("<p bob=\"foo\">", <Object>[
      ht.TokenType.LT,
      "p",
      "bob",
      ht.TokenType.EQ,
      "\"foo\"",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_string_partial() {
    _tokenize("<p bob=\"foo",
        <Object>[ht.TokenType.LT, "p", "bob", ht.TokenType.EQ, "\"foo"]);
  }

  void test_tokenize_string_single_quote() {
    _tokenize("<p bob='foo'>", <Object>[
      ht.TokenType.LT,
      "p",
      "bob",
      ht.TokenType.EQ,
      "'foo'",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_string_single_quote_partial() {
    _tokenize("<p bob='foo",
        <Object>[ht.TokenType.LT, "p", "bob", ht.TokenType.EQ, "'foo"]);
  }

  void test_tokenize_tag_begin_end() {
    _tokenize("<html></html>", <Object>[
      ht.TokenType.LT,
      "html",
      ht.TokenType.GT,
      ht.TokenType.LT_SLASH,
      "html",
      ht.TokenType.GT
    ]);
  }

  void test_tokenize_tag_begin_only() {
    ht.Token token =
        _tokenize("<html>", <Object>[ht.TokenType.LT, "html", ht.TokenType.GT]);
    token = token.next;
    expect(token.offset, 1);
  }

  void test_tokenize_tag_incomplete_with_special_characters() {
    _tokenize("<br-a_b", <Object>[ht.TokenType.LT, "br-a_b"]);
  }

  void test_tokenize_tag_self_contained() {
    _tokenize("<br/>", <Object>[ht.TokenType.LT, "br", ht.TokenType.SLASH_GT]);
  }

  void test_tokenize_tags_wellformed() {
    _tokenize("<html><p>one two</p></html>", <Object>[
      ht.TokenType.LT,
      "html",
      ht.TokenType.GT,
      ht.TokenType.LT,
      "p",
      ht.TokenType.GT,
      "one two",
      ht.TokenType.LT_SLASH,
      "p",
      ht.TokenType.GT,
      ht.TokenType.LT_SLASH,
      "html",
      ht.TokenType.GT
    ]);
  }

  /**
   * Given an object representing an expected token, answer the expected token type.
   *
   * @param count the token count for error reporting
   * @param expected the object representing an expected token
   * @return the expected token type
   */
  ht.TokenType _getExpectedTokenType(int count, Object expected) {
    if (expected is ht.TokenType) {
      return expected;
    }
    if (expected is String) {
      String lexeme = expected;
      if (lexeme.startsWith("\"") || lexeme.startsWith("'")) {
        return ht.TokenType.STRING;
      }
      if (lexeme.startsWith("<!--")) {
        return ht.TokenType.COMMENT;
      }
      if (lexeme.startsWith("<!")) {
        return ht.TokenType.DECLARATION;
      }
      if (lexeme.startsWith("<?")) {
        return ht.TokenType.DIRECTIVE;
      }
      if (_isTag(lexeme)) {
        return ht.TokenType.TAG;
      }
      return ht.TokenType.TEXT;
    }
    fail(
        "Unknown expected token $count: ${expected != null ? expected.runtimeType : "null"}");
    return null;
  }

  bool _isTag(String lexeme) {
    if (lexeme.length == 0 || !Character.isLetter(lexeme.codeUnitAt(0))) {
      return false;
    }
    for (int index = 1; index < lexeme.length; index++) {
      int ch = lexeme.codeUnitAt(index);
      if (!Character.isLetterOrDigit(ch) && ch != 0x2D && ch != 0x5F) {
        return false;
      }
    }
    return true;
  }

  ht.Token _tokenize(String input, List<Object> expectedTokens) =>
      _tokenize2(input, expectedTokens, <int>[0]);
  ht.Token _tokenize2(
      String input, List<Object> expectedTokens, List<int> expectedLineStarts) {
    ht.AbstractScanner scanner = newScanner(input);
    scanner.passThroughElements = <String>["script"];
    int count = 0;
    ht.Token firstToken = scanner.tokenize();
    ht.Token token = firstToken;
    ht.Token previousToken = token.previous;
    expect(previousToken.type == ht.TokenType.EOF, isTrue);
    expect(previousToken.previous, same(previousToken));
    expect(previousToken.offset, -1);
    expect(previousToken.next, same(token));
    expect(token.offset, 0);
    while (token.type != ht.TokenType.EOF) {
      if (count == expectedTokens.length) {
        fail("too many parsed tokens");
      }
      Object expected = expectedTokens[count];
      ht.TokenType expectedTokenType = _getExpectedTokenType(count, expected);
      expect(token.type, same(expectedTokenType), reason: "token $count");
      if (expectedTokenType.lexeme != null) {
        expect(token.lexeme, expectedTokenType.lexeme, reason: "token $count");
      } else {
        expect(token.lexeme, expected, reason: "token $count");
      }
      count++;
      previousToken = token;
      token = token.next;
      expect(token.previous, same(previousToken));
    }
    expect(token.next, same(token));
    expect(token.offset, input.length);
    if (count != expectedTokens.length) {
      expect(false, isTrue, reason: "not enough parsed tokens");
    }
    List<int> lineStarts = scanner.lineStarts;
    bool success = expectedLineStarts.length == lineStarts.length;
    if (success) {
      for (int i = 0; i < lineStarts.length; i++) {
        if (expectedLineStarts[i] != lineStarts[i]) {
          success = false;
          break;
        }
      }
    }
    if (!success) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Expected line starts ");
      for (int start in expectedLineStarts) {
        buffer.write(start);
        buffer.write(", ");
      }
      buffer.write(" but found ");
      for (int start in lineStarts) {
        buffer.write(start);
        buffer.write(", ");
      }
      fail(buffer.toString());
    }
    return firstToken;
  }
}

/**
 * Implementation of [ConstantEvaluationValidator] used during unit tests;
 * verifies that any nodes referenced during constant evaluation are present in
 * the dependency graph.
 */
class ConstantEvaluationValidator_ForTest
    implements ConstantEvaluationValidator {
  ConstantValueComputer computer;

  ConstantEvaluationTarget _nodeBeingEvaluated;

  @override
  void beforeComputeValue(ConstantEvaluationTarget constant) {
    _nodeBeingEvaluated = constant;
  }

  @override
  void beforeGetConstantInitializers(ConstructorElement constructor) {
    // Make sure we properly recorded the dependency.
    expect(
        computer.referenceGraph.containsPath(_nodeBeingEvaluated, constructor),
        isTrue);
  }

  @override
  void beforeGetEvaluationResult(ConstantEvaluationTarget constant) {
    // Make sure we properly recorded the dependency.
    expect(computer.referenceGraph.containsPath(_nodeBeingEvaluated, constant),
        isTrue);
  }

  @override
  void beforeGetFieldEvaluationResult(FieldElementImpl field) {
    // Make sure we properly recorded the dependency.
    expect(computer.referenceGraph.containsPath(_nodeBeingEvaluated, field),
        isTrue);
  }

  @override
  void beforeGetParameterDefault(ParameterElement parameter) {
    // Make sure we properly recorded the dependency.
    expect(computer.referenceGraph.containsPath(_nodeBeingEvaluated, parameter),
        isTrue);
  }
}

@reflectiveTest
class ConstantEvaluatorTest extends ResolverTestCase {
  void fail_constructor() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_class() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_function() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_static() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_staticMethod() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_topLevel() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_typeParameter() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_prefixedIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_prefixedIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void test_bitAnd_int_int() {
    _assertValue3(74 & 42, "74 & 42");
  }

  void test_bitNot() {
    _assertValue3(~42, "~42");
  }

  void test_bitOr_int_int() {
    _assertValue3(74 | 42, "74 | 42");
  }

  void test_bitXor_int_int() {
    _assertValue3(74 ^ 42, "74 ^ 42");
  }

  void test_divide_double_double() {
    _assertValue2(3.2 / 2.3, "3.2 / 2.3");
  }

  void test_divide_double_double_byZero() {
    EvaluationResult result = _getExpressionValue("3.2 / 0.0");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.doubleValue.isInfinite, isTrue);
  }

  void test_divide_int_int() {
    _assertValue2(1.5, "3 / 2");
  }

  void test_divide_int_int_byZero() {
    EvaluationResult result = _getExpressionValue("3 / 0");
    expect(result.isValid, isTrue);
  }

  void test_equal_boolean_boolean() {
    _assertValue(false, "true == false");
  }

  void test_equal_int_int() {
    _assertValue(false, "2 == 3");
  }

  void test_equal_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a == 3");
    expect(result.isValid, isFalse);
  }

  void test_equal_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 == a");
    expect(result.isValid, isFalse);
  }

  void test_equal_string_string() {
    _assertValue(false, "'a' == 'b'");
  }

  void test_greaterThan_int_int() {
    _assertValue(false, "2 > 3");
  }

  void test_greaterThanOrEqual_int_int() {
    _assertValue(false, "2 >= 3");
  }

  void test_leftShift_int_int() {
    _assertValue3(64, "16 << 2");
  }

  void test_lessThan_int_int() {
    _assertValue(true, "2 < 3");
  }

  void test_lessThanOrEqual_int_int() {
    _assertValue(true, "2 <= 3");
  }

  void test_literal_boolean_false() {
    _assertValue(false, "false");
  }

  void test_literal_boolean_true() {
    _assertValue(true, "true");
  }

  void test_literal_list() {
    EvaluationResult result = _getExpressionValue("const ['a', 'b', 'c']");
    expect(result.isValid, isTrue);
  }

  void test_literal_map() {
    EvaluationResult result =
        _getExpressionValue("const {'a' : 'm', 'b' : 'n', 'c' : 'o'}");
    expect(result.isValid, isTrue);
  }

  void test_literal_null() {
    EvaluationResult result = _getExpressionValue("null");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.isNull, isTrue);
  }

  void test_literal_number_double() {
    _assertValue2(3.45, "3.45");
  }

  void test_literal_number_integer() {
    _assertValue3(42, "42");
  }

  void test_literal_string_adjacent() {
    _assertValue4("abcdef", "'abc' 'def'");
  }

  void test_literal_string_interpolation_invalid() {
    EvaluationResult result = _getExpressionValue("'a\${f()}c'");
    expect(result.isValid, isFalse);
  }

  void test_literal_string_interpolation_valid() {
    _assertValue4("a3c", "'a\${3}c'");
  }

  void test_literal_string_simple() {
    _assertValue4("abc", "'abc'");
  }

  void test_logicalAnd() {
    _assertValue(false, "true && false");
  }

  void test_logicalNot() {
    _assertValue(false, "!true");
  }

  void test_logicalOr() {
    _assertValue(true, "true || false");
  }

  void test_minus_double_double() {
    _assertValue2(3.2 - 2.3, "3.2 - 2.3");
  }

  void test_minus_int_int() {
    _assertValue3(1, "3 - 2");
  }

  void test_negated_boolean() {
    EvaluationResult result = _getExpressionValue("-true");
    expect(result.isValid, isFalse);
  }

  void test_negated_double() {
    _assertValue2(-42.3, "-42.3");
  }

  void test_negated_integer() {
    _assertValue3(-42, "-42");
  }

  void test_notEqual_boolean_boolean() {
    _assertValue(true, "true != false");
  }

  void test_notEqual_int_int() {
    _assertValue(true, "2 != 3");
  }

  void test_notEqual_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a != 3");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 != a");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_string_string() {
    _assertValue(true, "'a' != 'b'");
  }

  void test_parenthesizedExpression() {
    _assertValue4("a", "('a')");
  }

  void test_plus_double_double() {
    _assertValue2(2.3 + 3.2, "2.3 + 3.2");
  }

  void test_plus_int_int() {
    _assertValue3(5, "2 + 3");
  }

  void test_plus_string_string() {
    _assertValue4("ab", "'a' + 'b'");
  }

  void test_remainder_double_double() {
    _assertValue2(3.2 % 2.3, "3.2 % 2.3");
  }

  void test_remainder_int_int() {
    _assertValue3(2, "8 % 3");
  }

  void test_rightShift() {
    _assertValue3(16, "64 >> 2");
  }

  void test_stringLength_complex() {
    _assertValue3(6, "('qwe' + 'rty').length");
  }

  void test_stringLength_simple() {
    _assertValue3(6, "'Dvorak'.length");
  }

  void test_times_double_double() {
    _assertValue2(2.3 * 3.2, "2.3 * 3.2");
  }

  void test_times_int_int() {
    _assertValue3(6, "2 * 3");
  }

  void test_truncatingDivide_double_double() {
    _assertValue3(1, "3.2 ~/ 2.3");
  }

  void test_truncatingDivide_int_int() {
    _assertValue3(3, "10 ~/ 3");
  }

  void _assertValue(bool expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value.type.name, "bool");
    expect(value.boolValue, expectedValue);
  }

  void _assertValue2(double expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.doubleValue, expectedValue);
  }

  void _assertValue3(int expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "int");
    expect(value.intValue, expectedValue);
  }

  void _assertValue4(String expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value, isNotNull);
    ParameterizedType type = value.type;
    expect(type, isNotNull);
    expect(type.name, "String");
    expect(value.stringValue, expectedValue);
  }

  EvaluationResult _getExpressionValue(String contents) {
    Source source = addSource("var x = $contents;");
    LibraryElement library = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, library);
    expect(unit, isNotNull);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember declaration = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration, declaration);
    NodeList<VariableDeclaration> variables =
        (declaration as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    ConstantEvaluator evaluator =
        new ConstantEvaluator(source, analysisContext.typeProvider);
    return evaluator.evaluate(variables[0].initializer);
  }
}

@reflectiveTest
class ConstantFinderTest extends EngineTestCase {
  AstNode _node;
  TypeProvider _typeProvider;
  AnalysisContext _context;
  Source _source;

  void setUp() {
    super.setUp();
    _typeProvider = new TestTypeProvider();
    _context = new TestAnalysisContext();
    _source = new TestSource();
  }

  /**
   * Test an annotation that consists solely of an identifier (and hence
   * represents a reference to a compile-time constant variable).
   */
  void test_visitAnnotation_constantVariable() {
    _node = AstFactory.annotation(AstFactory.identifier3('x'));
    expect(_findAnnotations(), contains(_node));
  }

  /**
   * Test an annotation that represents the invocation of a constant
   * constructor.
   */
  void test_visitAnnotation_invocation() {
    _node = AstFactory.annotation2(
        AstFactory.identifier3('A'), null, AstFactory.argumentList());
    expect(_findAnnotations(), contains(_node));
  }

  void test_visitConstructorDeclaration_const() {
    ConstructorElement element = _setupConstructorDeclaration("A", true);
    expect(_findConstants(), contains(element));
  }

  void test_visitConstructorDeclaration_nonConst() {
    _setupConstructorDeclaration("A", false);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_const() {
    VariableElement element = _setupVariableDeclaration("v", true, true);
    expect(_findConstants(), contains(element));
  }

  void test_visitVariableDeclaration_final_inClass() {
    _setupFieldDeclaration('C', 'f', Keyword.FINAL);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        hasConstConstructor: true);
    expect(_findConstants(), contains(field.element));
  }

  void test_visitVariableDeclaration_final_outsideClass() {
    _setupVariableDeclaration('v', false, true, isFinal: true);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_noInitializer() {
    _setupVariableDeclaration("v", true, false);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_nonConst() {
    _setupVariableDeclaration("v", false, true);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_static_const_inClass() {
    VariableDeclaration field =
        _setupFieldDeclaration('C', 'f', Keyword.CONST, isStatic: true);
    expect(_findConstants(), contains(field.element));
  }

  void test_visitVariableDeclaration_static_const_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.CONST,
        isStatic: true, hasConstConstructor: true);
    expect(_findConstants(), contains(field.element));
  }

  void test_visitVariableDeclaration_static_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        isStatic: true, hasConstConstructor: true);
    expect(_findConstants(), isNot(contains(field.element)));
  }

  void test_visitVariableDeclaration_uninitialized_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        isInitialized: false, hasConstConstructor: true);
    expect(_findConstants(), isNot(contains(field.element)));
  }

  void test_visitVariableDeclaration_uninitialized_static_const_inClass() {
    _setupFieldDeclaration('C', 'f', Keyword.CONST,
        isStatic: true, isInitialized: false);
    expect(_findConstants(), isEmpty);
  }

  List<Annotation> _findAnnotations() {
    Set<Annotation> annotations = new Set<Annotation>();
    for (ConstantEvaluationTarget target in _findConstants()) {
      if (target is ConstantEvaluationTarget_Annotation) {
        expect(target.context, same(_context));
        expect(target.source, same(_source));
        annotations.add(target.annotation);
      }
    }
    return new List<Annotation>.from(annotations);
  }

  Set<ConstantEvaluationTarget> _findConstants() {
    ConstantFinder finder = new ConstantFinder(_context, _source, _source);
    _node.accept(finder);
    Set<ConstantEvaluationTarget> constants = finder.constantsToCompute;
    expect(constants, isNotNull);
    return constants;
  }

  ConstructorElement _setupConstructorDeclaration(String name, bool isConst) {
    Keyword constKeyword = isConst ? Keyword.CONST : null;
    ConstructorDeclaration constructorDeclaration = AstFactory
        .constructorDeclaration2(
            constKeyword,
            null,
            null,
            name,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    ClassElement classElement = ElementFactory.classElement2(name);
    ConstructorElement element =
        ElementFactory.constructorElement(classElement, name, isConst);
    constructorDeclaration.element = element;
    _node = constructorDeclaration;
    return element;
  }

  VariableDeclaration _setupFieldDeclaration(
      String className, String fieldName, Keyword keyword,
      {bool isInitialized: true,
      bool isStatic: false,
      bool hasConstConstructor: false}) {
    VariableDeclaration variableDeclaration = isInitialized
        ? AstFactory.variableDeclaration2(fieldName, AstFactory.integer(0))
        : AstFactory.variableDeclaration(fieldName);
    VariableElement fieldElement = ElementFactory.fieldElement(
        fieldName,
        isStatic,
        keyword == Keyword.FINAL,
        keyword == Keyword.CONST,
        _typeProvider.intType);
    variableDeclaration.name.staticElement = fieldElement;
    FieldDeclaration fieldDeclaration = AstFactory.fieldDeclaration2(
        isStatic, keyword, <VariableDeclaration>[variableDeclaration]);
    ClassDeclaration classDeclaration =
        AstFactory.classDeclaration(null, className, null, null, null, null);
    classDeclaration.members.add(fieldDeclaration);
    _node = classDeclaration;
    ClassElementImpl classElement = ElementFactory.classElement2(className);
    classElement.fields = <FieldElement>[fieldElement];
    classDeclaration.name.staticElement = classElement;
    if (hasConstConstructor) {
      ConstructorDeclaration constructorDeclaration = AstFactory
          .constructorDeclaration2(
              Keyword.CONST,
              null,
              AstFactory.identifier3(className),
              null,
              AstFactory.formalParameterList(),
              null,
              AstFactory.blockFunctionBody2());
      classDeclaration.members.add(constructorDeclaration);
      ConstructorElement constructorElement =
          ElementFactory.constructorElement(classElement, '', true);
      constructorDeclaration.element = constructorElement;
      classElement.constructors = <ConstructorElement>[constructorElement];
    } else {
      classElement.constructors = ConstructorElement.EMPTY_LIST;
    }
    return variableDeclaration;
  }

  VariableElement _setupVariableDeclaration(
      String name, bool isConst, bool isInitialized,
      {isFinal: false}) {
    VariableDeclaration variableDeclaration = isInitialized
        ? AstFactory.variableDeclaration2(name, AstFactory.integer(0))
        : AstFactory.variableDeclaration(name);
    SimpleIdentifier identifier = variableDeclaration.name;
    VariableElement element = ElementFactory.localVariableElement(identifier);
    identifier.staticElement = element;
    Keyword keyword = isConst ? Keyword.CONST : isFinal ? Keyword.FINAL : null;
    AstFactory.variableDeclarationList2(keyword, [variableDeclaration]);
    _node = variableDeclaration;
    return element;
  }
}

@reflectiveTest
class ConstantValueComputerTest extends ResolverTestCase {
  void test_annotation_constConstructor() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A(this.i);
}

class C {
  @A(5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    Map<String, DartObjectImpl> annotationFields = _assertType(result, 'A');
    _assertIntField(annotationFields, 'i', 5);
  }

  void test_annotation_constConstructor_named() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A.named(this.i);
}

class C {
  @A.named(5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    Map<String, DartObjectImpl> annotationFields = _assertType(result, 'A');
    _assertIntField(annotationFields, 'i', 5);
  }

  void test_annotation_constConstructor_noArgs() {
    // Failing to pass arguments to an annotation which is a constant
    // constructor is illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A(this.i);
}

class C {
  @A
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_constConstructor_noArgs_named() {
    // Failing to pass arguments to an annotation which is a constant
    // constructor is illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A.named(this.i);
}

class C {
  @A.named
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_nonConstConstructor() {
    // Calling a non-const constructor from an annotation that is illegal, but
    // shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  A(this.i);
}

class C {
  @A(5)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_staticConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
class C {
  static const int i = 5;

  @i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  void test_annotation_staticConst_args() {
    // Applying arguments to an annotation that is a static const is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class C {
  static const int i = 5;

  @i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_staticConst_otherClass() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  static const int i = 5;
}

class C {
  @A.i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  void test_annotation_staticConst_otherClass_args() {
    // Applying arguments to an annotation that is a static const is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  static const int i = 5;
}

class C {
  @A.i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_toplevelVariable() {
    CompilationUnit compilationUnit = resolveSource(r'''
const int i = 5;
class C {
  @i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  void test_annotation_toplevelVariable_args() {
    // Applying arguments to an annotation that is a toplevel variable is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
const int i = 5;
class C {
  @i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_computeValues_cycle() {
    TestLogger logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    Source librarySource = addSource(r'''
const int a = c;
const int b = a;
const int c = b;''');
    LibraryElement libraryElement = resolve2(librarySource);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    analysisContext.computeErrors(librarySource);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, librarySource, librarySource);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(3));
    _validate(false, (members[0] as TopLevelVariableDeclaration).variables);
    _validate(false, (members[1] as TopLevelVariableDeclaration).variables);
    _validate(false, (members[2] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_dependentVariables() {
    Source librarySource = addSource(r'''
const int b = a;
const int a = 0;''');
    LibraryElement libraryElement = resolve2(librarySource);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, librarySource, librarySource);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(2));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (members[1] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_empty() {
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.computeValues();
  }

  void test_computeValues_multipleSources() {
    Source librarySource = addNamedSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
const int c = b;
const int a = 0;''');
    Source partSource = addNamedSource(
        "/part.dart",
        r'''
part of lib;
const int b = a;
const int d = c;''');
    LibraryElement libraryElement = resolve2(librarySource);
    CompilationUnit libraryUnit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(libraryUnit, isNotNull);
    CompilationUnit partUnit =
        analysisContext.resolveCompilationUnit(partSource, libraryElement);
    expect(partUnit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(libraryUnit, librarySource, librarySource);
    computer.add(partUnit, partSource, librarySource);
    computer.computeValues();
    NodeList<CompilationUnitMember> libraryMembers = libraryUnit.declarations;
    expect(libraryMembers, hasLength(2));
    _validate(
        true, (libraryMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(
        true, (libraryMembers[1] as TopLevelVariableDeclaration).variables);
    NodeList<CompilationUnitMember> partMembers = libraryUnit.declarations;
    expect(partMembers, hasLength(2));
    _validate(true, (partMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (partMembers[1] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_singleVariable() {
    Source librarySource = addSource("const int a = 0;");
    LibraryElement libraryElement = resolve2(librarySource);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, librarySource, librarySource);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(1));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_value_depends_on_enum() {
    Source librarySource = addSource('''
enum E { id0, id1 }
const E e = E.id0;
''');
    LibraryElement libraryElement = resolve2(librarySource);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, librarySource, librarySource);
    computer.computeValues();
    TopLevelVariableDeclaration declaration = unit.declarations
        .firstWhere((member) => member is TopLevelVariableDeclaration);
    _validate(true, declaration.variables);
  }

  void test_dependencyOnConstructor() {
    // x depends on "const A()"
    _assertProperDependencies(r'''
class A {
  const A();
}
const x = const A();''');
  }

  void test_dependencyOnConstructorArgument() {
    // "const A(x)" depends on x
    _assertProperDependencies(r'''
class A {
  const A(this.next);
  final A next;
}
const A x = const A(null);
const A y = const A(x);''');
  }

  void test_dependencyOnConstructorArgument_unresolvedConstructor() {
    // "const A.a(x)" depends on x even if the constructor A.a can't be found.
    _assertProperDependencies(
        r'''
class A {
}
const int x = 1;
const A y = const A.a(x);''',
        [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
  }

  void test_dependencyOnConstructorInitializer() {
    // "const A()" depends on x
    _assertProperDependencies(r'''
const int x = 1;
class A {
  const A() : v = x;
  final int v;
}''');
  }

  void test_dependencyOnExplicitSuperConstructor() {
    // b depends on B() depends on A()
    _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(5);
}
const B b = const B();''');
  }

  void test_dependencyOnExplicitSuperConstructorParameters() {
    // b depends on B() depends on i
    _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(i);
}
const B b = const B();
const int i = 5;''');
  }

  void test_dependencyOnFactoryRedirect() {
    // a depends on A.foo() depends on A.bar()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  factory const A.foo() = A.bar;
  const A.bar();
}''');
  }

  void test_dependencyOnFactoryRedirectWithTypeParams() {
    _assertProperDependencies(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
  }

  void test_dependencyOnImplicitSuperConstructor() {
    // b depends on B() depends on A()
    _assertProperDependencies(r'''
class A {
  const A() : x = 5;
  final int x;
}
class B extends A {
  const B();
}
const B b = const B();''');
  }

  void test_dependencyOnInitializedFinal() {
    // a depends on A() depends on A.x
    _assertProperDependencies('''
class A {
  const A();
  final int x = 1;
}
const A a = const A();
''');
  }

  void test_dependencyOnInitializedNonStaticConst() {
    // Even though non-static consts are not allowed by the language, we need
    // to handle them for error recovery purposes.
    // a depends on A() depends on A.x
    _assertProperDependencies(
        '''
class A {
  const A();
  const int x = 1;
}
const A a = const A();
''',
        [CompileTimeErrorCode.CONST_INSTANCE_FIELD]);
  }

  void test_dependencyOnNonFactoryRedirect() {
    // a depends on A.foo() depends on A.bar()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  const A.bar();
}''');
  }

  void test_dependencyOnNonFactoryRedirect_arg() {
    // a depends on A.foo() depends on b
    _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar(b);
  const A.bar(x) : y = x;
  final int y;
}''');
  }

  void test_dependencyOnNonFactoryRedirect_defaultValue() {
    // a depends on A.foo() depends on A.bar() depends on b
    _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar();
  const A.bar([x = b]) : y = x;
  final int y;
}''');
  }

  void test_dependencyOnNonFactoryRedirect_toMissing() {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // missing.
    _assertProperDependencies(
        r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
}''',
        [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR]);
  }

  void test_dependencyOnNonFactoryRedirect_toNonConst() {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // non-const.
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  A.bar();
}''');
  }

  void test_dependencyOnNonFactoryRedirect_unnamed() {
    // a depends on A.foo() depends on A()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this();
  const A();
}''');
  }

  void test_dependencyOnOptionalParameterDefault() {
    // a depends on A() depends on B()
    _assertProperDependencies(r'''
class A {
  const A([x = const B()]) : b = x;
  final B b;
}
class B {
  const B();
}
const A a = const A();''');
  }

  void test_dependencyOnVariable() {
    // x depends on y
    _assertProperDependencies(r'''
const x = y + 1;
const y = 2;''');
  }

  void test_final_initialized_at_declaration() {
    CompilationUnit compilationUnit = resolveSource('''
class A {
  final int i = 123;
  const A();
}

const A a = const A();
''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, 'a');
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "i", 123);
  }

  void test_fromEnvironment_bool_default_false() {
    expect(_assertValidBool(_check_fromEnvironment_bool(null, "false")), false);
  }

  void test_fromEnvironment_bool_default_overridden() {
    expect(
        _assertValidBool(_check_fromEnvironment_bool("false", "true")), false);
  }

  void test_fromEnvironment_bool_default_parseError() {
    expect(_assertValidBool(_check_fromEnvironment_bool("parseError", "true")),
        true);
  }

  void test_fromEnvironment_bool_default_true() {
    expect(_assertValidBool(_check_fromEnvironment_bool(null, "true")), true);
  }

  void test_fromEnvironment_bool_false() {
    expect(_assertValidBool(_check_fromEnvironment_bool("false", null)), false);
  }

  void test_fromEnvironment_bool_parseError() {
    expect(_assertValidBool(_check_fromEnvironment_bool("parseError", null)),
        false);
  }

  void test_fromEnvironment_bool_true() {
    expect(_assertValidBool(_check_fromEnvironment_bool("true", null)), true);
  }

  void test_fromEnvironment_bool_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_bool(null, null));
  }

  void test_fromEnvironment_int_default_overridden() {
    expect(_assertValidInt(_check_fromEnvironment_int("234", "123")), 234);
  }

  void test_fromEnvironment_int_default_parseError() {
    expect(
        _assertValidInt(_check_fromEnvironment_int("parseError", "123")), 123);
  }

  void test_fromEnvironment_int_default_undeclared() {
    expect(_assertValidInt(_check_fromEnvironment_int(null, "123")), 123);
  }

  void test_fromEnvironment_int_ok() {
    expect(_assertValidInt(_check_fromEnvironment_int("234", null)), 234);
  }

  void test_fromEnvironment_int_parseError() {
    _assertValidNull(_check_fromEnvironment_int("parseError", null));
  }

  void test_fromEnvironment_int_parseError_nullDefault() {
    _assertValidNull(_check_fromEnvironment_int("parseError", "null"));
  }

  void test_fromEnvironment_int_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_int(null, null));
  }

  void test_fromEnvironment_int_undeclared_nullDefault() {
    _assertValidNull(_check_fromEnvironment_int(null, "null"));
  }

  void test_fromEnvironment_string_default_overridden() {
    expect(_assertValidString(_check_fromEnvironment_string("abc", "'def'")),
        "abc");
  }

  void test_fromEnvironment_string_default_undeclared() {
    expect(_assertValidString(_check_fromEnvironment_string(null, "'def'")),
        "def");
  }

  void test_fromEnvironment_string_empty() {
    expect(_assertValidString(_check_fromEnvironment_string("", null)), "");
  }

  void test_fromEnvironment_string_ok() {
    expect(
        _assertValidString(_check_fromEnvironment_string("abc", null)), "abc");
  }

  void test_fromEnvironment_string_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_string(null, null));
  }

  void test_fromEnvironment_string_undeclared_nullDefault() {
    _assertValidNull(_check_fromEnvironment_string(null, "null"));
  }

  void test_instanceCreationExpression_computedField() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(4, 5);
class A {
  const A(int i, int j) : k = 2 * i + j;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 13);
  }

  void test_instanceCreationExpression_computedField_namedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(false, true, true);
  }

  void test_instanceCreationExpression_computedField_namedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(false, true, false);
  }

  void test_instanceCreationExpression_computedField_unnamedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(false, false, true);
  }

  void test_instanceCreationExpression_computedField_unnamedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(false, false, false);
  }

  void test_instanceCreationExpression_computedField_usesConstConstructor() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : b = const B(4);
  final int b;
}
class B {
  const B(this.k);
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fieldsOfA = _assertType(result, "A");
    expect(fieldsOfA, hasLength(1));
    Map<String, DartObjectImpl> fieldsOfB =
        _assertFieldType(fieldsOfA, "b", "B");
    expect(fieldsOfB, hasLength(1));
    _assertIntField(fieldsOfB, "k", 4);
  }

  void test_instanceCreationExpression_computedField_usesStaticConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : k = i + B.bar;
  final int k;
}
class B {
  static const bar = 4;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  void test_instanceCreationExpression_computedField_usesToplevelConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
const bar = 4;
class A {
  const A(int i) : k = i + bar;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  void test_instanceCreationExpression_explicitSuper() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const B(4, 5);
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B(int x, this.y) : super(x * 2);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 5);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 8);
  }

  void test_instanceCreationExpression_fieldFormalParameter() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(42);
class A {
  int x;
  const A(this.x)
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 42);
  }

  void test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(true, true, true);
  }

  void test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(true, true, false);
  }

  void test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(true, false, true);
  }

  void test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(true, false, false);
  }

  void test_instanceCreationExpression_implicitSuper() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const B(4);
class A {
  const A() : x = 3;
  final int x;
}
class B extends A {
  const B(this.y);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 4);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 3);
  }

  void test_instanceCreationExpression_nonFactoryRedirect() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'x', 5);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_arg() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1(1);
class A {
  const A.a1(x) : this.a2(x + 100);
  const A.a2(x) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'y', 111);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_cycle() {
    // It is an error to have a cycle in non-factory redirects; however, we
    // need to make sure that even if the error occurs, attempting to evaluate
    // the constant will terminate.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const A() : this.b();
  const A.b() : this();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_nonFactoryRedirect_defaultArg() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2([x = 100]) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'y', 110);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_toMissing() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
  }

  void test_instanceCreationExpression_nonFactoryRedirect_toNonConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  A.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
  }

  void test_instanceCreationExpression_nonFactoryRedirect_unnamed() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this();
  const A() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'x', 5);
  }

  void test_instanceCreationExpression_redirect() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = B;
}
class B implements A {
  const B();
}''');
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "B");
  }

  void test_instanceCreationExpression_redirect_cycle() {
    // It is an error to have a cycle in factory redirects; however, we need
    // to make sure that even if the error occurs, attempting to evaluate the
    // constant will terminate.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  const factory A.b() = A;
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirect_extern() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  external const factory A();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirect_nonConst() {
    // It is an error for a const factory constructor redirect to a non-const
    // constructor; however, we need to make sure that even if the error
    // attempting to evaluate the constant won't cause a crash.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  A.b();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirectWithTypeParams() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  void test_instanceCreationExpression_redirectWithTypeSubstitution() {
    // To evaluate the redirection of A<int>,
    // A's template argument (T=int) must be substituted
    // into B's template argument (B<U> where U=T) to get B<int>.
    CompilationUnit compilationUnit = resolveSource(r'''
class A<T> {
  const factory A(var a) = B<T>;
}

class B<U> implements A {
  final U x;
  const B(this.x);
}

const A<int> a = const A<int>(10);''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  void test_instanceCreationExpression_symbol() {
    CompilationUnit compilationUnit =
        resolveSource("const foo = const Symbol('a');");
    EvaluationResultImpl evaluationResult =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    expect(evaluationResult.value, isNotNull);
    DartObjectImpl value = evaluationResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.value, "a");
  }

  void test_instanceCreationExpression_withSupertypeParams_explicit() {
    _checkInstanceCreation_withSupertypeParams(true);
  }

  void test_instanceCreationExpression_withSupertypeParams_implicit() {
    _checkInstanceCreation_withSupertypeParams(false);
  }

  void test_instanceCreationExpression_withTypeParams() {
    CompilationUnit compilationUnit = resolveSource(r'''
class C<E> {
  const C();
}
const c_int = const C<int>();
const c_num = const C<num>();''');
    EvaluationResultImpl c_int =
        _evaluateTopLevelVariable(compilationUnit, "c_int");
    _assertType(c_int, "C<int>");
    DartObjectImpl c_int_value = c_int.value;
    EvaluationResultImpl c_num =
        _evaluateTopLevelVariable(compilationUnit, "c_num");
    _assertType(c_num, "C<num>");
    DartObjectImpl c_num_value = c_num.value;
    expect(c_int_value == c_num_value, isFalse);
  }

  void test_isValidSymbol() {
    expect(ConstantEvaluationEngine.isValidPublicSymbol(""), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.bar"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo\$"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo\$bar"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("iff"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("gif"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if\$"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("\$if"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo="), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.bar="), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.+"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("void"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("_foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("_foo.bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo._bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.if"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo=.bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo."), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("+.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("void.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.void"), isFalse);
  }

  void test_length_of_improperly_typed_string_expression() {
    // Since type annotations are ignored in unchecked mode, the improper
    // types on s1 and s2 shouldn't prevent us from evaluating i to
    // 'alpha'.length.
    CompilationUnit compilationUnit = resolveSource('''
const int s1 = 'alpha';
const int s2 = 'beta';
const int i = (true ? s1 : s2).length;
''');
    ConstTopLevelVariableElementImpl element =
        findTopLevelDeclaration(compilationUnit, 'i').element;
    EvaluationResultImpl result = element.evaluationResult;
    expect(_assertValidInt(result), 5);
  }

  void test_length_of_improperly_typed_string_identifier() {
    // Since type annotations are ignored in unchecked mode, the improper type
    // on s shouldn't prevent us from evaluating i to 'alpha'.length.
    CompilationUnit compilationUnit = resolveSource('''
const int s = 'alpha';
const int i = s.length;
''');
    ConstTopLevelVariableElementImpl element =
        findTopLevelDeclaration(compilationUnit, 'i').element;
    EvaluationResultImpl result = element.evaluationResult;
    expect(_assertValidInt(result), 5);
  }

  void test_non_static_const_initialized_at_declaration() {
    // Even though non-static consts are not allowed by the language, we need
    // to handle them for error recovery purposes.
    CompilationUnit compilationUnit = resolveSource('''
class A {
  const int i = 123;
  const A();
}

const A a = const A();
''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, 'a');
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "i", 123);
  }

  void test_symbolLiteral_void() {
    CompilationUnit compilationUnit =
        resolveSource("const voidSymbol = #void;");
    VariableDeclaration voidSymbol =
        findTopLevelDeclaration(compilationUnit, "voidSymbol");
    EvaluationResultImpl voidSymbolResult =
        (voidSymbol.element as VariableElementImpl).evaluationResult;
    DartObjectImpl value = voidSymbolResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.value, "void");
  }

  Map<String, DartObjectImpl> _assertFieldType(
      Map<String, DartObjectImpl> fields,
      String fieldName,
      String expectedType) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.displayName, expectedType);
    return field.fields;
  }

  void _assertIntField(
      Map<String, DartObjectImpl> fields, String fieldName, int expectedValue) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.name, "int");
    expect(field.intValue, expectedValue);
  }

  void _assertNullField(Map<String, DartObjectImpl> fields, String fieldName) {
    DartObjectImpl field = fields[fieldName];
    expect(field.isNull, isTrue);
  }

  void _assertProperDependencies(String sourceText,
      [List<ErrorCode> expectedErrorCodes = ErrorCode.EMPTY_LIST]) {
    Source source = addSource(sourceText);
    LibraryElement element = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, element);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, source, source);
    computer.computeValues();
    assertErrors(source, expectedErrorCodes);
  }

  Map<String, DartObjectImpl> _assertType(
      EvaluationResultImpl result, String typeName) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type.displayName, typeName);
    return value.fields;
  }

  bool _assertValidBool(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.boolType);
    bool boolValue = value.boolValue;
    expect(boolValue, isNotNull);
    return boolValue;
  }

  int _assertValidInt(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.intType);
    return value.intValue;
  }

  void _assertValidNull(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.nullType);
  }

  String _assertValidString(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.stringType);
    return value.stringValue;
  }

  void _assertValidUnknown(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.isUnknown, isTrue);
  }

  EvaluationResultImpl _check_fromEnvironment_bool(
      String valueInEnvironment, String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
        "const $varName = const bool.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  EvaluationResultImpl _check_fromEnvironment_int(
      String valueInEnvironment, String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
        "const $varName = const int.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  EvaluationResultImpl _check_fromEnvironment_string(
      String valueInEnvironment, String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
        "const $varName = const String.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  void _checkInstanceCreation_withSupertypeParams(bool isExplicit) {
    String superCall = isExplicit ? " : super()" : "";
    CompilationUnit compilationUnit = resolveSource("""
class A<T> {
  const A();
}
class B<T, U> extends A<T> {
  const B()$superCall;
}
class C<T, U> extends A<U> {
  const C()$superCall;
}
const b_int_num = const B<int, num>();
const c_int_num = const C<int, num>();""");
    EvaluationResultImpl b_int_num =
        _evaluateTopLevelVariable(compilationUnit, "b_int_num");
    Map<String, DartObjectImpl> b_int_num_fields =
        _assertType(b_int_num, "B<int, num>");
    _assertFieldType(b_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<int>");
    EvaluationResultImpl c_int_num =
        _evaluateTopLevelVariable(compilationUnit, "c_int_num");
    Map<String, DartObjectImpl> c_int_num_fields =
        _assertType(c_int_num, "C<int, num>");
    _assertFieldType(c_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<num>");
  }

  void _checkInstanceCreationOptionalParams(
      bool isFieldFormal, bool isNamed, bool hasDefault) {
    String fieldName = "j";
    String paramName = isFieldFormal ? fieldName : "i";
    String formalParam =
        "${isFieldFormal ? "this." : "int "}$paramName${hasDefault ? " = 3" : ""}";
    CompilationUnit compilationUnit = resolveSource("""
const x = const A();
const y = const A(${isNamed ? '$paramName: ' : ''}10);
class A {
  const A(${isNamed ? "{$formalParam}" : "[$formalParam]"})${isFieldFormal ? "" : " : $fieldName = $paramName"};
  final int $fieldName;
}""");
    EvaluationResultImpl x = _evaluateTopLevelVariable(compilationUnit, "x");
    Map<String, DartObjectImpl> fieldsOfX = _assertType(x, "A");
    expect(fieldsOfX, hasLength(1));
    if (hasDefault) {
      _assertIntField(fieldsOfX, fieldName, 3);
    } else {
      _assertNullField(fieldsOfX, fieldName);
    }
    EvaluationResultImpl y = _evaluateTopLevelVariable(compilationUnit, "y");
    Map<String, DartObjectImpl> fieldsOfY = _assertType(y, "A");
    expect(fieldsOfY, hasLength(1));
    _assertIntField(fieldsOfY, fieldName, 10);
  }

  /**
   * Search [compilationUnit] for a class named [className], containing a
   * method [methodName], with exactly one annotation.  Return the constant
   * value of the annotation.
   */
  EvaluationResultImpl _evaluateAnnotation(
      CompilationUnit compilationUnit, String className, String memberName) {
    for (CompilationUnitMember member in compilationUnit.declarations) {
      if (member is ClassDeclaration && member.name.name == className) {
        for (ClassMember classMember in member.members) {
          if (classMember is MethodDeclaration &&
              classMember.name.name == memberName) {
            expect(classMember.metadata, hasLength(1));
            ElementAnnotationImpl elementAnnotation =
                classMember.metadata[0].elementAnnotation;
            return elementAnnotation.evaluationResult;
          }
        }
      }
    }
    fail('Class member not found');
    return null;
  }

  EvaluationResultImpl _evaluateTopLevelVariable(
      CompilationUnit compilationUnit, String name) {
    VariableDeclaration varDecl =
        findTopLevelDeclaration(compilationUnit, name);
    ConstTopLevelVariableElementImpl varElement = varDecl.element;
    return varElement.evaluationResult;
  }

  ConstantValueComputer _makeConstantValueComputer() {
    ConstantEvaluationValidator_ForTest validator =
        new ConstantEvaluationValidator_ForTest();
    validator.computer = new ConstantValueComputer(
        analysisContext2,
        analysisContext2.typeProvider,
        analysisContext2.declaredVariables,
        validator);
    return validator.computer;
  }

  void _validate(bool shouldBeValid, VariableDeclarationList declarationList) {
    for (VariableDeclaration declaration in declarationList.variables) {
      VariableElementImpl element = declaration.element as VariableElementImpl;
      expect(element, isNotNull);
      EvaluationResultImpl result = element.evaluationResult;
      if (shouldBeValid) {
        expect(result.value, isNotNull);
      } else {
        expect(result.value, isNull);
      }
    }
  }
}

@reflectiveTest
class ConstantVisitorTest extends ResolverTestCase {
  void test_visitConditionalExpression_false() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(false), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(
        0,
        expression.accept(new ConstantVisitor(
            new ConstantEvaluationEngine(
                new TestTypeProvider(), new DeclaredVariables()),
            errorReporter)));
    errorListener.assertNoErrors();
  }

  void test_visitConditionalExpression_nonBooleanCondition() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    NullLiteral conditionExpression = AstFactory.nullLiteral();
    ConditionalExpression expression = AstFactory.conditionalExpression(
        conditionExpression, thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(
            new TestTypeProvider(), new DeclaredVariables()),
        errorReporter));
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
  }

  void test_visitConditionalExpression_nonConstantElse() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.identifier3("x");
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(
            new TestTypeProvider(), new DeclaredVariables()),
        errorReporter));
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  void test_visitConditionalExpression_nonConstantThen() {
    Expression thenExpression = AstFactory.identifier3("x");
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(
            new TestTypeProvider(), new DeclaredVariables()),
        errorReporter));
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  void test_visitConditionalExpression_true() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(
        1,
        expression.accept(new ConstantVisitor(
            new ConstantEvaluationEngine(
                new TestTypeProvider(), new DeclaredVariables()),
            errorReporter)));
    errorListener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_className() {
    CompilationUnit compilationUnit = resolveSource('''
const a = C;
class C {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    ClassElement element = result.value;
    expect(element.name, 'C');
  }

  void test_visitSimpleIdentifier_dynamic() {
    CompilationUnit compilationUnit = resolveSource('''
const a = dynamic;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    expect(result.value, typeProvider.dynamicType.element);
  }

  void test_visitSimpleIdentifier_inEnvironment() {
    CompilationUnit compilationUnit = resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["b"] = six;
    _assertValue(6, _evaluateConstant(compilationUnit, "a", environment));
  }

  void test_visitSimpleIdentifier_notInEnvironment() {
    CompilationUnit compilationUnit = resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["c"] = six;
    _assertValue(3, _evaluateConstant(compilationUnit, "a", environment));
  }

  void test_visitSimpleIdentifier_withoutEnvironment() {
    CompilationUnit compilationUnit = resolveSource(r'''
const a = b;
const b = 3;''');
    _assertValue(3, _evaluateConstant(compilationUnit, "a", null));
  }

  void _assertValue(int expectedValue, DartObjectImpl result) {
    expect(result, isNotNull);
    expect(result.type.name, "int");
    expect(result.intValue, expectedValue);
  }

  NonExistingSource _dummySource() {
    String path = '/test.dart';
    return new NonExistingSource(path, toUri(path), UriKind.FILE_URI);
  }

  DartObjectImpl _evaluateConstant(CompilationUnit compilationUnit, String name,
      Map<String, DartObjectImpl> lexicalEnvironment) {
    Source source = compilationUnit.element.source;
    Expression expression =
        findTopLevelConstantExpression(compilationUnit, name);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables()),
        errorReporter,
        lexicalEnvironment: lexicalEnvironment));
    errorListener.assertNoErrors();
    return result;
  }
}

@reflectiveTest
class ContentCacheTest {
  void test_setContents() {
    Source source = new TestSource();
    ContentCache cache = new ContentCache();
    expect(cache.getContents(source), isNull);
    expect(cache.getModificationStamp(source), isNull);
    String contents = "library lib;";
    expect(cache.setContents(source, contents), isNull);
    expect(cache.getContents(source), contents);
    expect(cache.getModificationStamp(source), isNotNull);
    expect(cache.setContents(source, contents), contents);
    expect(cache.setContents(source, null), contents);
    expect(cache.getContents(source), isNull);
    expect(cache.getModificationStamp(source), isNull);
    expect(cache.setContents(source, null), isNull);
  }
}

@reflectiveTest
class CustomUriResolverTest {
  void test_creation() {
    expect(new CustomUriResolver({}), isNotNull);
  }

  void test_resolve_unknown_uri() {
    UriResolver resolver =
        new CustomUriResolver({'custom:library': '/path/to/library.dart',});
    Source result =
        resolver.resolveAbsolute(parseUriWithException("custom:non_library"));
    expect(result, isNull);
  }

  void test_resolve_uri() {
    String path =
        FileUtilities2.createFile("/path/to/library.dart").getAbsolutePath();
    UriResolver resolver = new CustomUriResolver({'custom:library': path,});
    Source result =
        resolver.resolveAbsolute(parseUriWithException("custom:library"));
    expect(result, isNotNull);
    expect(result.fullName, path);
  }
}

@reflectiveTest
class DartObjectImplTest extends EngineTestCase {
  TypeProvider _typeProvider = new TestTypeProvider();

  void test_add_knownDouble_knownDouble() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_add_knownDouble_knownInt() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _intValue(2));
  }

  void test_add_knownDouble_unknownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_add_knownDouble_unknownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_add_knownInt_knownInt() {
    _assertAdd(_intValue(3), _intValue(1), _intValue(2));
  }

  void test_add_knownInt_knownString() {
    _assertAdd(null, _intValue(1), _stringValue("2"));
  }

  void test_add_knownInt_unknownDouble() {
    _assertAdd(_doubleValue(null), _intValue(1), _doubleValue(null));
  }

  void test_add_knownInt_unknownInt() {
    _assertAdd(_intValue(null), _intValue(1), _intValue(null));
  }

  void test_add_knownString_knownInt() {
    _assertAdd(null, _stringValue("1"), _intValue(2));
  }

  void test_add_knownString_knownString() {
    _assertAdd(_stringValue("ab"), _stringValue("a"), _stringValue("b"));
  }

  void test_add_knownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue("a"), _stringValue(null));
  }

  void test_add_unknownDouble_knownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_add_unknownDouble_knownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_add_unknownInt_knownDouble() {
    _assertAdd(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_add_unknownInt_knownInt() {
    _assertAdd(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_add_unknownString_knownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue("b"));
  }

  void test_add_unknownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue(null));
  }

  void test_bitAnd_knownInt_knownInt() {
    _assertBitAnd(_intValue(2), _intValue(6), _intValue(3));
  }

  void test_bitAnd_knownInt_knownString() {
    _assertBitAnd(null, _intValue(6), _stringValue("3"));
  }

  void test_bitAnd_knownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitAnd_knownString_knownInt() {
    _assertBitAnd(null, _stringValue("6"), _intValue(3));
  }

  void test_bitAnd_unknownInt_knownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitAnd_unknownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitNot_knownInt() {
    _assertBitNot(_intValue(-4), _intValue(3));
  }

  void test_bitNot_knownString() {
    _assertBitNot(null, _stringValue("6"));
  }

  void test_bitNot_unknownInt() {
    _assertBitNot(_intValue(null), _intValue(null));
  }

  void test_bitOr_knownInt_knownInt() {
    _assertBitOr(_intValue(7), _intValue(6), _intValue(3));
  }

  void test_bitOr_knownInt_knownString() {
    _assertBitOr(null, _intValue(6), _stringValue("3"));
  }

  void test_bitOr_knownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitOr_knownString_knownInt() {
    _assertBitOr(null, _stringValue("6"), _intValue(3));
  }

  void test_bitOr_unknownInt_knownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitOr_unknownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitXor_knownInt_knownInt() {
    _assertBitXor(_intValue(5), _intValue(6), _intValue(3));
  }

  void test_bitXor_knownInt_knownString() {
    _assertBitXor(null, _intValue(6), _stringValue("3"));
  }

  void test_bitXor_knownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitXor_knownString_knownInt() {
    _assertBitXor(null, _stringValue("6"), _intValue(3));
  }

  void test_bitXor_unknownInt_knownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitXor_unknownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_concatenate_knownInt_knownString() {
    _assertConcatenate(null, _intValue(2), _stringValue("def"));
  }

  void test_concatenate_knownString_knownInt() {
    _assertConcatenate(null, _stringValue("abc"), _intValue(3));
  }

  void test_concatenate_knownString_knownString() {
    _assertConcatenate(
        _stringValue("abcdef"), _stringValue("abc"), _stringValue("def"));
  }

  void test_concatenate_knownString_unknownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue("abc"), _stringValue(null));
  }

  void test_concatenate_unknownString_knownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_divide_knownDouble_knownDouble() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_divide_knownDouble_knownInt() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _intValue(2));
  }

  void test_divide_knownDouble_unknownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_divide_knownDouble_unknownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_divide_knownInt_knownInt() {
    _assertDivide(_doubleValue(3.0), _intValue(6), _intValue(2));
  }

  void test_divide_knownInt_knownString() {
    _assertDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_divide_knownInt_unknownDouble() {
    _assertDivide(_doubleValue(null), _intValue(6), _doubleValue(null));
  }

  void test_divide_knownInt_unknownInt() {
    _assertDivide(_doubleValue(null), _intValue(6), _intValue(null));
  }

  void test_divide_knownString_knownInt() {
    _assertDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_divide_unknownDouble_knownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownDouble_knownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_divide_unknownInt_knownDouble() {
    _assertDivide(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownInt_knownInt() {
    _assertDivide(_doubleValue(null), _intValue(null), _intValue(2));
  }

  void test_equalEqual_bool_false() {
    _assertEqualEqual(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_equalEqual_bool_true() {
    _assertEqualEqual(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_equalEqual_bool_unknown() {
    _assertEqualEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_equalEqual_double_false() {
    _assertEqualEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_equalEqual_double_true() {
    _assertEqualEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_equalEqual_double_unknown() {
    _assertEqualEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_equalEqual_int_false() {
    _assertEqualEqual(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_equalEqual_int_true() {
    _assertEqualEqual(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_equalEqual_int_unknown() {
    _assertEqualEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_equalEqual_list_empty() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_list_false() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_map_empty() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_map_false() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_null() {
    _assertEqualEqual(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_equalEqual_string_false() {
    _assertEqualEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_equalEqual_string_true() {
    _assertEqualEqual(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_equalEqual_string_unknown() {
    _assertEqualEqual(
        _boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_equals_list_false_differentSizes() {
    expect(
        _listValue([_boolValue(true)]) ==
            _listValue([_boolValue(true), _boolValue(false)]),
        isFalse);
  }

  void test_equals_list_false_sameSize() {
    expect(_listValue([_boolValue(true)]) == _listValue([_boolValue(false)]),
        isFalse);
  }

  void test_equals_list_true_empty() {
    expect(_listValue(), _listValue());
  }

  void test_equals_list_true_nonEmpty() {
    expect(_listValue([_boolValue(true)]), _listValue([_boolValue(true)]));
  }

  void test_equals_map_true_empty() {
    expect(_mapValue(), _mapValue());
  }

  void test_equals_symbol_false() {
    expect(_symbolValue("a") == _symbolValue("b"), isFalse);
  }

  void test_equals_symbol_true() {
    expect(_symbolValue("a"), _symbolValue("a"));
  }

  void test_getValue_bool_false() {
    expect(_boolValue(false).value, false);
  }

  void test_getValue_bool_true() {
    expect(_boolValue(true).value, true);
  }

  void test_getValue_bool_unknown() {
    expect(_boolValue(null).value, isNull);
  }

  void test_getValue_double_known() {
    double value = 2.3;
    expect(_doubleValue(value).value, value);
  }

  void test_getValue_double_unknown() {
    expect(_doubleValue(null).value, isNull);
  }

  void test_getValue_int_known() {
    int value = 23;
    expect(_intValue(value).value, value);
  }

  void test_getValue_int_unknown() {
    expect(_intValue(null).value, isNull);
  }

  void test_getValue_list_empty() {
    Object result = _listValue().value;
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(0));
  }

  void test_getValue_list_valid() {
    Object result = _listValue([_intValue(23)]).value;
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(1));
  }

  void test_getValue_map_empty() {
    Object result = _mapValue().value;
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(0));
  }

  void test_getValue_map_valid() {
    Object result =
        _mapValue([_stringValue("key"), _stringValue("value")]).value;
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(1));
  }

  void test_getValue_null() {
    expect(_nullValue().value, isNull);
  }

  void test_getValue_string_known() {
    String value = "twenty-three";
    expect(_stringValue(value).value, value);
  }

  void test_getValue_string_unknown() {
    expect(_stringValue(null).value, isNull);
  }

  void test_greaterThan_knownDouble_knownDouble_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThan_knownDouble_knownDouble_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThan_knownDouble_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThan_knownDouble_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThan_knownDouble_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThan_knownDouble_unknownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThan_knownInt_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThan_knownInt_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _intValue(2), _intValue(1));
  }

  void test_greaterThan_knownInt_knownString() {
    _assertGreaterThan(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThan_knownInt_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThan_knownInt_unknownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThan_knownString_knownInt() {
    _assertGreaterThan(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThan_unknownDouble_knownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownDouble_knownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThan_unknownInt_knownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownInt_knownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThanOrEqual_knownDouble_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownDouble_unknownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_false() {
    _assertGreaterThanOrEqual(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_true() {
    _assertGreaterThanOrEqual(_boolValue(true), _intValue(2), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownString() {
    _assertGreaterThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThanOrEqual_knownInt_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownInt_unknownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThanOrEqual_knownString_knownInt() {
    _assertGreaterThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownDouble_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownDouble_knownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownInt_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownInt_knownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_hasExactValue_bool_false() {
    expect(_boolValue(false).hasExactValue, isTrue);
  }

  void test_hasExactValue_bool_true() {
    expect(_boolValue(true).hasExactValue, isTrue);
  }

  void test_hasExactValue_bool_unknown() {
    expect(_boolValue(null).hasExactValue, isTrue);
  }

  void test_hasExactValue_double_known() {
    expect(_doubleValue(2.3).hasExactValue, isTrue);
  }

  void test_hasExactValue_double_unknown() {
    expect(_doubleValue(null).hasExactValue, isTrue);
  }

  void test_hasExactValue_dynamic() {
    expect(_dynamicValue().hasExactValue, isFalse);
  }

  void test_hasExactValue_int_known() {
    expect(_intValue(23).hasExactValue, isTrue);
  }

  void test_hasExactValue_int_unknown() {
    expect(_intValue(null).hasExactValue, isTrue);
  }

  void test_hasExactValue_list_empty() {
    expect(_listValue().hasExactValue, isTrue);
  }

  void test_hasExactValue_list_invalid() {
    expect(_dynamicValue().hasExactValue, isFalse);
  }

  void test_hasExactValue_list_valid() {
    expect(_listValue([_intValue(23)]).hasExactValue, isTrue);
  }

  void test_hasExactValue_map_empty() {
    expect(_mapValue().hasExactValue, isTrue);
  }

  void test_hasExactValue_map_invalidKey() {
    expect(_mapValue([_dynamicValue(), _stringValue("value")]).hasExactValue,
        isFalse);
  }

  void test_hasExactValue_map_invalidValue() {
    expect(_mapValue([_stringValue("key"), _dynamicValue()]).hasExactValue,
        isFalse);
  }

  void test_hasExactValue_map_valid() {
    expect(
        _mapValue([_stringValue("key"), _stringValue("value")]).hasExactValue,
        isTrue);
  }

  void test_hasExactValue_null() {
    expect(_nullValue().hasExactValue, isTrue);
  }

  void test_hasExactValue_num() {
    expect(_numValue().hasExactValue, isFalse);
  }

  void test_hasExactValue_string_known() {
    expect(_stringValue("twenty-three").hasExactValue, isTrue);
  }

  void test_hasExactValue_string_unknown() {
    expect(_stringValue(null).hasExactValue, isTrue);
  }

  void test_identical_bool_false() {
    _assertIdentical(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_identical_bool_true() {
    _assertIdentical(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_identical_bool_unknown() {
    _assertIdentical(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_identical_double_false() {
    _assertIdentical(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_identical_double_true() {
    _assertIdentical(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_identical_double_unknown() {
    _assertIdentical(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_identical_int_false() {
    _assertIdentical(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_identical_int_true() {
    _assertIdentical(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_identical_int_unknown() {
    _assertIdentical(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_identical_list_empty() {
    _assertIdentical(_boolValue(true), _listValue(), _listValue());
  }

  void test_identical_list_false() {
    _assertIdentical(
        _boolValue(false), _listValue(), _listValue([_intValue(3)]));
  }

  void test_identical_map_empty() {
    _assertIdentical(_boolValue(true), _mapValue(), _mapValue());
  }

  void test_identical_map_false() {
    _assertIdentical(_boolValue(false), _mapValue(),
        _mapValue([_intValue(1), _intValue(2)]));
  }

  void test_identical_null() {
    _assertIdentical(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_identical_string_false() {
    _assertIdentical(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_identical_string_true() {
    _assertIdentical(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_identical_string_unknown() {
    _assertIdentical(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_integerDivide_knownDouble_knownDouble() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_integerDivide_knownDouble_knownInt() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _intValue(2));
  }

  void test_integerDivide_knownDouble_unknownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_integerDivide_knownDouble_unknownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_integerDivide_knownInt_knownInt() {
    _assertIntegerDivide(_intValue(3), _intValue(6), _intValue(2));
  }

  void test_integerDivide_knownInt_knownString() {
    _assertIntegerDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_integerDivide_knownInt_unknownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _doubleValue(null));
  }

  void test_integerDivide_knownInt_unknownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_integerDivide_knownString_knownInt() {
    _assertIntegerDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_integerDivide_unknownDouble_knownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownDouble_knownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(null), _intValue(2));
  }

  void test_integerDivide_unknownInt_knownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownInt_knownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_isBoolNumStringOrNull_bool_false() {
    expect(_boolValue(false).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_true() {
    expect(_boolValue(true).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_unknown() {
    expect(_boolValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_known() {
    expect(_doubleValue(2.3).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_unknown() {
    expect(_doubleValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_dynamic() {
    expect(_dynamicValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_known() {
    expect(_intValue(23).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_unknown() {
    expect(_intValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_list() {
    expect(_listValue().isBoolNumStringOrNull, isFalse);
  }

  void test_isBoolNumStringOrNull_null() {
    expect(_nullValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_num() {
    expect(_numValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_known() {
    expect(_stringValue("twenty-three").isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_unknown() {
    expect(_stringValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_lessThan_knownDouble_knownDouble_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThan_knownDouble_knownDouble_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThan_knownDouble_knownInt_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThan_knownDouble_knownInt_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThan_knownDouble_unknownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThan_knownDouble_unknownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThan_knownInt_knownInt_false() {
    _assertLessThan(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThan_knownInt_knownInt_true() {
    _assertLessThan(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThan_knownInt_knownString() {
    _assertLessThan(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThan_knownInt_unknownDouble() {
    _assertLessThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThan_knownInt_unknownInt() {
    _assertLessThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThan_knownString_knownInt() {
    _assertLessThan(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThan_unknownDouble_knownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownDouble_knownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThan_unknownInt_knownDouble() {
    _assertLessThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownInt_knownInt() {
    _assertLessThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_false() {
    _assertLessThanOrEqual(
        _boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_true() {
    _assertLessThanOrEqual(
        _boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_unknownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownDouble_unknownInt() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThanOrEqual_knownInt_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThanOrEqual_knownInt_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThanOrEqual_knownInt_knownString() {
    _assertLessThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThanOrEqual_knownInt_unknownDouble() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownInt_unknownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThanOrEqual_knownString_knownInt() {
    _assertLessThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThanOrEqual_unknownDouble_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownDouble_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_unknownInt_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownInt_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_logicalAnd_false_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalAnd_false_null() {
    try {
      _assertLogicalAnd(_boolValue(false), _boolValue(false), _nullValue());
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_false_string() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _boolValue(false), _stringValue("false"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_false_true() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_logicalAnd_null_false() {
    try {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_null_true() {
    try {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_string_false() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _stringValue("true"), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_string_true() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _stringValue("false"), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_true_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(true), _boolValue(false));
  }

  void test_logicalAnd_true_null() {
    _assertLogicalAnd(null, _boolValue(true), _nullValue());
  }

  void test_logicalAnd_true_string() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _boolValue(true), _stringValue("true"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_true_true() {
    _assertLogicalAnd(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_logicalNot_false() {
    _assertLogicalNot(_boolValue(true), _boolValue(false));
  }

  void test_logicalNot_null() {
    _assertLogicalNot(null, _nullValue());
  }

  void test_logicalNot_string() {
    try {
      _assertLogicalNot(_boolValue(true), _stringValue(null));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalNot_true() {
    _assertLogicalNot(_boolValue(false), _boolValue(true));
  }

  void test_logicalNot_unknown() {
    _assertLogicalNot(_boolValue(null), _boolValue(null));
  }

  void test_logicalOr_false_false() {
    _assertLogicalOr(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalOr_false_null() {
    _assertLogicalOr(null, _boolValue(false), _nullValue());
  }

  void test_logicalOr_false_string() {
    try {
      _assertLogicalOr(
          _boolValue(false), _boolValue(false), _stringValue("false"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_false_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_logicalOr_null_false() {
    try {
      _assertLogicalOr(_boolValue(false), _nullValue(), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_null_true() {
    try {
      _assertLogicalOr(_boolValue(true), _nullValue(), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_string_false() {
    try {
      _assertLogicalOr(
          _boolValue(false), _stringValue("true"), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_string_true() {
    try {
      _assertLogicalOr(
          _boolValue(true), _stringValue("false"), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_true_false() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(false));
  }

  void test_logicalOr_true_null() {
    try {
      _assertLogicalOr(_boolValue(true), _boolValue(true), _nullValue());
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_true_string() {
    try {
      _assertLogicalOr(
          _boolValue(true), _boolValue(true), _stringValue("true"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_true_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_minus_knownDouble_knownDouble() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _doubleValue(3.0));
  }

  void test_minus_knownDouble_knownInt() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _intValue(3));
  }

  void test_minus_knownDouble_unknownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _doubleValue(null));
  }

  void test_minus_knownDouble_unknownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _intValue(null));
  }

  void test_minus_knownInt_knownInt() {
    _assertMinus(_intValue(1), _intValue(4), _intValue(3));
  }

  void test_minus_knownInt_knownString() {
    _assertMinus(null, _intValue(4), _stringValue("3"));
  }

  void test_minus_knownInt_unknownDouble() {
    _assertMinus(_doubleValue(null), _intValue(4), _doubleValue(null));
  }

  void test_minus_knownInt_unknownInt() {
    _assertMinus(_intValue(null), _intValue(4), _intValue(null));
  }

  void test_minus_knownString_knownInt() {
    _assertMinus(null, _stringValue("4"), _intValue(3));
  }

  void test_minus_unknownDouble_knownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownDouble_knownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_minus_unknownInt_knownDouble() {
    _assertMinus(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownInt_knownInt() {
    _assertMinus(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_negated_double_known() {
    _assertNegated(_doubleValue(2.0), _doubleValue(-2.0));
  }

  void test_negated_double_unknown() {
    _assertNegated(_doubleValue(null), _doubleValue(null));
  }

  void test_negated_int_known() {
    _assertNegated(_intValue(-3), _intValue(3));
  }

  void test_negated_int_unknown() {
    _assertNegated(_intValue(null), _intValue(null));
  }

  void test_negated_string() {
    _assertNegated(null, _stringValue(null));
  }

  void test_notEqual_bool_false() {
    _assertNotEqual(_boolValue(false), _boolValue(true), _boolValue(true));
  }

  void test_notEqual_bool_true() {
    _assertNotEqual(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_notEqual_bool_unknown() {
    _assertNotEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_notEqual_double_false() {
    _assertNotEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_notEqual_double_true() {
    _assertNotEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_notEqual_double_unknown() {
    _assertNotEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_notEqual_int_false() {
    _assertNotEqual(_boolValue(false), _intValue(5), _intValue(5));
  }

  void test_notEqual_int_true() {
    _assertNotEqual(_boolValue(true), _intValue(-5), _intValue(5));
  }

  void test_notEqual_int_unknown() {
    _assertNotEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_notEqual_null() {
    _assertNotEqual(_boolValue(false), _nullValue(), _nullValue());
  }

  void test_notEqual_string_false() {
    _assertNotEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("abc"));
  }

  void test_notEqual_string_true() {
    _assertNotEqual(_boolValue(true), _stringValue("abc"), _stringValue("def"));
  }

  void test_notEqual_string_unknown() {
    _assertNotEqual(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_performToString_bool_false() {
    _assertPerformToString(_stringValue("false"), _boolValue(false));
  }

  void test_performToString_bool_true() {
    _assertPerformToString(_stringValue("true"), _boolValue(true));
  }

  void test_performToString_bool_unknown() {
    _assertPerformToString(_stringValue(null), _boolValue(null));
  }

  void test_performToString_double_known() {
    _assertPerformToString(_stringValue("2.0"), _doubleValue(2.0));
  }

  void test_performToString_double_unknown() {
    _assertPerformToString(_stringValue(null), _doubleValue(null));
  }

  void test_performToString_int_known() {
    _assertPerformToString(_stringValue("5"), _intValue(5));
  }

  void test_performToString_int_unknown() {
    _assertPerformToString(_stringValue(null), _intValue(null));
  }

  void test_performToString_null() {
    _assertPerformToString(_stringValue("null"), _nullValue());
  }

  void test_performToString_string_known() {
    _assertPerformToString(_stringValue("abc"), _stringValue("abc"));
  }

  void test_performToString_string_unknown() {
    _assertPerformToString(_stringValue(null), _stringValue(null));
  }

  void test_remainder_knownDouble_knownDouble() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _doubleValue(2.0));
  }

  void test_remainder_knownDouble_knownInt() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _intValue(2));
  }

  void test_remainder_knownDouble_unknownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(7.0), _doubleValue(null));
  }

  void test_remainder_knownDouble_unknownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_remainder_knownInt_knownInt() {
    _assertRemainder(_intValue(1), _intValue(7), _intValue(2));
  }

  void test_remainder_knownInt_knownString() {
    _assertRemainder(null, _intValue(7), _stringValue("2"));
  }

  void test_remainder_knownInt_unknownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(7), _doubleValue(null));
  }

  void test_remainder_knownInt_unknownInt() {
    _assertRemainder(_intValue(null), _intValue(7), _intValue(null));
  }

  void test_remainder_knownString_knownInt() {
    _assertRemainder(null, _stringValue("7"), _intValue(2));
  }

  void test_remainder_unknownDouble_knownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownDouble_knownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_remainder_unknownInt_knownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownInt_knownInt() {
    _assertRemainder(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_shiftLeft_knownInt_knownInt() {
    _assertShiftLeft(_intValue(48), _intValue(6), _intValue(3));
  }

  void test_shiftLeft_knownInt_knownString() {
    _assertShiftLeft(null, _intValue(6), _stringValue(null));
  }

  void test_shiftLeft_knownInt_tooLarge() {
    _assertShiftLeft(
        _intValue(null),
        _intValue(6),
        new DartObjectImpl(
            _typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftLeft_knownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_shiftLeft_knownString_knownInt() {
    _assertShiftLeft(null, _stringValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_knownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_shiftRight_knownInt_knownInt() {
    _assertShiftRight(_intValue(6), _intValue(48), _intValue(3));
  }

  void test_shiftRight_knownInt_knownString() {
    _assertShiftRight(null, _intValue(48), _stringValue(null));
  }

  void test_shiftRight_knownInt_tooLarge() {
    _assertShiftRight(
        _intValue(null),
        _intValue(48),
        new DartObjectImpl(
            _typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftRight_knownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(48), _intValue(null));
  }

  void test_shiftRight_knownString_knownInt() {
    _assertShiftRight(null, _stringValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_knownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_stringLength_int() {
    try {
      _assertStringLength(_intValue(null), _intValue(0));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_stringLength_knownString() {
    _assertStringLength(_intValue(3), _stringValue("abc"));
  }

  void test_stringLength_unknownString() {
    _assertStringLength(_intValue(null), _stringValue(null));
  }

  void test_times_knownDouble_knownDouble() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _doubleValue(3.0));
  }

  void test_times_knownDouble_knownInt() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _intValue(3));
  }

  void test_times_knownDouble_unknownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _doubleValue(null));
  }

  void test_times_knownDouble_unknownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _intValue(null));
  }

  void test_times_knownInt_knownInt() {
    _assertTimes(_intValue(6), _intValue(2), _intValue(3));
  }

  void test_times_knownInt_knownString() {
    _assertTimes(null, _intValue(2), _stringValue("3"));
  }

  void test_times_knownInt_unknownDouble() {
    _assertTimes(_doubleValue(null), _intValue(2), _doubleValue(null));
  }

  void test_times_knownInt_unknownInt() {
    _assertTimes(_intValue(null), _intValue(2), _intValue(null));
  }

  void test_times_knownString_knownInt() {
    _assertTimes(null, _stringValue("2"), _intValue(3));
  }

  void test_times_unknownDouble_knownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_times_unknownDouble_knownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_times_unknownInt_knownDouble() {
    _assertTimes(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_times_unknownInt_knownInt() {
    _assertTimes(_intValue(null), _intValue(null), _intValue(3));
  }

  /**
   * Assert that the result of adding the left and right operands is the expected value, or that the
   * operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertAdd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.add(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.add(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-anding the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitAnd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitAnd(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.bitAnd(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the bit-not of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.bitNot(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.bitNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-oring the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitOr(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitOr(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.bitOr(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-xoring the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitXor(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitXor(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.bitXor(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of concatenating the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertConcatenate(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.concatenate(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.concatenate(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of dividing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertDivide(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.divide(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.divide(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands for equality is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertEqualEqual(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.equalEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.equalEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertGreaterThan(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.greaterThan(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.greaterThan(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertGreaterThanOrEqual(DartObjectImpl expected,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands using
   * identical() is the expected value.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   */
  void _assertIdentical(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    DartObjectImpl result =
        leftOperand.isIdentical(_typeProvider, rightOperand);
    expect(result, isNotNull);
    expect(result, expected);
  }

  void _assertInstanceOfObjectArray(Object result) {
    // TODO(scheglov) implement
  }

  /**
   * Assert that the result of dividing the left and right operands as integers is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertIntegerDivide(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.integerDivide(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.integerDivide(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLessThan(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.lessThan(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.lessThan(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLessThanOrEqual(DartObjectImpl expected,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-anding the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalAnd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.logicalAnd(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.logicalAnd(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the logical-not of the operand is the expected value, or that the operation throws
   * an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.logicalNot(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.logicalNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-oring the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalOr(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.logicalOr(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.logicalOr(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of subtracting the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertMinus(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.minus(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.minus(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the negation of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertNegated(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.negated(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.negated(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands for inequality is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertNotEqual(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.notEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.notEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that converting the operand to a string is the expected value, or that the operation
   * throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertPerformToString(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.performToString(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.performToString(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of taking the remainder of the left and right operands is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertRemainder(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.remainder(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.remainder(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertShiftLeft(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.shiftLeft(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.shiftLeft(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertShiftRight(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.shiftRight(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.shiftRight(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the length of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertStringLength(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.stringLength(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.stringLength(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertTimes(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.times(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.times(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  DartObjectImpl _boolValue(bool value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.boolType, BoolState.UNKNOWN_VALUE);
    } else if (identical(value, false)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.FALSE_STATE);
    } else if (identical(value, true)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.TRUE_STATE);
    }
    fail("Invalid boolean value used in test");
    return null;
  }

  DartObjectImpl _doubleValue(double value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.doubleType, new DoubleState(value));
    }
  }

  DartObjectImpl _dynamicValue() {
    return new DartObjectImpl(
        _typeProvider.nullType, DynamicState.DYNAMIC_STATE);
  }

  DartObjectImpl _intValue(int value) {
    if (value == null) {
      return new DartObjectImpl(_typeProvider.intType, IntState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(_typeProvider.intType, new IntState(value));
    }
  }

  DartObjectImpl _listValue(
      [List<DartObjectImpl> elements = DartObjectImpl.EMPTY_LIST]) {
    return new DartObjectImpl(_typeProvider.listType, new ListState(elements));
  }

  DartObjectImpl _mapValue(
      [List<DartObjectImpl> keyElementPairs = DartObjectImpl.EMPTY_LIST]) {
    Map<DartObjectImpl, DartObjectImpl> map =
        new Map<DartObjectImpl, DartObjectImpl>();
    int count = keyElementPairs.length;
    for (int i = 0; i < count;) {
      map[keyElementPairs[i++]] = keyElementPairs[i++];
    }
    return new DartObjectImpl(_typeProvider.mapType, new MapState(map));
  }

  DartObjectImpl _nullValue() {
    return new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
  }

  DartObjectImpl _numValue() {
    return new DartObjectImpl(_typeProvider.nullType, NumState.UNKNOWN_VALUE);
  }

  DartObjectImpl _stringValue(String value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.stringType, StringState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.stringType, new StringState(value));
    }
  }

  DartObjectImpl _symbolValue(String value) {
    return new DartObjectImpl(_typeProvider.symbolType, new SymbolState(value));
  }
}

@reflectiveTest
class DartUriResolverTest {
  void test_creation() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    expect(new DartUriResolver(sdk), isNotNull);
  }

  void test_isDartUri_null_scheme() {
    Uri uri = parseUriWithException("foo.dart");
    expect('', uri.scheme);
    expect(DartUriResolver.isDartUri(uri), isFalse);
  }

  void test_resolve_dart() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNotNull);
  }

  void test_resolve_dart_nonExistingLibrary() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result = resolver.resolveAbsolute(parseUriWithException("dart:cor"));
    expect(result, isNull);
  }

  void test_resolve_nonDart() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result = resolver
        .resolveAbsolute(parseUriWithException("package:some/file.dart"));
    expect(result, isNull);
  }
}

@reflectiveTest
class DeclaredVariablesTest extends EngineTestCase {
  void test_getBool_false() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "false");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.boolValue, false);
  }

  void test_getBool_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "not true");
    _assertNullDartObject(
        typeProvider, variables.getBool(typeProvider, variableName));
  }

  void test_getBool_true() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "true");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.boolValue, true);
  }

  void test_getBool_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(
        typeProvider.boolType, variables.getBool(typeProvider, variableName));
  }

  void test_getInt_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "four score and seven years");
    _assertNullDartObject(
        typeProvider, variables.getInt(typeProvider, variableName));
  }

  void test_getInt_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(
        typeProvider.intType, variables.getInt(typeProvider, variableName));
  }

  void test_getInt_valid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "23");
    DartObject object = variables.getInt(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.intValue, 23);
  }

  void test_getString_defined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    String value = "value";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, value);
    DartObject object = variables.getString(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.stringValue, value);
  }

  void test_getString_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(typeProvider.stringType,
        variables.getString(typeProvider, variableName));
  }

  void _assertNullDartObject(TestTypeProvider typeProvider, DartObject result) {
    expect(result.type, typeProvider.nullType);
  }

  void _assertUnknownDartObject(
      ParameterizedType expectedType, DartObject result) {
    expect((result as DartObjectImpl).isUnknown, isTrue);
    expect(result.type, expectedType);
  }
}

@reflectiveTest
class DirectoryBasedDartSdkTest {
  void fail_getDocFileFor() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile docFile = sdk.getDocFileFor("html");
    expect(docFile, isNotNull);
  }

  void test_creation() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    expect(sdk, isNotNull);
  }

  void test_fromFile_invalid() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    expect(
        sdk.fromFileUri(new JavaFile("/not/in/the/sdk.dart").toURI()), isNull);
  }

  void test_fromFile_library() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(new JavaFile.relative(
            new JavaFile.relative(sdk.libraryDirectory, "core"), "core.dart")
        .toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core");
  }

  void test_fromFile_part() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(new JavaFile.relative(
            new JavaFile.relative(sdk.libraryDirectory, "core"), "num.dart")
        .toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core/num.dart");
  }

  void test_getDart2JsExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.dart2JsExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_getDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.directory;
    expect(directory, isNotNull);
    expect(directory.exists(), isTrue);
  }

  void test_getDocDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.docDirectory;
    expect(directory, isNotNull);
  }

  void test_getLibraryDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.libraryDirectory;
    expect(directory, isNotNull);
    expect(directory.exists(), isTrue);
  }

  void test_getPubExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.pubExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_getSdkVersion() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    String version = sdk.sdkVersion;
    expect(version, isNotNull);
    expect(version.length > 0, isTrue);
  }

  void test_getVmExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.vmExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  DirectoryBasedDartSdk _createDartSdk() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull,
        reason:
            "No SDK configured; set the property 'com.google.dart.sdk' on the command line");
    return new DirectoryBasedDartSdk(sdkDirectory);
  }
}

@reflectiveTest
class DirectoryBasedSourceContainerTest {
  void test_contains() {
    JavaFile dir = FileUtilities2.createFile("/does/not/exist");
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist/some.dart");
    JavaFile file2 =
        FileUtilities2.createFile("/does/not/exist/folder/some2.dart");
    JavaFile file3 = FileUtilities2.createFile("/does/not/exist3/some3.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    FileBasedSource source3 = new FileBasedSource(file3);
    DirectoryBasedSourceContainer container =
        new DirectoryBasedSourceContainer.con1(dir);
    expect(container.contains(source1), isTrue);
    expect(container.contains(source2), isTrue);
    expect(container.contains(source3), isFalse);
  }
}

@reflectiveTest
class ElementBuilderTest extends EngineTestCase {
  void test_visitCatchClause() {
    // } catch (e, s) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String exceptionParameterName = "e";
    String stackParameterName = "s";
    CatchClause clause =
        AstFactory.catchClause2(exceptionParameterName, stackParameterName);
    clause.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(2));
    VariableElement exceptionVariable = variables[0];
    expect(exceptionVariable, isNotNull);
    expect(exceptionVariable.name, exceptionParameterName);
    expect(exceptionVariable.hasImplicitType, isTrue);
    expect(exceptionVariable.isSynthetic, isFalse);
    expect(exceptionVariable.isConst, isFalse);
    expect(exceptionVariable.isFinal, isFalse);
    expect(exceptionVariable.initializer, isNull);
    VariableElement stackVariable = variables[1];
    expect(stackVariable, isNotNull);
    expect(stackVariable.name, stackParameterName);
    expect(stackVariable.isSynthetic, isFalse);
    expect(stackVariable.isConst, isFalse);
    expect(stackVariable.isFinal, isFalse);
    expect(stackVariable.initializer, isNull);
  }

  void test_visitCatchClause_withType() {
    // } on E catch (e) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String exceptionParameterName = "e";
    CatchClause clause = AstFactory.catchClause4(
        AstFactory.typeName4('E'), exceptionParameterName);
    clause.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(1));
    VariableElement exceptionVariable = variables[0];
    expect(exceptionVariable, isNotNull);
    expect(exceptionVariable.name, exceptionParameterName);
    expect(exceptionVariable.hasImplicitType, isFalse);
  }

  void test_visitClassDeclaration_abstract() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        Keyword.ABSTRACT, className, null, null, null, null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isTrue);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration =
        AstFactory.classDeclaration(null, className, null, null, null, null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_parameterized() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    String firstVariableName = "E";
    String secondVariableName = "F";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([firstVariableName, secondVariableName]),
        null,
        null,
        null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstVariableName);
    expect(typeParameters[1].name, secondVariableName);
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_withMembers() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "C";
    String typeParameterName = "E";
    String fieldName = "f";
    String methodName = "m";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([typeParameterName]),
        null,
        null,
        null, [
      AstFactory.fieldDeclaration2(
          false, null, [AstFactory.variableDeclaration(fieldName)]),
      AstFactory.methodDeclaration2(
          null,
          null,
          null,
          null,
          AstFactory.identifier3(methodName),
          AstFactory.formalParameterList(),
          AstFactory.blockFunctionBody2())
    ]);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, typeParameterName);
    List<FieldElement> fields = type.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, fieldName);
    List<MethodElement> methods = type.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
  }

  void test_visitClassTypeAlias() {
    // class B {}
    // class M {}
    // class C = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C', null, null, AstFactory.typeName(classB, []), withClause, null);
    alias.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(alias.element, same(type));
    expect(type.name, equals('C'));
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isTrue);
    expect(type.isSynthetic, isFalse);
    expect(type.typeParameters, isEmpty);
    expect(type.fields, isEmpty);
    expect(type.methods, isEmpty);
  }

  void test_visitClassTypeAlias_abstract() {
    // class B {}
    // class M {}
    // abstract class C = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias('C', null,
        Keyword.ABSTRACT, AstFactory.typeName(classB, []), withClause, null);
    classCAst.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.isAbstract, isTrue);
    expect(type.isMixinApplication, isTrue);
  }

  void test_visitClassTypeAlias_typeParams() {
    // class B {}
    // class M {}
    // class C<T> = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElementImpl classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias(
        'C',
        AstFactory.typeParameterList(['T']),
        null,
        AstFactory.typeName(classB, []),
        withClause,
        null);
    classCAst.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.typeParameters, hasLength(1));
    expect(type.typeParameters[0].name, equals('T'));
  }

  void test_visitConstructorDeclaration_external() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration = AstFactory
        .constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isTrue);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_factory() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration = AstFactory
        .constructorDeclaration2(
            null,
            Keyword.FACTORY,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isTrue);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration = AstFactory
        .constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_named() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration constructorDeclaration = AstFactory
        .constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            constructorName,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, constructorName);
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.name.staticElement, same(constructor));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitConstructorDeclaration_unnamed() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration = AstFactory
        .constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitDeclaredIdentifier_noType() {
    // var i
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    var variableName = 'i';
    DeclaredIdentifier identifier =
        AstFactory.declaredIdentifier3(variableName);
    AstFactory.forEachStatement(
        identifier, AstFactory.nullLiteral(), AstFactory.emptyStatement());
    identifier.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(1));
    LocalVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.isConst, isFalse);
    expect(variable.isDeprecated, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isOverride, isFalse);
    expect(variable.isPrivate, isFalse);
    expect(variable.isPublic, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.name, variableName);
  }

  void test_visitDeclaredIdentifier_type() {
    // E i
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    var variableName = 'i';
    DeclaredIdentifier identifier =
        AstFactory.declaredIdentifier4(AstFactory.typeName4('E'), variableName);
    AstFactory.forEachStatement(
        identifier, AstFactory.nullLiteral(), AstFactory.emptyStatement());
    identifier.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(1));
    LocalVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isFalse);
    expect(variable.isConst, isFalse);
    expect(variable.isDeprecated, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isOverride, isFalse);
    expect(variable.isPrivate, isFalse);
    expect(variable.isPublic, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.name, variableName);
  }

  void test_visitDefaultFormalParameter_noType() {
    // p = 0
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = 'p';
    DefaultFormalParameter formalParameter = AstFactory
        .positionalFormalParameter(
            AstFactory.simpleFormalParameter3(parameterName),
            AstFactory.integer(0));
    formalParameter.accept(builder);

    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter.hasImplicitType, isTrue);
    expect(parameter.isConst, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isInitializingFormal, isFalse);
    expect(parameter.isOverride, isFalse);
    expect(parameter.isPrivate, isFalse);
    expect(parameter.isPublic, isTrue);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
  }

  void test_visitDefaultFormalParameter_type() {
    // E p = 0
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = 'p';
    DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter4(
            AstFactory.typeName4('E'), parameterName),
        AstFactory.integer(0));
    formalParameter.accept(builder);

    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter.hasImplicitType, isFalse);
    expect(parameter.isConst, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isInitializingFormal, isFalse);
    expect(parameter.isOverride, isFalse);
    expect(parameter.isPrivate, isFalse);
    expect(parameter.isPublic, isTrue);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
  }

  void test_visitEnumDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String enumName = "E";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2(enumName, ["ONE"]);
    enumDeclaration.accept(builder);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    ClassElement enumElement = enums[0];
    expect(enumElement, isNotNull);
    expect(enumElement.name, enumName);
  }

  void test_visitFieldDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String firstFieldName = "x";
    String secondFieldName = "y";
    FieldDeclaration fieldDeclaration =
        AstFactory.fieldDeclaration2(false, null, [
      AstFactory.variableDeclaration(firstFieldName),
      AstFactory.variableDeclaration(secondFieldName)
    ]);
    fieldDeclaration.accept(builder);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(2));
    FieldElement firstField = fields[0];
    expect(firstField, isNotNull);
    expect(firstField.name, firstFieldName);
    expect(firstField.initializer, isNull);
    expect(firstField.isConst, isFalse);
    expect(firstField.isFinal, isFalse);
    expect(firstField.isSynthetic, isFalse);
    FieldElement secondField = fields[1];
    expect(secondField, isNotNull);
    expect(secondField.name, secondFieldName);
    expect(secondField.initializer, isNull);
    expect(secondField.isConst, isFalse);
    expect(secondField.isFinal, isFalse);
    expect(secondField.isSynthetic, isFalse);
  }

  void test_visitFieldFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter =
        AstFactory.fieldFormalParameter(null, null, parameterName);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(0));
  }

  void test_visitFieldFormalParameter_funtionTyped() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter = AstFactory.fieldFormalParameter(
        null,
        null,
        parameterName,
        AstFactory
            .formalParameterList([AstFactory.simpleFormalParameter3("a")]));
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(1));
  }

  void test_visitFormalParameterList() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String firstParameterName = "a";
    String secondParameterName = "b";
    FormalParameterList parameterList = AstFactory.formalParameterList([
      AstFactory.simpleFormalParameter3(firstParameterName),
      AstFactory.simpleFormalParameter3(secondParameterName)
    ]);
    parameterList.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
  }

  void test_visitFunctionDeclaration_external() {
    // external f();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        null,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.emptyFunctionBody()));
    declaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    declaration.accept(builder);

    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.name, functionName);
    expect(declaration.element, same(function));
    expect(declaration.functionExpression.element, same(function));
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isExternal, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionDeclaration_getter() {
    // get f() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.GET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.accept(builder);

    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    expect(accessor.name, functionName);
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.hasImplicitReturnType, isTrue);
    expect(accessor.isGetter, isTrue);
    expect(accessor.isExternal, isFalse);
    expect(accessor.isSetter, isFalse);
    expect(accessor.isSynthetic, isFalse);
    expect(accessor.typeParameters, hasLength(0));
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionDeclaration_plain() {
    // T f() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        AstFactory.typeName4('T'),
        null,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.accept(builder);

    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.hasImplicitReturnType, isFalse);
    expect(function.name, functionName);
    expect(declaration.element, same(function));
    expect(declaration.functionExpression.element, same(function));
    expect(function.isExternal, isFalse);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionDeclaration_setter() {
    // set f() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.SET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.accept(builder);

    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    expect(accessor.hasImplicitReturnType, isFalse);
    expect(accessor.name, "$functionName=");
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.isGetter, isFalse);
    expect(accessor.isExternal, isFalse);
    expect(accessor.isSetter, isTrue);
    expect(accessor.isSynthetic, isFalse);
    expect(accessor.typeParameters, hasLength(0));
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionDeclaration_typeParameters() {
    // f<E>() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String functionName = 'f';
    String typeParameterName = 'E';
    FunctionExpression expression = AstFactory.functionExpression3(
        AstFactory.typeParameterList([typeParameterName]),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    FunctionDeclaration declaration =
        AstFactory.functionDeclaration(null, null, functionName, expression);
    declaration.accept(builder);

    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.name, functionName);
    expect(function.isExternal, isFalse);
    expect(function.isSynthetic, isFalse);
    expect(declaration.element, same(function));
    expect(expression.element, same(function));
    List<TypeParameterElement> typeParameters = function.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, typeParameterName);
  }

  void test_visitFunctionExpression() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    FunctionExpression expression = AstFactory.functionExpression2(
        AstFactory.formalParameterList(), AstFactory.blockFunctionBody2());
    expression.accept(builder);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(expression.element, same(function));
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionTypeAlias() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    String parameterName = "E";
    FunctionTypeAlias aliasNode = AstFactory.typeAlias(
        null, aliasName, AstFactory.typeParameterList([parameterName]), null);
    aliasNode.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, parameterName);
  }

  void test_visitFunctionTypedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstFactory.functionTypedFormalParameter(null, parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    SourceRange visibleRange = parameter.visibleRange;
    expect(100, visibleRange.offset);
    expect(110, visibleRange.end);
  }

  void test_visitFunctionTypedFormalParameter_withTypeParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstFactory.functionTypedFormalParameter(null, parameterName);
    formalParameter.typeParameters = AstFactory.typeParameterList(['F']);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.typeParameters, hasLength(1));
    SourceRange visibleRange = parameter.visibleRange;
    expect(100, visibleRange.offset);
    expect(110, visibleRange.end);
  }

  void test_visitLabeledStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String labelName = "l";
    LabeledStatement statement = AstFactory.labeledStatement(
        [AstFactory.label2(labelName)], AstFactory.breakStatement());
    statement.accept(builder);
    List<LabelElement> labels = holder.labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, labelName);
    expect(label.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_abstract() {
    // m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isTrue);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_external() {
    // external m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isTrue);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_getter() {
    // get m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isFalse);
    expect(getter.isExternal, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_abstract() {
    // get m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isTrue);
    expect(getter.isExternal, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_external() {
    // external get m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isFalse);
    expect(getter.isExternal, isTrue);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_minimal() {
    // T m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        AstFactory.typeName4('T'),
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isFalse);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_operator() {
    // operator +(addend) {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "+";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        Keyword.OPERATOR,
        AstFactory.identifier3(methodName),
        AstFactory
            .formalParameterList([AstFactory.simpleFormalParameter3("addend")]),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(1));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_setter() {
    // set m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.hasImplicitReturnType, isFalse);
    expect(setter.isAbstract, isFalse);
    expect(setter.isExternal, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_abstract() {
    // set m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.hasImplicitReturnType, isFalse);
    expect(setter.isAbstract, isTrue);
    expect(setter.isExternal, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_external() {
    // external m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.hasImplicitReturnType, isFalse);
    expect(setter.isAbstract, isFalse);
    expect(setter.isExternal, isTrue);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_static() {
    // static m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        Keyword.STATIC,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isTrue);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_typeParameters() {
    // m<E>() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.typeParameters = AstFactory.typeParameterList(['E']);
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(1));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_withMembers() {
    // m(p) { var v; try { l: return; } catch (e) {} }
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String methodName = "m";
    String parameterName = "p";
    String localVariableName = "v";
    String labelName = "l";
    String exceptionParameterName = "e";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(
            [AstFactory.simpleFormalParameter3(parameterName)]),
        AstFactory.blockFunctionBody2([
          AstFactory.variableDeclarationStatement2(
              Keyword.VAR, [AstFactory.variableDeclaration(localVariableName)]),
          AstFactory.tryStatement2(
              AstFactory.block([
                AstFactory.labeledStatement([AstFactory.label2(labelName)],
                    AstFactory.returnStatement())
              ]),
              [AstFactory.catchClause(exceptionParameterName)])
        ]));
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
    List<VariableElement> parameters = method.parameters;
    expect(parameters, hasLength(1));
    VariableElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    List<VariableElement> localVariables = method.localVariables;
    expect(localVariables, hasLength(2));
    VariableElement firstVariable = localVariables[0];
    VariableElement secondVariable = localVariables[1];
    expect(firstVariable, isNotNull);
    expect(secondVariable, isNotNull);
    expect(
        (firstVariable.name == localVariableName &&
                secondVariable.name == exceptionParameterName) ||
            (firstVariable.name == exceptionParameterName &&
                secondVariable.name == localVariableName),
        isTrue);
    List<LabelElement> labels = method.labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, labelName);
  }

  void test_visitNamedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3(parameterName),
        AstFactory.identifier3("42"));
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.NAMED);
    {
      SourceRange visibleRange = parameter.visibleRange;
      expect(100, visibleRange.offset);
      expect(110, visibleRange.end);
    }
    expect(parameter.defaultValueCode, "42");
    FunctionElement initializer = parameter.initializer;
    expect(initializer, isNotNull);
    expect(initializer.isSynthetic, isTrue);
  }

  void test_visitSimpleFormalParameter_noType() {
    // p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter =
        AstFactory.simpleFormalParameter3(parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isTrue);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    {
      SourceRange visibleRange = parameter.visibleRange;
      expect(100, visibleRange.offset);
      expect(110, visibleRange.end);
    }
  }

  void test_visitSimpleFormalParameter_type() {
    // T p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter = AstFactory.simpleFormalParameter4(
        AstFactory.typeName4('T'), parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isFalse);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    {
      SourceRange visibleRange = parameter.visibleRange;
      expect(100, visibleRange.offset);
      expect(110, visibleRange.end);
    }
  }

  void test_visitTypeAlias_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    TypeAlias typeAlias = AstFactory.typeAlias(null, aliasName, null, null);
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
  }

  void test_visitTypeAlias_withFormalParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    String firstParameterName = "x";
    String secondParameterName = "y";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList(),
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3(firstParameterName),
          AstFactory.simpleFormalParameter3(secondParameterName)
        ]));
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters, hasLength(0));
  }

  void test_visitTypeAlias_withTypeParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String aliasName = "F";
    String firstTypeParameterName = "A";
    String secondTypeParameterName = "B";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList(
            [firstTypeParameterName, secondTypeParameterName]),
        AstFactory.formalParameterList());
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, isNotNull);
    expect(parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstTypeParameterName);
    expect(typeParameters[1].name, secondTypeParameterName);
  }

  void test_visitTypeParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String parameterName = "E";
    TypeParameter typeParameter = AstFactory.typeParameter(parameterName);
    typeParameter.accept(builder);
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameterElement = typeParameters[0];
    expect(typeParameterElement, isNotNull);
    expect(typeParameterElement.name, parameterName);
    expect(typeParameterElement.bound, isNull);
    expect(typeParameterElement.isSynthetic, isFalse);
  }

  void test_visitVariableDeclaration_inConstructor() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    //
    // C() {var v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstFactory.variableDeclarationStatement2(null, [variable]);
    ConstructorDeclaration constructor = AstFactory.constructorDeclaration2(
        null,
        null,
        AstFactory.identifier3("C"),
        "C",
        AstFactory.formalParameterList(),
        null,
        AstFactory.blockFunctionBody2([statement]));
    constructor.accept(builder);

    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    List<LocalVariableElement> variableElements =
        constructors[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.hasImplicitType, isTrue);
    expect(variableElement.name, variableName);
  }

  void test_visitVariableDeclaration_inMethod() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    //
    // m() {T v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement = AstFactory.variableDeclarationStatement(
        null, AstFactory.typeName4('T'), [variable]);
    MethodDeclaration method = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.hasImplicitType, isFalse);
    expect(variableElement.name, variableName);
  }

  void test_visitVariableDeclaration_localNestedInFunction() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    //
    // var f = () {var v;};
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstFactory.variableDeclarationStatement2(null, [variable]);
    Expression initializer = AstFactory.functionExpression2(
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    String fieldName = "f";
    VariableDeclaration field =
        AstFactory.variableDeclaration2(fieldName, initializer);
    FieldDeclaration fieldDeclaration =
        AstFactory.fieldDeclaration2(false, null, [field]);
    fieldDeclaration.accept(builder);

    List<FieldElement> variables = holder.fields;
    expect(variables, hasLength(1));
    FieldElement fieldElement = variables[0];
    expect(fieldElement, isNotNull);
    FunctionElement initializerElement = fieldElement.initializer;
    expect(initializerElement, isNotNull);
    List<FunctionElement> functionElements = initializerElement.functions;
    expect(functionElements, hasLength(1));
    List<LocalVariableElement> variableElements =
        functionElements[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.hasImplicitType, isTrue);
    expect(variableElement.isConst, isFalse);
    expect(variableElement.isFinal, isFalse);
    expect(variableElement.isSynthetic, isFalse);
    expect(variableElement.name, variableName);
  }

  void test_visitVariableDeclaration_noInitializer() {
    // var v;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, null);
    AstFactory.variableDeclarationList2(null, [variableDeclaration]);
    variableDeclaration.accept(builder);

    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.initializer, isNull);
    expect(variable.name, variableName);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNotNull);
  }

  void test_visitVariableDeclaration_top_const_hasInitializer() {
    // const v = 42;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, AstFactory.integer(42));
    AstFactory.variableDeclarationList2(Keyword.CONST, [variableDeclaration]);
    variableDeclaration.accept(builder);

    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, new isInstanceOf<ConstTopLevelVariableElementImpl>());
    expect(variable.initializer, isNotNull);
    expect(variable.name, variableName);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.isConst, isTrue);
    expect(variable.isFinal, isFalse);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNull);
  }

  void test_visitVariableDeclaration_top_final() {
    // final v;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, null);
    AstFactory.variableDeclarationList2(Keyword.FINAL, [variableDeclaration]);
    variableDeclaration.accept(builder);
    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.initializer, isNull);
    expect(variable.name, variableName);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNull);
  }

  void _useParameterInMethod(
      FormalParameter formalParameter, int blockOffset, int blockEnd) {
    Block block = AstFactory.block();
    block.leftBracket.offset = blockOffset;
    block.rightBracket.offset = blockEnd - 1;
    BlockFunctionBody body = AstFactory.blockFunctionBody(block);
    AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("main"),
        AstFactory.formalParameterList([formalParameter]),
        body);
  }
}

@reflectiveTest
class ElementLocatorTest extends ResolverTestCase {
  void fail_locate_ExportDirective() {
    AstNode id = _findNodeIn("export", "export 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ImportElement, ImportElement, element);
  }

  void fail_locate_Identifier_libraryDirective() {
    AstNode id = _findNodeIn("foo", "library foo.bar;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  void fail_locate_Identifier_partOfDirective() {
    // Can't resolve the library element without the library declaration.
    //    AstNode id = findNodeIn("foo", "part of foo.bar;");
    //    Element element = ElementLocator.locate(id);
    //    assertInstanceOf(LibraryElement.class, element);
    fail("Test this case");
  }

  @override
  void reset() {
    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.hint = false;
    resetWithOptions(analysisOptions);
  }

  void test_locate_AssignmentExpression() {
    AstNode id = _findNodeIn(
        "+=",
        r'''
int x = 0;
void main() {
  x += 1;
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_BinaryExpression() {
    AstNode id = _findNodeIn("+", "var x = 3 + 4;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_ClassDeclaration() {
    AstNode id = _findNodeIn("class", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  void test_locate_CompilationUnit() {
    CompilationUnit cu = _resolveContents("// only comment");
    expect(cu.element, isNotNull);
    Element element = ElementLocator.locate(cu);
    expect(element, same(cu.element));
  }

  void test_locate_ConstructorDeclaration() {
    AstNode id = _findNodeIndexedIn(
        "bar",
        0,
        r'''
class A {
  A.bar() {}
}''');
    ConstructorDeclaration declaration =
        id.getAncestor((node) => node is ConstructorDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  void test_locate_FunctionDeclaration() {
    AstNode id = _findNodeIn("f", "int f() => 3;");
    FunctionDeclaration declaration =
        id.getAncestor((node) => node is FunctionDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement, FunctionElement, element);
  }

  void test_locate_Identifier_annotationClass_namedConstructor_forSimpleFormalParameter() {
    AstNode id = _findNodeIndexedIn(
        "Class",
        2,
        r'''
class Class {
  const Class.name();
}
void main(@Class.name() parameter) {
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  void test_locate_Identifier_annotationClass_unnamedConstructor_forSimpleFormalParameter() {
    AstNode id = _findNodeIndexedIn(
        "Class",
        2,
        r'''
class Class {
  const Class();
}
void main(@Class() parameter) {
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  void test_locate_Identifier_className() {
    AstNode id = _findNodeIn("A", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  void test_locate_Identifier_constructor_named() {
    AstNode id = _findNodeIndexedIn(
        "bar",
        0,
        r'''
class A {
  A.bar() {}
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  void test_locate_Identifier_constructor_unnamed() {
    AstNode id = _findNodeIndexedIn(
        "A",
        1,
        r'''
class A {
  A() {}
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  void test_locate_Identifier_fieldName() {
    AstNode id = _findNodeIn("x", "class A { var x; }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldElement, FieldElement, element);
  }

  void test_locate_Identifier_propertAccess() {
    AstNode id = _findNodeIn(
        "length",
        r'''
void main() {
 int x = 'foo'.length;
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement, element);
  }

  void test_locate_ImportDirective() {
    AstNode id = _findNodeIn("import", "import 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ImportElement, ImportElement, element);
  }

  void test_locate_IndexExpression() {
    AstNode id = _findNodeIndexedIn(
        "\\[",
        1,
        r'''
void main() {
  List x = [1, 2];
  var y = x[0];
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_InstanceCreationExpression() {
    AstNode node = _findNodeIndexedIn(
        "A(",
        0,
        r'''
class A {}
void main() {
 new A();
}''');
    Element element = ElementLocator.locate(node);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  void test_locate_InstanceCreationExpression_type_prefixedIdentifier() {
    // prepare: new pref.A()
    SimpleIdentifier identifier = AstFactory.identifier3("A");
    PrefixedIdentifier prefixedIdentifier =
        AstFactory.identifier4("pref", identifier);
    InstanceCreationExpression creation = AstFactory
        .instanceCreationExpression2(
            Keyword.NEW, AstFactory.typeName3(prefixedIdentifier));
    // set ClassElement
    ClassElement classElement = ElementFactory.classElement2("A");
    identifier.staticElement = classElement;
    // set ConstructorElement
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classElement, null);
    creation.constructorName.staticElement = constructorElement;
    // verify that "A" is resolved to ConstructorElement
    Element element = ElementLocator.locate(identifier);
    expect(element, same(classElement));
  }

  void test_locate_InstanceCreationExpression_type_simpleIdentifier() {
    // prepare: new A()
    SimpleIdentifier identifier = AstFactory.identifier3("A");
    InstanceCreationExpression creation = AstFactory
        .instanceCreationExpression2(
            Keyword.NEW, AstFactory.typeName3(identifier));
    // set ClassElement
    ClassElement classElement = ElementFactory.classElement2("A");
    identifier.staticElement = classElement;
    // set ConstructorElement
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classElement, null);
    creation.constructorName.staticElement = constructorElement;
    // verify that "A" is resolved to ConstructorElement
    Element element = ElementLocator.locate(identifier);
    expect(element, same(classElement));
  }

  void test_locate_LibraryDirective() {
    AstNode id = _findNodeIn("library", "library foo;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  void test_locate_MethodDeclaration() {
    AstNode id = _findNodeIn(
        "m",
        r'''
class A {
  void m() {}
}''');
    MethodDeclaration declaration =
        id.getAncestor((node) => node is MethodDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_MethodInvocation_method() {
    AstNode id = _findNodeIndexedIn(
        "bar",
        1,
        r'''
class A {
  int bar() => 42;
}
void main() {
 var f = new A().bar();
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_MethodInvocation_topLevel() {
    String code = r'''
foo(x) {}
void main() {
 foo(0);
}''';
    CompilationUnit cu = _resolveContents(code);
    int offset = code.indexOf('foo(0)');
    AstNode node = new NodeLocator(offset).searchWithin(cu);
    MethodInvocation invocation =
        node.getAncestor((n) => n is MethodInvocation);
    Element element = ElementLocator.locate(invocation);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement, FunctionElement, element);
  }

  void test_locate_PostfixExpression() {
    AstNode id = _findNodeIn("++", "int addOne(int x) => x++;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_PrefixedIdentifier() {
    AstNode id = _findNodeIn(
        "int",
        r'''
import 'dart:core' as core;
core.int value;''');
    PrefixedIdentifier identifier =
        id.getAncestor((node) => node is PrefixedIdentifier);
    Element element = ElementLocator.locate(identifier);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  void test_locate_PrefixExpression() {
    AstNode id = _findNodeIn("++", "int addOne(int x) => ++x;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_StringLiteral_exportUri() {
    addNamedSource("/foo.dart", "library foo;");
    AstNode id = _findNodeIn("'foo.dart'", "export 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  void test_locate_StringLiteral_expression() {
    AstNode id = _findNodeIn("abc", "var x = 'abc';");
    Element element = ElementLocator.locate(id);
    expect(element, isNull);
  }

  void test_locate_StringLiteral_importUri() {
    addNamedSource("/foo.dart", "library foo; class A {}");
    AstNode id =
        _findNodeIn("'foo.dart'", "import 'foo.dart'; class B extends A {}");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  void test_locate_StringLiteral_partUri() {
    addNamedSource("/foo.dart", "part of app;");
    AstNode id = _findNodeIn("'foo.dart'", "library app; part 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf((obj) => obj is CompilationUnitElement,
        CompilationUnitElement, element);
  }

  void test_locate_VariableDeclaration() {
    AstNode id = _findNodeIn("x", "var x = 'abc';");
    VariableDeclaration declaration =
        id.getAncestor((node) => node is VariableDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, element);
  }

  void test_locateWithOffset_BinaryExpression() {
    AstNode id = _findNodeIn("+", "var x = 3 + 4;");
    Element element = ElementLocator.locateWithOffset(id, 0);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locateWithOffset_StringLiteral() {
    AstNode id = _findNodeIn("abc", "var x = 'abc';");
    Element element = ElementLocator.locateWithOffset(id, 1);
    expect(element, isNull);
  }

  /**
   * Find the first AST node matching a pattern in the resolved AST for the given source.
   *
   * [nodePattern] the (unique) pattern used to identify the node of interest.
   * [code] the code to resolve.
   * Returns the matched node in the resolved AST for the given source lines.
   */
  AstNode _findNodeIn(String nodePattern, String code) {
    return _findNodeIndexedIn(nodePattern, 0, code);
  }

  /**
   * Find the AST node matching the given indexed occurrence of a pattern in the resolved AST for
   * the given source.
   *
   * [nodePattern] the pattern used to identify the node of interest.
   * [index] the index of the pattern match of interest.
   * [code] the code to resolve.
   * Returns the matched node in the resolved AST for the given source lines
   */
  AstNode _findNodeIndexedIn(String nodePattern, int index, String code) {
    CompilationUnit cu = _resolveContents(code);
    int start = _getOffsetOfMatch(code, nodePattern, index);
    int end = start + nodePattern.length;
    return new NodeLocator(start, end).searchWithin(cu);
  }

  int _getOffsetOfMatch(String contents, String pattern, int matchIndex) {
    if (matchIndex == 0) {
      return contents.indexOf(pattern);
    }
    JavaPatternMatcher matcher =
        new JavaPatternMatcher(new RegExp(pattern), contents);
    int count = 0;
    while (matcher.find()) {
      if (count == matchIndex) {
        return matcher.start();
      }
      ++count;
    }
    return -1;
  }

  /**
   * Parse, resolve and verify the given source lines to produce a fully
   * resolved AST.
   *
   * [code] the code to resolve.
   *
   * Returns the result of resolving the AST structure representing the content
   * of the source.
   *
   * Throws if source cannot be verified.
   */
  CompilationUnit _resolveContents(String code) {
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    return analysisContext.resolveCompilationUnit(source, library);
  }
}

@reflectiveTest
class EnumMemberBuilderTest extends EngineTestCase {
  void test_visitEnumDeclaration_multiple() {
    String firstName = "ONE";
    String secondName = "TWO";
    String thirdName = "THREE";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2("E", [firstName, secondName, thirdName]);

    ClassElement enumElement = _buildElement(enumDeclaration);
    List<FieldElement> fields = enumElement.fields;
    expect(fields, hasLength(5));

    FieldElement constant = fields[2];
    expect(constant, isNotNull);
    expect(constant.name, firstName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(constant);

    constant = fields[3];
    expect(constant, isNotNull);
    expect(constant.name, secondName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(constant);

    constant = fields[4];
    expect(constant, isNotNull);
    expect(constant.name, thirdName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(constant);
  }

  void test_visitEnumDeclaration_single() {
    String firstName = "ONE";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2("E", [firstName]);

    ClassElement enumElement = _buildElement(enumDeclaration);
    List<FieldElement> fields = enumElement.fields;
    expect(fields, hasLength(3));

    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, "index");
    expect(field.isStatic, isFalse);
    expect(field.isSynthetic, isTrue);
    _assertGetter(field);

    field = fields[1];
    expect(field, isNotNull);
    expect(field.name, "values");
    expect(field.isStatic, isTrue);
    expect(field.isSynthetic, isTrue);
    expect((field as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(field);

    FieldElement constant = fields[2];
    expect(constant, isNotNull);
    expect(constant.name, firstName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(constant);
  }

  void _assertGetter(FieldElement field) {
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.variable, same(field));
    expect(getter.type, isNotNull);
  }

  ClassElement _buildElement(EnumDeclaration enumDeclaration) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder elementBuilder = new ElementBuilder(holder);
    enumDeclaration.accept(elementBuilder);
    EnumMemberBuilder memberBuilder =
        new EnumMemberBuilder(new TestTypeProvider());
    enumDeclaration.accept(memberBuilder);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    return enums[0];
  }
}

@reflectiveTest
class ErrorReporterTest extends EngineTestCase {
  /**
   * Create a type with the given name in a compilation unit with the given name.
   *
   * @param fileName the name of the compilation unit containing the class
   * @param typeName the name of the type to be created
   * @return the type that was created
   */
  InterfaceType createType(String fileName, String typeName) {
    CompilationUnitElementImpl unit = ElementFactory.compilationUnit(fileName);
    ClassElementImpl element = ElementFactory.classElement2(typeName);
    unit.types = <ClassElement>[element];
    return element.type;
  }

  void test_creation() {
    GatheringErrorListener listener = new GatheringErrorListener();
    TestSource source = new TestSource();
    expect(new ErrorReporter(listener, source), isNotNull);
  }

  void test_reportErrorForElement_named() {
    DartType type = createType("/test1.dart", "A");
    ClassElement element = type.element;
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(listener, element.source);
    reporter.reportErrorForElement(
        StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
        element,
        ['A']);
    AnalysisError error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  void test_reportErrorForElement_unnamed() {
    ImportElementImpl element =
        ElementFactory.importFor(ElementFactory.library(null, ''), null);
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(
        listener,
        new NonExistingSource(
            '/test.dart', toUri('/test.dart'), UriKind.FILE_URI));
    reporter.reportErrorForElement(
        StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
        element,
        ['A']);
    AnalysisError error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  void test_reportTypeErrorForNode_differentNames() {
    DartType firstType = createType("/test1.dart", "A");
    DartType secondType = createType("/test2.dart", "B");
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") < 0, isTrue);
  }

  void test_reportTypeErrorForNode_sameName() {
    String typeName = "A";
    DartType firstType = createType("/test1.dart", typeName);
    DartType secondType = createType("/test2.dart", typeName);
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") >= 0, isTrue);
  }
}

@reflectiveTest
class ErrorSeverityTest extends EngineTestCase {
  void test_max_error_error() {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.ERROR),
        same(ErrorSeverity.ERROR));
  }

  void test_max_error_none() {
    expect(
        ErrorSeverity.ERROR.max(ErrorSeverity.NONE), same(ErrorSeverity.ERROR));
  }

  void test_max_error_warning() {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.ERROR));
  }

  void test_max_none_error() {
    expect(
        ErrorSeverity.NONE.max(ErrorSeverity.ERROR), same(ErrorSeverity.ERROR));
  }

  void test_max_none_none() {
    expect(
        ErrorSeverity.NONE.max(ErrorSeverity.NONE), same(ErrorSeverity.NONE));
  }

  void test_max_none_warning() {
    expect(ErrorSeverity.NONE.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.WARNING));
  }

  void test_max_warning_error() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.ERROR),
        same(ErrorSeverity.ERROR));
  }

  void test_max_warning_none() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.NONE),
        same(ErrorSeverity.WARNING));
  }

  void test_max_warning_warning() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.WARNING));
  }
}

/**
 * Tests for the [ExitDetector] that do not require that the AST be resolved.
 *
 * See [ExitDetectorTest2] for tests that require the AST to be resolved.
 */
@reflectiveTest
class ExitDetectorTest extends ParserTestCase {
  void fail_doStatement_continue_with_label() {
    _assertFalse("{ x: do { continue x; } while(true); }");
  }

  void fail_whileStatement_continue_with_label() {
    _assertFalse("{ x: while (true) { continue x; } }");
  }

  void fail_whileStatement_doStatement_scopeRequired() {
    _assertTrue("{ while (true) { x: do { continue x; } while(true); }");
  }

  void test_asExpression() {
    _assertFalse("a as Object;");
  }

  void test_asExpression_throw() {
    _assertTrue("throw '' as Object;");
  }

  void test_assertStatement() {
    _assertFalse("assert(a);");
  }

  void test_assertStatement_throw() {
    _assertFalse("assert((throw 0));");
  }

  void test_assignmentExpression() {
    _assertFalse("v = 1;");
  }

  void test_assignmentExpression_lhs_throw() {
    _assertTrue("a[throw ''] = 0;");
  }

  void test_assignmentExpression_rhs_throw() {
    _assertTrue("v = throw '';");
  }

  void test_await_false() {
    _assertFalse("await x;");
  }

  void test_await_throw_true() {
    _assertTrue("bool b = await (throw '' || true);");
  }

  void test_binaryExpression_and() {
    _assertFalse("a && b;");
  }

  void test_binaryExpression_and_lhs() {
    _assertTrue("throw '' && b;");
  }

  void test_binaryExpression_and_rhs() {
    _assertFalse("a && (throw '');");
  }

  void test_binaryExpression_and_rhs2() {
    _assertFalse("false && (throw '');");
  }

  void test_binaryExpression_and_rhs3() {
    _assertTrue("true && (throw '');");
  }

  void test_binaryExpression_ifNull() {
    _assertFalse("a ?? b;");
  }

  void test_binaryExpression_ifNull_lhs() {
    _assertTrue("throw '' ?? b;");
  }

  void test_binaryExpression_ifNull_rhs() {
    _assertFalse("a ?? (throw '');");
  }

  void test_binaryExpression_ifNull_rhs2() {
    _assertFalse("null ?? (throw '');");
  }

  void test_binaryExpression_or() {
    _assertFalse("a || b;");
  }

  void test_binaryExpression_or_lhs() {
    _assertTrue("throw '' || b;");
  }

  void test_binaryExpression_or_rhs() {
    _assertFalse("a || (throw '');");
  }

  void test_binaryExpression_or_rhs2() {
    _assertFalse("true || (throw '');");
  }

  void test_binaryExpression_or_rhs3() {
    _assertTrue("false || (throw '');");
  }

  void test_block_empty() {
    _assertFalse("{}");
  }

  void test_block_noReturn() {
    _assertFalse("{ int i = 0; }");
  }

  void test_block_return() {
    _assertTrue("{ return 0; }");
  }

  void test_block_returnNotLast() {
    _assertTrue("{ return 0; throw 'a'; }");
  }

  void test_block_throwNotLast() {
    _assertTrue("{ throw 0; x = null; }");
  }

  void test_cascadeExpression_argument() {
    _assertTrue("a..b(throw '');");
  }

  void test_cascadeExpression_index() {
    _assertTrue("a..[throw ''];");
  }

  void test_cascadeExpression_target() {
    _assertTrue("throw ''..b();");
  }

  void test_conditional_ifElse_bothThrows() {
    _assertTrue("c ? throw '' : throw '';");
  }

  void test_conditional_ifElse_elseThrows() {
    _assertFalse("c ? i : throw '';");
  }

  void test_conditional_ifElse_noThrow() {
    _assertFalse("c ? i : j;");
  }

  void test_conditional_ifElse_thenThrow() {
    _assertFalse("c ? throw '' : j;");
  }

  void test_conditionalAccess() {
    _assertFalse("a?.b;");
  }

  void test_conditionalAccess_lhs() {
    _assertTrue("(throw '')?.b;");
  }

  void test_conditionalAccessAssign() {
    _assertFalse("a?.b = c;");
  }

  void test_conditionalAccessAssign_lhs() {
    _assertTrue("(throw '')?.b = c;");
  }

  void test_conditionalAccessAssign_rhs() {
    _assertFalse("a?.b = throw '';");
  }

  void test_conditionalAccessAssign_rhs2() {
    _assertFalse("null?.b = throw '';");
  }

  void test_conditionalAccessIfNullAssign() {
    _assertFalse("a?.b ??= c;");
  }

  void test_conditionalAccessIfNullAssign_lhs() {
    _assertTrue("(throw '')?.b ??= c;");
  }

  void test_conditionalAccessIfNullAssign_rhs() {
    _assertFalse("a?.b ??= throw '';");
  }

  void test_conditionalAccessIfNullAssign_rhs2() {
    _assertFalse("null?.b ??= throw '';");
  }

  void test_conditionalCall() {
    _assertFalse("a?.b(c);");
  }

  void test_conditionalCall_lhs() {
    _assertTrue("(throw '')?.b(c);");
  }

  void test_conditionalCall_rhs() {
    _assertFalse("a?.b(throw '');");
  }

  void test_conditionalCall_rhs2() {
    _assertFalse("null?.b(throw '');");
  }

  void test_creation() {
    expect(new ExitDetector(), isNotNull);
  }

  void test_doStatement_throwCondition() {
    _assertTrue("{ do {} while (throw ''); }");
  }

  void test_doStatement_true_break() {
    _assertFalse("{ do { break; } while (true); }");
  }

  void test_doStatement_true_continue() {
    _assertTrue("{ do { continue; } while (true); }");
  }

  void test_doStatement_true_if_return() {
    _assertTrue("{ do { if (true) {return null;} } while (true); }");
  }

  void test_doStatement_true_noBreak() {
    _assertTrue("{ do {} while (true); }");
  }

  void test_doStatement_true_return() {
    _assertTrue("{ do { return null; } while (true);  }");
  }

  void test_emptyStatement() {
    _assertFalse(";");
  }

  void test_forEachStatement() {
    _assertFalse("for (element in list) {}");
  }

  void test_forEachStatement_throw() {
    _assertTrue("for (element in throw '') {}");
  }

  void test_forStatement_condition() {
    _assertTrue("for (; throw 0;) {}");
  }

  void test_forStatement_implicitTrue() {
    _assertTrue("for (;;) {}");
  }

  void test_forStatement_implicitTrue_break() {
    _assertFalse("for (;;) { break; }");
  }

  void test_forStatement_initialization() {
    _assertTrue("for (i = throw 0;;) {}");
  }

  void test_forStatement_true() {
    _assertTrue("for (; true; ) {}");
  }

  void test_forStatement_true_break() {
    _assertFalse("{ for (; true; ) { break; } }");
  }

  void test_forStatement_true_continue() {
    _assertTrue("{ for (; true; ) { continue; } }");
  }

  void test_forStatement_true_if_return() {
    _assertTrue("{ for (; true; ) { if (true) {return null;} } }");
  }

  void test_forStatement_true_noBreak() {
    _assertTrue("{ for (; true; ) {} }");
  }

  void test_forStatement_updaters() {
    _assertTrue("for (;; i++, throw 0) {}");
  }

  void test_forStatement_variableDeclaration() {
    _assertTrue("for (int i = throw 0;;) {}");
  }

  void test_functionExpression() {
    _assertFalse("(){};");
  }

  void test_functionExpression_bodyThrows() {
    _assertFalse("(int i) => throw '';");
  }

  void test_functionExpressionInvocation() {
    _assertFalse("f(g);");
  }

  void test_functionExpressionInvocation_argumentThrows() {
    _assertTrue("f(throw '');");
  }

  void test_functionExpressionInvocation_targetThrows() {
    _assertTrue("throw ''(g);");
  }

  void test_identifier_prefixedIdentifier() {
    _assertFalse("a.b;");
  }

  void test_identifier_simpleIdentifier() {
    _assertFalse("a;");
  }

  void test_if_false_else_return() {
    _assertTrue("if (false) {} else { return 0; }");
  }

  void test_if_false_noReturn() {
    _assertFalse("if (false) {}");
  }

  void test_if_false_return() {
    _assertFalse("if (false) { return 0; }");
  }

  void test_if_noReturn() {
    _assertFalse("if (c) i++;");
  }

  void test_if_return() {
    _assertFalse("if (c) return 0;");
  }

  void test_if_true_noReturn() {
    _assertFalse("if (true) {}");
  }

  void test_if_true_return() {
    _assertTrue("if (true) { return 0; }");
  }

  void test_ifElse_bothReturn() {
    _assertTrue("if (c) return 0; else return 1;");
  }

  void test_ifElse_elseReturn() {
    _assertFalse("if (c) i++; else return 1;");
  }

  void test_ifElse_noReturn() {
    _assertFalse("if (c) i++; else j++;");
  }

  void test_ifElse_thenReturn() {
    _assertFalse("if (c) return 0; else j++;");
  }

  void test_ifNullAssign() {
    _assertFalse("a ??= b;");
  }

  void test_ifNullAssign_rhs() {
    _assertFalse("a ??= throw '';");
  }

  void test_indexExpression() {
    _assertFalse("a[b];");
  }

  void test_indexExpression_index() {
    _assertTrue("a[throw ''];");
  }

  void test_indexExpression_target() {
    _assertTrue("throw ''[b];");
  }

  void test_instanceCreationExpression() {
    _assertFalse("new A(b);");
  }

  void test_instanceCreationExpression_argumentThrows() {
    _assertTrue("new A(throw '');");
  }

  void test_isExpression() {
    _assertFalse("A is B;");
  }

  void test_isExpression_throws() {
    _assertTrue("throw '' is B;");
  }

  void test_labeledStatement() {
    _assertFalse("label: a;");
  }

  void test_labeledStatement_throws() {
    _assertTrue("label: throw '';");
  }

  void test_literal_boolean() {
    _assertFalse("true;");
  }

  void test_literal_double() {
    _assertFalse("1.1;");
  }

  void test_literal_integer() {
    _assertFalse("1;");
  }

  void test_literal_null() {
    _assertFalse("null;");
  }

  void test_literal_String() {
    _assertFalse("'str';");
  }

  void test_methodInvocation() {
    _assertFalse("a.b(c);");
  }

  void test_methodInvocation_argument() {
    _assertTrue("a.b(throw '');");
  }

  void test_methodInvocation_target() {
    _assertTrue("throw ''.b(c);");
  }

  void test_parenthesizedExpression() {
    _assertFalse("(a);");
  }

  void test_parenthesizedExpression_throw() {
    _assertTrue("(throw '');");
  }

  void test_propertyAccess() {
    _assertFalse("new Object().a;");
  }

  void test_propertyAccess_throws() {
    _assertTrue("(throw '').a;");
  }

  void test_rethrow() {
    _assertTrue("rethrow;");
  }

  void test_return() {
    _assertTrue("return 0;");
  }

  void test_superExpression() {
    _assertFalse("super.a;");
  }

  void test_switch_allReturn() {
    _assertTrue("switch (i) { case 0: return 0; default: return 1; }");
  }

  void test_switch_defaultWithNoStatements() {
    _assertFalse("switch (i) { case 0: return 0; default: }");
  }

  void test_switch_fallThroughToNotReturn() {
    _assertFalse("switch (i) { case 0: case 1: break; default: return 1; }");
  }

  void test_switch_fallThroughToReturn() {
    _assertTrue("switch (i) { case 0: case 1: return 0; default: return 1; }");
  }

  void test_switch_noDefault() {
    _assertFalse("switch (i) { case 0: return 0; }");
  }

  void test_switch_nonReturn() {
    _assertFalse("switch (i) { case 0: i++; default: return 1; }");
  }

  void test_thisExpression() {
    _assertFalse("this.a;");
  }

  void test_throwExpression() {
    _assertTrue("throw new Object();");
  }

  void test_tryStatement_noReturn() {
    _assertFalse("try {} catch (e, s) {} finally {}");
  }

  void test_tryStatement_return_catch() {
    _assertFalse("try {} catch (e, s) { return 1; } finally {}");
  }

  void test_tryStatement_return_finally() {
    _assertTrue("try {} catch (e, s) {} finally { return 1; }");
  }

  void test_tryStatement_return_try() {
    _assertTrue("try { return 1; } catch (e, s) {} finally {}");
  }

  void test_variableDeclarationStatement_noInitializer() {
    _assertFalse("int i;");
  }

  void test_variableDeclarationStatement_noThrow() {
    _assertFalse("int i = 0;");
  }

  void test_variableDeclarationStatement_throw() {
    _assertTrue("int i = throw new Object();");
  }

  void test_whileStatement_false_nonReturn() {
    _assertFalse("{ while (false) {} }");
  }

  void test_whileStatement_throwCondition() {
    _assertTrue("{ while (throw '') {} }");
  }

  void test_whileStatement_true_break() {
    _assertFalse("{ while (true) { break; } }");
  }

  void test_whileStatement_true_continue() {
    _assertTrue("{ while (true) { continue; } }");
  }

  void test_whileStatement_true_if_return() {
    _assertTrue("{ while (true) { if (true) {return null;} } }");
  }

  void test_whileStatement_true_noBreak() {
    _assertTrue("{ while (true) {} }");
  }

  void test_whileStatement_true_return() {
    _assertTrue("{ while (true) { return null; } }");
  }

  void test_whileStatement_true_throw() {
    _assertTrue("{ while (true) { throw ''; } }");
  }

  void _assertFalse(String source) {
    _assertHasReturn(false, source);
  }

  void _assertHasReturn(bool expectedResult, String source) {
    Statement statement = ParserTestCase.parseStatement(source);
    expect(ExitDetector.exits(statement), expectedResult);
  }

  void _assertTrue(String source) {
    _assertHasReturn(true, source);
  }
}

/**
 * Tests for the [ExitDetector] that require that the AST be resolved.
 *
 * See [ExitDetectorTest] for tests that do not require the AST to be resolved.
 */
@reflectiveTest
class ExitDetectorTest2 extends ResolverTestCase {
  void test_switch_withEnum_false_noDefault() {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    case B:
      x = 'B';
  }
  return x;
}
''');
    LibraryElement element = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, element);
    FunctionDeclaration function = unit.declarations.last;
    BlockFunctionBody body = function.functionExpression.body;
    Statement statement = body.block.statements[1];
    expect(ExitDetector.exits(statement), false);
  }

  void test_switch_withEnum_false_withDefault() {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    default:
      x = '?';
  }
  return x;
}
''');
    LibraryElement element = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, element);
    FunctionDeclaration function = unit.declarations.last;
    BlockFunctionBody body = function.functionExpression.body;
    Statement statement = body.block.statements[1];
    expect(ExitDetector.exits(statement), false);
  }

  void test_switch_withEnum_true_noDefault() {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    case B:
      return 'B';
  }
}
''');
    LibraryElement element = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, element);
    FunctionDeclaration function = unit.declarations.last;
    BlockFunctionBody body = function.functionExpression.body;
    Statement statement = body.block.statements[0];
    expect(ExitDetector.exits(statement), true);
  }

  void test_switch_withEnum_true_withDefault() {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    default:
      return '?';
  }
}
''');
    LibraryElement element = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, element);
    FunctionDeclaration function = unit.declarations.last;
    BlockFunctionBody body = function.functionExpression.body;
    Statement statement = body.block.statements[0];
    expect(ExitDetector.exits(statement), true);
  }
}

@reflectiveTest
class FileBasedSourceTest {
  void test_equals_false_differentFiles() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist1.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist2.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source1 == source2, isFalse);
  }

  void test_equals_false_null() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist1.dart");
    FileBasedSource source1 = new FileBasedSource(file);
    expect(source1 == null, isFalse);
  }

  void test_equals_true() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source1 == source2, isTrue);
  }

  void test_fileReadMode() {
    expect(FileBasedSource.fileReadMode('a'), 'a');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\n');
    expect(FileBasedSource.fileReadMode('ab'), 'ab');
    expect(FileBasedSource.fileReadMode('abc'), 'abc');
    expect(FileBasedSource.fileReadMode('a\nb'), 'a\nb');
    expect(FileBasedSource.fileReadMode('a\rb'), 'a\rb');
    expect(FileBasedSource.fileReadMode('a\r\nb'), 'a\r\nb');
  }

  void test_fileReadMode_changed() {
    FileBasedSource.fileReadMode = (String s) => s + 'xyz';
    expect(FileBasedSource.fileReadMode('a'), 'axyz');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\nxyz');
    expect(FileBasedSource.fileReadMode('ab'), 'abxyz');
    expect(FileBasedSource.fileReadMode('abc'), 'abcxyz');
    FileBasedSource.fileReadMode = (String s) => s;
  }

  void test_fileReadMode_normalize_eol_always() {
    FileBasedSource.fileReadMode =
        PhysicalResourceProvider.NORMALIZE_EOL_ALWAYS;
    expect(FileBasedSource.fileReadMode('a'), 'a');

    // '\n' -> '\n' as first, last and only character
    expect(FileBasedSource.fileReadMode('\n'), '\n');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\n');
    expect(FileBasedSource.fileReadMode('\na'), '\na');

    // '\r\n' -> '\n' as first, last and only character
    expect(FileBasedSource.fileReadMode('\r\n'), '\n');
    expect(FileBasedSource.fileReadMode('a\r\n'), 'a\n');
    expect(FileBasedSource.fileReadMode('\r\na'), '\na');

    // '\r' -> '\n' as first, last and only character
    expect(FileBasedSource.fileReadMode('\r'), '\n');
    expect(FileBasedSource.fileReadMode('a\r'), 'a\n');
    expect(FileBasedSource.fileReadMode('\ra'), '\na');

    FileBasedSource.fileReadMode = (String s) => s;
  }

  void test_getEncoding() {
    SourceFactory factory = new SourceFactory([new FileUriResolver()]);
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource(file);
    expect(factory.fromEncoding(source.encoding), source);
  }

  void test_getFullName() {
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource(file);
    expect(source.fullName, file.getAbsolutePath());
  }

  void test_getShortName() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source.shortName, "exist.dart");
  }

  void test_hashCode() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source2.hashCode, source1.hashCode);
  }

  void test_isInSystemLibrary_contagious() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    SourceFactory factory = new SourceFactory([resolver]);
    // resolve dart:core
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNotNull);
    expect(result.isInSystemLibrary, isTrue);
    // system libraries reference only other system libraries
    Source partSource = factory.resolveUri(result, "num.dart");
    expect(partSource, isNotNull);
    expect(partSource.isInSystemLibrary, isTrue);
  }

  void test_isInSystemLibrary_false() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isFalse);
  }

  void test_issue14500() {
    // see https://code.google.com/p/dart/issues/detail?id=14500
    FileBasedSource source = new FileBasedSource(
        FileUtilities2.createFile("/some/packages/foo:bar.dart"));
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
  }

  void test_resolveRelative_dart_fileName() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource(file, parseUriWithException("dart:test"));
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/lib.dart");
  }

  void test_resolveRelative_dart_filePath() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource(file, parseUriWithException("dart:test"));
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/c/lib.dart");
  }

  void test_resolveRelative_dart_filePathWithParent() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(
        file, parseUriWithException("dart:test/b/test.dart"));
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/c/lib.dart");
  }

  void test_resolveRelative_file_fileName() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/lib.dart");
  }

  void test_resolveRelative_file_filePath() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/c/lib.dart");
  }

  void test_resolveRelative_file_filePathWithParent() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter, which I
      // believe is not consistent across all machines that might run this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/c/lib.dart");
  }

  void test_resolveRelative_package_fileName() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource(file, parseUriWithException("package:b/test.dart"));
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:b/lib.dart");
  }

  void test_resolveRelative_package_fileNameWithoutPackageName() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource(file, parseUriWithException("package:test.dart"));
    expect(source, isNotNull);
    Uri relative = source.resolveRelativeUri(parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:lib.dart");
  }

  void test_resolveRelative_package_filePath() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source =
        new FileBasedSource(file, parseUriWithException("package:b/test.dart"));
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:b/c/lib.dart");
  }

  void test_resolveRelative_package_filePathWithParent() {
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(
        file, parseUriWithException("package:a/b/test.dart"));
    expect(source, isNotNull);
    Uri relative =
        source.resolveRelativeUri(parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:a/c/lib.dart");
  }

  void test_system() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source =
        new FileBasedSource(file, parseUriWithException("dart:core"));
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isTrue);
  }
}

@reflectiveTest
class FileUriResolverTest {
  void test_creation() {
    expect(new FileUriResolver(), isNotNull);
  }

  void test_resolve_file() {
    UriResolver resolver = new FileUriResolver();
    Source result = resolver
        .resolveAbsolute(parseUriWithException("file:/does/not/exist.dart"));
    expect(result, isNotNull);
    expect(result.fullName,
        FileUtilities2.createFile("/does/not/exist.dart").getAbsolutePath());
  }

  void test_resolve_nonFile() {
    UriResolver resolver = new FileUriResolver();
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNull);
  }

  void test_restore() {
    UriResolver resolver = new FileUriResolver();
    Uri uri = parseUriWithException('file:///foo/bar.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(resolver.restoreAbsolute(source), uri);
    expect(
        resolver.restoreAbsolute(
            new NonExistingSource(source.fullName, null, null)),
        uri);
  }
}

@reflectiveTest
class HtmlParserTest extends EngineTestCase {
  /**
   * The name of the 'script' tag in an HTML file.
   */
  static String _TAG_SCRIPT = "script";
  void fail_parse_scriptWithComment() {
    String scriptBody = r'''
      /**
       *     <editable-label bind-value="dartAsignableValue">
       *     </editable-label>
       */
      class Foo {}''';
    ht.HtmlUnit htmlUnit = parse("""
<html>
  <body>
    <script type='application/dart'>
$scriptBody
    </script>
  </body>
</html>""");
    _validate(htmlUnit, [
      _t4("html", [
        _t4("body", [
          _t("script", _a(["type", "'application/dart'"]), scriptBody)
        ])
      ])
    ]);
  }

  ht.HtmlUnit parse(String contents) {
//    TestSource source =
//        new TestSource.con1(FileUtilities2.createFile("/test.dart"), contents);
    ht.AbstractScanner scanner = new ht.StringScanner(null, contents);
    scanner.passThroughElements = <String>[_TAG_SCRIPT];
    ht.Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    ht.HtmlUnit unit =
        new ht.HtmlParser(null, errorListener, options).parse(token, lineInfo);
    errorListener.assertNoErrors();
    return unit;
  }

  void test_parse_attribute() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
    _validate(htmlUnit, [
      _t4("html", [
        _t("body", _a(["foo", "\"sdfsdf\""]), "")
      ])
    ]);
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.attributes[0].text, "sdfsdf");
  }

  void test_parse_attribute_EOF() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"");
    _validate(htmlUnit, [
      _t4("html", [
        _t("body", _a(["foo", "\"sdfsdf\""]), "")
      ])
    ]);
  }

  void test_parse_attribute_EOF_missing_quote() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsd");
    _validate(htmlUnit, [
      _t4("html", [
        _t("body", _a(["foo", "\"sdfsd"]), "")
      ])
    ]);
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.attributes[0].text, "sdfsd");
  }

  void test_parse_attribute_extra_quote() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"\"></body></html>");
    _validate(htmlUnit, [
      _t4("html", [
        _t("body", _a(["foo", "\"sdfsdf\""]), "")
      ])
    ]);
  }

  void test_parse_attribute_single_quote() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo='sdfsdf'></body></html>");
    _validate(htmlUnit, [
      _t4("html", [
        _t("body", _a(["foo", "'sdfsdf'"]), "")
      ])
    ]);
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.attributes[0].text, "sdfsdf");
  }

  void test_parse_comment_embedded() {
    ht.HtmlUnit htmlUnit = parse("<html <!-- comment -->></html>");
    _validate(htmlUnit, [_t3("html", "")]);
  }

  void test_parse_comment_first() {
    ht.HtmlUnit htmlUnit = parse("<!-- comment --><html></html>");
    _validate(htmlUnit, [_t3("html", "")]);
  }

  void test_parse_comment_in_content() {
    ht.HtmlUnit htmlUnit = parse("<html><!-- comment --></html>");
    _validate(htmlUnit, [_t3("html", "<!-- comment -->")]);
  }

  void test_parse_content() {
    ht.HtmlUnit htmlUnit = parse("<html>\n<p a=\"b\">blat \n </p>\n</html>");
    // ht.XmlTagNode.getContent() does not include whitespace
    // between '<' and '>' at this time
    _validate(htmlUnit, [
      _t3("html", "\n<pa=\"b\">blat \n </p>\n", [
        _t("p", _a(["a", "\"b\""]), "blat \n ")
      ])
    ]);
  }

  void test_parse_content_none() {
    ht.HtmlUnit htmlUnit = parse("<html><p/>blat<p/></html>");
    _validate(htmlUnit, [
      _t3("html", "<p/>blat<p/>", [_t3("p", ""), _t3("p", "")])
    ]);
  }

  void test_parse_declaration() {
    ht.HtmlUnit htmlUnit = parse("<!DOCTYPE html>\n\n<html><p></p></html>");
    _validate(htmlUnit, [
      _t4("html", [_t3("p", "")])
    ]);
  }

  void test_parse_directive() {
    ht.HtmlUnit htmlUnit = parse("<?xml ?>\n\n<html><p></p></html>");
    _validate(htmlUnit, [
      _t4("html", [_t3("p", "")])
    ]);
  }

  void test_parse_getAttribute() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.getAttribute("foo").text, "sdfsdf");
    expect(bodyNode.getAttribute("bar"), null);
    expect(bodyNode.getAttribute(null), null);
  }

  void test_parse_getAttributeText() {
    ht.HtmlUnit htmlUnit = parse("<html><body foo=\"sdfsdf\"></body></html>");
    ht.XmlTagNode htmlNode = htmlUnit.tagNodes[0];
    ht.XmlTagNode bodyNode = htmlNode.tagNodes[0];
    expect(bodyNode.getAttributeText("foo"), "sdfsdf");
    expect(bodyNode.getAttributeText("bar"), null);
    expect(bodyNode.getAttributeText(null), null);
  }

  void test_parse_headers() {
    String code = r'''
<html>
  <body>
    <h2>000</h2>
    <div>
      111
    </div>
  </body>
</html>''';
    ht.HtmlUnit htmlUnit = parse(code);
    _validate(htmlUnit, [
      _t4("html", [
        _t4("body", [_t3("h2", "000"), _t4("div")])
      ])
    ]);
  }

  void test_parse_script() {
    ht.HtmlUnit htmlUnit =
        parse("<html><script >here is <p> some</script></html>");
    _validate(htmlUnit, [
      _t4("html", [_t3("script", "here is <p> some")])
    ]);
  }

  void test_parse_self_closing() {
    ht.HtmlUnit htmlUnit = parse("<html>foo<br>bar</html>");
    _validate(htmlUnit, [
      _t3("html", "foo<br>bar", [_t3("br", "")])
    ]);
  }

  void test_parse_self_closing_declaration() {
    ht.HtmlUnit htmlUnit = parse("<!DOCTYPE html><html>foo</html>");
    _validate(htmlUnit, [_t3("html", "foo")]);
  }

  XmlValidator_Attributes _a(List<String> keyValuePairs) =>
      new XmlValidator_Attributes(keyValuePairs);
  XmlValidator_Tag _t(
          String tag, XmlValidator_Attributes attributes, String content,
          [List<XmlValidator_Tag> children = XmlValidator_Tag.EMPTY_LIST]) =>
      new XmlValidator_Tag(tag, attributes, content, children);
  XmlValidator_Tag _t3(String tag, String content,
          [List<XmlValidator_Tag> children = XmlValidator_Tag.EMPTY_LIST]) =>
      new XmlValidator_Tag(
          tag, new XmlValidator_Attributes(), content, children);
  XmlValidator_Tag _t4(String tag,
          [List<XmlValidator_Tag> children = XmlValidator_Tag.EMPTY_LIST]) =>
      new XmlValidator_Tag(tag, new XmlValidator_Attributes(), null, children);
  void _validate(ht.HtmlUnit htmlUnit, List<XmlValidator_Tag> expectedTags) {
    XmlValidator validator = new XmlValidator();
    validator.expectTags(expectedTags);
    htmlUnit.accept(validator);
    validator.assertValid();
  }
}

@reflectiveTest
class HtmlTagInfoBuilderTest extends HtmlParserTest {
  void test_builder() {
    HtmlTagInfoBuilder builder = new HtmlTagInfoBuilder();
    ht.HtmlUnit unit = parse(r'''
<html>
  <body>
    <div id="x"></div>
    <p class='c'></p>
    <div class='c'></div>
  </body>
</html>''');
    unit.accept(builder);
    HtmlTagInfo info = builder.getTagInfo();
    expect(info, isNotNull);
    List<String> allTags = info.allTags;
    expect(allTags, hasLength(4));
    expect(info.getTagWithId("x"), "div");
    List<String> tagsWithClass = info.getTagsWithClass("c");
    expect(tagsWithClass, hasLength(2));
  }
}

@reflectiveTest
class HtmlUnitBuilderTest extends EngineTestCase {
  InternalAnalysisContext _context;
  @override
  void setUp() {
    _context = AnalysisContextFactory.contextWithCore();
  }

  @override
  void tearDown() {
    _context = null;
    super.tearDown();
  }

  void test_embedded_script() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart">foo=2;</script>
</html>''');
    _validate(element, [
      _s(_l([_v("foo")]))
    ]);
  }

  void test_embedded_script_no_content() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart"></script>
</html>''');
    _validate(element, [_s(_l())]);
  }

  void test_external_script() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart" src="other.dart"/>
</html>''');
    _validate(element, [_s2("other.dart")]);
  }

  void test_external_script_no_source() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart"/>
</html>''');
    _validate(element, [_s2(null)]);
  }

  void test_external_script_with_content() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart" src="other.dart">blat=2;</script>
</html>''');
    _validate(element, [_s2("other.dart")]);
  }

  void test_no_scripts() {
    HtmlElementImpl element = _build(r'''
<!DOCTYPE html>
<html><p></p></html>''');
    _validate(element, []);
  }

  void test_two_dart_scripts() {
    HtmlElementImpl element = _build(r'''
<html>
<script type="application/dart">bar=2;</script>
<script type="application/dart" src="other.dart"/>
<script src="dart.js"/>
</html>''');
    _validate(element, [
      _s(_l([_v("bar")])),
      _s2("other.dart")
    ]);
  }

  HtmlElementImpl _build(String contents) {
    TestSource source = new TestSource(
        FileUtilities2.createFile("/test.html").getAbsolutePath(), contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    HtmlUnitBuilder builder = new HtmlUnitBuilder(_context);
    return builder.buildHtmlElement(source, _context.parseHtmlUnit(source));
  }

  HtmlUnitBuilderTest_ExpectedLibrary _l(
          [List<HtmlUnitBuilderTest_ExpectedVariable> expectedVariables =
              HtmlUnitBuilderTest_ExpectedVariable.EMPTY_LIST]) =>
      new HtmlUnitBuilderTest_ExpectedLibrary(this, expectedVariables);
  _ExpectedScript _s(HtmlUnitBuilderTest_ExpectedLibrary expectedLibrary) =>
      new _ExpectedScript.con1(expectedLibrary);
  _ExpectedScript _s2(String scriptSourcePath) =>
      new _ExpectedScript.con2(scriptSourcePath);
  HtmlUnitBuilderTest_ExpectedVariable _v(String varName) =>
      new HtmlUnitBuilderTest_ExpectedVariable(varName);
  void _validate(
      HtmlElementImpl element, List<_ExpectedScript> expectedScripts) {
    expect(element.context, same(_context));
    List<HtmlScriptElement> scripts = element.scripts;
    expect(scripts, isNotNull);
    expect(scripts, hasLength(expectedScripts.length));
    for (int scriptIndex = 0; scriptIndex < scripts.length; scriptIndex++) {
      expectedScripts[scriptIndex]._validate(scriptIndex, scripts[scriptIndex]);
    }
  }
}

class HtmlUnitBuilderTest_ExpectedLibrary {
  final HtmlUnitBuilderTest HtmlUnitBuilderTest_this;
  final List<HtmlUnitBuilderTest_ExpectedVariable> _expectedVariables;
  HtmlUnitBuilderTest_ExpectedLibrary(this.HtmlUnitBuilderTest_this,
      [this._expectedVariables =
          HtmlUnitBuilderTest_ExpectedVariable.EMPTY_LIST]);
  void _validate(int scriptIndex, EmbeddedHtmlScriptElementImpl script) {
    LibraryElement library = script.scriptLibrary;
    expect(library, isNotNull, reason: "script $scriptIndex");
    expect(script.context, same(HtmlUnitBuilderTest_this._context),
        reason: "script $scriptIndex");
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull, reason: "script $scriptIndex");
    List<TopLevelVariableElement> variables = unit.topLevelVariables;
    expect(variables, hasLength(_expectedVariables.length));
    for (int index = 0; index < variables.length; index++) {
      _expectedVariables[index].validate(scriptIndex, variables[index]);
    }
    expect(library.enclosingElement, same(script),
        reason: "script $scriptIndex");
  }
}

class HtmlUnitBuilderTest_ExpectedVariable {
  static const List<HtmlUnitBuilderTest_ExpectedVariable> EMPTY_LIST =
      const <HtmlUnitBuilderTest_ExpectedVariable>[];
  final String _expectedName;
  HtmlUnitBuilderTest_ExpectedVariable(this._expectedName);
  void validate(int scriptIndex, TopLevelVariableElement variable) {
    expect(variable, isNotNull, reason: "script $scriptIndex");
    expect(variable.name, _expectedName, reason: "script $scriptIndex");
  }
}

/**
 * Instances of the class `HtmlWarningCodeTest` test the generation of HTML warning codes.
 */
@reflectiveTest
class HtmlWarningCodeTest extends EngineTestCase {
  /**
   * The analysis context used to resolve the HTML files.
   */
  InternalAnalysisContext _context;

  /**
   * The contents of the 'test.html' file.
   */
  String _contents;

  /**
   * The list of reported errors.
   */
  List<AnalysisError> _errors;
  @override
  void setUp() {
    _context = AnalysisContextFactory.contextWithCore();
  }

  @override
  void tearDown() {
    _context = null;
    _contents = null;
    _errors = null;
    super.tearDown();
  }

  void test_invalidUri() {
    _verify(
        r'''
<html>
<script type='application/dart' src='ht:'/>
</html>''',
        [HtmlWarningCode.INVALID_URI]);
    _assertErrorLocation2(_errors[0], "ht:");
  }

  void test_uriDoesNotExist() {
    _verify(
        r'''
<html>
<script type='application/dart' src='other.dart'/>
</html>''',
        [HtmlWarningCode.URI_DOES_NOT_EXIST]);
    _assertErrorLocation2(_errors[0], "other.dart");
  }

  void _assertErrorLocation(
      AnalysisError error, int expectedOffset, int expectedLength) {
    expect(error.offset, expectedOffset, reason: error.toString());
    expect(error.length, expectedLength, reason: error.toString());
  }

  void _assertErrorLocation2(AnalysisError error, String expectedString) {
    _assertErrorLocation(
        error, _contents.indexOf(expectedString), expectedString.length);
  }

  void _verify(String contents, List<ErrorCode> expectedErrorCodes) {
    this._contents = contents;
    TestSource source = new TestSource(
        FileUtilities2.createFile("/test.html").getAbsolutePath(), contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    HtmlUnitBuilder builder = new HtmlUnitBuilder(_context);
    builder.buildHtmlElement(source, _context.parseHtmlUnit(source));
    GatheringErrorListener errorListener = new GatheringErrorListener();
    errorListener.addAll2(builder.errorListener);
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
    _errors = errorListener.errors;
  }
}

/**
 * Instances of the class `MockDartSdk` implement a [DartSdk].
 */
class MockDartSdk implements DartSdk {
  @override
  AnalysisContext get context => null;

  @override
  List<SdkLibrary> get sdkLibraries => null;

  @override
  String get sdkVersion => null;

  @override
  List<String> get uris => null;

  @override
  Source fromFileUri(Uri uri) => null;

  @override
  SdkLibrary getSdkLibrary(String dartUri) => null;

  @override
  Source mapDartUri(String dartUri) => null;
}

@reflectiveTest
class ReferenceFinderTest extends EngineTestCase {
  DirectedGraph<ConstantEvaluationTarget> _referenceGraph;
  VariableElement _head;
  Element _tail;
  @override
  void setUp() {
    _referenceGraph = new DirectedGraph<ConstantEvaluationTarget>();
    _head = ElementFactory.topLevelVariableElement2("v1");
  }

  void test_visitSimpleIdentifier_const() {
    _visitNode(_makeTailVariable("v2", true));
    _assertOneArc(_tail);
  }

  void test_visitSimpleIdentifier_nonConst() {
    _visitNode(_makeTailVariable("v2", false));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_const() {
    _visitNode(_makeTailSuperConstructorInvocation("A", true));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_nonConst() {
    _visitNode(_makeTailSuperConstructorInvocation("A", false));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_unresolved() {
    SuperConstructorInvocation superConstructorInvocation =
        AstFactory.superConstructorInvocation();
    _visitNode(superConstructorInvocation);
    _assertNoArcs();
  }

  void _assertNoArcs() {
    Set<ConstantEvaluationTarget> tails = _referenceGraph.getTails(_head);
    expect(tails, hasLength(0));
  }

  void _assertOneArc(Element tail) {
    Set<ConstantEvaluationTarget> tails = _referenceGraph.getTails(_head);
    expect(tails, hasLength(1));
    expect(tails.first, same(tail));
  }

  ReferenceFinder _createReferenceFinder(ConstantEvaluationTarget source) =>
      new ReferenceFinder((ConstantEvaluationTarget dependency) {
        _referenceGraph.addEdge(source, dependency);
      });
  SuperConstructorInvocation _makeTailSuperConstructorInvocation(
      String name, bool isConst) {
    List<ConstructorInitializer> initializers =
        new List<ConstructorInitializer>();
    ConstructorDeclaration constructorDeclaration = AstFactory
        .constructorDeclaration(AstFactory.identifier3(name), null,
            AstFactory.formalParameterList(), initializers);
    if (isConst) {
      constructorDeclaration.constKeyword = new KeywordToken(Keyword.CONST, 0);
    }
    ClassElementImpl classElement = ElementFactory.classElement2(name);
    SuperConstructorInvocation superConstructorInvocation =
        AstFactory.superConstructorInvocation();
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement(classElement, name, isConst);
    _tail = constructorElement;
    superConstructorInvocation.staticElement = constructorElement;
    return superConstructorInvocation;
  }

  SimpleIdentifier _makeTailVariable(String name, bool isConst) {
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration(name);
    ConstLocalVariableElementImpl variableElement =
        ElementFactory.constLocalVariableElement(name);
    _tail = variableElement;
    variableElement.const3 = isConst;
    AstFactory.variableDeclarationList2(
        isConst ? Keyword.CONST : Keyword.VAR, [variableDeclaration]);
    SimpleIdentifier identifier = AstFactory.identifier3(name);
    identifier.staticElement = variableElement;
    return identifier;
  }

  void _visitNode(AstNode node) {
    node.accept(_createReferenceFinder(_head));
  }
}

@reflectiveTest
class SDKLibrariesReaderTest extends EngineTestCase {
  void test_readFrom_dart2js() {
    LibraryMap libraryMap = new SdkLibrariesReader(true).readFromFile(
        FileUtilities2.createFile("/libs.dart"),
        r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'first' : const LibraryInfo(
    'first/first.dart',
    category: 'First',
    documented: true,
    platforms: VM_PLATFORM,
    dart2jsPath: 'first/first_dart2js.dart'),
};''');
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 1);
    SdkLibrary first = libraryMap.getLibrary("dart:first");
    expect(first, isNotNull);
    expect(first.category, "First");
    expect(first.path, "first/first_dart2js.dart");
    expect(first.shortName, "dart:first");
    expect(first.isDart2JsLibrary, false);
    expect(first.isDocumented, true);
    expect(first.isImplementation, false);
    expect(first.isVmLibrary, true);
  }

  void test_readFrom_empty() {
    LibraryMap libraryMap = new SdkLibrariesReader(false)
        .readFromFile(FileUtilities2.createFile("/libs.dart"), "");
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 0);
  }

  void test_readFrom_normal() {
    LibraryMap libraryMap = new SdkLibrariesReader(false).readFromFile(
        FileUtilities2.createFile("/libs.dart"),
        r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'first' : const LibraryInfo(
    'first/first.dart',
    category: 'First',
    documented: true,
    platforms: VM_PLATFORM),

  'second' : const LibraryInfo(
    'second/second.dart',
    category: 'Second',
    documented: false,
    implementation: true,
    platforms: 0),
};''');
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 2);
    SdkLibrary first = libraryMap.getLibrary("dart:first");
    expect(first, isNotNull);
    expect(first.category, "First");
    expect(first.path, "first/first.dart");
    expect(first.shortName, "dart:first");
    expect(first.isDart2JsLibrary, false);
    expect(first.isDocumented, true);
    expect(first.isImplementation, false);
    expect(first.isVmLibrary, true);
    SdkLibrary second = libraryMap.getLibrary("dart:second");
    expect(second, isNotNull);
    expect(second.category, "Second");
    expect(second.path, "second/second.dart");
    expect(second.shortName, "dart:second");
    expect(second.isDart2JsLibrary, false);
    expect(second.isDocumented, false);
    expect(second.isImplementation, true);
    expect(second.isVmLibrary, false);
  }
}

@reflectiveTest
class StringScannerTest extends AbstractScannerTest {
  @override
  ht.AbstractScanner newScanner(String input) {
    return new ht.StringScanner(null, input);
  }
}

/**
 * Instances of the class `ToSourceVisitorTest`
 */
@reflectiveTest
class ToSourceVisitorTest extends EngineTestCase {
  void fail_visitHtmlScriptTagNode_attributes_content() {
    _assertSource(
        "<script type='application/dart'>f() {}</script>",
        HtmlFactory.scriptTagWithContent(
            "f() {}", [HtmlFactory.attribute("type", "'application/dart'")]));
  }

  void fail_visitHtmlScriptTagNode_noAttributes_content() {
    _assertSource(
        "<script>f() {}</script>", HtmlFactory.scriptTagWithContent("f() {}"));
  }

  void test_visitHtmlScriptTagNode_attributes_noContent() {
    _assertSource(
        "<script type='application/dart'/>",
        HtmlFactory
            .scriptTag([HtmlFactory.attribute("type", "'application/dart'")]));
  }

  void test_visitHtmlScriptTagNode_noAttributes_noContent() {
    _assertSource("<script/>", HtmlFactory.scriptTag());
  }

  void test_visitHtmlUnit_empty() {
    _assertSource("", new ht.HtmlUnit(null, new List<ht.XmlTagNode>(), null));
  }

  void test_visitHtmlUnit_nonEmpty() {
    _assertSource(
        "<html/>", new ht.HtmlUnit(null, [HtmlFactory.tagNode("html")], null));
  }

  void test_visitXmlAttributeNode() {
    _assertSource("x=y", HtmlFactory.attribute("x", "y"));
  }

  /**
   * Assert that a `ToSourceVisitor` will produce the expected source when visiting the given
   * node.
   *
   * @param expectedSource the source string that the visitor is expected to produce
   * @param node the AST node being visited to produce the actual source
   */
  void _assertSource(String expectedSource, ht.XmlNode node) {
    PrintStringWriter writer = new PrintStringWriter();
    node.accept(new ht.ToSourceVisitor(writer));
    expect(writer.toString(), expectedSource);
  }
}

@reflectiveTest
class UriKindTest {
  void test_fromEncoding() {
    expect(UriKind.fromEncoding(0x64), same(UriKind.DART_URI));
    expect(UriKind.fromEncoding(0x66), same(UriKind.FILE_URI));
    expect(UriKind.fromEncoding(0x70), same(UriKind.PACKAGE_URI));
    expect(UriKind.fromEncoding(0x58), same(null));
  }

  void test_getEncoding() {
    expect(UriKind.DART_URI.encoding, 0x64);
    expect(UriKind.FILE_URI.encoding, 0x66);
    expect(UriKind.PACKAGE_URI.encoding, 0x70);
  }
}

/**
 * Instances of `XmlValidator` traverse an [XmlNode] structure and validate the node
 * hierarchy.
 */
class XmlValidator extends ht.RecursiveXmlVisitor<Object> {
  /**
   * A list containing the errors found while traversing the AST structure.
   */
  List<String> _errors = new List<String>();
  /**
   * The tags to expect when visiting or `null` if tags should not be checked.
   */
  List<XmlValidator_Tag> _expectedTagsInOrderVisited;
  /**
   * The current index into the [expectedTagsInOrderVisited] array.
   */
  int _expectedTagsIndex = 0;
  /**
   * The key/value pairs to expect when visiting or `null` if attributes should not be
   * checked.
   */
  List<String> _expectedAttributeKeyValuePairs;
  /**
   * The current index into the [expectedAttributeKeyValuePairs].
   */
  int _expectedAttributeIndex = 0;
  /**
   * Assert that no errors were found while traversing any of the AST structures that have been
   * visited.
   */
  void assertValid() {
    while (_expectedTagsIndex < _expectedTagsInOrderVisited.length) {
      String expectedTag =
          _expectedTagsInOrderVisited[_expectedTagsIndex++]._tag;
      _errors.add("Expected to visit node with tag: $expectedTag");
    }
    if (!_errors.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Invalid XML structure:");
      for (String message in _errors) {
        buffer.writeln();
        buffer.write("   ");
        buffer.write(message);
      }
      fail(buffer.toString());
    }
  }

  /**
   * Set the tags to be expected when visiting
   *
   * @param expectedTags the expected tags
   */
  void expectTags(List<XmlValidator_Tag> expectedTags) {
    // Flatten the hierarchy into expected order in which the tags are visited
    List<XmlValidator_Tag> expected = new List<XmlValidator_Tag>();
    _expectTags(expected, expectedTags);
    this._expectedTagsInOrderVisited = expected;
  }

  @override
  Object visitHtmlUnit(ht.HtmlUnit node) {
    if (node.parent != null) {
      _errors.add("HtmlUnit should not have a parent");
    }
    if (node.endToken.type != ht.TokenType.EOF) {
      _errors.add("HtmlUnit end token should be of type EOF");
    }
    _validateNode(node);
    return super.visitHtmlUnit(node);
  }

  @override
  Object visitXmlAttributeNode(ht.XmlAttributeNode actual) {
    if (actual.parent is! ht.XmlTagNode) {
      _errors.add(
          "Expected ${actual.runtimeType} to have parent of type XmlTagNode");
    }
    String actualName = actual.name;
    String actualValue = actual.valueToken.lexeme;
    if (_expectedAttributeIndex < _expectedAttributeKeyValuePairs.length) {
      String expectedName =
          _expectedAttributeKeyValuePairs[_expectedAttributeIndex];
      if (expectedName != actualName) {
        _errors.add(
            "Expected ${_expectedTagsIndex - 1} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${_expectedAttributeIndex ~/ 2} to have name: $expectedName but found: $actualName");
      }
      String expectedValue =
          _expectedAttributeKeyValuePairs[_expectedAttributeIndex + 1];
      if (expectedValue != actualValue) {
        _errors.add(
            "Expected ${_expectedTagsIndex - 1} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${_expectedAttributeIndex ~/ 2} to have value: $expectedValue but found: $actualValue");
      }
    } else {
      _errors.add(
          "Unexpected ${_expectedTagsIndex - 1} tag: ${_expectedTagsInOrderVisited[_expectedTagsIndex - 1]._tag} attribute ${_expectedAttributeIndex ~/ 2} name: $actualName value: $actualValue");
    }
    _expectedAttributeIndex += 2;
    _validateNode(actual);
    return super.visitXmlAttributeNode(actual);
  }

  @override
  Object visitXmlTagNode(ht.XmlTagNode actual) {
    if (!(actual.parent is ht.HtmlUnit || actual.parent is ht.XmlTagNode)) {
      _errors.add(
          "Expected ${actual.runtimeType} to have parent of type HtmlUnit or XmlTagNode");
    }
    if (_expectedTagsInOrderVisited != null) {
      String actualTag = actual.tag;
      if (_expectedTagsIndex < _expectedTagsInOrderVisited.length) {
        XmlValidator_Tag expected =
            _expectedTagsInOrderVisited[_expectedTagsIndex];
        if (expected._tag != actualTag) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} but found: $actualTag");
        }
        _expectedAttributeKeyValuePairs = expected._attributes._keyValuePairs;
        int expectedAttributeCount =
            _expectedAttributeKeyValuePairs.length ~/ 2;
        int actualAttributeCount = actual.attributes.length;
        if (expectedAttributeCount != actualAttributeCount) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} to have $expectedAttributeCount attributes but found $actualAttributeCount");
        }
        _expectedAttributeIndex = 0;
        _expectedTagsIndex++;
        expect(actual.attributeEnd, isNotNull);
        expect(actual.contentEnd, isNotNull);
        int count = 0;
        ht.Token token = actual.attributeEnd.next;
        ht.Token lastToken = actual.contentEnd;
        while (!identical(token, lastToken)) {
          token = token.next;
          if (++count > 1000) {
            fail(
                "Expected $_expectedTagsIndex tag: ${expected._tag} to have a sequence of tokens from getAttributeEnd() to getContentEnd()");
            break;
          }
        }
        if (actual.attributeEnd.type == ht.TokenType.GT) {
          if (ht.HtmlParser.SELF_CLOSING.contains(actual.tag)) {
            expect(actual.closingTag, isNull);
          } else {
            expect(actual.closingTag, isNotNull);
          }
        } else if (actual.attributeEnd.type == ht.TokenType.SLASH_GT) {
          expect(actual.closingTag, isNull);
        } else {
          fail("Unexpected attribute end token: ${actual.attributeEnd.lexeme}");
        }
        if (expected._content != null && expected._content != actual.content) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} to have content '${expected._content}' but found '${actual.content}'");
        }
        if (expected._children.length != actual.tagNodes.length) {
          _errors.add(
              "Expected $_expectedTagsIndex tag: ${expected._tag} to have ${expected._children.length} children but found ${actual.tagNodes.length}");
        } else {
          for (int index = 0; index < expected._children.length; index++) {
            String expectedChildTag = expected._children[index]._tag;
            String actualChildTag = actual.tagNodes[index].tag;
            if (expectedChildTag != actualChildTag) {
              _errors.add(
                  "Expected $_expectedTagsIndex tag: ${expected._tag} child $index to have tag: $expectedChildTag but found: $actualChildTag");
            }
          }
        }
      } else {
        _errors.add("Visited unexpected tag: $actualTag");
      }
    }
    _validateNode(actual);
    return super.visitXmlTagNode(actual);
  }

  /**
   * Append the specified tags to the array in depth first order
   *
   * @param expected the array to which the tags are added (not `null`)
   * @param expectedTags the expected tags to be added (not `null`, contains no `null`s)
   */
  void _expectTags(
      List<XmlValidator_Tag> expected, List<XmlValidator_Tag> expectedTags) {
    for (XmlValidator_Tag tag in expectedTags) {
      expected.add(tag);
      _expectTags(expected, tag._children);
    }
  }

  void _validateNode(ht.XmlNode node) {
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
    ht.XmlNode parent = node.parent;
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

class XmlValidator_Attributes {
  final List<String> _keyValuePairs;
  XmlValidator_Attributes([this._keyValuePairs = StringUtilities.EMPTY_ARRAY]);
}

class XmlValidator_Tag {
  static const List<XmlValidator_Tag> EMPTY_LIST = const <XmlValidator_Tag>[];
  final String _tag;
  final XmlValidator_Attributes _attributes;
  final String _content;
  final List<XmlValidator_Tag> _children;
  XmlValidator_Tag(this._tag, this._attributes, this._content,
      [this._children = EMPTY_LIST]);
}

class _ExpectedScript {
  String _expectedExternalScriptName;
  HtmlUnitBuilderTest_ExpectedLibrary _expectedLibrary;
  _ExpectedScript.con1(HtmlUnitBuilderTest_ExpectedLibrary expectedLibrary) {
    this._expectedExternalScriptName = null;
    this._expectedLibrary = expectedLibrary;
  }
  _ExpectedScript.con2(String expectedExternalScriptPath) {
    this._expectedExternalScriptName = expectedExternalScriptPath;
    this._expectedLibrary = null;
  }
  void _validate(int scriptIndex, HtmlScriptElement script) {
    if (_expectedLibrary != null) {
      _validateEmbedded(scriptIndex, script);
    } else {
      _validateExternal(scriptIndex, script);
    }
  }

  void _validateEmbedded(int scriptIndex, HtmlScriptElement script) {
    if (script is! EmbeddedHtmlScriptElementImpl) {
      fail(
          "Expected script $scriptIndex to be embedded, but found ${script != null ? script.runtimeType : "null"}");
    }
    EmbeddedHtmlScriptElementImpl embeddedScript =
        script as EmbeddedHtmlScriptElementImpl;
    _expectedLibrary._validate(scriptIndex, embeddedScript);
  }

  void _validateExternal(int scriptIndex, HtmlScriptElement script) {
    if (script is! ExternalHtmlScriptElementImpl) {
      fail(
          "Expected script $scriptIndex to be external with src=$_expectedExternalScriptName but found ${script != null ? script.runtimeType : "null"}");
    }
    ExternalHtmlScriptElementImpl externalScript =
        script as ExternalHtmlScriptElementImpl;
    Source scriptSource = externalScript.scriptSource;
    if (_expectedExternalScriptName == null) {
      expect(scriptSource, isNull, reason: "script $scriptIndex");
    } else {
      expect(scriptSource, isNotNull, reason: "script $scriptIndex");
      String actualExternalScriptName = scriptSource.shortName;
      expect(actualExternalScriptName, _expectedExternalScriptName,
          reason: "script $scriptIndex");
    }
  }
}
