// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/fix_all_of_error_code_in_file.dart';
import 'package:analysis_server/src/lsp/handlers/commands/organize_imports.dart';
import 'package:analysis_server/src/lsp/handlers/commands/perform_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/commands/send_workspace_edit.dart';
import 'package:analysis_server/src/lsp/handlers/commands/sort_members.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/progress.dart';

/// Handles workspace/executeCommand messages by delegating to a specific handler
/// based on the command.
class ExecuteCommandHandler
    extends MessageHandler<ExecuteCommandParams, Object> {
  final Map<String, CommandHandler> commandHandlers;
  ExecuteCommandHandler(LspAnalysisServer server)
      : commandHandlers = {
          Commands.sortMembers: SortMembersCommandHandler(server),
          Commands.organizeImports: OrganizeImportsCommandHandler(server),
          Commands.performRefactor: PerformRefactorCommandHandler(server),
          Commands.sendWorkspaceEdit: SendWorkspaceEditCommandHandler(server),
          Commands.fixAllOfErrorCodeInFile:
              FixAllOfErrorCodeInFileCommandHandler(server),
        },
        super(server);

  @override
  Method get handlesMessage => Method.workspace_executeCommand;

  @override
  LspJsonHandler<ExecuteCommandParams> get jsonHandler =>
      ExecuteCommandParams.jsonHandler;

  @override
  Future<ErrorOr<Object>> handle(
      ExecuteCommandParams params, CancellationToken cancellationToken) async {
    final handler = commandHandlers[params.command];
    if (handler == null) {
      return error(ServerErrorCodes.UnknownCommand,
          '${params.command} is not a valid command identifier', null);
    }

    final progress = params.workDoneToken != null
        ? ProgressReporter.clientProvided(server, params.workDoneToken)
        : server.clientCapabilities.window?.workDoneProgress == true
            ? ProgressReporter.serverCreated(server)
            : ProgressReporter.noop;
    return handler.handle(params.arguments, progress, cancellationToken);
  }
}
