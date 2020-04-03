// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

class _DartDevelopmentService implements DartDevelopmentService {
  _DartDevelopmentService(this._remoteVmServiceUri, this._uri);

  Future<void> startService() async {
    // Establish the connection to the VM service.
    _vmServiceSocket = await WebSocket.connect(remoteVmServiceWsUri.toString());
    _vmServiceStream = _vmServiceSocket.asBroadcastStream();
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
    _uri = Uri(scheme: 'http', host: host, port: _server.port);
  }

  /// Stop accepting requests after gracefully handling existing requests.
  Future<void> shutdown() async {
    await _server.close();
    await _vmServiceSocket.close();
  }

  // Attempt to upgrade HTTP requests to a websocket before processing them as
  // standard HTTP requests. The websocket handler will fail quickly if the
  // request doesn't appear to be a websocket upgrade request.
  Cascade _handlers() => Cascade().add(_webSocketHandler()).add(_httpHandler());

  Handler _webSocketHandler() => webSocketHandler((WebSocketChannel ws) {
        // TODO(bkonyi): actually process requests instead of blindly forwarding them.
        _vmServiceStream.listen(
          (event) => ws.sink.add(event),
          onDone: () => ws.sink.close(),
        );
        ws.stream.listen((event) => _vmServiceSocket.add(event));
      });

  Handler _httpHandler() {
    // TODO(bkonyi): actually process requests instead of blindly forwarding them.
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

  Uri get remoteVmServiceUri => _remoteVmServiceUri;
  Uri get remoteVmServiceWsUri => _toWebSocket(_remoteVmServiceUri);
  Uri _remoteVmServiceUri;

  Uri get uri => _uri;
  Uri get wsUri => _toWebSocket(_uri);
  Uri _uri;

  bool get isRunning => _uri != null;

  WebSocket _vmServiceSocket;
  Stream _vmServiceStream;
  HttpServer _server;
}
