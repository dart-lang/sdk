// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/organize_imports.dart';
import 'package:analysis_server/src/lsp/handlers/commands/sort_members.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

/// Handles workspace/executeCommand messages by delegating to a specific handler
/// based on the command.
class ExecuteCommandHandler
    extends MessageHandler<ExecuteCommandParams, Object> {
  final Map<String, CommandHandler> commandHandlers;
  ExecuteCommandHandler(LspAnalysisServer server)
      : commandHandlers = {
          Commands.sortMembers: new SortMembersCommandHandler(server),
          Commands.organizeImports: new OrganizeImportsCommandHandler(server),
        },
        super(server);

  Method get handlesMessage => Method.workspace_executeCommand;

  @override
  ExecuteCommandParams convertParams(Map<String, dynamic> json) =>
      ExecuteCommandParams.fromJson(json);

  Future<ErrorOr<Object>> handle(ExecuteCommandParams params) async {
    final handler = commandHandlers[params.command];
    if (handler == null) {
      return error(ServerErrorCodes.UnknownCommand,
          '${params.command} is not a valid command identifier', null);
    }
    return handler.handle(params.arguments);
  }
}
