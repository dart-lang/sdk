// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide MessageType;
import 'package:analysis_server/src/analysis_server.dart' show MessageType;
import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename_unit_member.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

typedef StaticOptions = Either2<bool, RenameOptions>;

class PrepareRenameHandler extends LspMessageHandler<TextDocumentPositionParams,
    TextDocumentPrepareRenameResult> {
  PrepareRenameHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_prepareRename;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<TextDocumentPrepareRenameResult>> handle(
      TextDocumentPositionParams params,
      MessageInfo message,
      CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) async {
      final node = NodeLocator(offset).searchWithin(unit.result.unit);
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

      return success(TextDocumentPrepareRenameResult.t1(PlaceholderAndRange(
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
      )));
    });
  }
}

class RenameHandler extends LspMessageHandler<RenameParams, WorkspaceEdit?>
    with LspHandlerHelperMixin {
  RenameHandler(super.server);

  LspGlobalClientConfiguration get config =>
      server.lspClientConfiguration.global;

  @override
  Method get handlesMessage => Method.textDocument_rename;

  @override
  LspJsonHandler<RenameParams> get jsonHandler => RenameParams.jsonHandler;

  /// Checks whether a client supports Rename resource operations.
  bool get _clientSupportsRename {
    final capabilities = server.lspClientCapabilities;
    return (capabilities?.documentChanges ?? false) &&
        (capabilities?.renameResourceOperations ?? false);
  }

  @override
  Future<ErrorOr<WorkspaceEdit?>> handle(
      RenameParams params, MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final textDocument = params.textDocument;
    final path = pathOfDoc(params.textDocument);
    // If the client provided us a version doc identifier, we'll use it to ensure
    // we're not computing a rename for an old document. If not, we'll just assume
    // the version the server had at the time of receiving the request is valid
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
      final node = NodeLocator(offset).searchWithin(unit.result.unit);
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
        final prompt = server.userPromptSender;

        // If this change would produce errors but we can't prompt the user,
        // just fail with the message.
        if (prompt == null) {
          return error(ServerErrorCodes.RenameNotValid, finalStatus.message!);
        }

        // Otherwise, ask the user whether to proceed with the rename.
        final userChoice = await prompt(
          MessageType.warning,
          finalStatus.message!,
          [
            UserPromptActions.renameAnyway,
            UserPromptActions.cancel,
          ],
        );

        if (token.isCancellationRequested) {
          return cancelled();
        }

        if (userChoice != UserPromptActions.renameAnyway) {
          // Return an empty workspace edit response so we do not perform any
          // rename, but also so we do not cause the client to show the user an
          // error after they clicked cancel.
          return success(emptyWorkspaceEdit);
        }
      }

      // Compute the actual change.
      // Don't include potential edits while we don't have a way for the user
      // to opt-in/out.
      // https://github.com/Dart-Code/Dart-Code/issues/4131.
      // TODO(dantup): Check whether LSP's annotated edits would allow us to
      //  send potential edits in their own group that can be easily toggled by
      //  the user.
      refactoring.includePotential = false;
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
          final oldComputedFilename = refactoring.oldName.toFileName;
          final newFilename = params.newName.toFileName;

          // Only if the existing filename matches exactly what we'd expect for
          // the original class name will we consider renaming.
          if (actualFilename == oldComputedFilename) {
            final renameConfig = config.renameFilesWithClasses;
            final shouldRename = renameConfig == 'always' ||
                (renameConfig == 'prompt' &&
                    await _promptToRenameFile(actualFilename, newFilename));
            if (shouldRename) {
              final newPath = pathContext.join(folder, newFilename);
              final renameEdit =
                  createRenameEdit(pathContext, declaringFile, newPath);
              workspaceEdit = mergeWorkspaceEdits([workspaceEdit, renameEdit]);
            }
          }
        }
      }

      return success(workspaceEdit);
    });
  }

  bool _isClassRename(RenameRefactoring refactoring) =>
      refactoring is RenameUnitMemberRefactoringImpl &&
      refactoring.element is InterfaceElement;

  /// Asks the user whether they would like to rename the file along with the
  /// class.
  Future<bool> _promptToRenameFile(
      String oldFilename, String newFilename) async {
    final prompt = server.userPromptSender;
    // If we can't prompt, do the same as if they said no.
    if (prompt == null) {
      return false;
    }

    final userChoice = await prompt(
      MessageType.info,
      "Rename '$oldFilename' to '$newFilename'?",
      [
        UserPromptActions.yes,
        UserPromptActions.no,
      ],
    );

    return userChoice == UserPromptActions.yes;
  }
}

class RenameRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  RenameRegistrations(super.info);

  @override
  ToJsonable? get options => RenameRegistrationOptions(
      documentSelector: fullySupportedTypes, prepareProvider: true);

  @override
  Method get registrationMethod => Method.textDocument_rename;

  @override
  StaticOptions get staticOptions => clientCapabilities.renameValidation
      ? Either2<bool, RenameOptions>.t2(RenameOptions(prepareProvider: true))
      : Either2<bool, RenameOptions>.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.rename;
}
