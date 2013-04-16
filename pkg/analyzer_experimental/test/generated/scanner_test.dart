// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.scanner_test;

import 'dart:collection';
import 'package:analyzer_experimental/src/generated/java_core.dart';
import 'package:analyzer_experimental/src/generated/java_engine.dart';
import 'package:analyzer_experimental/src/generated/java_junit.dart';
import 'package:analyzer_experimental/src/generated/source.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:unittest/unittest.dart' as _ut;
import 'test_support.dart';

class KeywordStateTest extends JUnitTestCase {
  void test_KeywordState() {
    List<Keyword> keywords = Keyword.values;
    int keywordCount = keywords.length;
    List<String> textToTest = new List<String>(keywordCount * 3);
    for (int i = 0; i < keywordCount; i++) {
      String syntax3 = keywords[i].syntax;
      textToTest[i] = syntax3;
      textToTest[i + keywordCount] = "${syntax3}x";
      textToTest[i + keywordCount * 2] = syntax3.substring(0, syntax3.length - 1);
    }
    KeywordState firstState = KeywordState.KEYWORD_STATE;
    for (int i = 0; i < textToTest.length; i++) {
      String text = textToTest[i];
      int index = 0;
      int length10 = text.length;
      KeywordState state = firstState;
      while (index < length10 && state != null) {
        state = state.next(text.codeUnitAt(index));
        index++;
      }
      if (i < keywordCount) {
        JUnitTestCase.assertNotNull(state);
        JUnitTestCase.assertNotNull(state.keyword());
        JUnitTestCase.assertEquals(keywords[i], state.keyword());
      } else if (i < keywordCount * 2) {
        JUnitTestCase.assertNull(state);
      } else {
        JUnitTestCase.assertNotNull(state);
      }
    }
  }
  static dartSuite() {
    _ut.group('KeywordStateTest', () {
      _ut.test('test_KeywordState', () {
        final __test = new KeywordStateTest();
        runJUnitTest(__test, __test.test_KeywordState);
      });
    });
  }
}
class TokenTypeTest extends EngineTestCase {
  void test_isOperator() {
    JUnitTestCase.assertTrue(TokenType.AMPERSAND.isOperator());
    JUnitTestCase.assertTrue(TokenType.AMPERSAND_AMPERSAND.isOperator());
    JUnitTestCase.assertTrue(TokenType.AMPERSAND_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.BANG.isOperator());
    JUnitTestCase.assertTrue(TokenType.BANG_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.BAR.isOperator());
    JUnitTestCase.assertTrue(TokenType.BAR_BAR.isOperator());
    JUnitTestCase.assertTrue(TokenType.BAR_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.CARET.isOperator());
    JUnitTestCase.assertTrue(TokenType.CARET_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.EQ_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.GT.isOperator());
    JUnitTestCase.assertTrue(TokenType.GT_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.GT_GT.isOperator());
    JUnitTestCase.assertTrue(TokenType.GT_GT_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.INDEX.isOperator());
    JUnitTestCase.assertTrue(TokenType.INDEX_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.IS.isOperator());
    JUnitTestCase.assertTrue(TokenType.LT.isOperator());
    JUnitTestCase.assertTrue(TokenType.LT_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.LT_LT.isOperator());
    JUnitTestCase.assertTrue(TokenType.LT_LT_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.MINUS.isOperator());
    JUnitTestCase.assertTrue(TokenType.MINUS_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.MINUS_MINUS.isOperator());
    JUnitTestCase.assertTrue(TokenType.PERCENT.isOperator());
    JUnitTestCase.assertTrue(TokenType.PERCENT_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.PERIOD_PERIOD.isOperator());
    JUnitTestCase.assertTrue(TokenType.PLUS.isOperator());
    JUnitTestCase.assertTrue(TokenType.PLUS_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.PLUS_PLUS.isOperator());
    JUnitTestCase.assertTrue(TokenType.QUESTION.isOperator());
    JUnitTestCase.assertTrue(TokenType.SLASH.isOperator());
    JUnitTestCase.assertTrue(TokenType.SLASH_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.STAR.isOperator());
    JUnitTestCase.assertTrue(TokenType.STAR_EQ.isOperator());
    JUnitTestCase.assertTrue(TokenType.TILDE.isOperator());
    JUnitTestCase.assertTrue(TokenType.TILDE_SLASH.isOperator());
    JUnitTestCase.assertTrue(TokenType.TILDE_SLASH_EQ.isOperator());
  }
  void test_isUserDefinableOperator() {
    JUnitTestCase.assertTrue(TokenType.AMPERSAND.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.BAR.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.CARET.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.EQ_EQ.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.GT.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.GT_EQ.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.GT_GT.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.INDEX.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.INDEX_EQ.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.LT.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.LT_EQ.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.LT_LT.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.MINUS.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.PERCENT.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.PLUS.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.SLASH.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.STAR.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.TILDE.isUserDefinableOperator());
    JUnitTestCase.assertTrue(TokenType.TILDE_SLASH.isUserDefinableOperator());
  }
  static dartSuite() {
    _ut.group('TokenTypeTest', () {
      _ut.test('test_isOperator', () {
        final __test = new TokenTypeTest();
        runJUnitTest(__test, __test.test_isOperator);
      });
      _ut.test('test_isUserDefinableOperator', () {
        final __test = new TokenTypeTest();
        runJUnitTest(__test, __test.test_isUserDefinableOperator);
      });
    });
  }
}
/**
 * The class {@code TokenFactory} defines utility methods that can be used to create tokens.
 */
class TokenFactory {
  static Token token(Keyword keyword) => new KeywordToken(keyword, 0);
  static Token token2(String lexeme) => new StringToken(TokenType.STRING, lexeme, 0);
  static Token token3(TokenType type) => new Token(type, 0);
  static Token token4(TokenType type, String lexeme) => new StringToken(type, lexeme, 0);
  /**
   * Prevent the creation of instances of this class.
   */
  TokenFactory() {
  }
}
class CharBufferScannerTest extends AbstractScannerTest {
  Token scan(String source, GatheringErrorListener listener) {
    CharBuffer buffer = CharBuffer.wrap(source);
    CharBufferScanner scanner = new CharBufferScanner(null, buffer, listener);
    Token result = scanner.tokenize();
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    return result;
  }
  static dartSuite() {
    _ut.group('CharBufferScannerTest', () {
      _ut.test('test_ampersand', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_ampersand);
      });
      _ut.test('test_ampersand_ampersand', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_ampersand_ampersand);
      });
      _ut.test('test_ampersand_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_ampersand_eq);
      });
      _ut.test('test_at', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_at);
      });
      _ut.test('test_backping', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_backping);
      });
      _ut.test('test_backslash', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_backslash);
      });
      _ut.test('test_bang', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_bang);
      });
      _ut.test('test_bang_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_bang_eq);
      });
      _ut.test('test_bar', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_bar);
      });
      _ut.test('test_bar_bar', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_bar_bar);
      });
      _ut.test('test_bar_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_bar_eq);
      });
      _ut.test('test_caret', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_caret);
      });
      _ut.test('test_caret_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_caret_eq);
      });
      _ut.test('test_close_curly_bracket', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_close_curly_bracket);
      });
      _ut.test('test_close_paren', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_close_paren);
      });
      _ut.test('test_close_quare_bracket', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_close_quare_bracket);
      });
      _ut.test('test_colon', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_colon);
      });
      _ut.test('test_comma', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_comma);
      });
      _ut.test('test_comment_multi', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_comment_multi);
      });
      _ut.test('test_comment_multi_unterminated', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_comment_multi_unterminated);
      });
      _ut.test('test_comment_nested', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_comment_nested);
      });
      _ut.test('test_comment_single', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_comment_single);
      });
      _ut.test('test_double_both_E', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_both_E);
      });
      _ut.test('test_double_both_e', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_both_e);
      });
      _ut.test('test_double_fraction', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_fraction);
      });
      _ut.test('test_double_fraction_D', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_D);
      });
      _ut.test('test_double_fraction_E', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_E);
      });
      _ut.test('test_double_fraction_Ed', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_Ed);
      });
      _ut.test('test_double_fraction_d', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_d);
      });
      _ut.test('test_double_fraction_e', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_e);
      });
      _ut.test('test_double_fraction_ed', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_ed);
      });
      _ut.test('test_double_missingDigitInExponent', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_missingDigitInExponent);
      });
      _ut.test('test_double_whole_D', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_whole_D);
      });
      _ut.test('test_double_whole_E', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_whole_E);
      });
      _ut.test('test_double_whole_Ed', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_whole_Ed);
      });
      _ut.test('test_double_whole_d', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_whole_d);
      });
      _ut.test('test_double_whole_e', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_whole_e);
      });
      _ut.test('test_double_whole_ed', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_double_whole_ed);
      });
      _ut.test('test_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_eq);
      });
      _ut.test('test_eq_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_eq_eq);
      });
      _ut.test('test_gt', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_gt);
      });
      _ut.test('test_gt_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_gt_eq);
      });
      _ut.test('test_gt_gt', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_gt_gt);
      });
      _ut.test('test_gt_gt_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_gt_gt_eq);
      });
      _ut.test('test_hash', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_hash);
      });
      _ut.test('test_hexidecimal', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_hexidecimal);
      });
      _ut.test('test_hexidecimal_missingDigit', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_hexidecimal_missingDigit);
      });
      _ut.test('test_identifier', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_identifier);
      });
      _ut.test('test_illegalChar', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_illegalChar);
      });
      _ut.test('test_index', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_index);
      });
      _ut.test('test_index_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_index_eq);
      });
      _ut.test('test_int', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_int);
      });
      _ut.test('test_int_initialZero', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_int_initialZero);
      });
      _ut.test('test_keyword_abstract', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_abstract);
      });
      _ut.test('test_keyword_as', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_as);
      });
      _ut.test('test_keyword_assert', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_assert);
      });
      _ut.test('test_keyword_break', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_break);
      });
      _ut.test('test_keyword_case', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_case);
      });
      _ut.test('test_keyword_catch', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_catch);
      });
      _ut.test('test_keyword_class', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_class);
      });
      _ut.test('test_keyword_const', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_const);
      });
      _ut.test('test_keyword_continue', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_continue);
      });
      _ut.test('test_keyword_default', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_default);
      });
      _ut.test('test_keyword_do', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_do);
      });
      _ut.test('test_keyword_dynamic', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_dynamic);
      });
      _ut.test('test_keyword_else', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_else);
      });
      _ut.test('test_keyword_enum', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_enum);
      });
      _ut.test('test_keyword_export', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_export);
      });
      _ut.test('test_keyword_extends', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_extends);
      });
      _ut.test('test_keyword_factory', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_factory);
      });
      _ut.test('test_keyword_false', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_false);
      });
      _ut.test('test_keyword_final', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_final);
      });
      _ut.test('test_keyword_finally', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_finally);
      });
      _ut.test('test_keyword_for', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_for);
      });
      _ut.test('test_keyword_get', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_get);
      });
      _ut.test('test_keyword_if', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_if);
      });
      _ut.test('test_keyword_implements', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_implements);
      });
      _ut.test('test_keyword_import', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_import);
      });
      _ut.test('test_keyword_in', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_in);
      });
      _ut.test('test_keyword_is', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_is);
      });
      _ut.test('test_keyword_library', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_library);
      });
      _ut.test('test_keyword_new', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_new);
      });
      _ut.test('test_keyword_null', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_null);
      });
      _ut.test('test_keyword_operator', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_operator);
      });
      _ut.test('test_keyword_part', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_part);
      });
      _ut.test('test_keyword_rethrow', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_rethrow);
      });
      _ut.test('test_keyword_return', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_return);
      });
      _ut.test('test_keyword_set', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_set);
      });
      _ut.test('test_keyword_static', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_static);
      });
      _ut.test('test_keyword_super', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_super);
      });
      _ut.test('test_keyword_switch', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_switch);
      });
      _ut.test('test_keyword_this', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_this);
      });
      _ut.test('test_keyword_throw', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_throw);
      });
      _ut.test('test_keyword_true', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_true);
      });
      _ut.test('test_keyword_try', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_try);
      });
      _ut.test('test_keyword_typedef', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_typedef);
      });
      _ut.test('test_keyword_var', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_var);
      });
      _ut.test('test_keyword_void', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_void);
      });
      _ut.test('test_keyword_while', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_while);
      });
      _ut.test('test_keyword_with', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_keyword_with);
      });
      _ut.test('test_lineInfo', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_lineInfo);
      });
      _ut.test('test_lt', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_lt);
      });
      _ut.test('test_lt_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_lt_eq);
      });
      _ut.test('test_lt_lt', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_lt_lt);
      });
      _ut.test('test_lt_lt_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_lt_lt_eq);
      });
      _ut.test('test_minus', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_minus);
      });
      _ut.test('test_minus_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_minus_eq);
      });
      _ut.test('test_minus_minus', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_minus_minus);
      });
      _ut.test('test_openSquareBracket', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_openSquareBracket);
      });
      _ut.test('test_open_curly_bracket', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_open_curly_bracket);
      });
      _ut.test('test_open_paren', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_open_paren);
      });
      _ut.test('test_open_square_bracket', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_open_square_bracket);
      });
      _ut.test('test_percent', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_percent);
      });
      _ut.test('test_percent_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_percent_eq);
      });
      _ut.test('test_period', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_period);
      });
      _ut.test('test_periodAfterNumberNotIncluded_identifier', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_periodAfterNumberNotIncluded_identifier);
      });
      _ut.test('test_periodAfterNumberNotIncluded_period', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_periodAfterNumberNotIncluded_period);
      });
      _ut.test('test_period_period', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_period_period);
      });
      _ut.test('test_period_period_period', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_period_period_period);
      });
      _ut.test('test_plus', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_plus);
      });
      _ut.test('test_plus_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_plus_eq);
      });
      _ut.test('test_plus_plus', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_plus_plus);
      });
      _ut.test('test_question', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_question);
      });
      _ut.test('test_scriptTag_withArgs', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_scriptTag_withArgs);
      });
      _ut.test('test_scriptTag_withSpace', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_scriptTag_withSpace);
      });
      _ut.test('test_scriptTag_withoutSpace', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_scriptTag_withoutSpace);
      });
      _ut.test('test_semicolon', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_semicolon);
      });
      _ut.test('test_slash', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_slash);
      });
      _ut.test('test_slash_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_slash_eq);
      });
      _ut.test('test_star', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_star);
      });
      _ut.test('test_star_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_star_eq);
      });
      _ut.test('test_startAndEnd', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_startAndEnd);
      });
      _ut.test('test_string_multi_double', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_multi_double);
      });
      _ut.test('test_string_multi_interpolation_block', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_multi_interpolation_block);
      });
      _ut.test('test_string_multi_interpolation_identifier', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_multi_interpolation_identifier);
      });
      _ut.test('test_string_multi_single', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_multi_single);
      });
      _ut.test('test_string_multi_unterminated', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_multi_unterminated);
      });
      _ut.test('test_string_raw_multi_double', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_raw_multi_double);
      });
      _ut.test('test_string_raw_multi_single', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_raw_multi_single);
      });
      _ut.test('test_string_raw_multi_unterminated', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_raw_multi_unterminated);
      });
      _ut.test('test_string_raw_simple_double', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_double);
      });
      _ut.test('test_string_raw_simple_single', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_single);
      });
      _ut.test('test_string_raw_simple_unterminated_eof', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_unterminated_eof);
      });
      _ut.test('test_string_raw_simple_unterminated_eol', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_unterminated_eol);
      });
      _ut.test('test_string_simple_double', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_double);
      });
      _ut.test('test_string_simple_escapedDollar', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_escapedDollar);
      });
      _ut.test('test_string_simple_interpolation_block', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_block);
      });
      _ut.test('test_string_simple_interpolation_blockWithNestedMap', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_blockWithNestedMap);
      });
      _ut.test('test_string_simple_interpolation_firstAndLast', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_firstAndLast);
      });
      _ut.test('test_string_simple_interpolation_identifier', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_identifier);
      });
      _ut.test('test_string_simple_single', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_single);
      });
      _ut.test('test_string_simple_unterminated_eof', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_unterminated_eof);
      });
      _ut.test('test_string_simple_unterminated_eol', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_string_simple_unterminated_eol);
      });
      _ut.test('test_tilde', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_tilde);
      });
      _ut.test('test_tilde_slash', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_tilde_slash);
      });
      _ut.test('test_tilde_slash_eq', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_tilde_slash_eq);
      });
      _ut.test('test_unclosedPairInInterpolation', () {
        final __test = new CharBufferScannerTest();
        runJUnitTest(__test, __test.test_unclosedPairInInterpolation);
      });
    });
  }
}
class StringScannerTest extends AbstractScannerTest {
  void test_setSourceStart() {
    int offsetDelta = 42;
    GatheringErrorListener listener = new GatheringErrorListener();
    StringScanner scanner = new StringScanner(null, "a", listener);
    scanner.setSourceStart(3, 9, offsetDelta);
    scanner.tokenize();
    List<int> lineStarts3 = scanner.lineStarts;
    JUnitTestCase.assertNotNull(lineStarts3);
    JUnitTestCase.assertEquals(3, lineStarts3.length);
    JUnitTestCase.assertEquals(33, lineStarts3[2]);
  }
  Token scan(String source, GatheringErrorListener listener) {
    StringScanner scanner = new StringScanner(null, source, listener);
    Token result = scanner.tokenize();
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    return result;
  }
  static dartSuite() {
    _ut.group('StringScannerTest', () {
      _ut.test('test_ampersand', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_ampersand);
      });
      _ut.test('test_ampersand_ampersand', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_ampersand_ampersand);
      });
      _ut.test('test_ampersand_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_ampersand_eq);
      });
      _ut.test('test_at', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_at);
      });
      _ut.test('test_backping', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_backping);
      });
      _ut.test('test_backslash', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_backslash);
      });
      _ut.test('test_bang', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_bang);
      });
      _ut.test('test_bang_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_bang_eq);
      });
      _ut.test('test_bar', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_bar);
      });
      _ut.test('test_bar_bar', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_bar_bar);
      });
      _ut.test('test_bar_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_bar_eq);
      });
      _ut.test('test_caret', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_caret);
      });
      _ut.test('test_caret_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_caret_eq);
      });
      _ut.test('test_close_curly_bracket', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_close_curly_bracket);
      });
      _ut.test('test_close_paren', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_close_paren);
      });
      _ut.test('test_close_quare_bracket', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_close_quare_bracket);
      });
      _ut.test('test_colon', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_colon);
      });
      _ut.test('test_comma', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_comma);
      });
      _ut.test('test_comment_multi', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_comment_multi);
      });
      _ut.test('test_comment_multi_unterminated', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_comment_multi_unterminated);
      });
      _ut.test('test_comment_nested', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_comment_nested);
      });
      _ut.test('test_comment_single', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_comment_single);
      });
      _ut.test('test_double_both_E', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_both_E);
      });
      _ut.test('test_double_both_e', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_both_e);
      });
      _ut.test('test_double_fraction', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_fraction);
      });
      _ut.test('test_double_fraction_D', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_D);
      });
      _ut.test('test_double_fraction_E', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_E);
      });
      _ut.test('test_double_fraction_Ed', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_Ed);
      });
      _ut.test('test_double_fraction_d', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_d);
      });
      _ut.test('test_double_fraction_e', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_e);
      });
      _ut.test('test_double_fraction_ed', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_fraction_ed);
      });
      _ut.test('test_double_missingDigitInExponent', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_missingDigitInExponent);
      });
      _ut.test('test_double_whole_D', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_whole_D);
      });
      _ut.test('test_double_whole_E', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_whole_E);
      });
      _ut.test('test_double_whole_Ed', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_whole_Ed);
      });
      _ut.test('test_double_whole_d', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_whole_d);
      });
      _ut.test('test_double_whole_e', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_whole_e);
      });
      _ut.test('test_double_whole_ed', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_double_whole_ed);
      });
      _ut.test('test_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_eq);
      });
      _ut.test('test_eq_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_eq_eq);
      });
      _ut.test('test_gt', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_gt);
      });
      _ut.test('test_gt_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_gt_eq);
      });
      _ut.test('test_gt_gt', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_gt_gt);
      });
      _ut.test('test_gt_gt_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_gt_gt_eq);
      });
      _ut.test('test_hash', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_hash);
      });
      _ut.test('test_hexidecimal', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_hexidecimal);
      });
      _ut.test('test_hexidecimal_missingDigit', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_hexidecimal_missingDigit);
      });
      _ut.test('test_identifier', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_identifier);
      });
      _ut.test('test_illegalChar', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_illegalChar);
      });
      _ut.test('test_index', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_index);
      });
      _ut.test('test_index_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_index_eq);
      });
      _ut.test('test_int', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_int);
      });
      _ut.test('test_int_initialZero', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_int_initialZero);
      });
      _ut.test('test_keyword_abstract', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_abstract);
      });
      _ut.test('test_keyword_as', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_as);
      });
      _ut.test('test_keyword_assert', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_assert);
      });
      _ut.test('test_keyword_break', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_break);
      });
      _ut.test('test_keyword_case', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_case);
      });
      _ut.test('test_keyword_catch', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_catch);
      });
      _ut.test('test_keyword_class', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_class);
      });
      _ut.test('test_keyword_const', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_const);
      });
      _ut.test('test_keyword_continue', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_continue);
      });
      _ut.test('test_keyword_default', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_default);
      });
      _ut.test('test_keyword_do', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_do);
      });
      _ut.test('test_keyword_dynamic', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_dynamic);
      });
      _ut.test('test_keyword_else', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_else);
      });
      _ut.test('test_keyword_enum', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_enum);
      });
      _ut.test('test_keyword_export', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_export);
      });
      _ut.test('test_keyword_extends', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_extends);
      });
      _ut.test('test_keyword_factory', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_factory);
      });
      _ut.test('test_keyword_false', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_false);
      });
      _ut.test('test_keyword_final', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_final);
      });
      _ut.test('test_keyword_finally', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_finally);
      });
      _ut.test('test_keyword_for', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_for);
      });
      _ut.test('test_keyword_get', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_get);
      });
      _ut.test('test_keyword_if', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_if);
      });
      _ut.test('test_keyword_implements', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_implements);
      });
      _ut.test('test_keyword_import', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_import);
      });
      _ut.test('test_keyword_in', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_in);
      });
      _ut.test('test_keyword_is', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_is);
      });
      _ut.test('test_keyword_library', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_library);
      });
      _ut.test('test_keyword_new', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_new);
      });
      _ut.test('test_keyword_null', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_null);
      });
      _ut.test('test_keyword_operator', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_operator);
      });
      _ut.test('test_keyword_part', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_part);
      });
      _ut.test('test_keyword_rethrow', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_rethrow);
      });
      _ut.test('test_keyword_return', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_return);
      });
      _ut.test('test_keyword_set', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_set);
      });
      _ut.test('test_keyword_static', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_static);
      });
      _ut.test('test_keyword_super', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_super);
      });
      _ut.test('test_keyword_switch', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_switch);
      });
      _ut.test('test_keyword_this', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_this);
      });
      _ut.test('test_keyword_throw', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_throw);
      });
      _ut.test('test_keyword_true', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_true);
      });
      _ut.test('test_keyword_try', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_try);
      });
      _ut.test('test_keyword_typedef', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_typedef);
      });
      _ut.test('test_keyword_var', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_var);
      });
      _ut.test('test_keyword_void', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_void);
      });
      _ut.test('test_keyword_while', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_while);
      });
      _ut.test('test_keyword_with', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_keyword_with);
      });
      _ut.test('test_lineInfo', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_lineInfo);
      });
      _ut.test('test_lt', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_lt);
      });
      _ut.test('test_lt_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_lt_eq);
      });
      _ut.test('test_lt_lt', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_lt_lt);
      });
      _ut.test('test_lt_lt_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_lt_lt_eq);
      });
      _ut.test('test_minus', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_minus);
      });
      _ut.test('test_minus_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_minus_eq);
      });
      _ut.test('test_minus_minus', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_minus_minus);
      });
      _ut.test('test_openSquareBracket', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_openSquareBracket);
      });
      _ut.test('test_open_curly_bracket', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_open_curly_bracket);
      });
      _ut.test('test_open_paren', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_open_paren);
      });
      _ut.test('test_open_square_bracket', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_open_square_bracket);
      });
      _ut.test('test_percent', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_percent);
      });
      _ut.test('test_percent_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_percent_eq);
      });
      _ut.test('test_period', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_period);
      });
      _ut.test('test_periodAfterNumberNotIncluded_identifier', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_periodAfterNumberNotIncluded_identifier);
      });
      _ut.test('test_periodAfterNumberNotIncluded_period', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_periodAfterNumberNotIncluded_period);
      });
      _ut.test('test_period_period', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_period_period);
      });
      _ut.test('test_period_period_period', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_period_period_period);
      });
      _ut.test('test_plus', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_plus);
      });
      _ut.test('test_plus_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_plus_eq);
      });
      _ut.test('test_plus_plus', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_plus_plus);
      });
      _ut.test('test_question', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_question);
      });
      _ut.test('test_scriptTag_withArgs', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_scriptTag_withArgs);
      });
      _ut.test('test_scriptTag_withSpace', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_scriptTag_withSpace);
      });
      _ut.test('test_scriptTag_withoutSpace', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_scriptTag_withoutSpace);
      });
      _ut.test('test_semicolon', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_semicolon);
      });
      _ut.test('test_setSourceStart', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_setSourceStart);
      });
      _ut.test('test_slash', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_slash);
      });
      _ut.test('test_slash_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_slash_eq);
      });
      _ut.test('test_star', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_star);
      });
      _ut.test('test_star_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_star_eq);
      });
      _ut.test('test_startAndEnd', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_startAndEnd);
      });
      _ut.test('test_string_multi_double', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_multi_double);
      });
      _ut.test('test_string_multi_interpolation_block', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_multi_interpolation_block);
      });
      _ut.test('test_string_multi_interpolation_identifier', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_multi_interpolation_identifier);
      });
      _ut.test('test_string_multi_single', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_multi_single);
      });
      _ut.test('test_string_multi_unterminated', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_multi_unterminated);
      });
      _ut.test('test_string_raw_multi_double', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_raw_multi_double);
      });
      _ut.test('test_string_raw_multi_single', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_raw_multi_single);
      });
      _ut.test('test_string_raw_multi_unterminated', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_raw_multi_unterminated);
      });
      _ut.test('test_string_raw_simple_double', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_double);
      });
      _ut.test('test_string_raw_simple_single', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_single);
      });
      _ut.test('test_string_raw_simple_unterminated_eof', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_unterminated_eof);
      });
      _ut.test('test_string_raw_simple_unterminated_eol', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_raw_simple_unterminated_eol);
      });
      _ut.test('test_string_simple_double', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_double);
      });
      _ut.test('test_string_simple_escapedDollar', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_escapedDollar);
      });
      _ut.test('test_string_simple_interpolation_block', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_block);
      });
      _ut.test('test_string_simple_interpolation_blockWithNestedMap', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_blockWithNestedMap);
      });
      _ut.test('test_string_simple_interpolation_firstAndLast', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_firstAndLast);
      });
      _ut.test('test_string_simple_interpolation_identifier', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_interpolation_identifier);
      });
      _ut.test('test_string_simple_single', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_single);
      });
      _ut.test('test_string_simple_unterminated_eof', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_unterminated_eof);
      });
      _ut.test('test_string_simple_unterminated_eol', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_string_simple_unterminated_eol);
      });
      _ut.test('test_tilde', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_tilde);
      });
      _ut.test('test_tilde_slash', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_tilde_slash);
      });
      _ut.test('test_tilde_slash_eq', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_tilde_slash_eq);
      });
      _ut.test('test_unclosedPairInInterpolation', () {
        final __test = new StringScannerTest();
        runJUnitTest(__test, __test.test_unclosedPairInInterpolation);
      });
    });
  }
}
/**
 * Instances of the class {@code TokenStreamValidator} are used to validate the correct construction
 * of a stream of tokens.
 */
class TokenStreamValidator {
  /**
   * Validate that the stream of tokens that starts with the given token is correct.
   * @param token the first token in the stream of tokens to be validated
   */
  void validate(Token token) {
    JavaStringBuilder builder = new JavaStringBuilder();
    validateStream(builder, token);
    if (builder.length > 0) {
      JUnitTestCase.fail(builder.toString());
    }
  }
  void validateStream(JavaStringBuilder builder, Token token) {
    if (token == null) {
      return;
    }
    Token previousToken = null;
    int previousEnd = -1;
    Token currentToken = token;
    while (currentToken != null && currentToken.type != TokenType.EOF) {
      validateStream(builder, currentToken.precedingComments);
      TokenType type38 = currentToken.type;
      if (identical(type38, TokenType.OPEN_CURLY_BRACKET) || identical(type38, TokenType.OPEN_PAREN) || identical(type38, TokenType.OPEN_SQUARE_BRACKET) || identical(type38, TokenType.STRING_INTERPOLATION_EXPRESSION)) {
        if (currentToken is! BeginToken) {
          builder.append("\r\nExpected BeginToken, found ");
          builder.append(currentToken.runtimeType.toString());
          builder.append(" ");
          writeToken(builder, currentToken);
        }
      }
      int currentStart = currentToken.offset;
      int currentLength = currentToken.length;
      int currentEnd = currentStart + currentLength - 1;
      if (currentStart <= previousEnd) {
        builder.append("\r\nInvalid token sequence: ");
        writeToken(builder, previousToken);
        builder.append(" followed by ");
        writeToken(builder, currentToken);
      }
      previousEnd = currentEnd;
      previousToken = currentToken;
      currentToken = currentToken.next;
    }
  }
  void writeToken(JavaStringBuilder builder, Token token) {
    builder.append("[");
    builder.append(token.type);
    builder.append(", '");
    builder.append(token.lexeme);
    builder.append("', ");
    builder.append(token.offset);
    builder.append(", ");
    builder.append(token.length);
    builder.append("]");
  }
}
abstract class AbstractScannerTest extends JUnitTestCase {
  void test_ampersand() {
    assertToken(TokenType.AMPERSAND, "&");
  }
  void test_ampersand_ampersand() {
    assertToken(TokenType.AMPERSAND_AMPERSAND, "&&");
  }
  void test_ampersand_eq() {
    assertToken(TokenType.AMPERSAND_EQ, "&=");
  }
  void test_at() {
    assertToken(TokenType.AT, "@");
  }
  void test_backping() {
    assertToken(TokenType.BACKPING, "`");
  }
  void test_backslash() {
    assertToken(TokenType.BACKSLASH, "\\");
  }
  void test_bang() {
    assertToken(TokenType.BANG, "!");
  }
  void test_bang_eq() {
    assertToken(TokenType.BANG_EQ, "!=");
  }
  void test_bar() {
    assertToken(TokenType.BAR, "|");
  }
  void test_bar_bar() {
    assertToken(TokenType.BAR_BAR, "||");
  }
  void test_bar_eq() {
    assertToken(TokenType.BAR_EQ, "|=");
  }
  void test_caret() {
    assertToken(TokenType.CARET, "^");
  }
  void test_caret_eq() {
    assertToken(TokenType.CARET_EQ, "^=");
  }
  void test_close_curly_bracket() {
    assertToken(TokenType.CLOSE_CURLY_BRACKET, "}");
  }
  void test_close_paren() {
    assertToken(TokenType.CLOSE_PAREN, ")");
  }
  void test_close_quare_bracket() {
    assertToken(TokenType.CLOSE_SQUARE_BRACKET, "]");
  }
  void test_colon() {
    assertToken(TokenType.COLON, ":");
  }
  void test_comma() {
    assertToken(TokenType.COMMA, ",");
  }
  void test_comment_multi() {
    assertComment(TokenType.MULTI_LINE_COMMENT, "/* comment */");
  }
  void test_comment_multi_unterminated() {
    assertError(ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT, 3, "/* x");
  }
  void test_comment_nested() {
    assertComment(TokenType.MULTI_LINE_COMMENT, "/* comment /* within a */ comment */");
  }
  void test_comment_single() {
    assertComment(TokenType.SINGLE_LINE_COMMENT, "// comment");
  }
  void test_double_both_e() {
    assertToken(TokenType.DOUBLE, "0.123e4");
  }
  void test_double_both_E() {
    assertToken(TokenType.DOUBLE, "0.123E4");
  }
  void test_double_fraction() {
    assertToken(TokenType.DOUBLE, ".123");
  }
  void test_double_fraction_d() {
    assertToken(TokenType.DOUBLE, ".123d");
  }
  void test_double_fraction_D() {
    assertToken(TokenType.DOUBLE, ".123D");
  }
  void test_double_fraction_e() {
    assertToken(TokenType.DOUBLE, ".123e4");
  }
  void test_double_fraction_E() {
    assertToken(TokenType.DOUBLE, ".123E4");
  }
  void test_double_fraction_ed() {
    assertToken(TokenType.DOUBLE, ".123e4d");
  }
  void test_double_fraction_Ed() {
    assertToken(TokenType.DOUBLE, ".123E4d");
  }
  void test_double_missingDigitInExponent() {
    assertError(ScannerErrorCode.MISSING_DIGIT, 1, "1e");
  }
  void test_double_whole_d() {
    assertToken(TokenType.DOUBLE, "12d");
  }
  void test_double_whole_D() {
    assertToken(TokenType.DOUBLE, "12D");
  }
  void test_double_whole_e() {
    assertToken(TokenType.DOUBLE, "12e4");
  }
  void test_double_whole_E() {
    assertToken(TokenType.DOUBLE, "12E4");
  }
  void test_double_whole_ed() {
    assertToken(TokenType.DOUBLE, "12e4d");
  }
  void test_double_whole_Ed() {
    assertToken(TokenType.DOUBLE, "12E4d");
  }
  void test_eq() {
    assertToken(TokenType.EQ, "=");
  }
  void test_eq_eq() {
    assertToken(TokenType.EQ_EQ, "==");
  }
  void test_gt() {
    assertToken(TokenType.GT, ">");
  }
  void test_gt_eq() {
    assertToken(TokenType.GT_EQ, ">=");
  }
  void test_gt_gt() {
    assertToken(TokenType.GT_GT, ">>");
  }
  void test_gt_gt_eq() {
    assertToken(TokenType.GT_GT_EQ, ">>=");
  }
  void test_hash() {
    assertToken(TokenType.HASH, "#");
  }
  void test_hexidecimal() {
    assertToken(TokenType.HEXADECIMAL, "0x1A2B3C");
  }
  void test_hexidecimal_missingDigit() {
    assertError(ScannerErrorCode.MISSING_HEX_DIGIT, 1, "0x");
  }
  void test_identifier() {
    assertToken(TokenType.IDENTIFIER, "result");
  }
  void test_illegalChar() {
    assertError(ScannerErrorCode.ILLEGAL_CHARACTER, 0, "\u0312");
  }
  void test_index() {
    assertToken(TokenType.INDEX, "[]");
  }
  void test_index_eq() {
    assertToken(TokenType.INDEX_EQ, "[]=");
  }
  void test_int() {
    assertToken(TokenType.INT, "123");
  }
  void test_int_initialZero() {
    assertToken(TokenType.INT, "0123");
  }
  void test_keyword_abstract() {
    assertKeywordToken("abstract");
  }
  void test_keyword_as() {
    assertKeywordToken("as");
  }
  void test_keyword_assert() {
    assertKeywordToken("assert");
  }
  void test_keyword_break() {
    assertKeywordToken("break");
  }
  void test_keyword_case() {
    assertKeywordToken("case");
  }
  void test_keyword_catch() {
    assertKeywordToken("catch");
  }
  void test_keyword_class() {
    assertKeywordToken("class");
  }
  void test_keyword_const() {
    assertKeywordToken("const");
  }
  void test_keyword_continue() {
    assertKeywordToken("continue");
  }
  void test_keyword_default() {
    assertKeywordToken("default");
  }
  void test_keyword_do() {
    assertKeywordToken("do");
  }
  void test_keyword_dynamic() {
    assertKeywordToken("dynamic");
  }
  void test_keyword_else() {
    assertKeywordToken("else");
  }
  void test_keyword_enum() {
    assertKeywordToken("enum");
  }
  void test_keyword_export() {
    assertKeywordToken("export");
  }
  void test_keyword_extends() {
    assertKeywordToken("extends");
  }
  void test_keyword_factory() {
    assertKeywordToken("factory");
  }
  void test_keyword_false() {
    assertKeywordToken("false");
  }
  void test_keyword_final() {
    assertKeywordToken("final");
  }
  void test_keyword_finally() {
    assertKeywordToken("finally");
  }
  void test_keyword_for() {
    assertKeywordToken("for");
  }
  void test_keyword_get() {
    assertKeywordToken("get");
  }
  void test_keyword_if() {
    assertKeywordToken("if");
  }
  void test_keyword_implements() {
    assertKeywordToken("implements");
  }
  void test_keyword_import() {
    assertKeywordToken("import");
  }
  void test_keyword_in() {
    assertKeywordToken("in");
  }
  void test_keyword_is() {
    assertKeywordToken("is");
  }
  void test_keyword_library() {
    assertKeywordToken("library");
  }
  void test_keyword_new() {
    assertKeywordToken("new");
  }
  void test_keyword_null() {
    assertKeywordToken("null");
  }
  void test_keyword_operator() {
    assertKeywordToken("operator");
  }
  void test_keyword_part() {
    assertKeywordToken("part");
  }
  void test_keyword_rethrow() {
    assertKeywordToken("rethrow");
  }
  void test_keyword_return() {
    assertKeywordToken("return");
  }
  void test_keyword_set() {
    assertKeywordToken("set");
  }
  void test_keyword_static() {
    assertKeywordToken("static");
  }
  void test_keyword_super() {
    assertKeywordToken("super");
  }
  void test_keyword_switch() {
    assertKeywordToken("switch");
  }
  void test_keyword_this() {
    assertKeywordToken("this");
  }
  void test_keyword_throw() {
    assertKeywordToken("throw");
  }
  void test_keyword_true() {
    assertKeywordToken("true");
  }
  void test_keyword_try() {
    assertKeywordToken("try");
  }
  void test_keyword_typedef() {
    assertKeywordToken("typedef");
  }
  void test_keyword_var() {
    assertKeywordToken("var");
  }
  void test_keyword_void() {
    assertKeywordToken("void");
  }
  void test_keyword_while() {
    assertKeywordToken("while");
  }
  void test_keyword_with() {
    assertKeywordToken("with");
  }
  void test_lineInfo() {
    String source = "/*\r *\r */";
    GatheringErrorListener listener = new GatheringErrorListener();
    Token token = scan(source, listener);
    JUnitTestCase.assertSame(TokenType.MULTI_LINE_COMMENT, token.precedingComments.type);
    listener.assertNoErrors();
    LineInfo info = listener.getLineInfo(new TestSource());
    JUnitTestCase.assertNotNull(info);
    JUnitTestCase.assertEquals(3, info.getLocation(source.length - 1).lineNumber);
  }
  void test_lt() {
    assertToken(TokenType.LT, "<");
  }
  void test_lt_eq() {
    assertToken(TokenType.LT_EQ, "<=");
  }
  void test_lt_lt() {
    assertToken(TokenType.LT_LT, "<<");
  }
  void test_lt_lt_eq() {
    assertToken(TokenType.LT_LT_EQ, "<<=");
  }
  void test_minus() {
    assertToken(TokenType.MINUS, "-");
  }
  void test_minus_eq() {
    assertToken(TokenType.MINUS_EQ, "-=");
  }
  void test_minus_minus() {
    assertToken(TokenType.MINUS_MINUS, "--");
  }
  void test_open_curly_bracket() {
    assertToken(TokenType.OPEN_CURLY_BRACKET, "{");
  }
  void test_open_paren() {
    assertToken(TokenType.OPEN_PAREN, "(");
  }
  void test_open_square_bracket() {
    assertToken(TokenType.OPEN_SQUARE_BRACKET, "[");
  }
  void test_openSquareBracket() {
    assertToken(TokenType.OPEN_SQUARE_BRACKET, "[");
  }
  void test_percent() {
    assertToken(TokenType.PERCENT, "%");
  }
  void test_percent_eq() {
    assertToken(TokenType.PERCENT_EQ, "%=");
  }
  void test_period() {
    assertToken(TokenType.PERIOD, ".");
  }
  void test_period_period() {
    assertToken(TokenType.PERIOD_PERIOD, "..");
  }
  void test_period_period_period() {
    assertToken(TokenType.PERIOD_PERIOD_PERIOD, "...");
  }
  void test_periodAfterNumberNotIncluded_identifier() {
    assertTokens("42.isEven()", [new StringToken(TokenType.INT, "42", 0), new Token(TokenType.PERIOD, 2), new StringToken(TokenType.IDENTIFIER, "isEven", 3), new Token(TokenType.OPEN_PAREN, 9), new Token(TokenType.CLOSE_PAREN, 10)]);
  }
  void test_periodAfterNumberNotIncluded_period() {
    assertTokens("42..isEven()", [new StringToken(TokenType.INT, "42", 0), new Token(TokenType.PERIOD_PERIOD, 2), new StringToken(TokenType.IDENTIFIER, "isEven", 4), new Token(TokenType.OPEN_PAREN, 10), new Token(TokenType.CLOSE_PAREN, 11)]);
  }
  void test_plus() {
    assertToken(TokenType.PLUS, "+");
  }
  void test_plus_eq() {
    assertToken(TokenType.PLUS_EQ, "+=");
  }
  void test_plus_plus() {
    assertToken(TokenType.PLUS_PLUS, "++");
  }
  void test_question() {
    assertToken(TokenType.QUESTION, "?");
  }
  void test_scriptTag_withArgs() {
    assertToken(TokenType.SCRIPT_TAG, "#!/bin/dart -debug");
  }
  void test_scriptTag_withoutSpace() {
    assertToken(TokenType.SCRIPT_TAG, "#!/bin/dart");
  }
  void test_scriptTag_withSpace() {
    assertToken(TokenType.SCRIPT_TAG, "#! /bin/dart");
  }
  void test_semicolon() {
    assertToken(TokenType.SEMICOLON, ";");
  }
  void test_slash() {
    assertToken(TokenType.SLASH, "/");
  }
  void test_slash_eq() {
    assertToken(TokenType.SLASH_EQ, "/=");
  }
  void test_star() {
    assertToken(TokenType.STAR, "*");
  }
  void test_star_eq() {
    assertToken(TokenType.STAR_EQ, "*=");
  }
  void test_startAndEnd() {
    Token token = scan2("a");
    Token previous5 = token.previous;
    JUnitTestCase.assertEquals(token, previous5.next);
    JUnitTestCase.assertEquals(previous5, previous5.previous);
    Token next7 = token.next;
    JUnitTestCase.assertEquals(next7, next7.next);
    JUnitTestCase.assertEquals(token, next7.previous);
  }
  void test_string_multi_double() {
    assertToken(TokenType.STRING, "\"\"\"multi-line\nstring\"\"\"");
  }
  void test_string_multi_interpolation_block() {
    assertTokens("\"Hello \${name}!\"", [new StringToken(TokenType.STRING, "\"Hello ", 0), new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 7), new StringToken(TokenType.IDENTIFIER, "name", 9), new Token(TokenType.CLOSE_CURLY_BRACKET, 13), new StringToken(TokenType.STRING, "!\"", 14)]);
  }
  void test_string_multi_interpolation_identifier() {
    assertTokens("\"Hello \$name!\"", [new StringToken(TokenType.STRING, "\"Hello ", 0), new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 7), new StringToken(TokenType.IDENTIFIER, "name", 8), new StringToken(TokenType.STRING, "!\"", 12)]);
  }
  void test_string_multi_single() {
    assertToken(TokenType.STRING, "'''string'''");
  }
  void test_string_multi_unterminated() {
    assertError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 8, "'''string");
  }
  void test_string_raw_multi_double() {
    assertToken(TokenType.STRING, "r\"\"\"string\"\"\"");
  }
  void test_string_raw_multi_single() {
    assertToken(TokenType.STRING, "r'''string'''");
  }
  void test_string_raw_multi_unterminated() {
    assertError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 9, "r'''string");
  }
  void test_string_raw_simple_double() {
    assertToken(TokenType.STRING, "r\"string\"");
  }
  void test_string_raw_simple_single() {
    assertToken(TokenType.STRING, "r'string'");
  }
  void test_string_raw_simple_unterminated_eof() {
    assertError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 7, "r'string");
  }
  void test_string_raw_simple_unterminated_eol() {
    assertError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 8, "r'string\n");
  }
  void test_string_simple_double() {
    assertToken(TokenType.STRING, "\"string\"");
  }
  void test_string_simple_escapedDollar() {
    assertToken(TokenType.STRING, "'a\\\$b'");
  }
  void test_string_simple_interpolation_block() {
    assertTokens("'Hello \${name}!'", [new StringToken(TokenType.STRING, "'Hello ", 0), new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 7), new StringToken(TokenType.IDENTIFIER, "name", 9), new Token(TokenType.CLOSE_CURLY_BRACKET, 13), new StringToken(TokenType.STRING, "!'", 14)]);
  }
  void test_string_simple_interpolation_blockWithNestedMap() {
    assertTokens("'a \${f({'b' : 'c'})} d'", [new StringToken(TokenType.STRING, "'a ", 0), new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 3), new StringToken(TokenType.IDENTIFIER, "f", 5), new Token(TokenType.OPEN_PAREN, 6), new Token(TokenType.OPEN_CURLY_BRACKET, 7), new StringToken(TokenType.STRING, "'b'", 8), new Token(TokenType.COLON, 12), new StringToken(TokenType.STRING, "'c'", 14), new Token(TokenType.CLOSE_CURLY_BRACKET, 17), new Token(TokenType.CLOSE_PAREN, 18), new Token(TokenType.CLOSE_CURLY_BRACKET, 19), new StringToken(TokenType.STRING, " d'", 20)]);
  }
  void test_string_simple_interpolation_firstAndLast() {
    assertTokens("'\$greeting \$name'", [new StringToken(TokenType.STRING, "'", 0), new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 1), new StringToken(TokenType.IDENTIFIER, "greeting", 2), new StringToken(TokenType.STRING, " ", 10), new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 11), new StringToken(TokenType.IDENTIFIER, "name", 12), new StringToken(TokenType.STRING, "'", 16)]);
  }
  void test_string_simple_interpolation_identifier() {
    assertTokens("'Hello \$name!'", [new StringToken(TokenType.STRING, "'Hello ", 0), new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 7), new StringToken(TokenType.IDENTIFIER, "name", 8), new StringToken(TokenType.STRING, "!'", 12)]);
  }
  void test_string_simple_single() {
    assertToken(TokenType.STRING, "'string'");
  }
  void test_string_simple_unterminated_eof() {
    assertError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 6, "'string");
  }
  void test_string_simple_unterminated_eol() {
    assertError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 7, "'string\r");
  }
  void test_tilde() {
    assertToken(TokenType.TILDE, "~");
  }
  void test_tilde_slash() {
    assertToken(TokenType.TILDE_SLASH, "~/");
  }
  void test_tilde_slash_eq() {
    assertToken(TokenType.TILDE_SLASH_EQ, "~/=");
  }
  void test_unclosedPairInInterpolation() {
    GatheringErrorListener listener = new GatheringErrorListener();
    scan("'\${(}'", listener);
  }
  Token scan(String source, GatheringErrorListener listener);
  void assertComment(TokenType commentType, String source) {
    Token token = scan2(source);
    JUnitTestCase.assertNotNull(token);
    JUnitTestCase.assertEquals(TokenType.EOF, token.type);
    Token comment = token.precedingComments;
    JUnitTestCase.assertNotNull(comment);
    JUnitTestCase.assertEquals(commentType, comment.type);
    JUnitTestCase.assertEquals(0, comment.offset);
    JUnitTestCase.assertEquals(source.length, comment.length);
    JUnitTestCase.assertEquals(source, comment.lexeme);
  }
  /**
   * Assert that scanning the given source produces an error with the given code.
   * @param illegalCharacter
   * @param i
   * @param source the source to be scanned to produce the error
   */
  void assertError(ScannerErrorCode expectedError, int expectedOffset, String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    scan(source, listener);
    listener.assertErrors([new AnalysisError.con2(null, expectedOffset, 1, expectedError, [(source.codeUnitAt(expectedOffset) as int)])]);
  }
  /**
   * Assert that when scanned the given source contains a single keyword token with the same lexeme
   * as the original source.
   * @param source the source to be scanned
   */
  void assertKeywordToken(String source) {
    Token token = scan2(source);
    JUnitTestCase.assertNotNull(token);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, token.type);
    JUnitTestCase.assertEquals(0, token.offset);
    JUnitTestCase.assertEquals(source.length, token.length);
    JUnitTestCase.assertEquals(source, token.lexeme);
    Object value3 = token.value();
    JUnitTestCase.assertTrue(value3 is Keyword);
    JUnitTestCase.assertEquals(source, ((value3 as Keyword)).syntax);
    token = scan2(" ${source} ");
    JUnitTestCase.assertNotNull(token);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, token.type);
    JUnitTestCase.assertEquals(1, token.offset);
    JUnitTestCase.assertEquals(source.length, token.length);
    JUnitTestCase.assertEquals(source, token.lexeme);
    value3 = token.value();
    JUnitTestCase.assertTrue(value3 is Keyword);
    JUnitTestCase.assertEquals(source, ((value3 as Keyword)).syntax);
    JUnitTestCase.assertEquals(TokenType.EOF, token.next.type);
  }
  /**
   * Assert that the token scanned from the given source has the expected type.
   * @param expectedType the expected type of the token
   * @param source the source to be scanned to produce the actual token
   */
  Token assertToken(TokenType expectedType, String source) {
    Token originalToken = scan2(source);
    JUnitTestCase.assertNotNull(originalToken);
    JUnitTestCase.assertEquals(expectedType, originalToken.type);
    JUnitTestCase.assertEquals(0, originalToken.offset);
    JUnitTestCase.assertEquals(source.length, originalToken.length);
    JUnitTestCase.assertEquals(source, originalToken.lexeme);
    if (identical(expectedType, TokenType.SCRIPT_TAG)) {
      return originalToken;
    } else if (identical(expectedType, TokenType.SINGLE_LINE_COMMENT)) {
      Token tokenWithSpaces = scan2(" ${source}");
      JUnitTestCase.assertNotNull(tokenWithSpaces);
      JUnitTestCase.assertEquals(expectedType, tokenWithSpaces.type);
      JUnitTestCase.assertEquals(1, tokenWithSpaces.offset);
      JUnitTestCase.assertEquals(source.length, tokenWithSpaces.length);
      JUnitTestCase.assertEquals(source, tokenWithSpaces.lexeme);
      return originalToken;
    }
    Token tokenWithSpaces = scan2(" ${source} ");
    JUnitTestCase.assertNotNull(tokenWithSpaces);
    JUnitTestCase.assertEquals(expectedType, tokenWithSpaces.type);
    JUnitTestCase.assertEquals(1, tokenWithSpaces.offset);
    JUnitTestCase.assertEquals(source.length, tokenWithSpaces.length);
    JUnitTestCase.assertEquals(source, tokenWithSpaces.lexeme);
    JUnitTestCase.assertEquals(TokenType.EOF, originalToken.next.type);
    return originalToken;
  }
  /**
   * Assert that when scanned the given source contains a sequence of tokens identical to the given
   * tokens.
   * @param source the source to be scanned
   * @param expectedTokens the tokens that are expected to be in the source
   */
  void assertTokens(String source, List<Token> expectedTokens) {
    Token token = scan2(source);
    JUnitTestCase.assertNotNull(token);
    for (int i = 0; i < expectedTokens.length; i++) {
      Token expectedToken = expectedTokens[i];
      JUnitTestCase.assertEqualsMsg("Wrong type for token ${i}", expectedToken.type, token.type);
      JUnitTestCase.assertEqualsMsg("Wrong offset for token ${i}", expectedToken.offset, token.offset);
      JUnitTestCase.assertEqualsMsg("Wrong length for token ${i}", expectedToken.length, token.length);
      JUnitTestCase.assertEqualsMsg("Wrong lexeme for token ${i}", expectedToken.lexeme, token.lexeme);
      token = token.next;
      JUnitTestCase.assertNotNull(token);
    }
    JUnitTestCase.assertEquals(TokenType.EOF, token.type);
  }
  Token scan2(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Token token = scan(source, listener);
    listener.assertNoErrors();
    return token;
  }
}
main() {
  CharBufferScannerTest.dartSuite();
  KeywordStateTest.dartSuite();
  StringScannerTest.dartSuite();
  TokenTypeTest.dartSuite();
}