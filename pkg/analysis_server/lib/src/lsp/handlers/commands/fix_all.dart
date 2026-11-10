// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/operations/fix_all_in_file.dart';
import 'package:analysis_server/src/lsp/progress.dart';

class FixAllCommandHandler extends SimpleEditCommandHandler<LspAnalysisServer> {
  new(super.server);

  @override
  String get commandName => 'Fix All';

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<void>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    if (parameters['path'] is! String) {
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.invalidCommandArguments,
          message: '$commandName requires a Map argument containing a "path"',
        ),
      );
    }

    var path = parameters['path'] as String;
    var autoTriggered = parameters['autoTriggered'] == true;

    return withPath(path: path, cancellationToken, (path, _, checkAbort) async {
      var operation = FixAllInFileOperation(
        server: server,
        message: message,
        path: path,
        cancellationToken: cancellationToken,
        autoTriggered: autoTriggered,
      );
      var edit = await operation.compute();

      if (checkAbort() case var reason?) return reason;

      return edit.mapResult((result) async {
        var (edit, _) = result;
        if (edit == null) {
          return success(null);
        }

        // Sending the edit to the client must be outside of the lock because
        // otherwise the response will not be processed.
        return await sendWorkspaceEditToClient(edit);
      });
    });
  }
}
