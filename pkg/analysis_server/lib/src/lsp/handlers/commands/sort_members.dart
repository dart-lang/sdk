// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class SortMembersCommandHandler
    extends CommandHandler<ExecuteCommandParams, Object> {
  SortMembersCommandHandler(LspAnalysisServer server) : super(server);

  @override
  Future<ErrorOr<void>> handle(List<dynamic> arguments) async {
    if (arguments == null || arguments.length != 1 || arguments[0] is! String) {
      return ErrorOr.error(new ResponseError(
        ServerErrorCodes.InvalidCommandArguments,
        '${Commands.sortMembers} requires a single String parameter containing the path of a Dart file',
        null,
      ));
    }

    return error(
      ServerErrorCodes.UnknownCommand,
      'This command is not yet implemented',
      null,
    );
  }
}
