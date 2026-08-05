// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/asset_reader.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/connections/app_connection.dart';
import 'package:dwds/src/debugging/execution_context.dart';
import 'package:dwds/src/debugging/remote_debugger.dart';
import 'package:dwds/src/services/chrome/chrome_proxy_service.dart';
import 'package:dwds/src/services/debug_service.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:sse/server/sse_handler.dart';

/// A Dart Web Debug Service.
///
/// Creates a [ChromeProxyService] from an existing Chrome instance.
final class ChromeDebugService extends DebugService<ChromeProxyService> {
  ChromeDebugService._({
    required super.serverHostname,
    required super.useSse,
    required super.ddsConfig,
    required super.urlEncoder,
  });

  static const _kSseHandlerPath = '\$debugHandler';

  @protected
  @override
  Future<void> initialize({
    required ChromeProxyService proxyService,
    void Function(Map<String, Object>)? onRequest,
    void Function(Map<String, Object?>)? onResponse,
  }) async {
    await super.initialize(proxyService: proxyService);
    shelf.Handler handler;
    // DDS will always connect to DWDS via web sockets.
    if (useSse && !ddsConfig.enable) {
      handler = _initializeSSEHandler(
        chromeProxyService: proxyService,
        onRequest: onRequest,
        onResponse: onResponse,
      );
    } else {
      handler = initializeWebSocketHandler(
        proxyService: proxyService,
        onRequest: onRequest,
        onResponse: onResponse,
      );
    }
    await serve(handler: handler);
  }

  static Future<ChromeDebugService> start({
    required String hostname,
    required RemoteDebugger remoteDebugger,
    required ExecutionContext executionContext,
    required AssetReader assetReader,
    required AppConnection appConnection,
    UrlEncoder? urlEncoder,
    void Function(Map<String, Object>)? onRequest,
    void Function(Map<String, Object?>)? onResponse,
    required DartDevelopmentServiceConfiguration ddsConfig,
    bool useSse = false,
    ExpressionCompiler? expressionCompiler,
  }) async {
    final debugService = ChromeDebugService._(
      serverHostname: hostname,
      useSse: useSse,
      ddsConfig: ddsConfig,
      urlEncoder: urlEncoder,
    );
    final chromeProxyService = await ChromeProxyService.create(
      remoteDebugger: remoteDebugger,
      debugService: debugService,
      assetReader: assetReader,
      appConnection: appConnection,
      executionContext: executionContext,
      expressionCompiler: expressionCompiler,
    );
    await debugService.initialize(
      proxyService: chromeProxyService,
      onRequest: onRequest,
      onResponse: onResponse,
    );
    return debugService;
  }

  shelf.Handler _initializeSSEHandler({
    required ChromeProxyService chromeProxyService,
    void Function(Map<String, Object>)? onRequest,
    void Function(Map<String, Object?>)? onResponse,
  }) {
    final sseHandler = SseHandler(
      Uri.parse('/$authToken/$_kSseHandlerPath'),
      keepAlive: const Duration(seconds: 5),
    );
    final handler = sseHandler.handler;
    safeUnawaited(() async {
      while (await sseHandler.connections.hasNext) {
        final connection = await sseHandler.connections.next;
        handleConnection(
          connection,
          chromeProxyService,
          serviceExtensionRegistry,
          onRequest: onRequest,
          onResponse: onResponse,
        );
      }
    }());
    return handler;
  }
}
