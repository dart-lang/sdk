// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library socket.server;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_edit.dart';
import 'package:analysis_server/src/domain_search.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/package_map_provider.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';

/**
 * Instances of the class [SocketServer] implement the common parts of
 * http-based and stdio-based analysis servers.  The primary responsibility of
 * the SocketServer is to manage the lifetime of the AnalysisServer and to
 * encode and decode the JSON messages exchanged with the client.
 */
class SocketServer {
  /**
   * The analysis server that was created when a client established a
   * connection, or `null` if no such connection has yet been established.
   */
  AnalysisServer analysisServer;

  /**
   * Create an analysis server which will communicate with the client using the
   * given serverChannel.
   */
  void createAnalysisServer(ServerCommunicationChannel serverChannel) {
    if (analysisServer != null) {
      RequestError error = new RequestError.serverAlreadyStarted();
      serverChannel.sendResponse(new Response('', error));
      serverChannel.listen((Request request) {
        serverChannel.sendResponse(new Response(request.id, error));
      });
      return;
    }
    PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    analysisServer = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new PubPackageMapProvider(resourceProvider),
        rethrowExceptions: false);
    _initializeHandlers(analysisServer);
  }

  /**
   * Initialize the handlers to be used by the given [server].
   */
  void _initializeHandlers(AnalysisServer server) {
    server.handlers = [
        new ServerDomainHandler(server),
        new AnalysisDomainHandler(server),
        new EditDomainHandler(server),
        new SearchDomainHandler(server),
        new CompletionDomainHandler(server),
    ];
  }

}