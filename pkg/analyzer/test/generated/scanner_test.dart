// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.scanner_test;

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/scanner/scanner.dart' as fe;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LineInfoTest);
  });
}

class CharacterRangeReaderTest extends EngineTestCase {
  void test_advance() {
    CharSequenceReader baseReader = new CharSequenceReader("xyzzy");
    CharacterRangeReader reader = new CharacterRangeReader(baseReader, 1, 4);
    expect(reader.advance(), 0x79);
    expect(reader.advance(), 0x80);
    expect(reader.advance(), 0x80);
    expect(reader.advance(), -1);
    expect(reader.advance(), -1);
  }

  void test_creation() {
    CharSequenceReader baseReader = new CharSequenceReader("xyzzy");
    CharacterRangeReader reader = new CharacterRangeReader(baseReader, 1, 4);
    expect(reader, isNotNull);
  }

  void test_getOffset() {
    CharSequenceReader baseReader = new CharSequenceReader("xyzzy");
    CharacterRangeReader reader = new CharacterRangeReader(baseReader, 1, 2);
    expect(reader.offset, 1);
    reader.advance();
    expect(reader.offset, 2);
    reader.advance();
    expect(reader.offset, 2);
  }

  void test_getString() {
    CharSequenceReader baseReader = new CharSequenceReader("__xyzzy__");
    CharacterRangeReader reader = new CharacterRangeReader(baseReader, 2, 7);
    reader.offset = 5;
    expect(reader.getString(3, 0), "yzz");
    expect(reader.getString(4, 1), "zzy");
  }

  void test_peek() {
    CharSequenceReader baseReader = new CharSequenceReader("xyzzy");
    CharacterRangeReader reader = new CharacterRangeReader(baseReader, 1, 3);
    expect(reader.peek(), 0x79);
    expect(reader.peek(), 0x79);
    reader.advance();
    expect(reader.peek(), 0x80);
    expect(reader.peek(), 0x80);
    reader.advance();
    expect(reader.peek(), -1);
    expect(reader.peek(), -1);
  }

  void test_setOffset() {
    CharSequenceReader baseReader = new CharSequenceReader("xyzzy");
    CharacterRangeReader reader = new CharacterRangeReader(baseReader, 1, 4);
    reader.offset = 2;
    expect(reader.offset, 2);
  }
}

@reflectiveTest
class LineInfoTest extends EngineTestCase {
  void test_lineInfo_multilineComment() {
    String source = "/*\r\n *\r\n */";
    _assertLineInfo(source, [
      new ScannerTest_ExpectedLocation(0, 1, 1),
      new ScannerTest_ExpectedLocation(5, 2, 2),
      new ScannerTest_ExpectedLocation(source.length - 1, 3, 3)
    ]);
  }

  void test_lineInfo_multilineString() {
    String source = "'''a\r\nbc\r\nd'''";
    _assertLineInfo(source, [
      new ScannerTest_ExpectedLocation(0, 1, 1),
      new ScannerTest_ExpectedLocation(7, 2, 2),
      new ScannerTest_ExpectedLocation(source.length - 1, 3, 4)
    ]);
  }

  void test_lineInfo_multilineString_raw() {
    String source = "var a = r'''\nblah\n''';\n\nfoo";
    _assertLineInfo(source, [
      new ScannerTest_ExpectedLocation(0, 1, 1),
      new ScannerTest_ExpectedLocation(14, 2, 2),
      new ScannerTest_ExpectedLocation(source.length - 2, 5, 2)
    ]);
  }

  void test_lineInfo_simpleClass() {
    String source =
        "class Test {\r\n    String s = '...';\r\n    int get x => s.MISSING_GETTER;\r\n}";
    _assertLineInfo(source, [
      new ScannerTest_ExpectedLocation(0, 1, 1),
      new ScannerTest_ExpectedLocation(source.indexOf("MISSING_GETTER"), 3, 20),
      new ScannerTest_ExpectedLocation(source.length - 1, 4, 1)
    ]);
  }

  void test_lineInfo_slashN() {
    String source = "class Test {\n}";
    _assertLineInfo(source, [
      new ScannerTest_ExpectedLocation(0, 1, 1),
      new ScannerTest_ExpectedLocation(source.indexOf("}"), 2, 1)
    ]);
  }

  void test_linestarts() {
    String source = "var\r\ni\n=\n1;\n";
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    var token = scanner.tokenize();
    expect(token.lexeme, 'var');
    var lineStarts = scanner.lineStarts;
    expect(
        lineStarts, orderedEquals([0, 5, 7, 9, fe.Scanner.useFasta ? 12 : 11]));
  }

  void _assertLineInfo(
      String source, List<ScannerTest_ExpectedLocation> expectedLocations) {
    GatheringErrorListener listener = new GatheringErrorListener();
    _scanWithListener(source, listener);
    listener.assertNoErrors();
    LineInfo info = listener.getLineInfo(new TestSource());
    expect(info, isNotNull);
    int count = expectedLocations.length;
    for (int i = 0; i < count; i++) {
      ScannerTest_ExpectedLocation expectedLocation = expectedLocations[i];
      LineInfo_Location location = info.getLocation(expectedLocation._offset);
      expect(location.lineNumber, expectedLocation._lineNumber,
          reason: 'Line number in location $i');
      expect(location.columnNumber, expectedLocation._columnNumber,
          reason: 'Column number in location $i');
    }
  }

  Token _scanWithListener(String source, GatheringErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    scanner.scanGenericMethodComments = genericMethodComments;
    scanner.scanLazyAssignmentOperators = lazyAssignmentOperators;
    Token result = scanner.tokenize();
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    return result;
  }
}

/**
 * An `ExpectedLocation` encodes information about the expected location of a
 * given offset in source code.
 */
class ScannerTest_ExpectedLocation {
  final int _offset;

  final int _lineNumber;

  final int _columnNumber;

  ScannerTest_ExpectedLocation(
      this._offset, this._lineNumber, this._columnNumber);
}

/**
 * A `TokenStreamValidator` is used to validate the correct construction of a
 * stream of tokens.
 */
class TokenStreamValidator {
  /**
   * Validate that the stream of tokens that starts with the given [token] is
   * correct.
   */
  void validate(Token token) {
    StringBuffer buffer = new StringBuffer();
    _validateStream(buffer, token);
    if (buffer.length > 0) {
      fail(buffer.toString());
    }
  }

  void _validateStream(StringBuffer buffer, Token token) {
    if (token == null) {
      return;
    }
    Token previousToken = null;
    int previousEnd = -1;
    Token currentToken = token;
    while (currentToken != null && currentToken.type != TokenType.EOF) {
      _validateStream(buffer, currentToken.precedingComments);
      TokenType type = currentToken.type;
      if (type == TokenType.OPEN_CURLY_BRACKET ||
          type == TokenType.OPEN_PAREN ||
          type == TokenType.OPEN_SQUARE_BRACKET ||
          type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
        if (currentToken is! BeginToken) {
          buffer.write("\r\nExpected BeginToken, found ");
          buffer.write(currentToken.runtimeType.toString());
          buffer.write(" ");
          _writeToken(buffer, currentToken);
        }
      }
      int currentStart = currentToken.offset;
      int currentLength = currentToken.length;
      int currentEnd = currentStart + currentLength - 1;
      if (currentStart <= previousEnd) {
        buffer.write("\r\nInvalid token sequence: ");
        _writeToken(buffer, previousToken);
        buffer.write(" followed by ");
        _writeToken(buffer, currentToken);
      }
      previousEnd = currentEnd;
      previousToken = currentToken;
      currentToken = currentToken.next;
    }
  }

  void _writeToken(StringBuffer buffer, Token token) {
    buffer.write("[");
    buffer.write(token.type);
    buffer.write(", '");
    buffer.write(token.lexeme);
    buffer.write("', ");
    buffer.write(token.offset);
    buffer.write(", ");
    buffer.write(token.length);
    buffer.write("]");
  }
}
