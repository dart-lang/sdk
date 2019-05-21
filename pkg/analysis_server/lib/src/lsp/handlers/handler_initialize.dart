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

  ErrorOr<InitializeResult> handle(InitializeParams params) {
    final openWorkspacePaths = <String>[];

    // The onlyAnalyzeProjectsWithOpenFiles flag allows opening huge folders
    // without setting them as analysis roots. Instead, analysis roots will be
    // based only on the open files.
    final onlyAnalyzeProjectsWithOpenFiles = params.initializationOptions !=
            null
        ? params.initializationOptions['onlyAnalyzeProjectsWithOpenFiles'] ==
            true
        : false;

    // The suggestFromUnimportedLibraries flag allows clients to opt-out of
    // behaviour of including suggestions that are not imported. Defaults to true,
    // so must be explicitly passed as false to disable.
    final suggestFromUnimportedLibraries = params.initializationOptions ==
            null ||
        params.initializationOptions['suggestFromUnimportedLibraries'] != false;

    if (!onlyAnalyzeProjectsWithOpenFiles) {
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

    server.handleClientConnection(params.capabilities);
    server.messageHandler = new InitializingStateMessageHandler(
      server,
      openWorkspacePaths,
      onlyAnalyzeProjectsWithOpenFiles,
      suggestFromUnimportedLibraries,
    );

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
          true, // resolveProvider
          // Set the characters that will cause the editor to automatically
          // trigger completion.
          // TODO(dantup): There are several characters that we want to conditionally
          // allow to trigger completion, but they can only be added when the completion
          // provider is able to handle them in context:
          //
          //    {   trigger if being typed in a string immediately after a $
          //    '   trigger if the opening quote for an import/export
          //    "   trigger if the opening quote for an import/export
          //    /   trigger if as part of a path in an import/export
          //    \   trigger if as part of a path in an import/export
          //    :   don't trigger when typing case expressions (`case x:`)
          //
          // Additionally, we need to prefix `filterText` on completion items
          // with spaces for those that can follow whitespace (eg. `foo` in
          // `myArg: foo`) to ensure they're not filtered away when the user
          // types space.
          //
          // See https://github.com/Dart-Code/Dart-Code/blob/68d1cd271e88a785570257d487adbdec17abd6a3/src/providers/dart_completion_item_provider.ts#L36-L64
          // for the VS Code implementation of this.
          r'''.=($'''.split(''),
        ),
        new SignatureHelpOptions(
          // TODO(dantup): Signature help triggering is even more sensitive to
          // bad chars, so we'll need to implement the logic described here:
          // https://github.com/dart-lang/sdk/issues/34241
          [],
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
        new DocumentOnTypeFormattingOptions('}', [';']),
        renameOptionsSupport
            ? Either2<bool, RenameOptions>.t2(new RenameOptions(true))
            : Either2<bool, RenameOptions>.t1(true),
        null,
        null,
        true, // foldingRangeProvider
        new ExecuteCommandOptions(Commands.serverSupportedCommands),
        null, // declarationProvider
        new ServerCapabilitiesWorkspace(
            new ServerCapabilitiesWorkspaceFolders(true, true)),
        null);

    return success(new InitializeResult(server.capabilities));
  }
}
