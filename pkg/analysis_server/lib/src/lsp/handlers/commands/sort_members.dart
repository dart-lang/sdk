// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';

class SortMembersCommandHandler extends SimpleEditCommandHandler {
  SortMembersCommandHandler(LspAnalysisServer server) : super(server);

  @override
  String get commandName => 'Sort Members';

  @override
  Future<ErrorOr<void>> handle(List<dynamic> arguments,
      ProgressReporter reporter, CancellationToken cancellationToken) async {
    if (arguments == null || arguments.length != 1 || arguments[0] is! String) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message:
            '$commandName requires a single String parameter containing the path of a Dart file',
      ));
    }

    // Get the version of the doc before we calculate edits so we can send it back
    // to the client so that they can discard this edit if the document has been
    // modified since.
    final path = arguments.single;
    final docIdentifier = server.getVersionedDocumentIdentifier(path);

    var driver = server.getAnalysisDriver(path);
    final result = await driver?.parseFile(path);

    if (cancellationToken.isCancellationRequested) {
      return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
    }

    if (result == null) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.FileNotAnalyzed,
        message: '$commandName is only available for analyzed files',
      ));
    }
    final code = result.content;
    final unit = result.unit;

    if (hasScanParseErrors(result.errors)) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.FileHasErrors,
        message:
            'Unable to $commandName because the file contains parse errors',
        data: path,
      ));
    }

    final sorter = MemberSorter(code, unit);
    final edits = sorter.sort();
    return await sendSourceEditsToClient(docIdentifier, unit, edits);
  }
}
