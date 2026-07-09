// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/asset_reader.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/connections/app_connection.dart';
import 'package:dwds/src/services/debug_service.dart';
import 'package:dwds/src/services/web_socket/web_socket_proxy_service.dart';
import 'package:meta/meta.dart';

/// Defines callbacks for sending messages to the connected client.
/// Returns the number of clients the request was successfully sent to.
typedef SendClientRequest = int Function(Object request);

/// WebSocket-based debug service for web debugging.
final class WebSocketDebugService extends DebugService<WebSocketProxyService> {
  WebSocketDebugService._({
    required super.serverHostname,
    required super.ddsConfig,
    required super.urlEncoder,
  }) : super(
         // The web socket debug service doesn't support SSE connections.
         useSse: false,
       );

  @protected
  @override
  Future<void> initialize({required WebSocketProxyService proxyService}) async {
    await super.initialize(proxyService: proxyService);
    await serve(
      handler: initializeWebSocketHandler(proxyService: proxyService),
    );
  }

  static Future<WebSocketDebugService> start({
    required String hostname,
    required AppConnection appConnection,
    required AssetReader assetReader,
    required SendClientRequest sendClientRequest,
    required DartDevelopmentServiceConfiguration ddsConfig,
    UrlEncoder? urlEncoder,
  }) async {
    final debugService = WebSocketDebugService._(
      serverHostname: hostname,
      ddsConfig: ddsConfig,
      urlEncoder: urlEncoder,
    );
    final webSocketProxyService = await WebSocketProxyService.create(
      sendClientRequest,
      appConnection,
      assetReader.basePath,
      debugService,
    );
    await debugService.initialize(proxyService: webSocketProxyService);
    return debugService;
  }
}
