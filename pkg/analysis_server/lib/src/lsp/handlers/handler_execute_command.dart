// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/fix_all.dart';
import 'package:analysis_server/src/lsp/handlers/commands/log_action.dart';
import 'package:analysis_server/src/lsp/handlers/commands/organize_imports.dart';
import 'package:analysis_server/src/lsp/handlers/commands/perform_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/commands/refactor_command_handler.dart';
import 'package:analysis_server/src/lsp/handlers/commands/send_workspace_edit.dart';
import 'package:analysis_server/src/lsp/handlers/commands/sort_members.dart';
import 'package:analysis_server/src/lsp/handlers/commands/validate_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';

/// Handles workspace/executeCommand messages by delegating to a specific
/// handler based on the command.
class ExecuteCommandHandler
    extends MessageHandler<ExecuteCommandParams, Object?> {
  final Map<String, CommandHandler<ExecuteCommandParams, Object>>
      commandHandlers;

  ExecuteCommandHandler(super.server)
      : commandHandlers = {
          Commands.sortMembers: SortMembersCommandHandler(server),
          Commands.organizeImports: OrganizeImportsCommandHandler(server),
          Commands.fixAll: FixAllCommandHandler(server),
          Commands.performRefactor: PerformRefactorCommandHandler(server),
          Commands.validateRefactor: ValidateRefactorCommandHandler(server),
          Commands.sendWorkspaceEdit: SendWorkspaceEditCommandHandler(server),
          Commands.logAction: LogActionCommandHandler(server),
          // Add commands for each of the refactorings.
          for (var entry in RefactoringProcessor.generators.entries)
            entry.key: RefactorCommandHandler(server, entry.key, entry.value),
        };

  @override
  Method get handlesMessage => Method.workspace_executeCommand;

  @override
  LspJsonHandler<ExecuteCommandParams> get jsonHandler =>
      ExecuteCommandParams.jsonHandler;

  @override
  Future<ErrorOr<Object?>> handle(ExecuteCommandParams params,
      MessageInfo message, CancellationToken token) async {
    final handler = commandHandlers[params.command];
    if (handler == null) {
      return error(ServerErrorCodes.UnknownCommand,
          '${params.command} is not a valid command identifier', null);
    }

    if (!handler.recordsOwnAnalytics) {
      server.analyticsManager.executedCommand(params.command);
    }
    final workDoneToken = params.workDoneToken;
    final progress = workDoneToken != null
        ? ProgressReporter.clientProvided(server, workDoneToken)
        : server.clientCapabilities?.workDoneProgress ?? false
            ? ProgressReporter.serverCreated(server)
            : ProgressReporter.noop;

    // To make passing arguments easier in commands, instead of a
    // `List<Object?>` we now use `Map<String, Object?>`.
    //
    // However, some handlers still support the list for compatibility so we
    // must allow them to convert a `List` to a `Map`.
    final arguments = params.arguments ?? const [];
    Map<String, Object?> commandParams;
    if (arguments.length == 1 && arguments[0] is Map<String, Object?>) {
      commandParams = arguments.single as Map<String, Object?>;
    } else if (handler is PositionalArgCommandHandler) {
      final argHandler = handler as PositionalArgCommandHandler;
      commandParams = argHandler.parseArgList(arguments);
    } else {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message: '${params.command} requires a single Map argument',
      ));
    }

    return handler.handle(commandParams, progress, token);
  }
}
