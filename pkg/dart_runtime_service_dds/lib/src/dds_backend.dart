// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:devtools_shared/devtools_shared.dart' show DtdInfo;
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'dds_isolate_manager.dart';
import 'dds_rpcs.dart';

final _logger = Logger('DartRuntimeServiceDdsBackend');

/// A [DartRuntimeServiceBackend] implementation that provides the Dart
/// Development Service (DDS) for a remote VM Service.
class DartRuntimeServiceDdsBackend
    extends DartRuntimeServiceBackend<DdsIsolateManager> {
  /// Creates a new [DartRuntimeServiceDdsBackend] connecting to the VM
  /// Service at [remoteVmServiceUri].
  DartRuntimeServiceDdsBackend(
    this.remoteVmServiceUri, {
    required super.frontend,
    this.appName,
    this.customDevToolsPath,
    this.devtoolsServerAddress,
    this.serveDevTools = false,
  });

  /// The [Uri] of the target VM Service.
  final Uri remoteVmServiceUri;

  /// The path segment for DevTools requests (e.g., 'devtools').
  static const _devtoolsPath = 'devtools';

  /// Whether DevTools is served directly by this service or redirected to an
  /// external instance.
  final bool serveDevTools;

  /// The address of an existing DevTools server to redirect to.
  final Uri? devtoolsServerAddress;

  /// A custom path to DevTools assets, overriding the default SDK location.
  final Uri? customDevToolsPath;

  /// The application name to register with DTD.
  final String? appName;

  DtdInfo? _hostedDartToolingDaemon;
  DtdInfo? get hostedDartToolingDaemon => _hostedDartToolingDaemon;

  Uri? _externalDevtoolsUri;

  late final shelf.Handler _httpHandler;

  late final DdsIsolateManager _isolateManager;
  late final WebSocketChannel _webSocketChannel;
  late final vm.VmService _vmServiceClient;
  late final DdsRpcHandlers _rpcHandlers;

  @override
  DdsIsolateManager get isolateManager => _isolateManager;

  vm.VmService get vmServiceClient => _vmServiceClient;

  @override
  shelf.Handler get httpHandler => _httpHandler;

  /// Sets the external DevTools URI to redirect DevTools requests to.
  void setExternalDevToolsUri(Uri uri) {
    if (serveDevTools && devtoolsServerAddress == null) {
      throw StateError('A hosted DevTools instance is already being served.');
    }
    _externalDevtoolsUri = uri;
  }

  /// The URI of the hosted DevTools instance, or null if not available.
  ///
  /// This is computed dynamically because it depends on the frontend URI
  /// (which is assigned when the HTTP server starts) and [_externalDevtoolsUri]
  /// (which can be set dynamically via [setExternalDevToolsUri]).
  Uri? get devToolsUri {
    Uri? baseUri;
    if (serveDevTools) {
      if (devtoolsServerAddress != null) {
        baseUri = devtoolsServerAddress;
      } else {
        final frontendUri = frontend.uri;
        final pathSegments = [
          ...frontendUri.pathSegments.where((e) => e.isNotEmpty),
          _devtoolsPath,
          '',
        ];
        baseUri = frontendUri.replace(
          scheme: frontendUri.isScheme('wss') ? 'https' : 'http',
          pathSegments: pathSegments,
        );
      }
    } else {
      baseUri = _externalDevtoolsUri;
    }
    if (baseUri == null) {
      return null;
    }
    final ddsUri = frontend.uri;
    final ddsWsPathSegments = [
      ...ddsUri.pathSegments.where((e) => e.isNotEmpty),
      'ws',
    ];
    final ddsWsUri = ddsUri.replace(pathSegments: ddsWsPathSegments);

    return baseUri.replace(query: 'uri=$ddsWsUri');
  }

  @override
  Future<void> initialize() async {
    // 1. Setup fallback proxy handler to forward unmatched requests to the
    // target VM service.
    final notFoundHandler = proxyHandler(remoteVmServiceUri);

    final appRoot = frontend.authCode != null
        ? '/${frontend.authCode}/$_devtoolsPath/'
        : '/$_devtoolsPath/';

    // 2. Configure DevTools HTTP routing: either serve static assets if hosted,
    // or redirect to an external DevTools server if provided.
    if (serveDevTools && devtoolsServerAddress == null) {
      final buildDir = (customDevToolsPath ?? _getDevToolsAssetPath())
          .toFilePath();
      _httpHandler = await defaultHandler(
        buildDir: buildDir,
        notFoundHandler: notFoundHandler,
        devtoolsExtensionsManager: ExtensionsManager(),
        appRoot: appRoot,
        enableLogging: frontend.config.enableLogging,
      );
    } else {
      _httpHandler = (shelf.Request request) {
        final pathSegments = request.url.pathSegments;
        if (pathSegments.isEmpty || pathSegments.first != _devtoolsPath) {
          return notFoundHandler(request);
        }

        final redirectUri = devtoolsServerAddress ?? _externalDevtoolsUri;
        if (redirectUri == null) {
          return shelf.Response.notFound(
            'No DevTools instance is registered with the Dart Development '
            'Service (DDS).',
          );
        }

        // Redirect to the external DevTools server.
        return shelf.Response.seeOther(
          redirectUri.replace(
            queryParameters: request.requestedUri.queryParameters,
          ),
        );
      };
    }

    // 3. Start the Dart Tooling Daemon (DTD) if DevTools is enabled.
    if (serveDevTools) {
      _hostedDartToolingDaemon = await startDtd(
        machineMode: false,
        printDtdUri: false,
      );
    }

    // 4. Connect to the target VM Service WebSocket and initialize isolate
    // state.
    final wsUri = _convertToWebSocketUri(remoteVmServiceUri);
    _webSocketChannel = WebSocketChannel.connect(wsUri);

    _vmServiceClient = vm.VmService(
      _webSocketChannel.stream.cast<String>(),
      (String message) => _webSocketChannel.sink.add(message),
    );

    _isolateManager = DdsIsolateManager(vmServiceClient: _vmServiceClient);
    await _isolateManager.initializeIsolates();

    _rpcHandlers = DdsRpcHandlers(this);
  }

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {}

  @override
  Future<void> shutdown() async {
    await _vmServiceClient.dispose();
    await _webSocketChannel.sink.close();
  }

  @override
  Future<void> clearState() async {}

  @override
  Future<void> onServerStarted({
    required Uri httpUri,
    required Uri wsUri,
  }) async {
    final hostedDtd = _hostedDartToolingDaemon;
    final secret = hostedDtd?.secret;
    if (hostedDtd != null && secret != null) {
      DartToolingDaemon? dtdClient;
      try {
        dtdClient = await DartToolingDaemon.connect(hostedDtd.localUri);
        final ddsWsPathSegments = [
          ...wsUri.pathSegments.where((e) => e.isNotEmpty),
          'ws',
        ];
        final ddsWsUri = wsUri.replace(pathSegments: ddsWsPathSegments);
        await dtdClient.registerVmService(
          uri: ddsWsUri.toString(),
          secret: secret,
          name: appName,
        );
      } catch (e, st) {
        _logger.warning('Failed to register VM Service to DTD: $e', e, st);
      } finally {
        await dtdClient?.close();
      }
    }
  }

  @override
  Future<void> onServerShutdown() async {}

  Uri _convertToWebSocketUri(Uri uri) {
    var scheme = uri.scheme;
    if (uri.isScheme('http')) {
      scheme = 'ws';
    } else if (uri.isScheme('https')) {
      scheme = 'wss';
    }
    var path = uri.path;
    if (!path.endsWith('/ws')) {
      if (path.endsWith('/')) {
        path = '${path}ws';
      } else {
        path = '$path/ws';
      }
    }
    return uri.replace(scheme: scheme, path: path);
  }

  /// Returns the fallback location of DevTools static assets bundled in the
  /// Dart SDK when [customDevToolsPath] is not specified.
  Uri _getDevToolsAssetPath() {
    final dartDir = File(Platform.resolvedExecutable).parent.path;
    final fullSdk = dartDir.endsWith('bin');
    return Uri.file(
      fullSdk
          ? path.absolute(dartDir, 'resources', _devtoolsPath)
          : path.absolute(dartDir, _devtoolsPath),
    );
  }

  @override
  UnmodifiableListView<ServiceRpcHandler> get rpcs => _rpcHandlers.rpcs;

  @override
  UnmodifiableListView<RpcHandlerWithParameters> get fallbacks =>
      UnmodifiableListView([forwardToRemoteVmService]);

  Future<RpcResponse> forwardToRemoteVmService(json_rpc.Parameters params) {
    return callVmService(
      params.method,
      args: params.value == null ? null : params.asMap.cast<String, Object?>(),
    );
  }

  Future<RpcResponse> callVmService(
    String method, {
    Map<String, Object?>? args,
  }) async {
    try {
      final response = await _vmServiceClient.callMethod(method, args: args);
      return response.toJson();
    } on vm.SentinelException catch (e) {
      return e.sentinel.toJson();
    } on vm.RPCError catch (e) {
      throw json_rpc.RpcException(e.code, e.message, data: e.data);
    }
  }
}
