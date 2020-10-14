// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/progress.dart';

/// This command allows a client to request the server send it a
/// workspace/applyEdit command, simply passing through the edits provided
/// by the client. This is to handle completion items that need to make edits
/// in files other than those containing the completion (not natively supported
/// by LSP). The edits are put into the [CompletionItem]s command field/
/// args and when the client calls the server to execute that command, the server
/// will call the client to execute workspace/applyEdit.
class SendWorkspaceEditCommandHandler extends SimpleEditCommandHandler {
  SendWorkspaceEditCommandHandler(LspAnalysisServer server) : super(server);

  @override
  String get commandName => 'Send Workspace Edit';

  @override
  Future<ErrorOr<void>> handle(List<dynamic> arguments,
      ProgressReporter reporter, CancellationToken cancellationToken) async {
    if (arguments == null ||
        arguments.length != 1 ||
        arguments[0] is! Map<String, dynamic>) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message:
            '$commandName requires a single List argument of WorkspaceEdit',
      ));
    }

    final workspaceEdit = WorkspaceEdit.fromJson(arguments[0]);

    return await sendWorkspaceEditToClient(workspaceEdit);
  }
}
