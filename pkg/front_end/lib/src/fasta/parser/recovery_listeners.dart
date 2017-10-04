// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Token;

import '../messages.dart' show Message;

import 'forwarding_listener.dart' show ForwardingListener;

import 'listener.dart' show Listener;

/// The abstract superclass of recovery listeners.
///
/// During the first phase of recovery, some portion of the code is reparsed
/// to record information (e.g. tokens) that were not recorded during
/// the primary parse phase. During this phase, the [listener] is null
/// so that reparsing will not effect the primary listener state,
/// but the [_primaryListener] is non-null for those few events
/// where the parser requires the listener to interpret the token stream.
class RecoveryListener extends ForwardingListener {
  // TODO(danrubel): remove the need for this field and this class
  // by removing listener events that interpret the token stream for the parser.
  final Listener _primaryListener;

  RecoveryListener(this._primaryListener);

  @override
  Token injectGenericCommentTypeAssign(Token token) =>
      _primaryListener.injectGenericCommentTypeAssign(token);

  @override
  Token injectGenericCommentTypeList(Token token) =>
      _primaryListener.injectGenericCommentTypeList(token);

  @override
  Token handleUnrecoverableError(Token token, Message message) =>
      _primaryListener.handleUnrecoverableError(token, message);

  @override
  Token newSyntheticToken(Token next) =>
      _primaryListener.newSyntheticToken(next);

  @override
  Token replaceTokenWithGenericCommentTypeAssign(
          Token tokenToStartReplacing, Token tokenWithComment) =>
      _primaryListener.replaceTokenWithGenericCommentTypeAssign(
          tokenToStartReplacing, tokenWithComment);
}

class ClassHeaderRecoveryListener extends RecoveryListener {
  Token extendsKeyword;
  Token implementsKeyword;
  Token withKeyword;

  ClassHeaderRecoveryListener(Listener primaryListener)
      : super(primaryListener);

  void clear() {
    extendsKeyword = null;
    implementsKeyword = null;
    withKeyword = null;
  }

  @override
  void endMixinApplication(Token withKeyword) {
    this.withKeyword = withKeyword;
    super.endMixinApplication(withKeyword);
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    this.extendsKeyword = extendsKeyword;
    super.handleClassExtends(extendsKeyword);
  }

  @override
  void handleClassImplements(Token implementsKeyword, int interfacesCount) {
    this.implementsKeyword = implementsKeyword;
    super.handleClassImplements(implementsKeyword, interfacesCount);
  }
}
