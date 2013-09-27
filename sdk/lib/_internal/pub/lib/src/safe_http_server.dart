// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.safe_http_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// TODO(nweiz): remove this when issue 9140 is fixed.
/// A wrapper around [HttpServer] that swallows errors caused by requests
/// behaving badly. This provides the following guarantees:
///
/// * The [SafeHttpServer.listen] onError callback will only emit server-wide
///   errors. It will not emit errors for requests that were unparseable or
///   where the connection was closed too soon.
/// * [HttpResponse.done] will emit no errors.
///
/// The [HttpRequest] data stream can still emit errors.
class SafeHttpServer extends StreamView<HttpRequest> implements HttpServer {
  final HttpServer _inner;

  static Future<SafeHttpServer> bind([String host = "localhost",
      int port = 0, int backlog = 0]) {
    return HttpServer.bind(host, port, backlog: backlog)
        .then((server) => new SafeHttpServer(server));
  }

  SafeHttpServer(HttpServer server)
      : super(server),
        _inner = server;

  Future close() => _inner.close();

  int get port => _inner.port;

  set sessionTimeout(int timeout) {
    _inner.sessionTimeout = timeout;
  }

  String get serverHeader => _inner.serverHeader;
  set serverHeader(String value) {
    _inner.serverHeader = value;
  }

  Duration get idleTimeout => _inner.idleTimeout;
  set idleTimeout(Duration value) {
    _inner.idleTimeout = value;
  }

  HttpConnectionsInfo connectionsInfo() => _inner.connectionsInfo();

  StreamSubscription<HttpRequest> listen(void onData(HttpRequest value),
      {void onError(error), void onDone(),
      bool cancelOnError: false}) {
    var subscription;
    subscription = super.listen((request) {
      onData(new _HttpRequestWrapper(request));
    }, onError: (error) {
      // Ignore socket error 104, which is caused by a request being cancelled
      // before it writes any headers. There's no reason to care about such
      // requests.
      if (error is SocketException && error.osError.errorCode == 104) return;
      // Ignore any parsing errors, which come from malformed requests.
      if (error is HttpException) return;
      // Manually handle cancelOnError so the above (ignored) errors don't
      // cause unsubscription.
      if (cancelOnError) subscription.cancel();
      if (onError != null) onError(error);
    }, onDone: onDone);
    return subscription;
  }
}

/// A wrapper around [HttpRequest] for the sole purpose of swallowing errors on
/// [HttpResponse.done].
class _HttpRequestWrapper extends StreamView<List<int>> implements HttpRequest {
  final HttpRequest _inner;
  final HttpResponse response;

  _HttpRequestWrapper(HttpRequest inner)
      : super(inner),
        _inner = inner,
        response = new _HttpResponseWrapper(inner.response);

  int get contentLength => _inner.contentLength;
  String get method => _inner.method;
  Uri get uri => _inner.uri;
  HttpHeaders get headers => _inner.headers;
  List<Cookie> get cookies => _inner.cookies;
  bool get persistentConnection => _inner.persistentConnection;
  X509Certificate get certificate => _inner.certificate;
  HttpSession get session => _inner.session;
  String get protocolVersion => _inner.protocolVersion;
  HttpConnectionInfo get connectionInfo => _inner.connectionInfo;
}

/// A wrapper around [HttpResponse] for the sole purpose of swallowing errors on
/// [done].
class _HttpResponseWrapper implements HttpResponse {
  final HttpResponse _inner;
  Future<HttpResponse> _done;

  _HttpResponseWrapper(this._inner);

  /// Swallows all errors from writing to the response.
  Future<HttpResponse> get done {
    if (_done == null) _done = _inner.done.catchError((_) {});
    return _done;
  }

  int get contentLength => _inner.contentLength;
  set contentLength(int value) {
    _inner.contentLength = value;
  }

  int get statusCode => _inner.statusCode;
  set statusCode(int value) {
    _inner.statusCode = value;
  }

  String get reasonPhrase => _inner.reasonPhrase;
  set reasonPhrase(String value) {
    _inner.reasonPhrase = value;
  }

  bool get persistentConnection => _inner.persistentConnection;
  set persistentConnection(bool value) {
    _inner.persistentConnection = value;
  }

  Encoding get encoding => _inner.encoding;
  set encoding(Encoding value) {
    _inner.encoding = value;
  }

  HttpHeaders get headers => _inner.headers;
  List<Cookie> get cookies => _inner.cookies;
  Future<Socket> detachSocket() => _inner.detachSocket();
  HttpConnectionInfo get connectionInfo => _inner.connectionInfo;
  void add(List<int> data) => _inner.add(data);
  Future<HttpResponse> addStream(Stream<List<int>> stream) =>
    _inner.addStream(stream);
  Future close() => _inner.close();
  void write(Object obj) => _inner.write(obj);
  void writeAll(Iterable objects, [String separator = ""]) =>
    _inner.writeAll(objects, separator);
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);
  void writeln([Object obj = ""]) => _inner.writeln(obj);
  void addError(error) => _inner.addError(error);

  Duration get deadline => _inner.deadline;
  set deadline(Duration value) {
    _inner.deadline = value;
  }

  Future redirect(Uri location, {int status: HttpStatus.MOVED_TEMPORARILY}) =>
      _inner.redirect(location, status: status);
}
