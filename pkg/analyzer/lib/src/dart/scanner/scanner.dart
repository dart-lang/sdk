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
          ? new _Scanner2(source, reader.getContents(), errorListener)
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

  _Scanner2(this.source, this._contents, this._errorListener) {
    lineStarts.add(0);
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
  bool get hasUnmatchedGroups {
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
    throw 'unsupported operation';
  }

  @override
  Token get tail {
    throw 'unsupported operation';
  }

  @override
  Token tokenize() {
    // Note: Fasta always supports lazy assignment operators (`&&=` and `||=`),
    // so we can ignore the `scanLazyAssignmentOperators` flag.
    if (scanGenericMethodComments) {
      // Fasta doesn't support generic method comments.
      // TODO(danrubel): remove this once fasts support has been added.
      throw 'No generic method comment support in Fasta';
    }
    fasta.ScannerResult result = fasta.scanString(_contents,
        includeComments: _preserveComments,
        scanLazyAssignmentOperators: scanLazyAssignmentOperators);
    // fasta pretends there is an additional line at EOF
    lineStarts
        .addAll(result.lineStarts.sublist(1, result.lineStarts.length - 1));
    fasta.Token token = result.tokens;
    // The default recovery strategy used by scanString
    // places all error tokens at the head of the stream.
    while (token.type == TokenType.BAD_INPUT) {
      translateErrorToken(token, reportError);
      token = token.next;
    }
    firstToken = token;
    return firstToken;
  }

  @override
  set preserveComments(bool preserveComments) {
    this._preserveComments = preserveComments;
  }
}
