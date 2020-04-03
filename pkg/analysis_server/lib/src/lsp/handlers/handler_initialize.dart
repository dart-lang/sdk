// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

/// Helper for reading client dynamic registrations which may be ommitted by the
/// client.
class ClientDynamicRegistrations {
  /// All dynamic registrations supported by the Dart LSP server.
  ///
  /// Anything listed here and supported by the client will not send a static
  /// registration but intead dynamically register (usually only for a subset of
  /// files such as for .dart/pubspec.yaml/etc).
  ///
  /// When adding new capabilities that will be registered dynamically, the
  /// test_dynamicRegistration_XXX tests in `lsp/initialization_test.dart` should
  /// also be updated to ensure no double-registrations.
  static const supported = [
    Method.textDocument_didOpen,
    Method.textDocument_didChange,
    Method.textDocument_didClose,
    Method.textDocument_completion,
    Method.textDocument_hover,
    Method.textDocument_signatureHelp,
    Method.textDocument_references,
    Method.textDocument_documentHighlight,
    Method.textDocument_formatting,
    Method.textDocument_onTypeFormatting,
    Method.textDocument_definition,
    Method.textDocument_codeAction,
    Method.textDocument_rename,
    Method.textDocument_foldingRange,
  ];
  final ClientCapabilities _capabilities;

  ClientDynamicRegistrations(this._capabilities);

  bool get codeActions =>
      _capabilities.textDocument?.foldingRange?.dynamicRegistration ?? false;

  bool get completion =>
      _capabilities.textDocument?.completion?.dynamicRegistration ?? false;

  bool get definition =>
      _capabilities.textDocument?.definition?.dynamicRegistration ?? false;

  bool get documentHighlights =>
      _capabilities.textDocument?.documentHighlight?.dynamicRegistration ??
      false;

  bool get documentSymbol =>
      _capabilities.textDocument?.documentSymbol?.dynamicRegistration ?? false;

  bool get folding =>
      _capabilities.textDocument?.foldingRange?.dynamicRegistration ?? false;

  bool get formatting =>
      _capabilities.textDocument?.formatting?.dynamicRegistration ?? false;

  bool get hover =>
      _capabilities.textDocument?.hover?.dynamicRegistration ?? false;

  bool get implementation =>
      _capabilities.textDocument?.implementation?.dynamicRegistration ?? false;

  bool get references =>
      _capabilities.textDocument?.references?.dynamicRegistration ?? false;

  bool get rename =>
      _capabilities.textDocument?.rename?.dynamicRegistration ?? false;

  bool get signatureHelp =>
      _capabilities.textDocument?.signatureHelp?.dynamicRegistration ?? false;

  bool get textSync =>
      _capabilities.textDocument?.synchronization?.dynamicRegistration ?? false;

  bool get typeFormatting =>
      _capabilities.textDocument?.onTypeFormatting?.dynamicRegistration ??
      false;
}

class InitializeMessageHandler
    extends MessageHandler<InitializeParams, InitializeResult> {
  InitializeMessageHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.initialize;

  @override
  LspJsonHandler<InitializeParams> get jsonHandler =>
      InitializeParams.jsonHandler;

  @override
  ErrorOr<InitializeResult> handle(
      InitializeParams params, CancellationToken token) {
    server.handleClientConnection(
      params.capabilities,
      params.initializationOptions,
    );

    final openWorkspacePaths = <String>[];
    // The onlyAnalyzeProjectsWithOpenFiles flag allows opening huge folders
    // without setting them as analysis roots. Instead, analysis roots will be
    // based only on the open files.
    if (!server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
      if (params.workspaceFolders != null) {
        params.workspaceFolders.forEach((wf) {
          openWorkspacePaths.add(Uri.parse(wf.uri).toFilePath());
        });
      }
      if (params.rootUri != null) {
        openWorkspacePaths.add(Uri.parse(params.rootUri).toFilePath());
        // ignore: deprecated_member_use_from_same_package
      } else if (params.rootPath != null) {
        // This is deprecated according to LSP spec, but we still want to support
        // it in case older clients send us it.
        // ignore: deprecated_member_use_from_same_package
        openWorkspacePaths.add(params.rootPath);
      }
    }

    server.messageHandler = InitializingStateMessageHandler(
      server,
      openWorkspacePaths,
    );

    final codeActionLiteralSupport =
        params.capabilities.textDocument?.codeAction?.codeActionLiteralSupport;

    final renameOptionsSupport =
        params.capabilities.textDocument?.rename?.prepareSupport ?? false;

    final dynamicRegistrations =
        ClientDynamicRegistrations(params.capabilities);

    // When adding new capabilities to the server that may apply to specific file
    // types, it's important to update
    // [IntializedMessageHandler._performDynamicRegistration()] to notify
    // supporting clients of this. This avoids clients needing to hard-code the
    // list of what files types we support (and allows them to avoid sending
    // requests where we have only partial support for some types).
    server.capabilities = ServerCapabilities(
        dynamicRegistrations.textSync
            ? null
            : Either2<TextDocumentSyncOptions, num>.t1(TextDocumentSyncOptions(
                // The open/close and sync kind flags are registered dynamically if the
                // client supports them, so these static registrations are based on whether
                // the client supports dynamic registration.
                true,
                TextDocumentSyncKind.Incremental,
                false,
                false,
                null,
              )),
        dynamicRegistrations.hover ? null : true, // hoverProvider
        dynamicRegistrations.completion
            ? null
            : CompletionOptions(
                true, // resolveProvider
                dartCompletionTriggerCharacters,
              ),
        dynamicRegistrations.signatureHelp
            ? null
            : SignatureHelpOptions(
                dartSignatureHelpTriggerCharacters,
              ),
        dynamicRegistrations.definition ? null : true, // definitionProvider
        null,
        dynamicRegistrations.implementation
            ? null
            : true, // implementationProvider
        dynamicRegistrations.references ? null : true, // referencesProvider
        dynamicRegistrations.documentHighlights
            ? null
            : true, // documentHighlightProvider
        dynamicRegistrations.documentSymbol
            ? null
            : true, // documentSymbolProvider
        true, // workspaceSymbolProvider
        // "The `CodeActionOptions` return type is only valid if the client
        // signals code action literal support via the property
        // `textDocument.codeAction.codeActionLiteralSupport`."
        dynamicRegistrations.codeActions
            ? null
            : codeActionLiteralSupport != null
                ? Either2<bool, CodeActionOptions>.t2(
                    CodeActionOptions(DartCodeActionKind.serverSupportedKinds))
                : Either2<bool, CodeActionOptions>.t1(true),
        null,
        dynamicRegistrations.formatting
            ? null
            : true, // documentFormattingProvider
        false, // documentRangeFormattingProvider
        dynamicRegistrations.typeFormatting
            ? null
            : DocumentOnTypeFormattingOptions(
                dartTypeFormattingCharacters.first,
                dartTypeFormattingCharacters.skip(1).toList()),
        dynamicRegistrations.rename
            ? null
            : renameOptionsSupport
                ? Either2<bool, RenameOptions>.t2(RenameOptions(true))
                : Either2<bool, RenameOptions>.t1(true),
        null,
        null,
        dynamicRegistrations.folding ? null : true, // foldingRangeProvider
        null, // declarationProvider
        ExecuteCommandOptions(Commands.serverSupportedCommands),
        ServerCapabilitiesWorkspace(
            ServerCapabilitiesWorkspaceFolders(true, true)),
        null);

    return success(InitializeResult(server.capabilities));
  }
}
