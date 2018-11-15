// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class InitializationHandler extends MessageHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final LspAnalysisServer server;

  final List<String> _openWorkspacePaths = [];

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  InitializationHandler(this.server);

  /**
   * The messages that this handler can handle.
   */
  List<String> get handlesMessages => const ['initialize', 'initialized'];

  InitializeResult handleInitialize(InitializeParams params) {
    if (server.state != InitializationState.Uninitialized) {
      throw new ResponseError(ServerErrorCodes.ServerAlreadyInitialized,
          'Server already initialized', null);
    }

    if (params.workspaceFolders != null) {
      params.workspaceFolders.forEach((wf) {
        _openWorkspacePaths.add(Uri.parse(wf.uri).toFilePath());
      });
    }
    if (params.rootUri != null) {
      _openWorkspacePaths.add(Uri.parse(params.rootUri).toFilePath());
      // ignore: deprecated_member_use
    } else if (params.rootPath != null) {
      _openWorkspacePaths.add(params.rootUri);
    }

    server.setClientCapabilities(params.capabilities);
    server.state = InitializationState.Initializing;

    // TODO(dantup): This needs a real implementation. For this request we
    // should store the client capabilities on this.server and return what
    // we support.
    return new InitializeResult(new ServerCapabilities(
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
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        true, // documentFormattingProvider
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null));
  }

  void handleInitialized() {
    if (server.state != InitializationState.Initializing) {
      throw new ResponseError(ServerErrorCodes.ServerAlreadyInitialized,
          'Server already initialized', null);
    }

    server.state = InitializationState.Initialized;
    server.setAnalysisRoots(_openWorkspacePaths, [], {});
  }

  @override
  Object handleMessage(IncomingMessage message) {
    if (message is RequestMessage && message.method == 'initialize') {
      final params = convertParams(message, InitializeParams.fromJson);
      return handleInitialize(params);
    } else if (message is NotificationMessage &&
        message.method == 'initialized') {
      handleInitialized();
      return null;
    } else {
      throw 'Unexpected message';
    }
  }
}
