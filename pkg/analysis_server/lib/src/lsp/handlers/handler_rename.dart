// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/rename_unit_member.dart';
import 'package:analyzer/dart/element/element.dart';

class PrepareRenameHandler
    extends MessageHandler<TextDocumentPositionParams, RangeAndPlaceholder?> {
  PrepareRenameHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_prepareRename;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<RangeAndPlaceholder?>> handle(
      TextDocumentPositionParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) async {
      final node = await server.getNodeAtOffset(path.result, offset);
      final element = server.getElementOfNode(node);
      if (node == null || element == null) {
        return success(null);
      }

      final refactorDetails =
          RenameRefactoring.getElementToRename(node, element);
      if (refactorDetails == null) {
        return success(null);
      }

      final refactoring = RenameRefactoring.create(
          server.refactoringWorkspace, unit.result, refactorDetails.element);
      if (refactoring == null) {
        return success(null);
      }

      // Check the rename is valid here.
      final initStatus = await refactoring.checkInitialConditions();
      if (initStatus.hasFatalError) {
        return error(
            ServerErrorCodes.RenameNotValid, initStatus.problem!.message, null);
      }

      return success(RangeAndPlaceholder(
        range: toRange(
          unit.result.lineInfo,
          // If the offset is set to -1 it means there is no location for the
          // old name. However since we must provide a range for LSP, we'll use
          // a 0-character span at the originally requested location to ensure
          // it's valid.
          refactorDetails.offset == -1 ? offset : refactorDetails.offset,
          refactorDetails.length,
        ),
        placeholder: refactoring.oldName,
      ));
    });
  }
}

class RenameHandler extends MessageHandler<RenameParams, WorkspaceEdit?> {
  final _upperCasePattern = RegExp('[A-Z]');

  RenameHandler(LspAnalysisServer server) : super(server);

  LspGlobalClientConfiguration get config => server.clientConfiguration.global;

  @override
  Method get handlesMessage => Method.textDocument_rename;

  @override
  LspJsonHandler<RenameParams> get jsonHandler => RenameParams.jsonHandler;

  /// Checks whether a client supports Rename resource operations.
  bool get _clientSupportsRename {
    final capabilities = server.clientCapabilities;
    return (capabilities?.documentChanges ?? false) &&
        (capabilities?.renameResourceOperations ?? false);
  }

  @override
  Future<ErrorOr<WorkspaceEdit?>> handle(
      RenameParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final textDocument = params.textDocument;
    final path = pathOfDoc(params.textDocument);
    // If the client provided us a version doc identifier, we'll use it to ensure
    // we're not computing a rename for an old document. If not, we'll just assume
    // the version the server had at the time of recieving the request is valid
    // and then use it to verify the document hadn't changed again before we
    // send the edits.
    final docIdentifier = await path.mapResult((path) => success(
        textDocument is OptionalVersionedTextDocumentIdentifier
            ? textDocument
            : textDocument is VersionedTextDocumentIdentifier
                ? OptionalVersionedTextDocumentIdentifier(
                    uri: textDocument.uri, version: textDocument.version)
                : server.getVersionedDocumentIdentifier(path)));

    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) async {
      final node = await server.getNodeAtOffset(path.result, offset);
      final element = server.getElementOfNode(node);
      if (node == null || element == null) {
        return success(null);
      }

      final refactorDetails =
          RenameRefactoring.getElementToRename(node, element);
      if (refactorDetails == null) {
        return success(null);
      }

      final refactoring = RenameRefactoring.create(
          server.refactoringWorkspace, unit.result, refactorDetails.element);
      if (refactoring == null) {
        return success(null);
      }

      // Check the rename is valid here.
      final initStatus = await refactoring.checkInitialConditions();
      if (token.isCancellationRequested) {
        return cancelled();
      }
      if (initStatus.hasFatalError) {
        return error(
            ServerErrorCodes.RenameNotValid, initStatus.problem!.message, null);
      }

      // Check the name is valid.
      refactoring.newName = params.newName;
      final optionsStatus = refactoring.checkNewName();
      if (optionsStatus.hasError) {
        return error(ServerErrorCodes.RenameNotValid,
            optionsStatus.problem!.message, null);
      }

      // Final validation.
      final finalStatus = await refactoring.checkFinalConditions();
      if (token.isCancellationRequested) {
        return cancelled();
      }
      if (finalStatus.hasFatalError) {
        return error(ServerErrorCodes.RenameNotValid,
            finalStatus.problem!.message, null);
      } else if (finalStatus.hasError || finalStatus.hasWarning) {
        // Ask the user whether to proceed with the rename.
        final userChoice = await server.showUserPrompt(
          MessageType.Warning,
          finalStatus.message!,
          [
            MessageActionItem(title: UserPromptActions.renameAnyway),
            MessageActionItem(title: UserPromptActions.cancel),
          ],
        );

        if (token.isCancellationRequested) {
          return cancelled();
        }

        if (userChoice.title != UserPromptActions.renameAnyway) {
          // Return an empty workspace edit response so we do not perform any
          // rename, but also so we do not cause the client to show the user an
          // error after they clicked cancel.
          return success(emptyWorkspaceEdit);
        }
      }

      // Compute the actual change.
      final change = await refactoring.createChange();
      if (token.isCancellationRequested) {
        return cancelled();
      }

      // Before we send anything back, ensure the original file didn't change
      // while we were computing changes.
      if (fileHasBeenModified(path.result, docIdentifier.result.version)) {
        return fileModifiedError;
      }

      var workspaceEdit = createWorkspaceEdit(server, change);

      // Check whether we should handle renaming the file to match the class.
      if (_clientSupportsRename && _isClassRename(refactoring)) {
        final pathContext = server.resourceProvider.pathContext;
        // The rename must always be performed on the file that defines the
        // class which is not necessarily the one where the rename was invoked.
        final declaringFile = (refactoring as RenameUnitMemberRefactoringImpl)
            .element
            .declaration
            ?.source
            ?.fullName;
        if (declaringFile != null) {
          final folder = pathContext.dirname(declaringFile);
          final actualFilename = pathContext.basename(declaringFile);
          final oldComputedFilename =
              _fileNameForClassName(refactoring.oldName);
          final newFilename = _fileNameForClassName(params.newName);

          // Only if the existing filename matches exactly what we'd expect for
          // the original class name will we consider renaming.
          if (actualFilename == oldComputedFilename) {
            final renameConfig = config.renameFilesWithClasses;
            final shouldRename = renameConfig == 'always' ||
                (renameConfig == 'prompt' &&
                    await _promptToRenameFile(actualFilename, newFilename));
            if (shouldRename) {
              final newPath = pathContext.join(folder, newFilename);
              final renameEdit = createRenameEdit(declaringFile, newPath);
              workspaceEdit = mergeWorkspaceEdits([workspaceEdit, renameEdit]);
            }
          }
        }
      }

      return success(workspaceEdit);
    });
  }

  /// Computes a filename for a given class name (convert from PascalCase to
  /// snake_case).
  String _fileNameForClassName(String className) {
    final fileName = className
        .replaceAllMapped(_upperCasePattern,
            (match) => match.start == 0 ? match[0]! : '_${match[0]}')
        .toLowerCase();
    return '$fileName.dart';
  }

  bool _isClassRename(RenameRefactoring refactoring) =>
      refactoring is RenameUnitMemberRefactoringImpl &&
      refactoring.element is ClassElement;

  /// Asks the user whether they would like to rename the file along with the
  /// class.
  Future<bool> _promptToRenameFile(
      String oldFilename, String newFilename) async {
    final userChoice = await server.showUserPrompt(
      MessageType.Info,
      "Rename '$oldFilename' to '$newFilename'?",
      [
        MessageActionItem(title: UserPromptActions.yes),
        MessageActionItem(title: UserPromptActions.no),
      ],
    );

    return userChoice.title == UserPromptActions.yes;
  }
}
