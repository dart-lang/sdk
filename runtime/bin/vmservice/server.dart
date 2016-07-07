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
      socket.add(result);
    } catch (_) {
      print("Ignoring error posting over WebSocket.");
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

  void post(String result) {
    if (result == null) {
      close();
      return;
    }
    request.response..headers.contentType = jsonContentType
                    ..write(result)
                    ..close();
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
  final List<String> _allowedOrigins = <String>[];
  HttpServer _server;
  bool get running => _server != null;
  bool _displayMessages = false;

  Server(this._service, this._ip, this._port, this._originCheckDisabled) {
    _displayMessages = (_ip != '127.0.0.1' || _port != 8181);
  }

  void _addOrigin(String host, String port) {
    String origin = 'http://$host:$port';
    _allowedOrigins.add(origin);
  }

  bool _isAllowedOrigin(String origin) {
    for (String allowedOrigin in _allowedOrigins) {
      if (origin.startsWith(allowedOrigin)) {
        return true;
      }
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

  void _requestHandler(HttpRequest request) {
    if (!_originCheck(request)) {
      // This is a cross origin attempt to connect
      request.response.close();
      return;
    }
    if (request.method != 'GET') {
      // Not a GET request. Do nothing.
      request.response.close();
      return;
    }

    final String path =
          request.uri.path == '/' ? ROOT_REDIRECT_PATH : request.uri.path;

    if (path == WEBSOCKET_PATH) {
      WebSocketTransformer.upgrade(request,
                                   compression: CompressionOptions.OFF).then(
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

  Future startup() {
    if (_server != null) {
      // Already running.
      return new Future.value(this);
    }

    // Clear allowed origins.
    _allowedOrigins.clear();

    var address = new InternetAddress(_ip);
    // Startup HTTP server.
    return HttpServer.bind(address, _port).then((s) {
      _server = s;
      _server.listen(_requestHandler, cancelOnError: true);
      var ip = _server.address.address.toString();
      var port = _server.port.toString();
      // Add the numeric ip and host name to our allowed origins.
      _addOrigin(ip, port);
      _addOrigin(_server.address.host.toString(), port);
      // Explicitly add localhost and 127.0.0.1.
      _addOrigin('localhost', port);
      _addOrigin('127.0.0.1', port);
      if (_displayMessages) {
        print('Observatory listening on http://$ip:$port');
      }
      // Server is up and running.
      _notifyServerState(ip, _server.port);
      onServerAddressChange('http://$ip:$port');
      return this;
    }).catchError((e, st) {
      print('Could not start Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState("", 0);
      onServerAddressChange(null);
      return this;
    });
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

    // Force displaying of status messages if we are forcibly shutdown.
    _displayMessages = _displayMessages || forced;

    // Shutdown HTTP server and subscription.
    var ip = _server.address.address.toString();
    var port = _server.port.toString();
    return cleanup(forced).then((_) {
      if (_displayMessages) {
        print('Observatory no longer listening on http://$ip:$port');
      }
      _server = null;
      _notifyServerState("", 0);
      onServerAddressChange(null);
      return this;
    }).catchError((e, st) {
      _server = null;
      print('Could not shutdown Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState("", 0);
      onServerAddressChange(null);
      return this;
    });
  }

}

void _notifyServerState(String ip, int port)
    native "VMServiceIO_NotifyServerState";
