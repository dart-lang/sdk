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
  InitializeParams convertParams(Map<String, dynamic> json) =>
      InitializeParams.fromJson(json);

  ErrorOr<InitializeResult> handle(InitializeParams params) {
    final openWorkspacePaths = <String>[];

    if (params.workspaceFolders != null) {
      params.workspaceFolders.forEach((wf) {
        openWorkspacePaths.add(Uri.parse(wf.uri).toFilePath());
      });
    }
    if (params.rootUri != null) {
      openWorkspacePaths.add(Uri.parse(params.rootUri).toFilePath());
      // ignore: deprecated_member_use
    } else if (params.rootPath != null) {
      // This is deprecated according to LSP spec, but we still want to support
      // it in case older clients send us it.
      // ignore: deprecated_member_use
      openWorkspacePaths.add(params.rootPath);
    }

    server.handleClientConnection(params.capabilities);
    server.messageHandler =
        new InitializingStateMessageHandler(server, openWorkspacePaths);

    final codeActionLiteralSupport =
        params.capabilities.textDocument?.codeAction?.codeActionLiteralSupport;

    final renameOptionsSupport =
        params.capabilities.textDocument?.rename?.prepareSupport ?? false;

    server.capabilities = new ServerCapabilities(
        Either2<TextDocumentSyncOptions, num>.t1(new TextDocumentSyncOptions(
          true,
          TextDocumentSyncKind.Incremental,
          false,
          false,
          null,
        )),
        true, // hoverProvider
        new CompletionOptions(
          false,
          // Set the characters that will cause the editor to automatically
          // trigger completion.
          // TODO(dantup): This is quite eager and may need filtering in the
          // completion handler.
          // See https://github.com/Dart-Code/Dart-Code/blob/c616c93c87972713454eb0518f97c0278201a99a/src/providers/dart_completion_item_provider.ts#L36
          r'''.: =(${'"/\'''.split(''),
        ),
        new SignatureHelpOptions(
          // TODO(dantup): Signature help triggering is even more sensitive to
          // bad chars, so we'll need to implement the logic described here:
          // https://github.com/dart-lang/sdk/issues/34241
          [],
        ),
        true, // definitionProvider
        null,
        null,
        true, // referencesProvider
        true, // documentHighlightProvider
        true, // documentSymbolProvider
        null,
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
        new DocumentOnTypeFormattingOptions('}', [';']),
        renameOptionsSupport
            ? Either2<bool, RenameOptions>.t2(new RenameOptions(true))
            : Either2<bool, RenameOptions>.t1(true),
        null,
        null,
        null,
        new ExecuteCommandOptions(Commands.serverSupportedCommands),
        new ServerCapabilitiesWorkspace(
            new ServerCapabilitiesWorkspaceFolders(true, true)),
        null);

    return success(new InitializeResult(server.capabilities));
  }
}
