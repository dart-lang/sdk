// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

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

    final unnormalisedWorkspacePaths = <String>[];
    final workspaceFolders = params.workspaceFolders;
    final rootUri = params.rootUri;
    final rootPath = params.rootPath;
    // The onlyAnalyzeProjectsWithOpenFiles flag allows opening huge folders
    // without setting them as analysis roots. Instead, analysis roots will be
    // based only on the open files.
    if (!server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
      if (workspaceFolders != null) {
        workspaceFolders.forEach((wf) {
          final uri = Uri.parse(wf.uri);
          // Only file URIs are supported, but there's no way to signal this to
          // the LSP client (and certainly not before initialization).
          if (uri.isScheme('file')) {
            unnormalisedWorkspacePaths.add(uri.toFilePath());
          }
        });
      }
      if (rootUri != null) {
        final uri = Uri.parse(rootUri);
        if (uri.isScheme('file')) {
          unnormalisedWorkspacePaths.add(uri.toFilePath());
        }
      } else if (rootPath != null) {
        unnormalisedWorkspacePaths.add(rootPath);
      }
    }

    final pathContext = server.resourceProvider.pathContext;
    // Normalise all potential workspace folder paths as these may contain
    // trailing slashes (the LSP spec does not specific if folders
    // should/should not have them) and the analysis roots must be normalized.
    final workspacePaths =
        unnormalisedWorkspacePaths.map(pathContext.normalize).toList();

    server.messageHandler = InitializingStateMessageHandler(
      server,
      workspacePaths,
    );

    final capabilities = server.capabilitiesComputer
        .computeServerCapabilities(server.clientCapabilities!);
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
