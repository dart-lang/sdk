// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

final bool silentObservatory = const bool.fromEnvironment('SILENT_OBSERVATORY');

void serverPrint(String s) {
  if (silentObservatory) {
    // We've been requested to be silent.
    return;
  }
  print(s);
}

class WebSocketClient extends Client {
  static const int PARSE_ERROR_CODE = 4000;
  static const int BINARY_MESSAGE_ERROR_CODE = 4001;
  static const int NOT_MAP_ERROR_CODE = 4002;
  static const int ID_ERROR_CODE = 4003;
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
      var map;
      try {
        map = JSON.decode(message);
      } catch (e) {
        socket.close(PARSE_ERROR_CODE, 'Message parse error: $e');
        return;
      }
      if (map is! Map) {
        socket.close(NOT_MAP_ERROR_CODE, 'Message must be a JSON map.');
        return;
      }
      try {
        final rpc = new Message.fromJsonRpc(this, map);
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
      } catch (e) {
        socket.close(ID_ERROR_CODE, e.message);
      }
    } else {
      socket.close(BINARY_MESSAGE_ERROR_CODE, 'Message must be a string.');
    }
  }

  void post(dynamic result) {
    if (result == null) {
      // Do nothing.
      return;
    }
    try {
      if (result is String || result is Uint8List) {
        socket.add(result); // String or binary message.
      } else {
        // String message as external Uint8List.
        assert(result is List);
        Uint8List cstring = result[0];
        socket.addUtf8Text(cstring);
      }
    } catch (e, st) {
      serverPrint("Ignoring error posting over WebSocket.");
      serverPrint(e.toString());
      serverPrint(st.toString());
    }
  }

  dynamic toJson() {
    Map map = super.toJson();
    map['type'] = 'WebSocketClient';
    map['socket'] = '$socket';
    return map;
  }
}

class HttpRequestClient extends Client {
  static ContentType jsonContentType =
      new ContentType("application", "json", charset: "utf-8");
  final HttpRequest request;

  HttpRequestClient(this.request, VMService service)
      : super(service, sendEvents: false);

  disconnect() {
    request.response.close();
    close();
  }

  void post(dynamic result) {
    if (result == null) {
      close();
      return;
    }
    HttpResponse response = request.response;
    // We closed the connection for bad origins earlier.
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.contentType = jsonContentType;
    if (result is String) {
      response.write(result);
    } else {
      assert(result is List);
      Uint8List cstring = result[0]; // Already in UTF-8.
      response.add(cstring);
    }
    response.close();
    close();
  }

  dynamic toJson() {
    Map map = super.toJson();
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
  final int _port;
  final bool _originCheckDisabled;
  HttpServer _server;
  bool get running => _server != null;

  /// Returns the server address including the auth token.
  Uri get serverAddress {
    if (!running) {
      return null;
    }
    var ip = _server.address.address;
    var port = _server.port;
    var path = useAuthToken ? "$serviceAuthToken/" : "/";
    return new Uri(scheme: 'http', host: ip, port: port, path: path);
  }

  Server(this._service, this._ip, this._port, this._originCheckDisabled);

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

    if ((uri.port == _server.port) &&
        ((uri.host == _server.address.address) ||
            (uri.host == _server.address.host))) {
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
    List<String> origins = request.headers["Sec-WebSocket-Origin"];
    if (origins == null) {
      // Fall back to the general Origin field.
      origins = request.headers["Origin"];
    }
    if (origins == null) {
      // No origin sent. This is a non-browser client or a same-origin request.
      return true;
    }
    for (String origin in origins) {
      if (_isAllowedOrigin(origin)) {
        return true;
      }
    }
    return false;
  }

  /// Checks the [requestUri] for the service auth token and returns the path.
  /// If the service auth token check fails, returns null.
  String _checkAuthTokenAndGetPath(Uri requestUri) {
    if (!useAuthToken) {
      return requestUri.path == '/' ? ROOT_REDIRECT_PATH : requestUri.path;
    }
    final List<String> requestPathSegments = requestUri.pathSegments;
    if (requestPathSegments.length < 2) {
      // Malformed.
      return null;
    }
    // Check that we were given the auth token.
    final String authToken = requestPathSegments[0];
    if (authToken != serviceAuthToken) {
      // Malformed.
      return null;
    }
    // Construct the actual request path by chopping off the auth token.
    return (requestPathSegments[1] == '')
        ? ROOT_REDIRECT_PATH
        : '/${requestPathSegments.sublist(1).join('/')}';
  }

  Future _requestHandler(HttpRequest request) async {
    if (!_originCheck(request)) {
      // This is a cross origin attempt to connect
      request.response.close();
      return;
    }
    if (request.method == 'PUT') {
      // PUT requests are forwarded to DevFS for processing.

      List fsNameList;
      List fsPathList;
      List fsPathBase64List;
      List fsUriBase64List;
      Object fsName;
      Object fsPath;
      Object fsUri;

      try {
        // Extract the fs name and fs path from the request headers.
        fsNameList = request.headers['dev_fs_name'];
        fsName = fsNameList[0];

        // Prefer Uri encoding first.
        fsUriBase64List = request.headers['dev_fs_uri_b64'];
        if ((fsUriBase64List != null) && (fsUriBase64List.length > 0)) {
          String decodedFsUri = UTF8.decode(BASE64.decode(fsUriBase64List[0]));
          fsUri = Uri.parse(decodedFsUri);
        }

        // Fallback to path encoding.
        if (fsUri == null) {
          fsPathList = request.headers['dev_fs_path'];
          fsPathBase64List = request.headers['dev_fs_path_b64'];
          // If the 'dev_fs_path_b64' header field was sent, use that instead.
          if ((fsPathBase64List != null) && (fsPathBase64List.length > 0)) {
            fsPath = UTF8.decode(BASE64.decode(fsPathBase64List[0]));
          } else {
            fsPath = fsPathList[0];
          }
        }
      } catch (e) {/* ignore */}

      String result;
      try {
        result = await _service.devfs.handlePutStream(
            fsName, fsPath, fsUri, request.transform(GZIP.decoder));
      } catch (e) {/* ignore */}

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
      request.response.close();
      return;
    }

    final String path = _checkAuthTokenAndGetPath(request.uri);
    if (path == null) {
      // Malformed.
      request.response.close();
      return;
    }

    if (path == WEBSOCKET_PATH) {
      WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
        new WebSocketClient(webSocket, _service);
      });
      return;
    }

    if (assets == null) {
      request.response.headers.contentType = ContentType.TEXT;
      request.response.write("This VM was built without the Observatory UI.");
      request.response.close();
      return;
    }
    Asset asset = assets[path];
    if (asset != null) {
      // Serving up a static asset (e.g. .css, .html, .png).
      request.response.headers.contentType = ContentType.parse(asset.mimeType);
      request.response.add(asset.data);
      request.response.close();
      return;
    }
    // HTTP based service request.
    final client = new HttpRequestClient(request, _service);
    final message = new Message.fromUri(client, request.uri);
    client.onRequest(message); // exception free, no need to try catch
  }

  Future startup() async {
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
        for (var i = 0; i < addresses.length; i++) {
          address = addresses[i];
          if (address.type == InternetAddressType.IP_V4) break;
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
    final int maxAttempts = 10;
    while (!await poll()) {
      attempts++;
      serverPrint("Observatory server failed to start after $attempts tries");
      if (attempts > maxAttempts) {
        serverPrint('Could not start Observatory HTTP server:\n'
            '$pollError\n$pollStack\n');
        _notifyServerState("");
        onServerAddressChange(null);
        return this;
      }
      await new Future<Null>.delayed(const Duration(seconds: 1));
    }
    _server.listen(_requestHandler, cancelOnError: true);
    serverPrint('Observatory listening on $serverAddress');
    if (Platform.isFuchsia) {
      // Create a file with the port number.
      String tmp = Directory.systemTemp.path;
      String path = "$tmp/dart.services/${_server.port}";
      serverPrint("Creating $path");
      new File(path)..createSync(recursive: true);
    }
    // Server is up and running.
    _notifyServerState(serverAddress.toString());
    onServerAddressChange('$serverAddress');
    return this;
  }

  Future cleanup(bool force) {
    if (_server == null) {
      return new Future.value(null);
    }
    if (Platform.isFuchsia) {
      // Remove the file with the port number.
      String tmp = Directory.systemTemp.path;
      String path = "$tmp/dart.services/${_server.port}";
      serverPrint("Deleting $path");
      new File(path)..deleteSync();
    }
    return _server.close(force: force);
  }

  Future shutdown(bool forced) {
    if (_server == null) {
      // Not started.
      return new Future.value(this);
    }

    // Shutdown HTTP server and subscription.
    Uri oldServerAddress = serverAddress;
    return cleanup(forced).then((_) {
      serverPrint('Observatory no longer listening on $oldServerAddress');
      _server = null;
      _notifyServerState("");
      onServerAddressChange(null);
      return this;
    }).catchError((e, st) {
      _server = null;
      serverPrint('Could not shutdown Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState("");
      onServerAddressChange(null);
      return this;
    });
  }
}

void _notifyServerState(String uri) native "VMServiceIO_NotifyServerState";
