// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

/// A [MessageHandler] that rejects specific types of messages with a given
/// error code/message.
class RejectMessageHandler extends SharedMessageHandler<Object?, void> {
  @override
  final Method handlesMessage;
  final ErrorCodes errorCode;
  final String errorMessage;

  RejectMessageHandler(
    super.server,
    this.handlesMessage,
    this.errorCode,
    this.errorMessage,
  );

  @override
  LspJsonHandler<void> get jsonHandler => nullJsonHandler;

  @override
  // We never expose the rejected handler to other clients, it's used only to
  // support better error codes on attempts to call invalid methods (such as
  // calling `initialize` when the server is already initialized).
  bool get requiresTrustedCaller => true;

  @override
  ErrorOr<void> handle(
    Object? params,
    MessageInfo message,
    CancellationToken token,
  ) {
    return error(errorCode, errorMessage);
  }
}
