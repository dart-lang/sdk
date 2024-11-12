// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/correction/organize_imports.dart';

class OrganizeImportsCommandHandler extends SimpleEditCommandHandler {
  OrganizeImportsCommandHandler(super.server);

  @override
  String get commandName => 'Organize Imports';

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
          code: ServerErrorCodes.InvalidCommandArguments,
          message: '$commandName requires a Map argument containing a "path"',
        ),
      );
    }

    // Get the version of the doc before we calculate edits so we can send it back
    // to the client so that they can discard this edit if the document has been
    // modified since.
    var path = parameters['path'] as String;
    var docIdentifier = server.getVersionedDocumentIdentifier(path);
    var autoTriggered = (parameters['autoTriggered'] as bool?) ?? false;

    var result = await requireResolvedUnit(path);

    if (cancellationToken.isCancellationRequested) {
      return cancelled(cancellationToken);
    }

    return result.mapResult((result) async {
      var code = result.content;
      var unit = result.unit;

      if (hasScanParseErrors(result.errors)) {
        if (autoTriggered) {
          return success(null);
        }
        return ErrorOr.error(
          ResponseError(
            code: ServerErrorCodes.FileHasErrors,
            message:
                'Unable to $commandName because the file contains parse errors',
            data: path,
          ),
        );
      }

      var organizer = ImportOrganizer(code, unit, result.errors);
      var edits = organizer.organize();

      if (edits.isEmpty) {
        return success(null);
      }

      return await sendSourceEditsToClient(docIdentifier, unit, edits);
    });
  }
}
