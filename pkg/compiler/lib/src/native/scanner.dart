// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../parser/listener.dart' show Listener;
import '../parser/element_listener.dart' show ElementListener;
import '../tokens/token.dart' show BeginGroupToken, Token;
import '../tokens/token_constants.dart' as Tokens show EOF_TOKEN, STRING_TOKEN;

void checkAllowedLibrary(ElementListener listener, Token token) {
  if (listener.scannerOptions.canUseNative) return;
  listener.reportError(token, MessageKind.NATIVE_NOT_SUPPORTED);
}

Token handleNativeBlockToSkip(Listener listener, Token token) {
  checkAllowedLibrary(listener, token);
  token = token.next;
  if (identical(token.kind, Tokens.STRING_TOKEN)) {
    token = token.next;
  }
  if (identical(token.stringValue, '{')) {
    BeginGroupToken beginGroupToken = token;
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
    listener.endLiteralString(0);
    token = token.next;
  }
  listener.endReturnStatement(hasExpression, begin, token);
  // TODO(ngeoffray): expect a ';'.
  // Currently there are method with both native marker and Dart body.
  return token.next;
}
