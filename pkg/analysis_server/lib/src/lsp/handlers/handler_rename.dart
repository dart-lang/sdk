// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide MessageType;
import 'package:analysis_server/src/analysis_server.dart' show MessageType;
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename_unit_member.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

AstNode? _tweakLocatedNode(AstNode? node, int offset) {
  if (node is RepresentationDeclaration) {
    var extensionTypeDeclaration = node.parent;
    if (extensionTypeDeclaration is ExtensionTypeDeclaration) {
      if (extensionTypeDeclaration.name.end == offset) {
        node = extensionTypeDeclaration;
      }
    }
  }
  return node;
}

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

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));

    return (unit, offset).mapResults((unit, offset) async {
      var node = NodeLocator(offset).searchWithin(unit.unit);
      node = _tweakLocatedNode(node, offset);
      var element = server.getElementOfNode(node);
      if (node == null || element == null) {
        return success(null);
      }

      var refactorDetails = RenameRefactoring.getElementToRename(node, element);
      if (refactorDetails == null) {
        return success(null);
      }

      var refactoring = RenameRefactoring.create(
          server.refactoringWorkspace, unit, refactorDetails.element);
      if (refactoring == null) {
        return success(null);
      }

      // Check the rename is valid here.
      var initStatus = await refactoring.checkInitialConditions();
      if (initStatus.hasFatalError) {
        return error(
            ServerErrorCodes.RenameNotValid, initStatus.problem!.message);
      }

      return success(TextDocumentPrepareRenameResult.t1(PlaceholderAndRange(
        range: toRange(
          unit.lineInfo,
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

  @override
  Future<ErrorOr<WorkspaceEdit?>> handle(
      RenameParams params, MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      return serverNotInitializedError;
    }

    var pos = params.position;
    var textDocument = params.textDocument;
    var path = pathOfDoc(params.textDocument);
    // Capture the document version so we can verify it hasn't changed after
    // we've computed the rename.
    var docIdentifier = path.mapResultSync(
        (path) => success(extractDocumentVersion(textDocument, path)));

    var unit = await path.mapResult(requireResolvedUnit);
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));

    return (path, docIdentifier, unit, offset)
        .mapResults((path, docIdentifier, unit, offset) async {
      var node = NodeLocator(offset).searchWithin(unit.unit);
      node = _tweakLocatedNode(node, offset);
      var element = server.getElementOfNode(node);
      if (node == null || element == null) {
        return success(null);
      }

      var refactorDetails = RenameRefactoring.getElementToRename(node, element);
      if (refactorDetails == null) {
        return success(null);
      }

      var refactoring = RenameRefactoring.create(
          server.refactoringWorkspace, unit, refactorDetails.element);
      if (refactoring == null) {
        return success(null);
      }

      // Check the rename is valid here.
      var initStatus = await refactoring.checkInitialConditions();
      if (token.isCancellationRequested) {
        return cancelled();
      }
      if (initStatus.hasFatalError) {
        return error(
            ServerErrorCodes.RenameNotValid, initStatus.problem!.message);
      }

      // Check the name is valid.
      refactoring.newName = params.newName;
      var optionsStatus = refactoring.checkNewName();
      if (optionsStatus.hasError) {
        return error(
            ServerErrorCodes.RenameNotValid, optionsStatus.problem!.message);
      }

      // Final validation.
      var finalStatus = await refactoring.checkFinalConditions();
      if (token.isCancellationRequested) {
        return cancelled();
      }
      if (finalStatus.hasFatalError) {
        return error(
            ServerErrorCodes.RenameNotValid, finalStatus.problem!.message);
      } else if (finalStatus.hasError || finalStatus.hasWarning) {
        var prompt = server.userPromptSender;

        // If this change would produce errors but we can't prompt the user,
        // just fail with the message.
        if (prompt == null) {
          return error(ServerErrorCodes.RenameNotValid, finalStatus.message!);
        }

        // Otherwise, ask the user whether to proceed with the rename.
        var userChoice = await prompt(
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
      var change = await refactoring.createChange();
      if (token.isCancellationRequested) {
        return cancelled();
      }

      // Before we send anything back, ensure the original file didn't change
      // while we were computing changes.
      if (fileHasBeenModified(path, docIdentifier.version)) {
        return fileModifiedError;
      }

      var workspaceEdit =
          createWorkspaceEdit(server, clientCapabilities, change);

      // Check whether we should handle renaming the file to match the class.
      if (_clientSupportsRename(clientCapabilities) &&
          _isClassRename(refactoring)) {
        // The rename must always be performed on the file that defines the
        // class which is not necessarily the one where the rename was invoked.
        var declaringFile = (refactoring as RenameUnitMemberRefactoringImpl)
            .element
            .declaration
            ?.source
            ?.fullName;
        if (declaringFile != null) {
          var folder = pathContext.dirname(declaringFile);
          var actualFilename = pathContext.basename(declaringFile);
          var oldComputedFilename = refactoring.oldName.toFileName;
          var newFilename = params.newName.toFileName;

          // Only if the existing filename matches exactly what we'd expect for
          // the original class name will we consider renaming.
          if (actualFilename == oldComputedFilename) {
            var renameConfig = config.renameFilesWithClasses;
            var shouldRename = renameConfig == 'always' ||
                (renameConfig == 'prompt' &&
                    await _promptToRenameFile(actualFilename, newFilename));
            if (shouldRename) {
              var newPath = pathContext.join(folder, newFilename);
              var renameEdit =
                  createRenameEdit(uriConverter, declaringFile, newPath);
              workspaceEdit = mergeWorkspaceEdits([workspaceEdit, renameEdit]);
            }
          }
        }
      }

      return success(workspaceEdit);
    });
  }

  /// Checks whether the client supports Rename resource operations.
  bool _clientSupportsRename(LspClientCapabilities clientCapabilities) {
    return clientCapabilities.documentChanges &&
        clientCapabilities.renameResourceOperations;
  }

  bool _isClassRename(RenameRefactoring refactoring) =>
      refactoring is RenameUnitMemberRefactoringImpl &&
      refactoring.element is InterfaceElement;

  /// Asks the user whether they would like to rename the file along with the
  /// class.
  Future<bool> _promptToRenameFile(
      String oldFilename, String newFilename) async {
    var prompt = server.userPromptSender;
    // If we can't prompt, do the same as if they said no.
    if (prompt == null) {
      return false;
    }

    var userChoice = await prompt(
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
