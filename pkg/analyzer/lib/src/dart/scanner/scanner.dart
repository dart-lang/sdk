// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.scanner.scanner;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/fasta/scanner.dart' as fasta;
import 'package:front_end/src/scanner/errors.dart' show translateErrorToken;
import 'package:front_end/src/scanner/scanner.dart' as fe;
import 'package:front_end/src/scanner/token.dart' show Token, TokenType;

export 'package:analyzer/src/dart/error/syntactic_errors.dart';
export 'package:front_end/src/scanner/scanner.dart' show KeywordState;

/**
 * The class `Scanner` implements a scanner for Dart code.
 *
 * The lexical structure of Dart is ambiguous without knowledge of the context
 * in which a token is being scanned. For example, without context we cannot
 * determine whether source of the form "<<" should be scanned as a single
 * left-shift operator or as two left angle brackets. This scanner does not have
 * any context, so it always resolves such conflicts by scanning the longest
 * possible token.
 */
class Scanner extends fe.Scanner {
  /**
   * The source being scanned.
   */
  final Source source;

  /**
   * The error listener that will be informed of any errors that are found
   * during the scan.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * Initialize a newly created scanner to scan characters from the given
   * [source]. The given character [reader] will be used to read the characters
   * in the source. The given [_errorListener] will be informed of any errors
   * that are found.
   */
  factory Scanner(Source source, CharacterReader reader,
          AnalysisErrorListener errorListener) =>
      fe.Scanner.useFasta
          ? new _Scanner2(
              source, reader.getContents(), reader.offset, errorListener)
          : new Scanner._(source, reader, errorListener);

  Scanner._(this.source, CharacterReader reader, this._errorListener)
      : super.create(reader);

  @override
  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    _errorListener
        .onError(new AnalysisError(source, offset, 1, errorCode, arguments));
  }
}

/**
 * Replacement scanner based on fasta.
 */
class _Scanner2 implements Scanner {
  @override
  final Source source;

  /**
   * The text to be scanned.
   */
  final String _contents;

  /**
   * The offset of the first character from the reader.
   */
  final int _readerOffset;

  /**
   * The error listener that will be informed of any errors that are found
   * during the scan.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The flag specifying whether documentation comments should be parsed.
   */
  bool _preserveComments = true;

  @override
  final List<int> lineStarts = <int>[];

  @override
  Token firstToken;

  @override
  bool scanGenericMethodComments = false;

  @override
  bool scanLazyAssignmentOperators = false;

  _Scanner2(
      this.source, this._contents, this._readerOffset, this._errorListener) {
    lineStarts.add(0);
  }

  @override
  bool get hasUnmatchedGroups {
    throw 'unsupported operation';
  }

  @override
  set preserveComments(bool preserveComments) {
    this._preserveComments = preserveComments;
  }

  @override
  Token get tail {
    throw 'unsupported operation';
  }

  @override
  void appendToken(Token token) {
    throw 'unsupported operation';
  }

  @override
  int bigSwitch(int next) {
    throw 'unsupported operation';
  }

  @override
  void recordStartOfLine() {
    throw 'unsupported operation';
  }

  @override
  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    _errorListener
        .onError(new AnalysisError(source, offset, 1, errorCode, arguments));
  }

  @override
  void setSourceStart(int line, int column) {
    int offset = _readerOffset;
    if (line < 1 || column < 1 || offset < 0 || (line + column - 2) >= offset) {
      return;
    }
    lineStarts.removeAt(0);
    for (int i = 2; i < line; i++) {
      lineStarts.add(1);
    }
    lineStarts.add(offset - column + 1);
  }

  @override
  Token tokenize() {
    fasta.ScannerResult result = fasta.scanString(_contents,
        includeComments: _preserveComments,
        scanGenericMethodComments: scanGenericMethodComments,
        scanLazyAssignmentOperators: scanLazyAssignmentOperators);

    // fasta pretends there is an additional line at EOF
    result.lineStarts.removeLast();

    // for compatibility, there is already a first entry in lineStarts
    result.lineStarts.removeAt(0);

    lineStarts.addAll(result.lineStarts);
    fasta.Token token = result.tokens;
    // The default recovery strategy used by scanString
    // places all error tokens at the head of the stream.
    while (token.type == TokenType.BAD_INPUT) {
      translateErrorToken(token, reportError);
      token = token.next;
    }
    firstToken = token;
    // Update all token offsets based upon the reader's starting offset
    if (_readerOffset != -1) {
      final int delta = _readerOffset + 1;
      do {
        token.offset += delta;
        token = token.next;
      } while (!token.isEof);
    }
    return firstToken;
  }
}
