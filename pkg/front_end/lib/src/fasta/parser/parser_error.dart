// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.parser_error;

import '../fasta_codes.dart' show Message;

import '../scanner.dart' show Token;

class ParserError {
  /// Character offset from the beginning of file where this error starts.
  final int beginOffset;

  /// Character offset from the beginning of file where this error ends.
  final int endOffset;

  final Message message;

  ParserError(this.beginOffset, this.endOffset, this.message);

  ParserError.fromTokens(Token begin, Token end, Message message)
      : this(begin.charOffset, end.charOffset + end.charCount, message);

  String toString() => "@${beginOffset}: ${message.message}\n${message.tip}";
}
