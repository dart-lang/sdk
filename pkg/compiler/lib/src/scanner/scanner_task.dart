// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.scanner.task;

import '../common/tasks.dart' show CompilerTask, Measurer;
import '../diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
import '../elements/elements.dart' show CompilationUnitElement, LibraryElement;
import '../parser/diet_parser_task.dart' show DietParserTask;
import '../script.dart' show Script;
import '../tokens/token.dart' show Token;
import '../tokens/token_constants.dart' as Tokens show COMMENT_TOKEN, EOF_TOKEN;
import '../tokens/token_map.dart' show TokenMap;
import 'scanner.dart' show Scanner;
import 'string_scanner.dart' show StringScanner;

class ScannerTask extends CompilerTask {
  final DietParserTask _dietParser;
  final bool _preserveComments;
  final TokenMap _commentMap;
  final DiagnosticReporter reporter;

  ScannerTask(this._dietParser, this.reporter, Measurer measurer,
      {bool preserveComments: false, TokenMap commentMap})
      : _preserveComments = preserveComments,
        _commentMap = commentMap,
        super(measurer) {
    if (_preserveComments && _commentMap == null) {
      throw new ArgumentError(
          "commentMap must be provided if preserveComments is true");
    }
  }

  String get name => 'Scanner';

  void scanLibrary(LibraryElement library) {
    CompilationUnitElement compilationUnit = library.entryCompilationUnit;
    String canonicalUri = library.canonicalUri.toString();
    String resolvedUri = compilationUnit.script.resourceUri.toString();
    if (canonicalUri == resolvedUri) {
      reporter.log("Scanning library $canonicalUri");
    } else {
      reporter.log("Scanning library $canonicalUri ($resolvedUri)");
    }
    scan(compilationUnit);
  }

  void scan(CompilationUnitElement compilationUnit) {
    measure(() {
      scanElements(compilationUnit);
    });
  }

  void scanElements(CompilationUnitElement compilationUnit) {
    Script script = compilationUnit.script;
    Token tokens =
        new Scanner(script.file, includeComments: _preserveComments).tokenize();
    if (_preserveComments) {
      tokens = processAndStripComments(tokens);
    }
    _dietParser.dietParse(compilationUnit, tokens);
  }

  /**
   * Returns the tokens for the [source].
   *
   * The [StringScanner] implementation works on strings that end with a '0'
   * value ('\x00'). If [source] does not end with '0', the string is copied
   * before scanning.
   */
  Token tokenize(String source) {
    return measure(() {
      return new StringScanner.fromString(source, includeComments: false)
          .tokenize();
    });
  }

  Token processAndStripComments(Token currentToken) {
    Token firstToken = currentToken;
    Token prevToken;
    while (currentToken.kind != Tokens.EOF_TOKEN) {
      if (identical(currentToken.kind, Tokens.COMMENT_TOKEN)) {
        Token firstCommentToken = currentToken;
        while (identical(currentToken.kind, Tokens.COMMENT_TOKEN)) {
          currentToken = currentToken.next;
        }
        _commentMap[currentToken] = firstCommentToken;
        if (prevToken == null) {
          firstToken = currentToken;
        } else {
          prevToken.next = currentToken;
        }
      }
      prevToken = currentToken;
      currentToken = currentToken.next;
    }
    return firstToken;
  }
}
