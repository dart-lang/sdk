// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';

final _manager = _RefactorManager();

class PerformRefactorCommandHandler extends SimpleEditCommandHandler {
  PerformRefactorCommandHandler(LspAnalysisServer server) : super(server);

  @override
  String get commandName => 'Perform Refactor';

  @override
  Future<ErrorOr<void>> handle(List<dynamic> arguments,
      ProgressReporter reporter, CancellationToken cancellationToken) async {
    if (arguments == null ||
        arguments.length != 6 ||
        arguments[0] is! String || // kind
        arguments[1] is! String || // path
        (arguments[2] != null && arguments[2] is! int) || // docVersion
        arguments[3] is! int || // offset
        arguments[4] is! int || // length
        // options
        (arguments[5] != null && arguments[5] is! Map<String, dynamic>)) {
      // length
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message:
            '$commandName requires 6 parameters: RefactoringKind, docVersion, filePath, offset, length, options (optional)',
      ));
    }

    String kind = arguments[0];
    String path = arguments[1];
    int docVersion = arguments[2];
    int offset = arguments[3];
    int length = arguments[4];
    Map<String, dynamic> options = arguments[5];

    final result = await requireResolvedUnit(path);
    return result.mapResult((result) async {
      return _getRefactoring(
              RefactoringKind(kind), result, offset, length, options)
          .mapResult((refactoring) async {
        // If the token we were given is not cancellable, replace it with one that
        // is for the rest of this request, as a future refactor may need to cancel
        // this request.
        if (cancellationToken is! CancelableToken) {
          cancellationToken = CancelableToken();
        }
        _manager.begin(cancellationToken);

        try {
          reporter.begin('Refactoring…');
          final status = await refactoring.checkAllConditions();

          if (status.hasError) {
            return error(ServerErrorCodes.RefactorFailed, status.message);
          }

          if (cancellationToken.isCancellationRequested) {
            return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
          }

          final change = await refactoring.createChange();

          if (cancellationToken.isCancellationRequested) {
            return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
          }

          // If the file changed while we were validating and preparing the change,
          // we should fail to avoid sending bad edits.
          if (fileHasBeenModified(path, docVersion)) {
            return fileModifiedError;
          }

          final edit = createWorkspaceEdit(server, change.edits);
          return await sendWorkspaceEditToClient(edit);
        } on InconsistentAnalysisException {
          return fileModifiedError;
        } finally {
          _manager.end(cancellationToken);
          reporter.end();
        }
      });
    });
  }

  ErrorOr<Refactoring> _getRefactoring(
    RefactoringKind kind,
    ResolvedUnitResult result,
    int offset,
    int length,
    Map<String, dynamic> options,
  ) {
    switch (kind) {
      case RefactoringKind.EXTRACT_METHOD:
        final refactor = ExtractMethodRefactoring(
            server.searchEngine, result, offset, length);
        // TODO(dantup): For now we don't have a good way to prompt the user
        // for a method name so we just use a placeholder and expect them to
        // rename (this is what C#/Omnisharp does), but there's an open request
        // to handle this better.
        // https://github.com/microsoft/language-server-protocol/issues/764
        refactor.name =
            (options != null ? options['name'] : null) ?? 'newMethod';
        // Defaults to true, but may be surprising if users didn't have an option
        // to opt in.
        refactor.extractAll = false;
        return success(refactor);

      case RefactoringKind.EXTRACT_WIDGET:
        final refactor = ExtractWidgetRefactoring(
            server.searchEngine, result, offset, length);
        // TODO(dantup): For now we don't have a good way to prompt the user
        // for a method name so we just use a placeholder and expect them to
        // rename (this is what C#/Omnisharp does), but there's an open request
        // to handle this better.
        // https://github.com/microsoft/language-server-protocol/issues/764
        refactor.name =
            (options != null ? options['name'] : null) ?? 'NewWidget';
        return success(refactor);

      default:
        return error(ServerErrorCodes.InvalidCommandArguments,
            'Unknown RefactoringKind $kind was supplied to $commandName');
    }
  }
}

/// Manages a running refactor to help ensure only one refactor runs at a time.
class _RefactorManager {
  /// The cancellation token for the current in-progress refactor (or null).
  CancelableToken _currentRefactoringCancellationToken;

  /// Begins a new refactor, cancelling any other in-progress refactors.
  void begin(CancelableToken cancelToken) {
    _currentRefactoringCancellationToken?.cancel();
    _currentRefactoringCancellationToken = cancelToken;
  }

  /// Marks a refactor as no longer current.
  void end(CancelableToken cancelToken) {
    if (_currentRefactoringCancellationToken == cancelToken) {
      _currentRefactoringCancellationToken = null;
    }
  }
}
