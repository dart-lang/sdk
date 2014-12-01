// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of native;

void checkAllowedLibrary(ElementListener listener, Token token) {
  LibraryElement currentLibrary = listener.compilationUnitElement.library;
  if (currentLibrary.canUseNative) return;
  listener.reportError(token, MessageKind.NATIVE_NOT_SUPPORTED);
}

Token handleNativeBlockToSkip(Listener listener, Token token) {
  checkAllowedLibrary(listener, token);
  token = token.next;
  if (identical(token.kind, STRING_TOKEN)) {
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
  if (identical(token.kind, STRING_TOKEN)) {
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
