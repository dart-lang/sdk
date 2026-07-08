// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
library;

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/refactor_command_resolver.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';

/// A handler for the [CustomMethods.resolveCommand] custom request that allows
/// collecting user input via interactive form fields.
///
/// This handler is the main entry point for the LSP request and delegates to
/// sub-handlers like [RefactorCommandResolver] depending on the command that
/// needs resolving.
class CommandResolveHandler
    extends
        SharedMessageHandler<
          InteractiveExecuteCommandParams,
          InteractiveExecuteCommandParams
        > {
  new(super.server);

  @override
  Method get handlesMessage => CustomMethods.resolveCommand;

  @override
  LspJsonHandler<InteractiveExecuteCommandParams> get jsonHandler =>
      InteractiveExecuteCommandParams.jsonHandler;

  @override
  // This command is used as part of interactive forms and not expected to be
  // used by non-editor clients.
  bool get requiresTrustedCaller => true;

  @override
  Future<ErrorOr<InteractiveExecuteCommandParams>> handle(
    InteractiveExecuteCommandParams command,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (RefactoringProcessor.generators[command.command] case var generator?) {
      return await _handleRefactorCommand(command, generator, message, token);
    }

    return success(command);
  }

  /// Handles resolving a command that relates to a refactor by using
  /// [RefactorCommandResolver] to delegate to the [RefactoringProducer].
  Future<ErrorOr<InteractiveExecuteCommandParams>> _handleRefactorCommand(
    InteractiveExecuteCommandParams command,
    RefactoringProducerGenerator generator,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (command.arguments case [Map<String, Object?> arguments]) {
      var resolver = RefactorCommandResolver(server, generator, command);
      return await resolver.handle(
        message,
        arguments,
        ProgressReporter.noop,
        token,
      );
    } else {
      return error(
        ErrorCodes.InvalidParams,
        'Refactor commands should always have exactly one argument, which is a map',
      );
    }
  }
}
