// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.scanner.scanner;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/scanner/scanner.dart' as fe;

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
  Scanner(this.source, CharacterReader reader, this._errorListener)
      : super(reader);

  @override
  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    _errorListener
        .onError(new AnalysisError(source, offset, 1, errorCode, arguments));
  }
}
