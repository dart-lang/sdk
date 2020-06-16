// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

class _DartDevelopmentService implements DartDevelopmentService {
  _DartDevelopmentService(
    this._remoteVmServiceUri,
    this._uri,
    this._authCodesEnabled,
  ) {
    _clientManager = _ClientManager(this);
    _expressionEvaluator = _ExpressionEvaluator(this);
    _isolateManager = _IsolateManager(this);
    _loggingRepository = _LoggingRepository();
    _streamManager = _StreamManager(this);
    _authCode = _authCodesEnabled ? _makeAuthToken() : '';
  }

  Future<void> startService() async {
    // TODO(bkonyi): throw if we've already shutdown.
    // Establish the connection to the VM service.
    _vmServiceSocket = WebSocketChannel.connect(remoteVmServiceWsUri);
    _vmServiceClient = _BinaryCompatiblePeer(_vmServiceSocket, _streamManager);
    // Setup the JSON RPC client with the VM service.
    unawaited(_vmServiceClient.listen().then((_) => shutdown()));

    // Setup stream event handling.
    await streamManager.listen();

    // Populate initial isolate state.
    await _isolateManager.initialize();

    // Once we have a connection to the VM service, we're ready to spawn the intermediary.
    await _startDDSServer();
  }

  Future<void> _startDDSServer() async {
    // No provided address, bind to an available port on localhost.
    // TODO(bkonyi): handle case where there's no IPv4 loopback.
    final host = uri?.host ?? InternetAddress.loopbackIPv4.host;
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
      await _vmServiceClient.sendRequest('_yieldControlToDDS', {
        'uri': tmpUri.toString(),
      });
    } on json_rpc.RpcException catch (e) {
      await _server.close(force: true);
      // _yieldControlToDDS fails if DDS is not the only VM service client.
      throw DartDevelopmentServiceException._(e.data['details']);
    }

    _uri = tmpUri;
  }

  /// Stop accepting requests after gracefully handling existing requests.
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
    await _vmServiceSocket.sink.close();

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
  Cascade _handlers() => Cascade().add(_webSocketHandler()).add(_httpHandler());

  Handler _webSocketHandler() => webSocketHandler((WebSocketChannel ws) {
        final client = _DartDevelopmentServiceClient(
          this,
          ws,
          _vmServiceClient,
        );
        clientManager.addClient(client);
      });

  Handler _httpHandler() {
    // DDS doesn't support any HTTP requests itself, so we just forward all of
    // them to the VM service.
    final cascade = Cascade().add(proxyHandler(remoteVmServiceUri));
    return cascade.handler;
  }

  Uri _toWebSocket(Uri uri) {
    if (uri == null) {
      return null;
    }
    final pathSegments = <String>[];
    if (uri.pathSegments.isNotEmpty) {
      pathSegments.addAll(uri.pathSegments.where(
        // Strip out the empty string that appears at the end of path segments.
        // Empty string elements will result in an extra '/' being added to the
        // URI.
        (s) => s.isNotEmpty,
      ));
    }
    pathSegments.add('ws');
    return uri.replace(scheme: 'ws', pathSegments: pathSegments);
  }

  String _getNamespace(_DartDevelopmentServiceClient client) =>
      clientManager.clients.keyOf(client);

  bool get authCodesEnabled => _authCodesEnabled;
  final bool _authCodesEnabled;
  String _authCode;

  Uri get remoteVmServiceUri => _remoteVmServiceUri;
  Uri get remoteVmServiceWsUri => _toWebSocket(_remoteVmServiceUri);
  Uri _remoteVmServiceUri;

  Uri get uri => _uri;
  Uri get wsUri => _toWebSocket(_uri);
  Uri _uri;

  bool get isRunning => _uri != null;

  Future<void> get done => _done.future;
  Completer _done = Completer<void>();
  bool _shuttingDown = false;

  _ClientManager get clientManager => _clientManager;
  _ClientManager _clientManager;

  _ExpressionEvaluator get expressionEvaluator => _expressionEvaluator;
  _ExpressionEvaluator _expressionEvaluator;

  _IsolateManager get isolateManager => _isolateManager;
  _IsolateManager _isolateManager;

  _LoggingRepository get loggingRepository => _loggingRepository;
  _LoggingRepository _loggingRepository;

  _StreamManager get streamManager => _streamManager;
  _StreamManager _streamManager;

  json_rpc.Peer _vmServiceClient;
  WebSocketChannel _vmServiceSocket;
  HttpServer _server;
}
