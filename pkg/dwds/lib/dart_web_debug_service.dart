// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dwds/data/build_result.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/connections/app_connection.dart';
import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/events.dart';
import 'package:dwds/src/handlers/dev_handler.dart';
import 'package:dwds/src/handlers/injector.dart';
import 'package:dwds/src/handlers/socket_connections.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:dwds/src/servers/devtools.dart';
import 'package:dwds/src/servers/extension_backend.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

typedef ConnectionProvider = Future<ChromeConnection> Function();

/// The Dart Web Debug Service.
class Dwds {
  static final _logger = Logger('DWDS');
  final Middleware middleware;
  final Handler handler;
  final DevTools? _devTools;
  final DevHandler _devHandler;
  final AssetReader _assetReader;
  final bool _enableDebugging;
  final bool _useDwdsWebSocketConnection;

  Dwds._(
    this.middleware,
    this._devTools,
    this._devHandler,
    this._assetReader,
    this._enableDebugging,
    this._useDwdsWebSocketConnection,
  ) : handler = _devHandler.handler;

  Stream<AppConnection> get connectedApps => _devHandler.connectedApps;

  Stream<DwdsEvent> get events => eventStream;

  StreamController<DebugConnection> get extensionDebugConnections =>
      _devHandler.extensionDebugConnections;

  Future<void> stop() async {
    await _devTools?.close();
    await _devHandler.close();
    await _assetReader.close();
  }

  /// Creates a debug connection for the given app connection.
  ///
  /// Returns a [DebugConnection] that wraps the appropriate debug services
  /// based on the connection type (WebSocket or Chrome-based).
  Future<DebugConnection> debugConnection(AppConnection appConnection) async {
    if (!_enableDebugging) throw StateError('Debugging is not enabled.');

    if (_useDwdsWebSocketConnection) {
      return await _devHandler.createDebugConnectionForWebSocket(appConnection);
    } else {
      return await _devHandler.createDebugConnectionForChrome(appConnection);
    }
  }

  static Future<Dwds> start({
    required AssetReader assetReader,
    required Stream<BuildResult> buildResults,
    required ConnectionProvider chromeConnection,
    required ToolConfiguration toolConfiguration,
    bool useDwdsWebSocketConnection = false,
  }) async {
    globalToolConfiguration = toolConfiguration;
    final debugSettings = toolConfiguration.debugSettings;
    final appMetadata = toolConfiguration.appMetadata;
    DevTools? devTools;
    Future<String>? extensionUri;
    ExtensionBackend? extensionBackend;
    if (debugSettings.enableDebugExtension) {
      final handler = debugSettings.useSseForDebugBackend
          ? SseSocketHandler(
              SseHandler(
                Uri.parse('/\$debug'),
                // Proxy servers may actively kill long standing connections.
                // Allow for clients to reconnect in a short window. Making the
                // window too long may cause issues if the user closes a debug
                // session and initiates a new one during the keepAlive window.
                keepAlive: const Duration(seconds: 5),
              ),
            )
          : WebSocketSocketHandler();

      extensionBackend = await ExtensionBackend.start(
        handler,
        appMetadata.hostname,
      );
      extensionUri = Future.value(
        Uri(
          scheme: debugSettings.useSseForDebugBackend ? 'http' : 'ws',
          host: extensionBackend.hostname,
          port: extensionBackend.port,
          path: r'$debug',
        ).toString(),
      );
      final urlEncoder = debugSettings.urlEncoder;
      if (urlEncoder != null) {
        extensionUri = urlEncoder(await extensionUri);
      }
    }

    // TODO(bkonyi): only allow for serving DevTools via DDS.
    // ignore: deprecated_member_use_from_same_package
    final devToolsLauncher = debugSettings.devToolsLauncher;
    Uri? launchedDevToolsUri;
    if (devToolsLauncher != null &&
        // If DDS is configured to serve DevTools, use its instance.
        !debugSettings.ddsConfiguration.serveDevTools) {
      devTools = await devToolsLauncher(appMetadata.hostname);
      launchedDevToolsUri = Uri(
        scheme: 'http',
        host: devTools.hostname,
        port: devTools.port,
      );
      _logger.info('Serving DevTools at $launchedDevToolsUri\n');
    }

    final injected = DwdsInjector(extensionUri: extensionUri);

    final devHandler = DevHandler(
      chromeConnection,
      buildResults,
      devTools,
      assetReader,
      appMetadata.hostname,
      extensionBackend,
      debugSettings.urlEncoder,
      debugSettings.useSseForDebugProxy,
      debugSettings.useSseForInjectedClient,
      debugSettings.expressionCompiler,
      injected,
      DartDevelopmentServiceConfiguration(
        // This technically isn't correct, but
        // DartDevelopmentServiceConfiguration.enable is true by default, so
        // this won't break unmigrated tools.
        // ignore: deprecated_member_use_from_same_package
        enable: debugSettings.spawnDds && debugSettings.ddsConfiguration.enable,
        // ignore: deprecated_member_use_from_same_package
        port: debugSettings.ddsPort ?? debugSettings.ddsConfiguration.port,
        devToolsServerAddress:
            launchedDevToolsUri ??
            debugSettings.ddsConfiguration.devToolsServerAddress,
        serveDevTools: debugSettings.ddsConfiguration.serveDevTools,
        appName: debugSettings.ddsConfiguration.appName,
        dartExecutable: debugSettings.ddsConfiguration.dartExecutable,
      ),
      debugSettings.launchDevToolsInNewWindow,
      useWebSocketConnection: useDwdsWebSocketConnection,
      sseIgnoreDisconnect: debugSettings.sseIgnoreDisconnect,
    );

    return Dwds._(
      injected.middleware,
      devTools,
      devHandler,
      assetReader,
      debugSettings.enableDebugging,
      useDwdsWebSocketConnection,
    );
  }
}
