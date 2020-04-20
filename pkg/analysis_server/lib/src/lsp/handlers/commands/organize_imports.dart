// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/services/correction/organize_directives.dart';

class OrganizeImportsCommandHandler extends SimpleEditCommandHandler {
  OrganizeImportsCommandHandler(LspAnalysisServer server) : super(server);

  @override
  String get commandName => 'Organize Imports';

  @override
  Future<ErrorOr<void>> handle(List<dynamic> arguments) async {
    if (arguments == null || arguments.length != 1 || arguments[0] is! String) {
      return ErrorOr.error(ResponseError(
        ServerErrorCodes.InvalidCommandArguments,
        '$commandName requires a single String parameter containing the path of a Dart file',
        null,
      ));
    }

    // Get the version of the doc before we calculate edits so we can send it back
    // to the client so that they can discard this edit if the document has been
    // modified since.
    final path = arguments.single;
    final docIdentifier = server.getVersionedDocumentIdentifier(path);

    final result = await requireResolvedUnit(path);
    return result.mapResult((result) {
      final code = result.content;
      final unit = result.unit;

      if (hasScanParseErrors(result.errors)) {
        return ErrorOr.error(ResponseError(
          ServerErrorCodes.FileHasErrors,
          'Unable to $commandName because the file contains parse errors',
          path,
        ));
      }

      final organizer = DirectiveOrganizer(code, unit, result.errors);
      final edits = organizer.organize();

      return sendSourceEditsToClient(docIdentifier, unit, edits);
    });
  }
}
