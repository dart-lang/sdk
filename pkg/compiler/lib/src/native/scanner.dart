// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../parser/element_listener.dart' show ElementListener;
import 'package:front_end/src/fasta/scanner.dart' show Token;
import 'package:front_end/src/fasta/scanner/token_constants.dart' as Tokens
    show STRING_TOKEN;
import 'package:front_end/src/scanner/token.dart' show BeginToken;

void checkAllowedLibrary(ElementListener listener, Token token) {
  if (listener.scannerOptions.canUseNative) return;
  listener.reportErrorFromToken(token, MessageKind.NATIVE_NOT_SUPPORTED);
}

Token handleNativeBlockToSkip(ElementListener listener, Token token) {
  checkAllowedLibrary(listener, token);
  token = token.next;
  if (identical(token.kind, Tokens.STRING_TOKEN)) {
    token = token.next;
  }
  if (identical(token.stringValue, '{')) {
    BeginToken beginGroupToken = token;
    token = beginGroupToken.endGroup;
  }
  return token;
}

Token handleNativeFunctionBody(ElementListener listener, Token token) {
  checkAllowedLibrary(listener, token);
  Token begin = token;
  listener.beginReturnStatement(token);
  token = token.next;
  bool hasExpression = false;
  if (identical(token.kind, Tokens.STRING_TOKEN)) {
    hasExpression = true;
    listener.beginLiteralString(token);
    token = token.next;
    listener.endLiteralString(0, token);
  }
  listener.endReturnStatement(hasExpression, begin, token);
  // TODO(ngeoffray): expect a ';'.
  // Currently there are method with both native marker and Dart body.
  return token.next;
}
