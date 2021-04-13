// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.10

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../dds.dart';
import 'binary_compatible_peer.dart';
import 'client.dart';
import 'client_manager.dart';
import 'expression_evaluator.dart';
import 'isolate_manager.dart';
import 'stream_manager.dart';

@visibleForTesting
typedef PeerBuilder = Future<json_rpc.Peer> Function(WebSocketChannel, dynamic);

@visibleForTesting
typedef WebSocketBuilder = WebSocketChannel Function(Uri);

@visibleForTesting
PeerBuilder peerBuilder = _defaultPeerBuilder;

@visibleForTesting
WebSocketBuilder webSocketBuilder = _defaultWebSocketBuilder;

Future<json_rpc.Peer> _defaultPeerBuilder(
    WebSocketChannel ws, dynamic streamManager) async {
  return BinaryCompatiblePeer(ws, streamManager);
}

WebSocketChannel _defaultWebSocketBuilder(Uri uri) {
  return WebSocketChannel.connect(uri.replace(scheme: 'ws'));
}

class DartDevelopmentServiceImpl implements DartDevelopmentService {
  DartDevelopmentServiceImpl(
      this._remoteVmServiceUri, this._uri, this._authCodesEnabled, this._ipv6) {
    _clientManager = ClientManager(this);
    _expressionEvaluator = ExpressionEvaluator(this);
    _isolateManager = IsolateManager(this);
    _streamManager = StreamManager(this);
    _authCode = _authCodesEnabled ? _makeAuthToken() : '';
  }

  Future<void> startService() async {
    bool started = false;
    final completer = Completer<void>();
    // TODO(bkonyi): throw if we've already shutdown.
    // Establish the connection to the VM service.
    _vmServiceSocket = webSocketBuilder(remoteVmServiceWsUri);
    vmServiceClient = await peerBuilder(_vmServiceSocket, _streamManager);
    // Setup the JSON RPC client with the VM service.
    unawaited(
      vmServiceClient.listen().then(
        (_) {
          shutdown();
          if (!started && !completer.isCompleted) {
            completer
                .completeError(DartDevelopmentServiceException.failedToStart());
          }
        },
        onError: (e, st) {
          shutdown();
          if (!completer.isCompleted) {
            completer.completeError(
              DartDevelopmentServiceException.connectionIssue(e.toString()),
              st,
            );
          }
        },
      ),
    );

    try {
      // Setup stream event handling.
      await streamManager.listen();

      // Populate initial isolate state.
      await _isolateManager.initialize();

      // Once we have a connection to the VM service, we're ready to spawn the intermediary.
      await _startDDSServer();
      started = true;
      completer.complete();
    } on StateError {
      /* Ignore json-rpc state errors */
    } catch (e, st) {
      completer.completeError(e, st);
    }
    return completer.future;
  }

  Future<void> _startDDSServer() async {
    // No provided address, bind to an available port on localhost.
    final host = uri?.host ??
        (_ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4)
            .host;
    final port = uri?.port ?? 0;

    // Start the DDS server.
    _server = await io.serve(
        const Pipeline()
            .addMiddleware(_authCodeMiddleware)
            .addHandler(_handlers().handler),
        host,
        port);

    final tmpUri = Uri(
      scheme: 'http',
      host: host,
      port: _server.port,
      path: '$_authCode/',
    );

    // Notify the VM service that this client is DDS and that it should close
    // and refuse connections from other clients. DDS is now acting in place of
    // the VM service.
    try {
      await vmServiceClient.sendRequest('_yieldControlToDDS', {
        'uri': tmpUri.toString(),
      });
    } on json_rpc.RpcException catch (e) {
      await _server.close(force: true);
      String message = e.toString();
      if (e.data != null) {
        message += ' data: ${e.data}';
      }
      // _yieldControlToDDS fails if DDS is not the only VM service client.
      throw DartDevelopmentServiceException.existingDdsInstance(message);
    }

    _uri = tmpUri;
  }

  /// Stop accepting requests after gracefully handling existing requests.
  @override
  Future<void> shutdown() async {
    if (_done.isCompleted || _shuttingDown) {
      // Already shutdown.
      return;
    }
    _shuttingDown = true;
    // Don't accept anymore HTTP requests.
    await _server?.close();

    // Close connections to clients.
    await clientManager.shutdown();

    // Close connection to VM service.
    await _vmServiceSocket?.sink?.close();

    _done.complete();
  }

  /// Generates a base64 authentication code that must be passed as the first
  /// part of the request path. Used to prevent random connections from clients
  /// watching the common service ports.
  static String _makeAuthToken() {
    final kTokenByteSize = 8;
    final bytes = Uint8List(kTokenByteSize);
    final random = Random.secure();
    for (int i = 0; i < kTokenByteSize; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  /// Shelf middleware to verify authentication tokens before processing a
  /// request.
  ///
  /// If authentication codes are enabled, a 403 response is returned if the
  /// authentication code is not the first element of the request's path.
  /// Otherwise, the request is forwarded to the first handler.
  Handler _authCodeMiddleware(Handler innerHandler) => (Request request) {
        if (_authCodesEnabled) {
          final forbidden =
              Response.forbidden('missing or invalid authentication code');
          final pathSegments = request.url.pathSegments;
          if (pathSegments.isEmpty) {
            return forbidden;
          }
          final authToken = pathSegments[0];
          if (authToken != _authCode) {
            return forbidden;
          }
          // Creates a new request with the authentication code stripped from
          // the request URI. This method doesn't behave as you might expect.
          // Calling request.change(path: authToken) has the effect of changing
          // the request's handler path from '/' to '/$authToken/' while also
          // changing the request's url from '$authToken/restofpath/' to
          // 'restofpath/'. The handler path is only used by shelf, so this
          // operation has the effect of stripping the authentication code from
          // the request.
          request = request.change(path: authToken);
        }
        return innerHandler(request);
      };

  // Attempt to upgrade HTTP requests to a websocket before processing them as
  // standard HTTP requests. The websocket handler will fail quickly if the
  // request doesn't appear to be a websocket upgrade request.
  Cascade _handlers() {
    return Cascade()
        .add(_webSocketHandler())
        .add(_sseHandler())
        .add(_httpHandler());
  }

  Handler _webSocketHandler() => webSocketHandler((WebSocketChannel ws) {
        final client = DartDevelopmentServiceClient.fromWebSocket(
          this,
          ws,
          vmServiceClient,
        );
        clientManager.addClient(client);
      });

  Handler _sseHandler() {
    // Give connections time to reestablish before considering them closed.
    // Required to reestablish connections killed by UberProxy.
    const keepAlive = Duration(seconds: 30);
    final handler = authCodesEnabled
        ? SseHandler(
            Uri.parse('/$_authCode/$_kSseHandlerPath'),
            keepAlive: keepAlive,
          )
        : SseHandler(
            Uri.parse('/$_kSseHandlerPath'),
            keepAlive: keepAlive,
          );

    handler.connections.rest.listen((sseConnection) {
      final client = DartDevelopmentServiceClient.fromSSEConnection(
        this,
        sseConnection,
        vmServiceClient,
      );
      clientManager.addClient(client);
    });

    return handler.handler;
  }

  Handler _httpHandler() {
    // DDS doesn't support any HTTP requests itself, so we just forward all of
    // them to the VM service.
    final cascade = Cascade().add(proxyHandler(remoteVmServiceUri));
    return cascade.handler;
  }

  List<String> _cleanupPathSegments(Uri uri) {
    final pathSegments = <String>[];
    if (uri.pathSegments.isNotEmpty) {
      pathSegments.addAll(uri.pathSegments.where(
        // Strip out the empty string that appears at the end of path segments.
        // Empty string elements will result in an extra '/' being added to the
        // URI.
        (s) => s.isNotEmpty,
      ));
    }
    return pathSegments;
  }

  Uri _toWebSocket(Uri uri) {
    if (uri == null) {
      return null;
    }
    final pathSegments = _cleanupPathSegments(uri);
    pathSegments.add('ws');
    return uri.replace(scheme: 'ws', pathSegments: pathSegments);
  }

  Uri _toSse(Uri uri) {
    if (uri == null) {
      return null;
    }
    final pathSegments = _cleanupPathSegments(uri);
    pathSegments.add(_kSseHandlerPath);
    return uri.replace(scheme: 'sse', pathSegments: pathSegments);
  }

  String getNamespace(DartDevelopmentServiceClient client) =>
      clientManager.clients.keyOf(client);

  @override
  bool get authCodesEnabled => _authCodesEnabled;
  final bool _authCodesEnabled;
  String _authCode;

  @override
  Uri get remoteVmServiceUri => _remoteVmServiceUri;

  @override
  Uri get remoteVmServiceWsUri => _toWebSocket(_remoteVmServiceUri);
  Uri _remoteVmServiceUri;

  @override
  Uri get uri => _uri;

  @override
  Uri get sseUri => _toSse(_uri);

  Uri get wsUri => _toWebSocket(_uri);
  Uri _uri;

  final bool _ipv6;

  bool get isRunning => _uri != null;

  Future<void> get done => _done.future;
  Completer _done = Completer<void>();
  bool _shuttingDown = false;

  ClientManager get clientManager => _clientManager;
  ClientManager _clientManager;

  ExpressionEvaluator get expressionEvaluator => _expressionEvaluator;
  ExpressionEvaluator _expressionEvaluator;

  IsolateManager get isolateManager => _isolateManager;
  IsolateManager _isolateManager;

  StreamManager get streamManager => _streamManager;
  StreamManager _streamManager;

  static const _kSseHandlerPath = '\$debugHandler';

  json_rpc.Peer vmServiceClient;
  WebSocketChannel _vmServiceSocket;
  HttpServer _server;
}
