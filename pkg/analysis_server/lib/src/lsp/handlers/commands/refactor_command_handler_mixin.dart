// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// A mixin with functionality common to handlers for refactor commands.
mixin RefactorCommandHandlerMixin<T> on HandlerHelperMixin, Handler<T> {
  Future<ErrorOr<T>> execute(
    ProgressReporter progress,
    ResolvedLibraryResult library,
    ResolvedUnitResult unit,
    LspClientCapabilities clientCapabilities,
    RefactoringContext context,
    List<Object?> arguments,
  );

  Future<ErrorOr<T>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    // Use the editor capabilities, since we're building edits to send to the
    // editor regardless of who called us.
    var clientCapabilities = server.editorClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    var filePath = parameters['filePath'];
    var offset = parameters['selectionOffset'];
    var length = parameters['selectionLength'];
    var arguments = _validateArguments(parameters['arguments']);
    if (filePath is! String ||
        offset is! int ||
        length is! int ||
        arguments == null) {
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.invalidCommandArguments,
          message:
              'Refactoring operations require 4 parameters: '
              'filePath: String, '
              'offset: int, '
              'length: int, '
              'arguments: List',
        ),
      );
    }

    var library = await requireResolvedLibrary(filePath);
    return library.mapResult((library) async {
      var unit = library.unitWithPath(filePath);
      if (unit == null) {
        return error(
          ErrorCodes.InternalError,
          'The library containing a path did not contain the path.',
        );
      }

      var context = RefactoringContext(
        server: server,
        startSessions: await server.currentSessions,
        resolvedLibraryResult: library,
        resolvedUnitResult: unit,
        clientCapabilities: clientCapabilities,
        selectionOffset: offset,
        selectionLength: length,
        includeExperimental:
            server.lspClientConfiguration.global.experimentalRefactors,
      );

      return await execute(
        progress,
        library,
        unit,
        clientCapabilities,
        context,
        arguments,
      );
    });
  }

  /// If the [arguments] is a list, then return it. Otherwise, return `null`
  /// to indicate that they aren't what we were expecting.
  List<Object?>? _validateArguments(Object? arguments) {
    if (arguments is! List<Object?>) {
      return null;
    }
    return arguments;
  }
}
