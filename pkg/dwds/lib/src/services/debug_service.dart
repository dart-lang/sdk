// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dds/dds_launcher.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/events.dart';
import 'package:dwds/src/services/proxy_service.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';

bool _acceptNewConnections = true;

final _clientConnections = <int, StreamChannel>{};
int _clientId = 0;

Logger _logger = Logger('DebugService');

/// Common interface for debug services (Chrome or WebSocket based).
abstract class DebugService<T extends ProxyService> {
  DebugService({
    required this.serverHostname,
    required this.ddsConfig,
    required this.urlEncoder,
    required this.useSse,
  });

  /// The URI pointing to the VM service implementation hosted by the
  /// [DebugService].
  String get uri => _uri.toString();

  Uri get _uri => _cachedUri ??= () {
    final dds = _dds;
    if (ddsConfig.enable && dds != null) {
      return useSse ? dds.sseUri : dds.wsUri;
    }
    return useSse
        ? Uri(
            scheme: 'sse',
            host: _server.address.host,
            port: _server.port,
            path: '$authToken/\$debugHandler',
          )
        : Uri(
            scheme: 'ws',
            host: _server.address.host,
            port: _server.port,
            path: authToken,
          );
  }();

  Uri? _cachedUri;
  String? _ddsUri;

  late final T proxyService;

  final UrlEncoder? urlEncoder;

  late final String authToken = _makeAuthToken();
  final bool useSse;

  Future<String> get encodedUri async {
    return _encodedUri ??= await urlEncoder?.call(uri) ?? uri;
  }

  String? _encodedUri;

  DartDevelopmentServiceConfiguration ddsConfig;
  DartDevelopmentServiceLauncher? _dds;

  final String serverHostname;
  late final HttpServer _server;

  String get hostname => _uri.host;
  int get port => _uri.port;

  final serviceExtensionRegistry = ServiceExtensionRegistry();

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void>? _closed;

  @protected
  @mustCallSuper
  @mustBeOverridden
  // False positive
  // ignore: avoid-redundant-async
  Future<void> initialize({required T proxyService}) async {
    this.proxyService = proxyService;
  }

  @protected
  Future<void> serve({required shelf.Handler handler}) async {
    _server = await startHttpServer(serverHostname, port: 44456);
    serveHttpRequests(_server, handler, (e, s) {
      _logger.warning('Error serving requests', e);
      emitEvent(DwdsEvent.httpRequestException('$runtimeType', '$e:$s'));
    });
  }

  /// Closes the debug service and associated resources.
  Future<void> close() => _closed ??= Future.wait([
    _server.close(),
    if (_dds != null) _dds!.shutdown(),
  ]);

  Future<DartDevelopmentServiceLauncher> startDartDevelopmentService() async {
    // Note: DDS can handle both web socket and SSE connections with no
    // additional configuration.
    final hostname = _server.address.host;
    _dds = await DartDevelopmentServiceLauncher.start(
      appName: ddsConfig.appName ?? 'Unknown web app',
      remoteVmServiceUri: Uri(
        scheme: 'http',
        host: hostname,
        port: _server.port,
        path: authToken,
      ),
      serviceUri: Uri(
        scheme: 'http',
        host: hostname,
        port: ddsConfig.port ?? 0,
      ),
      devToolsServerAddress: ddsConfig.devToolsServerAddress,
      serveDevTools: ddsConfig.serveDevTools,
      dartExecutable: ddsConfig.dartExecutable,
    );
    return _dds!;
  }

  void yieldControlToDDS(String uri) {
    // We track the URI of the connected DDS instance seperately instead of
    // relying on _dds being non-null as there's no guarantee that DWDS is the
    // tool starting DDS.
    if (_ddsUri != null) {
      // This exception is identical to the one thrown from
      // sdk/lib/vmservice/vmservice.dart
      throw RPCError(
        '_yieldControlToDDS',
        RPCErrorKind.kFeatureDisabled.code,
        'A DDS instance is already connected at $_ddsUri.',
        {'ddsUri': _ddsUri.toString()},
      );
    }
    _acceptNewConnections = false;
    _ddsUri = uri;
  }

  @protected
  shelf.Handler initializeWebSocketHandler({
    required ProxyService proxyService,
    void Function(Map<String, Object>)? onRequest,
    void Function(Map<String, Object?>)? onResponse,
  }) {
    return _wrapHandler(
      webSocketHandler((Object webSocket, String? subprotocol) {
        handleConnection(
          webSocket as StreamChannel,
          proxyService,
          serviceExtensionRegistry,
          onRequest: onRequest,
          onResponse: onResponse,
        );
      }),
      authToken: authToken,
    );
  }

  shelf.Handler _wrapHandler(shelf.Handler innerHandler, {String? authToken}) {
    return (shelf.Request request) {
      if (!_acceptNewConnections) {
        return shelf.Response.forbidden(
          'Cannot connect directly to the VM service as a Dart Development '
          'Service (DDS) instance has taken control and can be found at '
          '$_ddsUri.',
        );
      }
      if (authToken != null && request.url.pathSegments.first != authToken) {
        return shelf.Response.forbidden('Incorrect auth token');
      }
      return innerHandler(request);
    };
  }

  @protected
  @mustCallSuper
  void handleConnection(
    StreamChannel channel,
    ProxyService proxyService,
    ServiceExtensionRegistry serviceExtensionRegistry, {
    void Function(Map<String, Object>)? onRequest,
    void Function(Map<String, Object?>)? onResponse,
  }) {
    final clientId = _clientId++;
    final responseController = StreamController<Map<String, Object?>>();
    responseController.stream
        .asyncMap<String>((response) async {
          // This error indicates a successful invocation to _yieldControlToDDS.
          // We don't have a good way to access the list of connected clients
          // while also being able to determine which client invoked the RPC
          // without some form of client ID.
          //
          // We can probably do better than this, but it will likely involve
          // some refactoring.
          if (response case {
            'error': {
              'code': DisconnectNonDartDevelopmentServiceClients.kErrorCode,
            },
          }) {
            final nonDdsClients = _clientConnections.entries
                .where((MapEntry<int, StreamChannel> e) => e.key != clientId)
                .map((e) => e.value);
            await Future.wait([
              for (final client in nonDdsClients) client.sink.close(),
            ]);
            // Remove the artificial error and return Success.
            response.remove('error');
            response['result'] = Success().toJson();
          }
          if (onResponse != null) onResponse(response);
          return jsonEncode(response);
        })
        .listen(channel.sink.add, onError: channel.sink.addError);
    final inputStream = channel.stream.map((value) {
      if (value is List<int>) {
        value = utf8.decode(value);
      } else if (value is! String) {
        throw StateError(
          'Got value with unexpected type ${value.runtimeType} from web '
          'socket, expected a List<int> or String.',
        );
      }
      final request = Map<String, Object>.from(
        jsonDecode(value as String) as Map,
      );
      if (onRequest != null) onRequest(request);
      return request;
    });
    VmServerConnection(
      inputStream,
      responseController.sink,
      serviceExtensionRegistry,
      proxyService,
    ).done.whenComplete(() {
      _clientConnections.remove(clientId);
      if (!_acceptNewConnections && _clientConnections.isEmpty) {
        // DDS has disconnected so we can allow for clients to connect directly
        // to DWDS.
        _ddsUri = null;
        _acceptNewConnections = true;
      }
    });
    _clientConnections[clientId] = channel;
  }

  // Creates a random auth token for more secure connections.
  String _makeAuthToken() {
    final tokenBytes = 8;
    final bytes = Uint8List(tokenBytes);
    final random = Random.secure();
    for (var i = 0; i < tokenBytes; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes);
  }
}
