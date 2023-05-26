// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/commands/abstract_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/session.dart';

class ValidateRefactorCommandHandler extends AbstractRefactorCommandHandler {
  ValidateRefactorCommandHandler(super.server);

  @override
  String get commandName => 'Validate Refactor';

  @override
  bool get recordsOwnAnalytics => true;

  @override
  FutureOr<ErrorOr<ValidateRefactorResult>> execute(
    String path,
    String kind,
    int offset,
    int length,
    Map<String, Object?>? options,
    CancellationToken cancellationToken,
    ProgressReporter reporter,
    int? docVersion,
  ) async {
    final actionName = 'dart.refactor.${kind.toLowerCase()}.validate';
    server.analyticsManager.executedCommand(actionName);

    // In order to prevent clients asking users for a method/widget name and
    // then failing because of something like "Cannot extract closure as method"
    // this command allows the client to call `checkInitialConditions()` after
    // the user selects the action but before prompting for a name.
    //
    // We do not perform that check when building the code actions because there
    // will be no visibility of the reason why the refactor is not available to
    // the user.

    final result = await requireResolvedUnit(path);
    return result.mapResult((result) async {
      final refactoring = await getRefactoring(
          RefactoringKind(kind), result, offset, length, options);
      return refactoring.mapResult((refactoring) async {
        // If the token we were given is not cancelable, wrap it with one that
        // is for the rest of this request as a future refactor may need to
        // cancel this request.
        final cancelableToken = cancellationToken.asCancelable();
        manager.begin(cancelableToken);

        try {
          reporter.begin('Preparing Refactor…');
          final status = await refactoring.checkInitialConditions();

          if (status.hasError) {
            return success(
                ValidateRefactorResult(valid: false, message: status.message!));
          }

          return success(ValidateRefactorResult(valid: true));
        } on InconsistentAnalysisException {
          return failure(fileModifiedError);
        } finally {
          manager.end(cancelableToken);
          reporter.end();
        }
      });
    });
  }
}
