// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

final _manager = LspRefactorManager._();

/// A base class for refactoring commands that need to create Refactorings from
/// client-supplied arguments.
abstract class AbstractRefactorCommandHandler extends SimpleEditCommandHandler {
  AbstractRefactorCommandHandler(super.server);

  @override
  String get commandName => 'Perform Refactor';

  LspRefactorManager get manager => _manager;

  FutureOr<ErrorOr<void>> execute(
      String path,
      String kind,
      int offset,
      int length,
      Map<String, Object?>? options,
      CancellationToken cancellationToken,
      ProgressReporter reporter,
      int? docVersion);

  Future<ErrorOr<Refactoring>> getRefactoring(
    RefactoringKind kind,
    ResolvedUnitResult result,
    int offset,
    int length,
    Map<String, dynamic>? options,
  ) async {
    switch (kind) {
      case RefactoringKind.EXTRACT_METHOD:
        final refactor = ExtractMethodRefactoring(
            server.searchEngine, result, offset, length);

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

      case RefactoringKind.EXTRACT_LOCAL_VARIABLE:
        final refactor = ExtractLocalRefactoring(result, offset, length);

        var preferredName = options != null ? options['name'] as String : null;
        // checkInitialConditions will populate names with suggestions.
        if (preferredName == null) {
          await refactor.checkInitialConditions();
          if (refactor.names.isNotEmpty) {
            preferredName = refactor.names.first;
          }
        }
        refactor.name = preferredName ?? 'newVariable';

        // Defaults to true, but may be surprising if users didn't have an option
        // to opt in.
        refactor.extractAll = false;
        return success(refactor);

      case RefactoringKind.EXTRACT_WIDGET:
        final refactor = ExtractWidgetRefactoring(
            server.searchEngine, result, offset, length);
        // Provide a default name for clients that do not have any custom
        // handling.
        // Clients can use the information documented for refactor.perform to
        // inject their own user-provided names until LSP has some native
        // support:
        // https://github.com/microsoft/language-server-protocol/issues/764
        refactor.name =
            options != null ? options['name'] as String : 'NewWidget';
        return success(refactor);

      case RefactoringKind.INLINE_LOCAL_VARIABLE:
        final refactor =
            InlineLocalRefactoring(server.searchEngine, result, offset);
        return success(refactor);

      case RefactoringKind.INLINE_METHOD:
        final refactor =
            InlineMethodRefactoring(server.searchEngine, result, offset);
        return success(refactor);

      case RefactoringKind.CONVERT_GETTER_TO_METHOD:
        final node = NodeLocator(offset).searchWithin(result.unit);
        final element = server.getElementOfNode(node);
        if (element != null) {
          if (element is PropertyAccessorElement) {
            final refactor = ConvertGetterToMethodRefactoring(
                server.searchEngine, result.session, element);
            return success(refactor);
          }
        }
        return error(ServerErrorCodes.InvalidCommandArguments,
            'Location supplied to $commandName $kind is not longer valid');

      case RefactoringKind.CONVERT_METHOD_TO_GETTER:
        final node = NodeLocator(offset).searchWithin(result.unit);
        final element = server.getElementOfNode(node);
        if (element != null) {
          if (element is ExecutableElement) {
            final refactor = ConvertMethodToGetterRefactoring(
                server.searchEngine, result.session, element);
            return success(refactor);
          }
        }
        return error(ServerErrorCodes.InvalidCommandArguments,
            'Location supplied to $commandName $kind is not longer valid');

      default:
        return error(ServerErrorCodes.InvalidCommandArguments,
            'Unknown RefactoringKind $kind was supplied to $commandName');
    }
  }

  @override
  Future<ErrorOr<void>> handle(List<Object?>? arguments,
      ProgressReporter reporter, CancellationToken cancellationToken) async {
    if (arguments == null ||
        arguments.length != 6 ||
        arguments[0] is! String || // kind
        arguments[1] is! String || // path
        (arguments[2] != null && arguments[2] is! int) || // docVersion
        arguments[3] is! int || // offset
        arguments[4] is! int || // length
        // options
        // Important: This arguments position is documented in
        // tool/lsp_spec/README.md to allow clients with custom code (such as
        // VS Code) to intercept the request and inject options (such as a
        // user-provided name). Any changes to these arguments must be backwards
        // compatible, keeping the options in this position.
        (arguments[5] != null && arguments[5] is! Map<String, Object?>)) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message:
            '$commandName requires 6 parameters: RefactoringKind, docVersion, filePath, offset, length, options (optional)',
      ));
    }

    final kind = arguments[0] as String;
    final path = arguments[1] as String;
    final docVersion = arguments[2] as int?;
    final offset = arguments[3] as int;
    final length = arguments[4] as int;
    final options = arguments[5] as Map<String, Object?>?;

    return execute(path, kind, offset, length, options, cancellationToken,
        reporter, docVersion);
  }
}

/// Manages a running refactor to help ensure only one refactor runs at a time.
class LspRefactorManager {
  /// The cancellation token for the current in-progress refactor (or null).
  CancelableToken? _currentRefactoringCancellationToken;

  LspRefactorManager._();

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
