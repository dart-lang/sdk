// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';

class LogActionCommandHandler
    extends CommandHandler<ExecuteCommandParams, Object> {
  LogActionCommandHandler(super.server);

  @override
  bool get recordsOwnAnalytics => true;

  @override
  Future<ErrorOr<void>> handle(
      MessageInfo message,
      Map<String, Object?> parameters,
      ProgressReporter progress,
      CancellationToken cancellationToken) async {
    final action = parameters['action'] as String;
    // Actions are recorded the same as commands.
    server.analyticsManager.executedCommand(action);

    return success(null);
  }
}
