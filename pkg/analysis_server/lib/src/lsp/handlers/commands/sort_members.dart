// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';

class SortMembersCommandHandler extends SimpleEditCommandHandler {
  new(super.server);

  @override
  String get commandName => 'Sort Members';

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
    var autoTriggered = (parameters['autoTriggered'] as bool?) ?? false;

    return await withParsedUnit(path: path, cancellationToken, (
      result,
      docIdentifier,
      _,
    ) async {
      var code = result.content;
      var unit = result.unit;

      if (hasScanParseErrors(result.diagnostics)) {
        // When auto-triggered (such as on save), ignore files that aren't
        // analyzed.
        if (autoTriggered) {
          return success(null);
        }
        return ErrorOr.error(
          ResponseError(
            code: ServerErrorCodes.fileHasErrors,
            message:
                'Unable to $commandName because the file contains parse errors',
            data: path,
          ),
        );
      }

      var sorter = MemberSorter(
        code,
        unit,
        result.analysisOptions.codeStyleOptions,
        result.lineInfo,
      );
      var edits = sorter.sort();

      if (edits.isEmpty) {
        return success(null);
      }

      return await sendSourceEditsToClient(docIdentifier, unit, edits);
    });
  }
}
