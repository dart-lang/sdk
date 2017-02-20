// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library socket.server;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:plugin/plugin.dart';

/**
 * Instances of the class [SocketServer] implement the common parts of
 * http-based and stdio-based analysis servers.  The primary responsibility of
 * the SocketServer is to manage the lifetime of the AnalysisServer and to
 * encode and decode the JSON messages exchanged with the client.
 */
class SocketServer {
  final AnalysisServerOptions analysisServerOptions;

  /**
   * The function used to create a new SDK using the default SDK.
   */
  final DartSdkManager sdkManager;

  final DartSdk defaultSdk;
  final InstrumentationService instrumentationService;
  final DiagnosticServer diagnosticServer;
  final ServerPlugin serverPlugin;
  final ResolverProvider fileResolverProvider;
  final ResolverProvider packageResolverProvider;
  final bool useSingleContextManager;

  /**
   * The analysis server that was created when a client established a
   * connection, or `null` if no such connection has yet been established.
   */
  AnalysisServer analysisServer;

  /**
   * The plugins that are defined outside the analysis_server package.
   */
  List<Plugin> userDefinedPlugins;

  SocketServer(
      this.analysisServerOptions,
      this.sdkManager,
      this.defaultSdk,
      this.instrumentationService,
      this.diagnosticServer,
      this.serverPlugin,
      this.fileResolverProvider,
      this.packageResolverProvider,
      this.useSingleContextManager);

  /**
   * Create an analysis server which will communicate with the client using the
   * given serverChannel.
   */
  void createAnalysisServer(ServerCommunicationChannel serverChannel) {
    if (analysisServer != null) {
      RequestError error = new RequestError(
          RequestErrorCode.SERVER_ALREADY_STARTED, "Server already started");
      serverChannel.sendResponse(new Response('', error: error));
      serverChannel.listen((Request request) {
        serverChannel.sendResponse(new Response(request.id, error: error));
      });
      return;
    }

    PhysicalResourceProvider resourceProvider;
    if (analysisServerOptions.fileReadMode == 'as-is') {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
    } else if (analysisServerOptions.fileReadMode == 'normalize-eol-always') {
      resourceProvider = new PhysicalResourceProvider(
          PhysicalResourceProvider.NORMALIZE_EOL_ALWAYS);
    } else {
      throw new Exception(
          'File read mode was set to the unknown mode: $analysisServerOptions.fileReadMode');
    }

    Index index = null;
    if (!analysisServerOptions.noIndex) {
      index = createMemoryIndex();
    }

    analysisServer = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new PubPackageMapProvider(resourceProvider, defaultSdk),
        index,
        serverPlugin,
        analysisServerOptions,
        sdkManager,
        instrumentationService,
        diagnosticServer: diagnosticServer,
        fileResolverProvider: fileResolverProvider,
        packageResolverProvider: packageResolverProvider,
        useSingleContextManager: useSingleContextManager,
        rethrowExceptions: false);
    analysisServer.userDefinedPlugins = userDefinedPlugins;
  }
}
