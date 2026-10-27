// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer/dart/analysis/results.dart';

/// Wraps a [checkAbort] function to also report cancellation of
/// [additionalToken].
ErrorOr<T>? Function() appendToken<T>(
  ErrorOr<T>? Function() checkAbort,
  CancelableToken additionalToken,
) {
  return () {
    if (additionalToken.isCancellationRequested) {
      return cancelled<T>(additionalToken);
    }
    return checkAbort();
  };
}

/// A base class for the legacy refactoring commands (EXTRACT_WIDGET, etc.) that
/// need to create [Refactoring]s from client-supplied arguments.
abstract class AbstractRefactorCommandHandler
    extends SimpleEditCommandHandler<AnalysisServer>
    with PositionalArgCommandHandler {
  new(super.server);

  @override
  String get commandName => 'Perform Refactor';

  /// The (singleton) [LspRefactorManager] used for cancelling refactors when
  /// another is started.
  LspRefactorManager get manager => LspRefactorManager.instance;

  FutureOr<ErrorOr<void>> execute(
    MessageInfo message,
    ResolvedUnitResult unit,
    String kind,
    int offset,
    int length,
    Map<String, Object?>? options,
    LspClientCapabilities clientCapabilities,
    CancellationToken cancellationToken,
    ProgressReporter reporter,
    ErrorOr<void>? Function() checkAbort,
  );

  Future<ErrorOr<Refactoring>> getRefactoring(
    RefactoringKind kind,
    ResolvedUnitResult result,
    int offset,
    int length,
    Map<String, Object?>? options,
  ) async {
    switch (kind) {
      case RefactoringKind.EXTRACT_METHOD:
        var refactor = ExtractMethodRefactoring(
          server.searchEngine,
          result,
          offset,
          length,
        );

        var preferredName = options != null ? options['name'] as String : null;
        // checkInitialConditions will populate names with suggestions.
        if (preferredName == null) {
          await refactor.checkInitialConditions();
          if (refactor.names.isNotEmpty) {
            preferredName = refactor.names.first;
          }
        }
        refactor.name = preferredName ?? 'newMethod';

        // Defaults to true, but may be surprising if users didn't have an option
        // to opt in.
        refactor.extractAll = false;
        return success(refactor);

      case RefactoringKind.EXTRACT_WIDGET:
        var refactor = ExtractWidgetRefactoring(
          server.searchEngine,
          result,
          offset,
          length,
        );
        // Provide a default name for clients that do not have any custom
        // handling.
        // Clients can use the information documented for refactor.perform to
        // inject their own user-provided names until LSP has some native
        // support:
        // https://github.com/microsoft/language-server-protocol/issues/764
        refactor.name = options != null
            ? options['name'] as String
            : 'NewWidget';
        return success(refactor);

      default:
        return error(
          ServerErrorCodes.invalidCommandArguments,
          'Unknown RefactoringKind $kind was supplied to $commandName',
        );
    }
  }

  @override
  Future<ErrorOr<void>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      return serverNotInitializedError;
    }

    if (parameters['kind'] is! String ||
        // TODO(dantup): We should migrate this to URIs.
        parameters['path'] is! String ||
        (parameters['docVersion'] is! int?) ||
        parameters['offset'] is! int ||
        parameters['length'] is! int ||
        (parameters['options'] is! Map<String, Object?>?)) {
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.invalidCommandArguments,
          message:
              '$commandName requires 6 parameters: '
              'kind: String (RefactoringKind), '
              'filePath: String, '
              'docVersion: int?, '
              'offset: int, '
              'length: int, '
              'options: Map<String, Object?>',
        ),
      );
    }

    var kind = parameters['kind'] as String;
    var path = parameters['path'] as String;
    var docVersion = parameters['docVersion'] as int?;
    var offset = parameters['offset'] as int;
    var length = parameters['length'] as int;
    var options = parameters['options'] as Map<String, Object?>?;

    // Use the client's version (if any) so we detect modifications made since
    // the client built the command, not only since this request started.
    var textDocument = OptionalVersionedTextDocumentIdentifier(
      uri: uriConverter.toClientUri(path),
      version: docVersion,
    );

    return withResolvedUnit(textDocument: textDocument, cancellationToken, (
      unit,
      _,
      checkAbort,
    ) async {
      return await execute(
        message,
        unit,
        kind,
        offset,
        length,
        options,
        clientCapabilities,
        cancellationToken,
        progress,
        checkAbort,
      );
    });
  }

  /// Parses "legacy" arguments passed a list, rather than in a map as a single
  /// argument.
  ///
  /// This is provided for backwards compatibility and is only supported by
  /// handlers intended to be called by clients with their own built arguments.
  @override
  Map<String, Object?> parseArgList(List<Object?> arguments) {
    if (arguments.length != 6) {
      return {};
    }

    return {
      'kind': arguments[0],
      'path': arguments[1],
      'docVersion': arguments[2],
      'offset': arguments[3],
      'length': arguments[4],
      // options
      // This field is overwritten (by index) by older versions of Dart-Code
      // that are not using Maps (prior to v3.42, 2022-06-01) so the index of
      // this item must not change.
      'options': arguments[5],
    };
  }
}

/// Manages a running refactor to help ensure only one refactor runs at a time.
class LspRefactorManager {
  /// A singleton [LspRefactorManager] used for cancelling refactors when
  /// another is started.
  static final instance = LspRefactorManager._();

  /// The cancellation token for the current in-progress refactor (or null).
  CancelableToken? _currentRefactoringCancellationToken;

  new _();

  /// Begins a new refactor, cancelling any other in-progress refactors.
  void begin(CancelableToken cancelToken) {
    _currentRefactoringCancellationToken?.cancel(
      reason:
          'Another workspace/executeCommand request for a refactor was started',
    );
    _currentRefactoringCancellationToken = cancelToken;
  }

  /// Marks a refactor as no longer current.
  void end(CancelableToken cancelToken) {
    if (_currentRefactoringCancellationToken == cancelToken) {
      _currentRefactoringCancellationToken = null;
    }
  }
}
