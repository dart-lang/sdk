// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

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
      var serial = map['id'];
      if (serial != null && serial is! num && serial is! String) {
        socket.close(ID_ERROR_CODE, '"id" must be a number, string, or null.');
      }
      onMessage(serial, new Message.fromJsonRpc(this, map));
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
        socket.add(result);  // String or binary message.
      } else {
        // String message as external Uint8List.
        assert(result is List);
        Uint8List cstring = result[0];
        socket.addUtf8Text(cstring);
      }
    } catch (e, st) {
      print("Ignoring error posting over WebSocket.");
      print(e);
      print(st);
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
      : super(service, sendEvents:false);

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
      Uint8List cstring = result[0];  // Already in UTF-8.
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
    return (requestPathSegments[1] == '') ?
        ROOT_REDIRECT_PATH : '/${requestPathSegments.sublist(1).join('/')}';
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
      Object fsName;
      Object fsPath;

      try {
        // Extract the fs name and fs path from the request headers.
        fsNameList = request.headers['dev_fs_name'];
        fsName = fsNameList[0];

        fsPathList = request.headers['dev_fs_path'];
        fsPathBase64List = request.headers['dev_fs_path_b64'];
        // If the 'dev_fs_path_b64' header field was sent, use that instead.
        if ((fsPathBase64List != null) && (fsPathBase64List.length > 0)) {
          fsPath = UTF8.decode(BASE64.decode(fsPathBase64List[0]));
        } else {
          fsPath = fsPathList[0];
        }
      } catch (e) { /* ignore */ }

      String result;
      try {
        result = await _service.devfs.handlePutStream(
            fsName,
            fsPath,
            request.transform(GZIP.decoder));
      } catch (e) { /* ignore */ }

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
      WebSocketTransformer.upgrade(request).then(
                                   (WebSocket webSocket) {
        new WebSocketClient(webSocket, _service);
      });
      return;
    }

    Asset asset = assets[path];
    if (asset != null) {
      // Serving up a static asset (e.g. .css, .html, .png).
      request.response.headers.contentType =
          ContentType.parse(asset.mimeType);
      request.response.add(asset.data);
      request.response.close();
      return;
    }
    // HTTP based service request.
    try {
      var client = new HttpRequestClient(request, _service);
      var message = new Message.fromUri(client, request.uri);
      client.onMessage(null, message);
    } catch (e) {
      print('Unexpected error processing HTTP request uri: '
            '${request.uri}\n$e\n');
      rethrow;
    }
  }

  Future startup() async {
    if (_server != null) {
      // Already running.
      return this;
    }

    // Startup HTTP server.
    try {
      var addresses = await InternetAddress.lookup(_ip);
      var address;
      // Prefer IPv4 addresses.
      for (var i = 0; i < addresses.length; i++) {
        address = addresses[i];
        if (address.type == InternetAddressType.IP_V4) break;
      }
      _server = await HttpServer.bind(address, _port);
      _server.listen(_requestHandler, cancelOnError: true);
      print('Observatory listening on $serverAddress');
      // Server is up and running.
      _notifyServerState(serverAddress.toString());
      onServerAddressChange('$serverAddress');
      return this;
    } catch (e, st) {
      print('Could not start Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState("");
      onServerAddressChange(null);
      return this;
    }
  }

  Future cleanup(bool force) {
    if (_server == null) {
      return new Future.value(null);
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
      print('Observatory no longer listening on $oldServerAddress');
      _server = null;
      _notifyServerState("");
      onServerAddressChange(null);
      return this;
    }).catchError((e, st) {
      _server = null;
      print('Could not shutdown Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState("");
      onServerAddressChange(null);
      return this;
    });
  }

}

void _notifyServerState(String uri)
    native "VMServiceIO_NotifyServerState";
