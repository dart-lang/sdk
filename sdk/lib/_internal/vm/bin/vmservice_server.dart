// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

bool silentObservatory = bool.fromEnvironment('SILENT_OBSERVATORY');

void serverPrint(String s) {
  if (silentObservatory) {
    // We've been requested to be silent.
    return;
  }
  print(s);
}

class WebSocketClient extends Client {
  static const int parseErrorCode = 4000;
  static const int binaryMessageErrorCode = 4001;
  static const int notMapErrorCode = 4002;
  static const int idErrorCode = 4003;
  final WebSocket socket;

  WebSocketClient(this.socket, VMService service) : super(service) {
    socket.listen((message) => onWebSocketMessage(message));
    socket.done.then((_) => close());
  }

  disconnect() {
    if (socket != null) {
      socket.close();
    }
  }

  void onWebSocketMessage(message) {
    if (message is String) {
      Map map;
      try {
        map = json.decode(message);
      } catch (e) {
        socket.close(parseErrorCode, 'Message parse error: $e');
        return;
      }
      if (map is! Map) {
        socket.close(notMapErrorCode, 'Message must be a JSON map.');
        return;
      }
      try {
        final rpc = Message.fromJsonRpc(this, map);
        switch (rpc.type) {
          case MessageType.Request:
            onRequest(rpc);
            break;
          case MessageType.Notification:
            onNotification(rpc);
            break;
          case MessageType.Response:
            onResponse(rpc);
            break;
        }
      } on dynamic catch (e) {
        socket.close(idErrorCode, e.message);
      }
    } else {
      socket.close(binaryMessageErrorCode, 'Message must be a string.');
    }
  }

  void post(Response? result) {
    if (result == null) {
      // The result of a notification event. Do nothing.
      return;
    }
    try {
      switch (result.kind) {
        case ResponsePayloadKind.String:
        case ResponsePayloadKind.Binary:
          socket.add(result.payload);
          break;
        case ResponsePayloadKind.Utf8String:
          socket.addUtf8Text(result.payload);
          break;
      }
    } on StateError catch (_) {
      // VM has shutdown, do nothing.
      return;
    }
  }

  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'type': 'WebSocketClient',
        'socket': '$socket',
      };
}

class HttpRequestClient extends Client {
  static final jsonContentType =
      ContentType('application', 'json', charset: 'utf-8');
  final HttpRequest request;

  HttpRequestClient(this.request, VMService service)
      : super(service, sendEvents: false);

  disconnect() {
    request.response.close();
    close();
  }

  void post(Response? result) {
    if (result == null) {
      // The result of a notification event. Nothing to do other than close the
      // connection.
      close();
      return;
    }

    HttpResponse response = request.response;
    // We closed the connection for bad origins earlier.
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.contentType = jsonContentType;
    switch (result.kind) {
      case ResponsePayloadKind.String:
        response.write(result.payload);
        break;
      case ResponsePayloadKind.Utf8String:
        response.add(result.payload);
        break;
      case ResponsePayloadKind.Binary:
        throw 'Can not handle binary responses';
    }
    response.close();
    close();
  }

  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['type'] = 'HttpRequestClient';
    map['request'] = '$request';
    return map;
  }
}

class Server {
  static const WEBSOCKET_PATH = '/ws';
  static const ROOT_REDIRECT_PATH = '/index.html';

  final VMService _service;
  final String _ip;
  final bool _originCheckDisabled;
  final bool _authCodesDisabled;
  final bool _enableServicePortFallback;
  final String? _serviceInfoFilename;
  HttpServer? _server;
  bool get running => _server != null;
  bool acceptNewWebSocketConnections = true;
  int _port = -1;

  /// Returns the server address including the auth token.
  Uri? get serverAddress {
    if (!running || _service.isExiting) {
      return null;
    }
    // If DDS is connected it should be treated as the "true" VM service and be
    // advertised as such.
    if (_service.ddsUri != null) {
      return _service.ddsUri;
    }
    final server = _server!;
    final ip = server.address.address;
    final port = server.port;
    final path = !_authCodesDisabled ? '$serviceAuthToken/' : '/';
    return Uri(scheme: 'http', host: ip, port: port, path: path);
  }

  // On Fuchsia, authentication codes are disabled by default. To enable, the authentication token
  // would have to be written into the hub alongside the port number.
  Server(
      this._service,
      this._ip,
      this._port,
      this._originCheckDisabled,
      bool authCodesDisabled,
      this._serviceInfoFilename,
      this._enableServicePortFallback)
      : _authCodesDisabled = (authCodesDisabled || Platform.isFuchsia);

  bool _isAllowedOrigin(String origin) {
    Uri uri;
    try {
      uri = Uri.parse(origin);
    } catch (_) {
      return false;
    }

    // Explicitly add localhost and 127.0.0.1 on any port (necessary for
    // adb port forwarding).
    if ((uri.host == 'localhost') ||
        (uri.host == '::1') ||
        (uri.host == '127.0.0.1')) {
      return true;
    }

    final server = _server!;
    if ((uri.port == server.port) &&
        ((uri.host == server.address.address) ||
            (uri.host == server.address.host))) {
      return true;
    }

    return false;
  }

  bool _originCheck(HttpRequest request) {
    if (_originCheckDisabled) {
      // Always allow.
      return true;
    }
    // First check the web-socket specific origin.
    List<String>? origins = request.headers['Sec-WebSocket-Origin'];
    if (origins == null) {
      // Fall back to the general Origin field.
      origins = request.headers['Origin'];
    }
    if (origins == null) {
      // No origin sent. This is a non-browser client or a same-origin request.
      return true;
    }
    for (final origin in origins) {
      if (_isAllowedOrigin(origin)) {
        return true;
      }
    }
    return false;
  }

  /// Checks the [requestUri] for the service auth token and returns the path
  /// as a String. If the service auth token check fails, returns null.
  /// Returns a Uri if a redirect is required.
  dynamic _checkAuthTokenAndGetPath(Uri requestUri) {
    if (_authCodesDisabled) {
      return requestUri.path == '/' ? ROOT_REDIRECT_PATH : requestUri.path;
    }
    final List<String> requestPathSegments = requestUri.pathSegments;
    if (requestPathSegments.isEmpty) {
      // Malformed.
      return null;
    }
    // Check that we were given the auth token.
    final authToken = requestPathSegments[0];
    if (authToken != serviceAuthToken) {
      // Malformed.
      return null;
    }
    // Missing a trailing '/'. We'll need to redirect to serve
    // ROOT_REDIRECT_PATH correctly, otherwise the response is misinterpreted.
    if (requestPathSegments.length == 1) {
      // requestPathSegments is unmodifiable. Copy it.
      final pathSegments = List<String>.from(requestPathSegments);

      // Adding an empty string to the path segments results in the path having
      // a trailing '/'.
      pathSegments.add('');

      return requestUri.replace(pathSegments: pathSegments);
    }
    // Construct the actual request path by chopping off the auth token.
    return (requestPathSegments[1] == '')
        ? ROOT_REDIRECT_PATH
        : '/${requestPathSegments.sublist(1).join('/')}';
  }

  Future _requestHandler(HttpRequest request) async {
    if (!_originCheck(request)) {
      // This is a cross origin attempt to connect
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write('forbidden origin');
      request.response.close();
      return;
    }
    if (request.method == 'PUT') {
      // PUT requests are forwarded to DevFS for processing.

      List fsNameList;
      List? fsPathList;
      List? fsPathBase64List;
      List? fsUriBase64List;
      Object? fsName;
      Object? fsPath;
      Uri? fsUri;

      try {
        // Extract the fs name and fs path from the request headers.
        fsNameList = request.headers['dev_fs_name']!;
        fsName = fsNameList[0];

        // Prefer Uri encoding first.
        fsUriBase64List = request.headers['dev_fs_uri_b64'];
        if ((fsUriBase64List != null) && (fsUriBase64List.length > 0)) {
          final decodedFsUri = utf8.decode(base64.decode(fsUriBase64List[0]));
          fsUri = Uri.parse(decodedFsUri);
        }

        // Fallback to path encoding.
        if (fsUri == null) {
          fsPathList = request.headers['dev_fs_path'];
          fsPathBase64List = request.headers['dev_fs_path_b64'];
          // If the 'dev_fs_path_b64' header field was sent, use that instead.
          if ((fsPathBase64List != null) && fsPathBase64List.isNotEmpty) {
            fsPath = utf8.decode(base64.decode(fsPathBase64List[0]));
          } else if (fsPathList != null && fsPathList.isNotEmpty) {
            fsPath = fsPathList[0];
          }
        }
      } catch (e) {/* ignore */}

      String result;
      try {
        result = await _service.devfs.handlePutStream(fsName, fsPath, fsUri,
            request.cast<List<int>>().transform(gzip.decoder));
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(e);
        request.response.close();
        return;
      }

      if (result != null) {
        request.response.headers.contentType =
            HttpRequestClient.jsonContentType;
        request.response.write(result);
      }
      request.response.close();
      return;
    }
    if (request.method != 'GET') {
      // Not a GET request. Do nothing.
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.write('method not allowed');
      request.response.close();
      return;
    }

    final result = _checkAuthTokenAndGetPath(request.uri);
    if (result == null) {
      // Either no authentication code was provided when one was expected or an
      // incorrect authentication code was provided.
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write('missing or invalid authentication code');
      request.response.close();
      return;
    } else if (result is Uri) {
      // The URI contains the valid auth token but is missing a trailing '/'.
      // Redirect to the same URI with the trailing '/' to correctly serve
      // index.html.
      request.response.redirect(result);
      return;
    }

    final String path = result;
    if (path == WEBSOCKET_PATH) {
      final subprotocols = request.headers['sec-websocket-protocol'];
      if (acceptNewWebSocketConnections) {
        WebSocketTransformer.upgrade(request,
                protocolSelector:
                    subprotocols == null ? null : (_) => 'implicit-redirect',
                compression: CompressionOptions.compressionOff)
            .then((WebSocket webSocket) {
          WebSocketClient(webSocket, _service);
        });
      } else {
        // Attempt to redirect client to the DDS instance.
        request.response.redirect(_service.ddsUri!);
      }
      return;
    }

    if (assets == null) {
      request.response.headers.contentType = ContentType.text;
      request.response.write('This VM was built without the Observatory UI.');
      request.response.close();
      return;
    }
    final asset = assets[path];
    if (asset != null) {
      // Serving up a static asset (e.g. .css, .html, .png).
      request.response.headers.contentType = ContentType.parse(asset.mimeType);
      request.response.add(asset.data);
      request.response.close();
      return;
    }
    // HTTP based service request.
    final client = HttpRequestClient(request, _service);
    final message = Message.fromUri(
        client, Uri(path: path, queryParameters: request.uri.queryParameters));
    client.onRequest(message); // exception free, no need to try catch
  }

  Future<void> _dumpServiceInfoToFile(String serviceInfoFilenameLocal) async {
    final serviceInfo = <String, dynamic>{
      'uri': serverAddress.toString(),
    };
    final file = File.fromUri(Uri.parse(serviceInfoFilenameLocal));
    return file.writeAsString(json.encode(serviceInfo)) as Future<void>;
  }

  Future<Server> startup() async {
    if (_server != null) {
      // Already running.
      return this;
    }

    // Startup HTTP server.
    var pollError;
    var pollStack;
    Future<bool> poll() async {
      try {
        var address;
        var addresses = await InternetAddress.lookup(_ip);
        // Prefer IPv4 addresses.
        for (int i = 0; i < addresses.length; i++) {
          address = addresses[i];
          if (address.type == InternetAddressType.IPv4) break;
        }
        _server = await HttpServer.bind(address, _port);
        return true;
      } catch (e, st) {
        pollError = e;
        pollStack = st;
        return false;
      }
    }

    // poll for the network for ~10 seconds.
    int attempts = 0;
    final maxAttempts = 10;
    while (!await poll()) {
      attempts++;
      serverPrint('Observatory server failed to start after $attempts tries');
      if (attempts > maxAttempts) {
        serverPrint('Could not start Observatory HTTP server:\n'
            '$pollError\n$pollStack\n');
        _notifyServerState('');
        onServerAddressChange(null);
        return this;
      }
      if (_port != 0 && _enableServicePortFallback && attempts >= 3) {
        _port = 0;
        serverPrint('Falling back to automatic port selection');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (_service.isExiting) {
      serverPrint('Observatory HTTP server exiting before listening as '
          'vm service has received exit request\n');
      await shutdown(true);
      return this;
    }
    final server = _server!;
    server.listen(_requestHandler, cancelOnError: true);
    if (!_waitForDdsToAdvertiseService) {
      await outputConnectionInformation();
    }
    // Server is up and running.
    _notifyServerState(serverAddress.toString());
    onServerAddressChange('$serverAddress');
    return this;
  }

  Future<void> outputConnectionInformation() async {
    serverPrint('Observatory listening on $serverAddress');
    if (Platform.isFuchsia) {
      // Create a file with the port number.
      final tmp = Directory.systemTemp.path;
      final path = '$tmp/dart.services/${_server!.port}';
      serverPrint('Creating $path');
      File(path)..createSync(recursive: true);
    }
    final serviceInfoFilenameLocal = _serviceInfoFilename;
    if (serviceInfoFilenameLocal != null &&
        serviceInfoFilenameLocal.isNotEmpty) {
      await _dumpServiceInfoToFile(serviceInfoFilenameLocal);
    }
  }

  Future<void> cleanup(bool force) {
    final serverLocal = _server;
    if (serverLocal == null) {
      return Future.value();
    }
    if (Platform.isFuchsia) {
      // Remove the file with the port number.
      final tmp = Directory.systemTemp.path;
      final path = '$tmp/dart.services/${serverLocal.port}';
      serverPrint('Deleting $path');
      File(path)..deleteSync();
    }
    return serverLocal.close(force: force);
  }

  Future<Server> shutdown(bool forced) {
    if (_server == null) {
      // Not started.
      return Future.value(this);
    }

    // Shutdown HTTP server and subscription.
    Uri oldServerAddress = serverAddress!;
    return cleanup(forced).then((_) {
      serverPrint('Observatory no longer listening on $oldServerAddress');
      _server = null;
      _notifyServerState('');
      onServerAddressChange(null);
      return this;
    }).catchError((e, st) {
      _server = null;
      serverPrint('Could not shutdown Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState('');
      onServerAddressChange(null);
      return this;
    });
  }
}

void _notifyServerState(String uri) native 'VMServiceIO_NotifyServerState';
