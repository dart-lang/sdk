// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style licenset hat can be found in the LICENSE file.

library fasta.scanner.recover;

import 'token.dart' show
    Token;

/// Recover from errors in [tokens]. The original sources are provided as
/// [bytes]. [lineStarts] are the beginning character offsets of lines, and
/// must be updated if recovery is performed rewriting the original source
/// code.
Token defaultRecoveryStrategy(
    List<int> bytes, Token tokens, List<int> lineStarts) {
  // See [Parser.reportErrorToken](package:front_end/src/fasta/parser/src/parser.dart) for how
  // it currently handles lexical errors. In addition, notice how the parser
  // calls [handleInvalidExpression], [handleInvalidFunctionBody], and
  // [handleInvalidTypeReference] to allow the listener to recover its internal
  // state. See [package:compiler/src/parser/element_listener.dart] for an
  // example of how these events are used.
  //
  // In addition, the scanner will attempt a bit of recovery when braces don't
  // match up during brace grouping. See
  // [ArrayBasedScanner.discardBeginGroupUntil](array_based_scanner.dart). For
  // more details on brace grouping see
  // [AbstractScanner.unmatchedBeginGroup](abstract_scanner.dart).
  return tokens;
}
