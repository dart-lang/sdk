// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

class _DartDevelopmentService implements DartDevelopmentService {
  _DartDevelopmentService(this._remoteVmServiceUri, this._uri) {
    _streamManager = _StreamManager(this);
  }

  Future<void> startService() async {
    // Establish the connection to the VM service.
    _vmServiceSocket = WebSocketChannel.connect(remoteVmServiceWsUri);
    _vmServiceClient = _BinaryCompatiblePeer(_vmServiceSocket, _streamManager);
    // Setup the JSON RPC client with the VM service.
    unawaited(_vmServiceClient.listen());

    // Setup stream event handling.
    streamManager.listen();

    // Once we have a connection to the VM service, we're ready to spawn the intermediary.
    await _startDDSServer();
  }

  Future<void> _startDDSServer() async {
    // No provided address, bind to an available port on localhost.
    // TODO(bkonyi): handle case where there's no IPv4 loopback.
    final host = uri?.host ?? InternetAddress.loopbackIPv4.host;
    final port = uri?.port ?? 0;

    // Start the DDS server.
    _server = await io.serve(_handlers().handler, host, port);

    final tmpUri = Uri(scheme: 'http', host: host, port: _server.port);

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
    // Don't accept anymore HTTP requests.
    await _server.close();

    // Close all incoming websocket connections.
    final futures = <Future>[];
    for (final client in _clients) {
      futures.add(client.close());
    }
    await Future.wait(futures);

    // Close connection to VM service.
    await _vmServiceSocket.sink.close();

    _done.complete();
  }

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
        _clients.add(client);
        client.listen().then((_) => _clients.remove(client));
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
      _clients.keyOf(client);

  Uri get remoteVmServiceUri => _remoteVmServiceUri;
  Uri get remoteVmServiceWsUri => _toWebSocket(_remoteVmServiceUri);
  Uri _remoteVmServiceUri;

  Uri get uri => _uri;
  Uri get wsUri => _toWebSocket(_uri);
  Uri _uri;

  bool get isRunning => _uri != null;

  Future<void> get done => _done.future;
  Completer _done = Completer<void>();

  _StreamManager get streamManager => _streamManager;
  _StreamManager _streamManager;

  // Handles namespace generation for service extensions.
  static const _kServicePrologue = 's';
  final NamedLookup<_DartDevelopmentServiceClient> _clients = NamedLookup(
    prologue: _kServicePrologue,
  );

  json_rpc.Peer _vmServiceClient;
  WebSocketChannel _vmServiceSocket;
  HttpServer _server;
}
