// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

/// A [MessageHandler] that rejects specific tpyes of messages with a given
/// error code/message.
class RejectMessageHandler extends MessageHandler<Object?, void> {
  @override
  final Method handlesMessage;
  final ErrorCodes errorCode;
  final String errorMessage;
  RejectMessageHandler(
      super.server, this.handlesMessage, this.errorCode, this.errorMessage);

  @override
  LspJsonHandler<void> get jsonHandler => NullJsonHandler;

  @override
  ErrorOr<void> handle(
      Object? _, MessageInfo message, CancellationToken token) {
    return error(errorCode, errorMessage, null);
  }
}
