// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/operations/fix_all_in_workspace.dart';

class GetFixesHandler
    extends
        SharedMessageHandler<
          DartGetWorkspaceFixesParams,
          DartGetWorkspaceFixesResult
        > {
  new(super.server);

  @override
  Method get handlesMessage => CustomMethods.getWorkspaceFixes;

  @override
  LspJsonHandler<DartGetWorkspaceFixesParams> get jsonHandler =>
      DartGetWorkspaceFixesParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<DartGetWorkspaceFixesResult>> handle(
    DartGetWorkspaceFixesParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    // This implementation is similar to the Fix All in Workspace command, but
    // whereas that applies the fixes (by sending a reverse-request to the
    // client), this simply returns them. It is a request, instead of a command.

    // Use the callers client capabilities here as we return the edit to them.
    // This differs from Fix All in Workspace where we always send the edits to
    // the editor.
    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      return serverNotInitializedError;
    }

    var operation = FixAllInWorkspaceOperation(
      server: server,
      message: message,
      cancellationToken: token,
      requireConfirmation: false,
      diagnosticCodes: params.diagnosticCodes,
    );

    var result = await operation.compute();
    return await result.mapResult((result) async {
      var (edit, details) = result;
      return success(DartGetWorkspaceFixesResult(edit: edit, details: details));
    });
  }
}
