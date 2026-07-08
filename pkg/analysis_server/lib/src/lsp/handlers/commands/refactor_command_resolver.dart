// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/refactor_command_handler_mixin.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';

/// A sub-handler for `command/resolve` that handles resolving commands for
/// refactors by delegating them to the appropriate [RefactoringProducer].
///
/// Some of the implementation here comes from [RefactorCommandHandlerMixin]
/// which has shared logic used for both resolving and executing refactors
/// (such as building the [RefactoringContext] from the commands arguments).
class RefactorCommandResolver
    with
        HandlerHelperMixin,
        Handler<InteractiveExecuteCommandParams>,
        RefactorCommandHandlerMixin {
  final RefactoringProducerGenerator generator;

  @override
  final AnalysisServer server;

  /// The client-supplied command to be resolved.
  final InteractiveExecuteCommandParams command;

  new(this.server, this.generator, this.command);

  @override
  Future<ErrorOr<InteractiveExecuteCommandParams>> execute(
    ProgressReporter progress,
    ResolvedLibraryResult library,
    ResolvedUnitResult unit,
    LspClientCapabilities clientCapabilities,
    RefactoringContext context,
    List<Object?> arguments,
  ) async {
    var producer = generator(context);

    if (!producer.isAvailable()) {
      // Generally this shouldn't happen (because we shouldn't have produced a
      // command that isn't valid), but it could if the client allowed the file
      // to be modified and didn't cancel.
      return error(
        ErrorCodes.InvalidParams,
        'Refactor command is no longer valid at this location',
      );
    }

    // Delegate to the refactoring producer so it can handle custom validation
    // etc.
    if (producer is ParameterizedRefactoringProducer) {
      return await producer.resolve(command);
    }

    // Otherwise, pass the original command back as-is.
    return success(command);
  }
}
