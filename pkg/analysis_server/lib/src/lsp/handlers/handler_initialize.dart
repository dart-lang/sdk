// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class InitializeMessageHandler
    extends MessageHandler<InitializeParams, InitializeResult> {
  InitializeMessageHandler(LspAnalysisServer server) : super(server);

  Method get handlesMessage => Method.initialize;

  @override
  LspJsonHandler<InitializeParams> get jsonHandler =>
      InitializeParams.jsonHandler;

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

    server.messageHandler = new InitializingStateMessageHandler(
      server,
      openWorkspacePaths,
    );

    final codeActionLiteralSupport =
        params.capabilities.textDocument?.codeAction?.codeActionLiteralSupport;

    final renameOptionsSupport =
        params.capabilities.textDocument?.rename?.prepareSupport ?? false;

    final dynamicTextSyncRegistration = params
            .capabilities.textDocument?.synchronization?.dynamicRegistration ??
        false;

    // When adding new capabilities to the server that may apply to specific file
    // types, it's important to update
    // [IntializedMessageHandler._performDynamicRegistration()] to notify
    // supporting clients of this. This avoids clients needing to hard-code the
    // list of what files types we support (and allows them to avoid sending
    // requests where we have only partial support for some types).
    server.capabilities = new ServerCapabilities(
        Either2<TextDocumentSyncOptions, num>.t1(new TextDocumentSyncOptions(
          // The open/close and sync kind flags are registered dynamically if the
          // client supports them, so these static registrations are based on whether
          // the client supports dynamic registration.
          dynamicTextSyncRegistration ? false : true,
          dynamicTextSyncRegistration
              ? TextDocumentSyncKind.None
              : TextDocumentSyncKind.Incremental,
          false,
          false,
          null,
        )),
        true, // hoverProvider
        new CompletionOptions(
          true, // resolveProvider
          dartCompletionTriggerCharacters,
        ),
        new SignatureHelpOptions(
          dartSignatureHelpTriggerCharacters,
        ),
        true, // definitionProvider
        null,
        true, // implementationProvider
        true, // referencesProvider
        true, // documentHighlightProvider
        true, // documentSymbolProvider
        true, // workspaceSymbolProvider
        // "The `CodeActionOptions` return type is only valid if the client
        // signals code action literal support via the property
        // `textDocument.codeAction.codeActionLiteralSupport`."
        codeActionLiteralSupport != null
            ? Either2<bool, CodeActionOptions>.t2(
                new CodeActionOptions(DartCodeActionKind.serverSupportedKinds))
            : Either2<bool, CodeActionOptions>.t1(true),
        null,
        true, // documentFormattingProvider
        false, // documentRangeFormattingProvider
        new DocumentOnTypeFormattingOptions(dartTypeFormattingCharacters.first,
            dartTypeFormattingCharacters.skip(1).toList()),
        renameOptionsSupport
            ? Either2<bool, RenameOptions>.t2(new RenameOptions(true))
            : Either2<bool, RenameOptions>.t1(true),
        null,
        null,
        true, // foldingRangeProvider
        null, // declarationProvider
        new ExecuteCommandOptions(Commands.serverSupportedCommands),
        new ServerCapabilitiesWorkspace(
            new ServerCapabilitiesWorkspaceFolders(true, true)),
        null);

    return success(new InitializeResult(server.capabilities));
  }
}
