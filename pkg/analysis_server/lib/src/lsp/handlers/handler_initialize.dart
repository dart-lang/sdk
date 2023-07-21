// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

class InitializeMessageHandler
    extends LspMessageHandler<InitializeParams, InitializeResult> {
  InitializeMessageHandler(super.server);

  @override
  Method get handlesMessage => Method.initialize;

  @override
  LspJsonHandler<InitializeParams> get jsonHandler =>
      InitializeParams.jsonHandler;

  @override
  ErrorOr<InitializeResult> handle(
      InitializeParams params, MessageInfo message, CancellationToken token) {
    server.analyticsManager.initialize(params);

    server.handleClientConnection(
      params.capabilities,
      params.clientInfo,
      params.initializationOptions,
    );

    final workspacePaths = <String>[];
    final workspaceFolders = params.workspaceFolders;
    final rootUri = params.rootUri;
    final rootPath = params.rootPath;
    // The onlyAnalyzeProjectsWithOpenFiles flag allows opening huge folders
    // without setting them as analysis roots. Instead, analysis roots will be
    // based only on the open files.
    if (!server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
      if (workspaceFolders != null) {
        for (var wf in workspaceFolders) {
          final uri = wf.uri;
          // Only file URIs are supported, but there's no way to signal this to
          // the LSP client (and certainly not before initialization).
          if (uri.isScheme('file')) {
            workspacePaths.add(uri.toFilePath());
          }
        }
      }
      if (rootUri != null) {
        if (rootUri.isScheme('file')) {
          workspacePaths.add(rootUri.toFilePath());
        }
      } else if (rootPath != null) {
        workspacePaths.add(rootPath);
      }
    }

    server.messageHandler = InitializingStateMessageHandler(
      server,
      workspacePaths,
    );

    final capabilities = server.capabilitiesComputer
        .computeServerCapabilities(server.lspClientCapabilities!);
    server.capabilities = capabilities;

    var sdkVersion = Platform.version;
    if (sdkVersion.contains(' ')) {
      sdkVersion = sdkVersion.substring(0, sdkVersion.indexOf(' '));
    }

    return success(InitializeResult(
      capabilities: capabilities,
      serverInfo: InitializeResultServerInfo(
        name: 'Dart SDK LSP Analysis Server',
        version: sdkVersion,
      ),
    ));
  }
}
