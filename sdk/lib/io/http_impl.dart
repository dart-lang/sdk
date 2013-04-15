// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _HttpIncoming extends Stream<List<int>> {
  final int _transferLength;
  final Completer _dataCompleter = new Completer();
  Stream<List<int>> _stream;

  bool fullBodyRead = false;

  // Common properties.
  final _HttpHeaders headers;
  bool upgraded = false;

  // ClientResponse properties.
  int statusCode;
  String reasonPhrase;

  // Request properties.
  String method;
  Uri uri;

  // The transfer length if the length of the message body as it
  // appears in the message (RFC 2616 section 4.4). This can be -1 if
  // the length of the massage body is not known due to transfer
  // codings.
  int get transferLength => _transferLength;

  _HttpIncoming(_HttpHeaders this.headers,
                int this._transferLength,
                Stream<List<int>> this._stream) {
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {void onError(error),
                                        void onDone(),
                                        bool cancelOnError}) {
    return _stream.listen(onData,
                          onError: onError,
                          onDone: onDone,
                          cancelOnError: cancelOnError);
  }

  // Is completed once all data have been received.
  Future get dataDone => _dataCompleter.future;

  void close() {
    fullBodyRead = true;
    _dataCompleter.complete();
  }
}

abstract class _HttpInboundMessage extends Stream<List<int>> {
  final _HttpIncoming _incoming;
  List<Cookie> _cookies;

  _HttpInboundMessage(_HttpIncoming this._incoming);

  List<Cookie> get cookies {
    if (_cookies != null) return _cookies;
    return _cookies = headers._parseCookies();
  }

  _HttpHeaders get headers => _incoming.headers;
  String get protocolVersion => headers.protocolVersion;
  int get contentLength => headers.contentLength;
  bool get persistentConnection => headers.persistentConnection;
}


class _HttpRequest extends _HttpInboundMessage implements HttpRequest {
  final HttpResponse response;

  // Lazy initialized parsed query parameters.
  Map<String, String> _queryParameters;

  final _HttpServer _httpServer;

  final _HttpConnection _httpConnection;

  _HttpSession _session;

  _HttpRequest(_HttpResponse this.response,
               _HttpIncoming _incoming,
               _HttpServer this._httpServer,
               _HttpConnection this._httpConnection)
      : super(_incoming) {
    response.headers.persistentConnection = headers.persistentConnection;

    if (_httpServer._sessionManagerInstance != null) {
      // Map to session if exists.
      var sessionIds = cookies
          .where((cookie) => cookie.name.toUpperCase() == _DART_SESSION_ID)
          .map((cookie) => cookie.value);
      for (var sessionId in sessionIds) {
        _session = _httpServer._sessionManager.getSession(sessionId);
        if (_session != null) {
          _session._markSeen();
          break;
        }
      }
    }
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {void onError(error),
                                        void onDone(),
                                        bool cancelOnError}) {
    return _incoming.listen(onData,
                            onError: onError,
                            onDone: onDone,
                            cancelOnError: cancelOnError);
  }

  Map<String, String> get queryParameters {
    if (_queryParameters == null) {
      _queryParameters = _HttpUtils.splitQueryString(uri.query);
    }
    return _queryParameters;
  }

  Uri get uri => _incoming.uri;

  String get method => _incoming.method;

  HttpSession get session {
    if (_session != null) {
      // It's already mapped, use it.
      return _session;
    }
    // Create session, store it in connection, and return.
    return _session = _httpServer._sessionManager.createSession();
  }

  HttpConnectionInfo get connectionInfo => _httpConnection.connectionInfo;

  X509Certificate get certificate {
    Socket socket = _httpConnection._socket;
    if (socket is SecureSocket) return socket.peerCertificate;
    return null;
  }
}


class _HttpClientResponse
    extends _HttpInboundMessage implements HttpClientResponse {
  List<RedirectInfo> get redirects => _httpRequest._responseRedirects;

  // The HttpClient this response belongs to.
  final _HttpClient _httpClient;

  // The HttpClientRequest of this response.
  final _HttpClientRequest _httpRequest;

  List<Cookie> _cookies;

  _HttpClientResponse(_HttpIncoming _incoming,
                      _HttpClientRequest this._httpRequest,
                      _HttpClient this._httpClient)
      : super(_incoming);

  int get statusCode => _incoming.statusCode;
  String get reasonPhrase => _incoming.reasonPhrase;

  X509Certificate get certificate {
    var socket = _httpRequest._httpClientConnection._socket;
    return socket.peerCertificate;
  }

  List<Cookie> get cookies {
    if (_cookies != null) return _cookies;
    _cookies = new List<Cookie>();
    List<String> values = headers[HttpHeaders.SET_COOKIE];
    if (values != null) {
      values.forEach((value) {
        _cookies.add(new Cookie.fromSetCookieValue(value));
      });
    }
    return _cookies;
  }

  bool get isRedirect {
    if (_httpRequest.method == "GET" || _httpRequest.method == "HEAD") {
      return statusCode == HttpStatus.MOVED_PERMANENTLY ||
             statusCode == HttpStatus.FOUND ||
             statusCode == HttpStatus.SEE_OTHER ||
             statusCode == HttpStatus.TEMPORARY_REDIRECT;
    } else if (_httpRequest.method == "POST") {
      return statusCode == HttpStatus.SEE_OTHER;
    }
    return false;
  }

  Future<HttpClientResponse> redirect([String method,
                                       Uri url,
                                       bool followLoops]) {
    if (method == null) {
      // Set method as defined by RFC 2616 section 10.3.4.
      if (statusCode == HttpStatus.SEE_OTHER && _httpRequest.method == "POST") {
        method = "GET";
      } else {
        method = _httpRequest.method;
      }
    }
    if (url == null) {
      String location = headers.value(HttpHeaders.LOCATION);
      if (location == null) {
        throw new StateError("Response has no Location header for redirect");
      }
      url = Uri.parse(location);
    }
    if (followLoops != true) {
      for (var redirect in redirects) {
        if (redirect.location == url) {
          return new Future.error(
              new RedirectLoopException(redirects));
        }
      }
    }
    return _httpClient._openUrlFromRequest(method, url, _httpRequest)
        .then((request) {
          request._responseRedirects.addAll(this.redirects);
          request._responseRedirects.add(new _RedirectInfo(statusCode,
                                                           method,
                                                           url));
          return request.close();
        });
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {void onError(error),
                                        void onDone(),
                                        bool cancelOnError}) {
    var stream = _incoming;
    if (headers.value(HttpHeaders.CONTENT_ENCODING) == "gzip") {
      stream = stream.transform(new ZLibInflater());
    }
    return stream.listen(onData,
                         onError: onError,
                         onDone: onDone,
                         cancelOnError: cancelOnError);
  }

  Future<Socket> detachSocket() {
    _httpClient._connectionClosed(_httpRequest._httpClientConnection);
    return _httpRequest._httpClientConnection.detachSocket();
  }

  HttpConnectionInfo get connectionInfo => _httpRequest.connectionInfo;

  bool get _shouldAuthenticateProxy {
    // Only try to authenticate if there is a challenge in the response.
    List<String> challenge = headers[HttpHeaders.PROXY_AUTHENTICATE];
    return statusCode == HttpStatus.PROXY_AUTHENTICATION_REQUIRED &&
        challenge != null && challenge.length == 1;
  }

  bool get _shouldAuthenticate {
    // Only try to authenticate if there is a challenge in the response.
    List<String> challenge = headers[HttpHeaders.WWW_AUTHENTICATE];
    return statusCode == HttpStatus.UNAUTHORIZED &&
        challenge != null && challenge.length == 1;
  }

  Future<HttpClientResponse> _authenticate() {
    Future<HttpClientResponse> retryWithCredentials(_Credentials cr) {
      if (cr != null) {
        // TODO(sgjesse): Support digest.
        if (cr.scheme == _AuthenticationScheme.BASIC) {
          // Drain body and retry.
          return fold(null, (x, y) {}).then((_) {
              return _httpClient._openUrlFromRequest(_httpRequest.method,
                                                     _httpRequest.uri,
                                                     _httpRequest)
                  .then((request) => request.close());
            });
        }
      }

      // Fall through to here to perform normal response handling if
      // there is no sensible authorization handling.
      return new Future.value(this);
    }

    List<String> challenge = headers[HttpHeaders.WWW_AUTHENTICATE];
    assert(challenge != null || challenge.length == 1);
    _HeaderValue header =
        new _HeaderValue.fromString(challenge[0], parameterSeparator: ",");
    _AuthenticationScheme scheme =
        new _AuthenticationScheme.fromString(header.value);
    String realm = header.parameters["realm"];

    // See if any credentials are available.
    _Credentials cr = _httpClient._findCredentials(_httpRequest.uri, scheme);

    if (cr != null && !cr.used) {
      // If credentials found prepare for retrying the request.
      return retryWithCredentials(cr);
    }

    // Ask for more credentials if none found or the one found has
    // already been used. If it has already been used it must now be
    // invalid and is removed.
    if (cr != null) {
      _httpClient._removeCredentials(cr);
      cr = null;
    }
    if (_httpClient._authenticate != null) {
      Future authComplete = _httpClient._authenticate(_httpRequest.uri,
                                                      scheme.toString(),
                                                      realm);
      return authComplete.then((credsAvailable) {
        if (credsAvailable) {
          cr = _httpClient._findCredentials(_httpRequest.uri, scheme);
          return retryWithCredentials(cr);
        } else {
          // No credentials available, complete with original response.
          return this;
        }
      });
    }

    // No credentials were found and the callback was not set.
    return new Future.value(this);
  }

  Future<HttpClientResponse> _authenticateProxy() {
    Future<HttpClientResponse> retryWithProxyCredentials(_ProxyCredentials cr) {
      return fold(null, (x, y) {}).then((_) {
          return _httpClient._openUrlFromRequest(_httpRequest.method,
                                                 _httpRequest.uri,
                                                 _httpRequest)
              .then((request) => request.close());
        });
    }

    List<String> challenge = headers[HttpHeaders.PROXY_AUTHENTICATE];
    assert(challenge != null || challenge.length == 1);
    _HeaderValue header =
        new _HeaderValue.fromString(challenge[0], parameterSeparator: ",");
    _AuthenticationScheme scheme =
        new _AuthenticationScheme.fromString(header.value);
    String realm = header.parameters["realm"];

    // See if any credentials are available.
    var proxy = _httpRequest._proxy;

    var cr =  _httpClient._findProxyCredentials(proxy);
    if (cr != null) {
      return retryWithProxyCredentials(cr);
    }

    // Ask for more credentials if none found.
    if (_httpClient._authenticateProxy != null) {
      Future authComplete = _httpClient._authenticateProxy(proxy.host,
                                                           proxy.port,
                                                           "basic",
                                                           realm);
      return authComplete.then((credsAvailable) {
        if (credsAvailable) {
          var cr =  _httpClient._findProxyCredentials(proxy);
          return retryWithProxyCredentials(cr);
        } else {
          // No credentials available, complete with original response.
          return this;
        }
      });
    }

    // No credentials were found and the callback was not set.
    return new Future.value(this);
  }
}


abstract class _HttpOutboundMessage<T> implements IOSink {
  // Used to mark when the body should be written. This is used for HEAD
  // requests and in error handling.
  bool _ignoreBody = false;
  bool _headersWritten = false;
  bool _asGZip = false;

  IOSink _headersSink;
  IOSink _dataSink;

  final _HttpOutgoing _outgoing;

  final _HttpHeaders headers;

  _HttpOutboundMessage(String protocolVersion, _HttpOutgoing outgoing)
      : _outgoing = outgoing,
        _headersSink = new IOSink(outgoing, encoding: Encoding.ASCII),
        headers = new _HttpHeaders(protocolVersion) {
    _dataSink = new IOSink(new _HttpOutboundConsumer(this));
  }

  int get contentLength => headers.contentLength;
  void set contentLength(int contentLength) {
    headers.contentLength = contentLength;
  }

  bool get persistentConnection => headers.persistentConnection;
  void set persistentConnection(bool p) {
    headers.persistentConnection = p;
  }

  Encoding get encoding {
    var charset;
    if (headers.contentType != null && headers.contentType.charset != null) {
      charset = headers.contentType.charset;
    } else {
      charset = "iso-8859-1";
    }
    return Encoding.fromName(charset);
  }

  void set encoding(Encoding value) {
    throw new StateError("IOSink encoding is not mutable");
  }

  void write(Object obj) {
    _dataSink.write(obj);
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    _dataSink.writeAll(objects, separator);
  }

  void writeln([Object obj = ""]) {
    _dataSink.writeln(obj);
  }

  void writeCharCode(int charCode) {
    _dataSink.writeCharCode(charCode);
  }

  void add(List<int> data) {
    if (data.length == 0) return;
    _dataSink.add(data);
  }

  void addError(error) {
    _dataSink.addError(error);
  }

  Future<T> addStream(Stream<List<int>> stream) {
    return _dataSink.addStream(stream);
  }

  Future close() {
    return _dataSink.close();
  }

  Future<T> get done => _dataSink.done;

  void _writeHeaders() {
    if (_headersWritten) return;
    _headersWritten = true;
    headers._synchronize();  // Be sure the 'chunked' option is updated.
    bool isServerSide = this is _HttpResponse;
    if (isServerSide && headers.chunkedTransferEncoding) {
      var response = this;
      List acceptEncodings =
          response._httpRequest.headers[HttpHeaders.ACCEPT_ENCODING];
      List contentEncoding = headers[HttpHeaders.CONTENT_ENCODING];
      if (acceptEncodings != null &&
          acceptEncodings
              .expand((list) => list.split(","))
              .any((encoding) => encoding.trim().toLowerCase() == "gzip") &&
          contentEncoding == null) {
        headers.set(HttpHeaders.CONTENT_ENCODING, "gzip");
        _asGZip = true;
      }
    }
    _writeHeader();
  }

  Future _addStream(Stream<List<int>> stream) {
    _writeHeaders();
    int contentLength = headers.contentLength;
    if (_ignoreBody) {
      stream.fold(null, (x, y) {}).catchError((_) {});
      return _headersSink.close();
    }
    stream = stream.transform(new _BufferTransformer());
    if (headers.chunkedTransferEncoding) {
      if (_asGZip) {
        stream = stream.transform(new ZLibDeflater(gzip: true, level: 6));
      }
      stream = stream.transform(new _ChunkedTransformer());
    } else if (contentLength >= 0) {
      stream = stream.transform(new _ContentLengthValidator(contentLength));
    }
    return _headersSink.addStream(stream);
  }

  Future _close() {
    // TODO(ajohnsen): Currently, contentLength, chunkedTransferEncoding and
    // persistentConnection is not guaranteed to be in sync.
    if (!_headersWritten) {
      if (!_ignoreBody && headers.contentLength == -1) {
        // If no body was written, _ignoreBody is false (it's not a HEAD
        // request) and the content-length is unspecified, set contentLength to
        // 0.
        headers.chunkedTransferEncoding = false;
        headers.contentLength = 0;
      } else if (!_ignoreBody && headers.contentLength > 0) {
        _headersSink.close().catchError((_) {});
        return new Future.error(new HttpException(
            "No content while contentLength was specified to be greater "
            " than 0: ${headers.contentLength}."));
      }
    }
    _writeHeaders();
    return _headersSink.close();
  }

  void _writeHeader();  // TODO(ajohnsen): Better name.
}


class _HttpOutboundConsumer implements StreamConsumer {
  final _HttpOutboundMessage _outbound;
  StreamController _controller;
  StreamSubscription _subscription;
  Completer _closeCompleter = new Completer();
  Completer _completer;

  _HttpOutboundConsumer(_HttpOutboundMessage this._outbound);

  void _onPause() {
    if (_controller.isPaused) {
      _subscription.pause();
    } else {
      _subscription.resume();
    }
  }

  void _onListen() {
    if (!_controller.hasListener && _subscription != null) {
      _subscription.cancel();
    }
  }

  _ensureController() {
    if (_controller != null) return;
    _controller = new StreamController(onPause: _onPause,
                                       onResume: _onPause,
                                       onListen: _onListen,
                                       onCancel: _onListen);
    _outbound._addStream(_controller.stream)
        .then((_) {
                _done();
                _closeCompleter.complete(_outbound);
              },
              onError: (error) {
                if (!_done(error)) {
                  _closeCompleter.completeError(error);
                }
              });
  }

  bool _done([error]) {
    if (_completer == null) return false;
    var tmp = _completer;
    _completer = null;
    if (error != null) {
      tmp.completeError(error);
    } else {
      tmp.complete(_outbound);
    }
    return true;
  }

  Future addStream(var stream) {
    _ensureController();
    _completer = new Completer();
    _subscription = stream.listen(
        (data) {
          _controller.add(data);
        },
        onDone: () {
          _done();
        },
        onError: (error) {
          _done(error);
        },
        cancelOnError: true);
    return _completer.future;
  }

  Future close() {
    Future closeOutbound() {
      return _outbound._close().then((_) => _outbound);
    }
    if (_controller == null) return closeOutbound();
    _controller.close();
    return _closeCompleter.future.then((_) => closeOutbound());
  }
}


class _BufferTransformer extends StreamEventTransformer<List<int>, List<int>> {
  const int MIN_CHUNK_SIZE = 4 * 1024;
  const int MAX_BUFFER_SIZE = 16 * 1024;

  final _BufferList _buffer = new _BufferList();

  void handleData(List<int> data, EventSink<List<int>> sink) {
    // TODO(ajohnsen): Use timeout?
    if (data.length == 0) return;
    if (data.length >= MIN_CHUNK_SIZE) {
      flush(sink);
      sink.add(data);
    } else {
      _buffer.add(data);
      if (_buffer.length >= MAX_BUFFER_SIZE) {
        flush(sink);
      }
    }
  }

  void handleDone(EventSink<List<int>> sink) {
    flush(sink);
    sink.close();
  }

  void flush(EventSink<List<int>> sink) {
    if (_buffer.length > 0) {
      sink.add(_buffer.readBytes());
      _buffer.clear();
    }
  }
}


class _HttpResponse extends _HttpOutboundMessage<HttpResponse>
    implements HttpResponse {
  int statusCode = 200;
  String _reasonPhrase;
  List<Cookie> _cookies;
  _HttpRequest _httpRequest;

  _HttpResponse(String protocolVersion,
                _HttpOutgoing _outgoing)
      : super(protocolVersion, _outgoing);

  List<Cookie> get cookies {
    if (_cookies == null) _cookies = new List<Cookie>();
    return _cookies;
  }

  String get reasonPhrase => _findReasonPhrase(statusCode);
  void set reasonPhrase(String reasonPhrase) {
    if (_headersWritten) throw new StateError("Header already sent");
    _reasonPhrase = reasonPhrase;
  }

  Future<Socket> detachSocket() {
    if (_headersWritten) throw new StateError("Headers already sent");
    _writeHeaders();
    var future = _httpRequest._httpConnection.detachSocket();
    // Close connection so the socket is 'free'.
    close();
    done.catchError((_) {
      // Catch any error on done, as they automatically will be
      // propagated to the websocket.
    });
    return future;
  }

  HttpConnectionInfo get connectionInfo => _httpRequest.connectionInfo;

  void _writeHeader() {
    var buffer = new _BufferList();
    writeSP() => buffer.add(const [_CharCode.SP]);
    writeCRLF() => buffer.add(const [_CharCode.CR, _CharCode.LF]);

    // Write status line.
    if (headers.protocolVersion == "1.1") {
      buffer.add(_Const.HTTP11);
    } else {
      buffer.add(_Const.HTTP10);
    }
    writeSP();
    buffer.add(statusCode.toString().codeUnits);
    writeSP();
    buffer.add(reasonPhrase.codeUnits);
    writeCRLF();

    var session = _httpRequest._session;
    if (session != null && !session._destroyed) {
      // Mark as not new.
      session._isNew = false;
      // Make sure we only send the current session id.
      bool found = false;
      for (int i = 0; i < cookies.length; i++) {
        if (cookies[i].name.toUpperCase() == _DART_SESSION_ID) {
          cookies[i].value = session.id;
          cookies[i].httpOnly = true;
          cookies[i].path = "/";
          found = true;
        }
      }
      if (!found) {
        var cookie = new Cookie(_DART_SESSION_ID, session.id);
        cookie.httpOnly = true;
        cookie.path = "/";
        cookies.add(cookie);
      }
    }
    // Add all the cookies set to the headers.
    if (_cookies != null) {
      _cookies.forEach((cookie) {
        headers.add(HttpHeaders.SET_COOKIE, cookie);
      });
    }

    headers._finalize();

    // Write headers.
    headers._write(buffer);
    writeCRLF();
    _headersSink.add(buffer.readBytes());
  }

  String _findReasonPhrase(int statusCode) {
    if (_reasonPhrase != null) {
      return _reasonPhrase;
    }

    switch (statusCode) {
      case HttpStatus.CONTINUE: return "Continue";
      case HttpStatus.SWITCHING_PROTOCOLS: return "Switching Protocols";
      case HttpStatus.OK: return "OK";
      case HttpStatus.CREATED: return "Created";
      case HttpStatus.ACCEPTED: return "Accepted";
      case HttpStatus.NON_AUTHORITATIVE_INFORMATION:
        return "Non-Authoritative Information";
      case HttpStatus.NO_CONTENT: return "No Content";
      case HttpStatus.RESET_CONTENT: return "Reset Content";
      case HttpStatus.PARTIAL_CONTENT: return "Partial Content";
      case HttpStatus.MULTIPLE_CHOICES: return "Multiple Choices";
      case HttpStatus.MOVED_PERMANENTLY: return "Moved Permanently";
      case HttpStatus.FOUND: return "Found";
      case HttpStatus.SEE_OTHER: return "See Other";
      case HttpStatus.NOT_MODIFIED: return "Not Modified";
      case HttpStatus.USE_PROXY: return "Use Proxy";
      case HttpStatus.TEMPORARY_REDIRECT: return "Temporary Redirect";
      case HttpStatus.BAD_REQUEST: return "Bad Request";
      case HttpStatus.UNAUTHORIZED: return "Unauthorized";
      case HttpStatus.PAYMENT_REQUIRED: return "Payment Required";
      case HttpStatus.FORBIDDEN: return "Forbidden";
      case HttpStatus.NOT_FOUND: return "Not Found";
      case HttpStatus.METHOD_NOT_ALLOWED: return "Method Not Allowed";
      case HttpStatus.NOT_ACCEPTABLE: return "Not Acceptable";
      case HttpStatus.PROXY_AUTHENTICATION_REQUIRED:
        return "Proxy Authentication Required";
      case HttpStatus.REQUEST_TIMEOUT: return "Request Time-out";
      case HttpStatus.CONFLICT: return "Conflict";
      case HttpStatus.GONE: return "Gone";
      case HttpStatus.LENGTH_REQUIRED: return "Length Required";
      case HttpStatus.PRECONDITION_FAILED: return "Precondition Failed";
      case HttpStatus.REQUEST_ENTITY_TOO_LARGE:
        return "Request Entity Too Large";
      case HttpStatus.REQUEST_URI_TOO_LONG: return "Request-URI Too Large";
      case HttpStatus.UNSUPPORTED_MEDIA_TYPE: return "Unsupported Media Type";
      case HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE:
        return "Requested range not satisfiable";
      case HttpStatus.EXPECTATION_FAILED: return "Expectation Failed";
      case HttpStatus.INTERNAL_SERVER_ERROR: return "Internal Server Error";
      case HttpStatus.NOT_IMPLEMENTED: return "Not Implemented";
      case HttpStatus.BAD_GATEWAY: return "Bad Gateway";
      case HttpStatus.SERVICE_UNAVAILABLE: return "Service Unavailable";
      case HttpStatus.GATEWAY_TIMEOUT: return "Gateway Time-out";
      case HttpStatus.HTTP_VERSION_NOT_SUPPORTED:
        return "Http Version not supported";
      default: return "Status $statusCode";
    }
  }
}


class _HttpClientRequest extends _HttpOutboundMessage<HttpClientResponse>
    implements HttpClientRequest {
  final String method;
  final Uri uri;
  final List<Cookie> cookies = new List<Cookie>();

  // The HttpClient this request belongs to.
  final _HttpClient _httpClient;
  final _HttpClientConnection _httpClientConnection;

  final Completer<HttpClientResponse> _responseCompleter
      = new Completer<HttpClientResponse>();

  final _Proxy _proxy;

  Future<HttpClientResponse> _response;

  // TODO(ajohnsen): Get default value from client?
  bool _followRedirects = true;

  int _maxRedirects = 5;

  List<RedirectInfo> _responseRedirects = [];

  _HttpClientRequest(_HttpOutgoing outgoing,
                     Uri this.uri,
                     String this.method,
                     _Proxy this._proxy,
                     _HttpClient this._httpClient,
                     _HttpClientConnection this._httpClientConnection)
      : super("1.1", outgoing) {
    // GET and HEAD have 'content-length: 0' by default.
    if (method == "GET" || method == "HEAD") {
      contentLength = 0;
    }
  }

  Future<HttpClientResponse> get done {
    if (_response == null) {
      _response = Future.wait([_responseCompleter.future,
                               super.done])
        .then((list) => list[0]);
    }
    return _response;
  }

  Future<HttpClientResponse> close() {
    super.close();
    return done;
  }

  int get maxRedirects => _maxRedirects;
  void set maxRedirects(int maxRedirects) {
    if (_headersWritten) throw new StateError("Request already sent");
    _maxRedirects = maxRedirects;
  }

  bool get followRedirects => _followRedirects;
  void set followRedirects(bool followRedirects) {
    if (_headersWritten) throw new StateError("Request already sent");
    _followRedirects = followRedirects;
  }

  HttpConnectionInfo get connectionInfo => _httpClientConnection.connectionInfo;

  void _onIncoming(_HttpIncoming incoming) {
    var response = new _HttpClientResponse(incoming,
                                           this,
                                          _httpClient);
    Future<HttpClientResponse> future;
    if (followRedirects && response.isRedirect) {
      if (response.redirects.length < maxRedirects) {
        // Redirect and drain response.
        future = response.fold(null, (x, y) {})
          .then((_) => response.redirect());
      } else {
        // End with exception, too many redirects.
        future = response.fold(null, (x, y) {})
            .then((_) => new Future.error(
                new RedirectLimitExceededException(response.redirects)));
      }
    } else if (response._shouldAuthenticateProxy) {
      future = response._authenticateProxy();
    } else if (response._shouldAuthenticate) {
      future = response._authenticate();
    } else {
      future = new Future<HttpClientResponse>.value(response);
    }
    future.then(
        (v) => _responseCompleter.complete(v),
        onError: (e) {
          _responseCompleter.completeError(e);
        });
  }

  void _onError(error) {
    _responseCompleter.completeError(error);
  }

  void _writeHeader() {
    var buffer = new _BufferList();
    writeSP() => buffer.add(const [_CharCode.SP]);
    writeCRLF() => buffer.add(const [_CharCode.CR, _CharCode.LF]);

    buffer.add(method.codeUnits);
    writeSP();
    // Send the path for direct connections and the whole URL for
    // proxy connections.
    if (_proxy.isDirect) {
      String path = uri.path;
      if (path.length == 0) path = "/";
      if (uri.query != "") {
        if (uri.fragment != "") {
          path = "${path}?${uri.query}#${uri.fragment}";
        } else {
          path = "${path}?${uri.query}";
        }
      }
      buffer.add(path.codeUnits);
    } else {
      buffer.add(uri.toString().codeUnits);
    }
    writeSP();
    buffer.add(_Const.HTTP11);
    writeCRLF();

    // Add the cookies to the headers.
    if (!cookies.isEmpty) {
      StringBuffer sb = new StringBuffer();
      for (int i = 0; i < cookies.length; i++) {
        if (i > 0) sb.write("; ");
        sb.write(cookies[i].name);
        sb.write("=");
        sb.write(cookies[i].value);
      }
      headers.add(HttpHeaders.COOKIE, sb.toString());
    }

    headers._finalize();

    // Write headers.
    headers._write(buffer);
    writeCRLF();
    _headersSink.add(buffer.readBytes());
  }
}


// Transformer that transforms data to HTTP Chunked Encoding.
class _ChunkedTransformer extends StreamEventTransformer<List<int>, List<int>> {
  void handleData(List<int> data, EventSink<List<int>> sink) {
    sink.add(_chunkHeader(data.length));
    if (data.length > 0) sink.add(data);
    sink.add(_chunkFooter);
  }

  void handleDone(EventSink<List<int>> sink) {
    handleData(const [], sink);
    sink.close();
  }

  static List<int> _chunkHeader(int length) {
    const hexDigits = const [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
                             0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46];
    var header = [];
    if (length == 0) {
      header.add(hexDigits[length]);
    } else {
      while (length > 0) {
        header.insert(0, hexDigits[length % 16]);
        length = length >> 4;
      }
    }
    header.add(_CharCode.CR);
    header.add(_CharCode.LF);
    return header;
  }

  // Footer is just a CRLF.
  static List<int> get _chunkFooter => const [_CharCode.CR, _CharCode.LF];
}


// Transformer that validates the content length.
class _ContentLengthValidator
    extends StreamEventTransformer<List<int>, List<int>> {
  final int expectedContentLength;
  int _bytesWritten = 0;

  _ContentLengthValidator(int this.expectedContentLength);

  void handleData(List<int> data, EventSink<List<int>> sink) {
    _bytesWritten += data.length;
    if (_bytesWritten > expectedContentLength) {
      sink.addError(new HttpException(
          "Content size exceeds specified contentLength. "
          "$_bytesWritten bytes written while expected "
          "$expectedContentLength. "
          "[${new String.fromCharCodes(data)}]"));
      sink.close();
    } else {
      sink.add(data);
    }
  }

  void handleDone(EventSink<List<int>> sink) {
    if (_bytesWritten < expectedContentLength) {
      sink.addError(new HttpException(
          "Content size below specified contentLength. "
          " $_bytesWritten bytes written while expected "
          "$expectedContentLength."));
    }
    sink.close();
  }
}


// Extends StreamConsumer as this is an internal type, only used to pipe to.
class _HttpOutgoing implements StreamConsumer<List<int>> {
  final Completer _doneCompleter = new Completer();
  final StreamConsumer _consumer;

  _HttpOutgoing(StreamConsumer this._consumer);

  Future addStream(Stream<List<int>> stream) {
    return _consumer.addStream(stream)
        .catchError((error) {
          _doneCompleter.completeError(error);
          throw error;
        });
  }

  Future close() {
    _doneCompleter.complete(_consumer);
    return new Future.value();
  }

  Future get done => _doneCompleter.future;
}


class _HttpClientConnection {
  final String key;
  final Socket _socket;
  final _HttpParser _httpParser;
  StreamSubscription _subscription;
  final _HttpClient _httpClient;

  Completer<_HttpIncoming> _nextResponseCompleter;
  Future _streamFuture;

  _HttpClientConnection(String this.key,
                        Socket this._socket,
                        _HttpClient this._httpClient)
      : _httpParser = new _HttpParser.responseParser() {
    _socket.pipe(_httpParser);

    // Set up handlers on the parser here, so we are sure to get 'onDone' from
    // the parser.
    _subscription = _httpParser.listen(
        (incoming) {
          // Only handle one incoming response at the time. Keep the
          // stream paused until the response have been processed.
          _subscription.pause();
          // We assume the response is not here, until we have send the request.
          assert(_nextResponseCompleter != null);
          var completer = _nextResponseCompleter;
          _nextResponseCompleter = null;
          completer.complete(incoming);
        },
        onError: (error) {
          if (_nextResponseCompleter != null) {
            _nextResponseCompleter.completeError(error);
            _nextResponseCompleter = null;
          }
        },
        onDone: () {
          close();
        });
  }

  _HttpClientRequest send(Uri uri, int port, String method, _Proxy proxy) {
    // Start with pausing the parser.
    _subscription.pause();
    var outgoing = new _HttpOutgoing(_socket);
    // Create new request object, wrapping the outgoing connection.
    var request = new _HttpClientRequest(outgoing,
                                         uri,
                                         method,
                                         proxy,
                                         _httpClient,
                                         this);
    request.headers.host = uri.domain;
    request.headers.port = port;
    request.headers.set(HttpHeaders.ACCEPT_ENCODING, "gzip");
    if (proxy.isAuthenticated) {
      // If the proxy configuration contains user information use that
      // for proxy basic authorization.
      String auth = CryptoUtils.bytesToBase64(
          _encodeString("${proxy.username}:${proxy.password}"));
      request.headers.set(HttpHeaders.PROXY_AUTHORIZATION, "Basic $auth");
    } else if (!proxy.isDirect && _httpClient._proxyCredentials.length > 0) {
      var cr =  _httpClient._findProxyCredentials(proxy);
      if (cr != null) {
        cr.authorize(request);
      }
    }
    if (uri.userInfo != null && !uri.userInfo.isEmpty) {
      // If the URL contains user information use that for basic
      // authorization.
      String auth =
          CryptoUtils.bytesToBase64(_encodeString(uri.userInfo));
      request.headers.set(HttpHeaders.AUTHORIZATION, "Basic $auth");
    } else {
      // Look for credentials.
      _Credentials cr = _httpClient._findCredentials(uri);
      if (cr != null) {
        cr.authorize(request);
      }
    }
    // Start sending the request (lazy, delayed until the user provides
    // data).
    _httpParser.responseToMethod = method;
    _streamFuture = outgoing.done
        .then((s) {
          // Request sent, set up response completer.
          _nextResponseCompleter = new Completer();

          // Listen for response.
          _nextResponseCompleter.future
              .then((incoming) {
                incoming.dataDone.then((_) {
                  if (incoming.headers.persistentConnection &&
                      request.persistentConnection) {
                    // Return connection, now we are done.
                    _httpClient._returnConnection(this);
                    _subscription.resume();
                  } else {
                    destroy();
                  }
                });
                request._onIncoming(incoming);
              })
              // If we see a state error, we failed to get the 'first'
              // element.
              // Transform the error to a HttpParserException, for
              // consistency.
              .catchError((error) {
                throw new HttpParserException(
                    "Connection closed before data was received");
              }, test: (error) => error is StateError)
              .catchError((error) {
                // We are done with the socket.
                destroy();
                request._onError(error);
              });

          // Resume the parser now we have a handler.
          _subscription.resume();
          return s;
        }, onError: (e) {
          destroy();
        });
    return request;
  }

  Future<Socket> detachSocket() {
    return _streamFuture.then(
        (_) => new _DetachedSocket(_socket, _httpParser.detachIncoming()));
  }

  void destroy() {
    _httpClient._connectionClosed(this);
    _socket.destroy();
  }

  void close() {
    _httpClient._connectionClosed(this);
    _streamFuture
          // TODO(ajohnsen): Add timeout.
        .then((_) => _socket.destroy());
  }

  HttpConnectionInfo get connectionInfo => _HttpConnectionInfo.create(_socket);
}

class _ConnnectionInfo {
  _ConnnectionInfo(_HttpClientConnection this.connection, _Proxy this.proxy);
  final _HttpClientConnection connection;
  final _Proxy proxy;
}


class _HttpClient implements HttpClient {
  // TODO(ajohnsen): Use eviction timeout.
  static const int DEFAULT_EVICTION_TIMEOUT = 60000;
  bool _closing = false;

  final Map<String, Set<_HttpClientConnection>> _idleConnections
      = new Map<String, Set<_HttpClientConnection>>();
  final Set<_HttpClientConnection> _activeConnections
      = new Set<_HttpClientConnection>();
  final List<_Credentials> _credentials = [];
  final List<_ProxyCredentials> _proxyCredentials = [];
  Function _authenticate;
  Function _authenticateProxy;
  Function _findProxy = HttpClient.findProxyFromEnvironment;

  Future<HttpClientRequest> open(String method,
                                 String host,
                                 int port,
                                 String path) {
    // TODO(sgjesse): The path set here can contain both query and
    // fragment. They should be cracked and set correctly.
    return _openUrl(method, new Uri.fromComponents(
        scheme: "http", domain: host, port: port, path: path));
  }

  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return _openUrl(method, url);
  }

  Future<HttpClientRequest> get(String host,
                                int port,
                                String path) {
    return open("get", host, port, path);
  }

  Future<HttpClientRequest> getUrl(Uri url) {
    return _openUrl("get", url);
  }

  Future<HttpClientRequest> post(String host,
                                 int port,
                                 String path) {
    return open("post", host, port, path);
  }

  Future<HttpClientRequest> postUrl(Uri url) {
    return _openUrl("post", url);
  }

  void close({bool force: false}) {
    _closing = true;
    // Create flattened copy of _idleConnections, as 'destory' will manipulate
    // it.
    var idle = _idleConnections.values.fold(
        [],
        (l, e) {
          l.addAll(e);
          return l;
        });
    idle.forEach((e) {
      e.close();
    });
    assert(_idleConnections.isEmpty);
    if (force) {
      for (var connection in _activeConnections.toList()) {
        connection.destroy();
      }
      assert(_activeConnections.isEmpty);
      _activeConnections.clear();
    }
  }

  set authenticate(Future<bool> f(Uri url, String scheme, String realm)) {
    _authenticate = f;
  }

  void addCredentials(Uri url, String realm, HttpClientCredentials cr) {
    _credentials.add(new _Credentials(url, realm, cr));
  }

  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm)) {
    _authenticateProxy = f;
  }

  void addProxyCredentials(String host,
                           int port,
                           String realm,
                           HttpClientCredentials cr) {
    _proxyCredentials.add(new _ProxyCredentials(host, port, realm, cr));
  }

  set findProxy(String f(Uri uri)) => _findProxy = f;

  Future<HttpClientRequest> _openUrl(String method, Uri uri) {
    if (method == null) {
      throw new ArgumentError(method);
    }
    if (uri.domain.isEmpty || (uri.scheme != "http" && uri.scheme != "https")) {
      throw new ArgumentError("Unsupported scheme '${uri.scheme}' in $uri");
    }

    bool isSecure = (uri.scheme == "https");
    int port = uri.port;
    if (port == 0) {
      port = isSecure ?
          HttpClient.DEFAULT_HTTPS_PORT :
          HttpClient.DEFAULT_HTTP_PORT;
    }
    // Check to see if a proxy server should be used for this connection.
    var proxyConf = const _ProxyConfiguration.direct();
    if (_findProxy != null) {
      // TODO(sgjesse): Keep a map of these as normally only a few
      // configuration strings will be used.
      try {
        proxyConf = new _ProxyConfiguration(_findProxy(uri));
      } catch (error, stackTrace) {
        return new Future.error(error, stackTrace);
      }
    }
    return _getConnection(uri.domain, port, proxyConf, isSecure)
        .then((info) {
          return info.connection.send(uri,
                                      port,
                                      method.toUpperCase(),
                                      info.proxy);
        });
  }

  Future<HttpClientRequest> _openUrlFromRequest(String method,
                                                Uri uri,
                                                _HttpClientRequest previous) {
    return openUrl(method, uri).then((_HttpClientRequest request) {
          // Only follow redirects if initial request did.
          request.followRedirects = previous.followRedirects;
          // Allow same number of redirects.
          request.maxRedirects = previous.maxRedirects;
          // Copy headers.
          for (var header in previous.headers._headers.keys) {
            if (request.headers[header] == null) {
              request.headers.set(header, previous.headers[header]);
            }
          }
          request.headers.chunkedTransferEncoding = false;
          request.contentLength = 0;
          return request;
        });
  }

  // Return a live connection to the idle pool.
  void _returnConnection(_HttpClientConnection connection) {
    _activeConnections.remove(connection);
    if (_closing) {
      connection.close();
      return;
    }
    // TODO(ajohnsen): Listen for socket close events.
    if (!_idleConnections.containsKey(connection.key)) {
      _idleConnections[connection.key] = new LinkedHashSet();
    }
    _idleConnections[connection.key].add(connection);
  }

  // Remove a closed connnection from the active set.
  void _connectionClosed(_HttpClientConnection connection) {
    _activeConnections.remove(connection);
    if (_idleConnections.containsKey(connection.key)) {
      _idleConnections[connection.key].remove(connection);
      if (_idleConnections[connection.key].isEmpty) {
        _idleConnections.remove(connection.key);
      }
    }
  }

  // Get a new _HttpClientConnection, either from the idle pool or created from
  // a new Socket.
  Future<_ConnnectionInfo> _getConnection(String uriHost,
                                          int uriPort,
                                          _ProxyConfiguration proxyConf,
                                          bool isSecure) {
    Iterator<_Proxy> proxies = proxyConf.proxies.iterator;

    Future<_ConnnectionInfo> connect(error) {
      if (!proxies.moveNext()) return new Future.error(error);
      _Proxy proxy = proxies.current;
      String host = proxy.isDirect ? uriHost: proxy.host;
      int port = proxy.isDirect ? uriPort: proxy.port;
      String key = isSecure ? "ssh:$host:$port" : "$host:$port";
      if (_idleConnections.containsKey(key)) {
        var connection = _idleConnections[key].first;
        _idleConnections[key].remove(connection);
        if (_idleConnections[key].isEmpty) {
          _idleConnections.remove(key);
        }
        _activeConnections.add(connection);
        return new Future.value(new _ConnnectionInfo(connection, proxy));
      }
      return (isSecure && proxy.isDirect
                  ? SecureSocket.connect(host,
                                         port,
                                         sendClientCertificate: true)
                  : Socket.connect(host, port))
        .then((socket) {
          socket.setOption(SocketOption.TCP_NODELAY, true);
          var connection = new _HttpClientConnection(key, socket, this);
          _activeConnections.add(connection);
          return new _ConnnectionInfo(connection, proxy);
        }, onError: (error) {
          // Continue with next proxy.
          return connect(error);
        });
    }
    return connect(new HttpException("No proxies given"));
  }

  _Credentials _findCredentials(Uri url, [_AuthenticationScheme scheme]) {
    // Look for credentials.
    _Credentials cr =
        _credentials.fold(null, (_Credentials prev, _Credentials value) {
          if (value.applies(url, scheme)) {
            if (prev == null) return value;
            return value.uri.path.length > prev.uri.path.length ? value : prev;
          } else {
            return prev;
          }
        });
    return cr;
  }

  _ProxyCredentials _findProxyCredentials(_Proxy proxy) {
    // Look for credentials.
    var it = _proxyCredentials.iterator;
    while (it.moveNext()) {
      if (it.current.applies(proxy, _AuthenticationScheme.BASIC)) {
        return it.current;
      }
    }
  }

  void _removeCredentials(_Credentials cr) {
    int index = _credentials.indexOf(cr);
    if (index != -1) {
      _credentials.removeAt(index);
    }
  }

  static String _findProxyFromEnvironment(Uri url,
                                          Map<String, String> environment) {
    checkNoProxy(String option) {
      if (option == null) return null;
      Iterator<String> names = option.split(",").map((s) => s.trim()).iterator;
      while (names.moveNext()) {
        if (url.domain.endsWith(names.current)) {
          return "DIRECT";
        }
      }
      return null;
    }

    checkProxy(String option) {
      if (option == null) return null;
      int pos = option.indexOf("://");
      if (pos >= 0) {
        option = option.substring(pos + 3);
      }
      if (option.indexOf(":") == -1) option = "$option:1080";
      return "PROXY $option";
    }

    // Default to using the process current environment.
    if (environment == null) environment = Platform.environment;

    String proxyCfg;

    String noProxy = environment["no_proxy"];
    if (noProxy == null) noProxy = environment["NO_PROXY"];
    if ((proxyCfg = checkNoProxy(noProxy)) != null) {
      return proxyCfg;
    }

    if (url.scheme == "http") {
      String proxy = environment["http_proxy"];
      if (proxy == null) proxy = environment["HTTP_PROXY"];
      if ((proxyCfg = checkProxy(proxy)) != null) {
        return proxyCfg;
      }
    } else if (url.scheme == "https") {
      String proxy = environment["https_proxy"];
      if (proxy == null) proxy = environment["HTTPS_PROXY"];
      if ((proxyCfg = checkProxy(proxy)) != null) {
        return proxyCfg;
      }
    }
    return "DIRECT";
  }
}


class _HttpConnection {
  static const _ACTIVE = 0;
  static const _IDLE = 1;
  static const _CLOSING = 2;
  static const _DETACHED = 3;

  int _state = _IDLE;

  final Socket _socket;
  final _HttpServer _httpServer;
  final _HttpParser _httpParser;
  StreamSubscription _subscription;

  Future _streamFuture;

  _HttpConnection(Socket this._socket, _HttpServer this._httpServer)
      : _httpParser = new _HttpParser.requestParser() {
    _socket.pipe(_httpParser);
    _subscription = _httpParser.listen(
        (incoming) {
          // Only handle one incoming request at the time. Keep the
          // stream paused until the request has been send.
          _subscription.pause();
          _state = _ACTIVE;
          var outgoing = new _HttpOutgoing(_socket);
          var response = new _HttpResponse(incoming.headers.protocolVersion,
                                           outgoing);
          var request = new _HttpRequest(response, incoming, _httpServer, this);
          _streamFuture = outgoing.done
              .then((_) {
                if (_state == _DETACHED) return;
                if (response.persistentConnection &&
                    request.persistentConnection &&
                    incoming.fullBodyRead) {
                  _state = _IDLE;
                  // Resume the subscription for incoming requests as the
                  // request is now processed.
                  _subscription.resume();
                } else {
                  // Close socket, keep-alive not used or body sent before
                  // received data was handled.
                  destroy();
                }
              })
              .catchError((e) {
                destroy();
              });
          response._ignoreBody = request.method == "HEAD";
          response._httpRequest = request;
          _httpServer._handleRequest(request);
        },
        onDone: () {
          destroy();
        },
        onError: (error) {
          _httpServer._handleError(error);
          destroy();
        });
  }

  void destroy() {
    if (_state == _CLOSING || _state == _DETACHED) return;
    _state = _CLOSING;
    _socket.destroy();
    _httpServer._connectionClosed(this);
  }

  Future<Socket> detachSocket() {
    _state = _DETACHED;
    // Remove connection from server.
    _httpServer._connectionClosed(this);

    _HttpDetachedIncoming detachedIncoming = _httpParser.detachIncoming();

    return _streamFuture.then((_) {
      return new _DetachedSocket(_socket, detachedIncoming);
    });
  }

  HttpConnectionInfo get connectionInfo => _HttpConnectionInfo.create(_socket);

  bool get _isActive => _state == _ACTIVE;
  bool get _isIdle => _state == _IDLE;
  bool get _isClosing => _state == _CLOSING;
  bool get _isDetached => _state == _DETACHED;
}


// HTTP server waiting for socket connections.
class _HttpServer extends Stream<HttpRequest> implements HttpServer {

  static Future<HttpServer> bind(String host, int port, int backlog) {
    return ServerSocket.bind(host, port, backlog).then((socket) {
      return new _HttpServer._(socket, true);
    });
  }

  static Future<HttpServer> bindSecure(String host,
                                       int port,
                                       int backlog,
                                       String certificate_name,
                                       bool requestClientCertificate) {
    return SecureServerSocket.bind(
        host,
        port,
        backlog,
        certificate_name,
        requestClientCertificate: requestClientCertificate)
        .then((socket) {
          return new _HttpServer._(socket, true);
        });
  }

  _HttpServer._(this._serverSocket, this._closeServer);

  _HttpServer.listenOn(ServerSocket this._serverSocket)
      : _closeServer = false;

  StreamSubscription<HttpRequest> listen(void onData(HttpRequest event),
                                         {void onError(error),
                                         void onDone(),
                                         bool cancelOnError}) {
    _serverSocket.listen(
        (Socket socket) {
          socket.setOption(SocketOption.TCP_NODELAY, true);
          // Accept the client connection.
          _HttpConnection connection = new _HttpConnection(socket, this);
          _connections.add(connection);
        },
        onError: _controller.addError,
        onDone: _controller.close);
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  void close() {
    closed = true;
    if (_serverSocket != null && _closeServer) {
      _serverSocket.close();
    }
    if (_sessionManagerInstance != null) {
      _sessionManagerInstance.close();
      _sessionManagerInstance = null;
    }
    for (_HttpConnection connection in _connections.toList()) {
      connection.destroy();
    }
    _connections.clear();
  }

  int get port {
    if (closed) throw new HttpException("HttpServer is not bound to a socket");
    return _serverSocket.port;
  }

  set sessionTimeout(int timeout) {
    _sessionManager.sessionTimeout = timeout;
  }

  void _handleRequest(HttpRequest request) {
    _controller.add(request);
  }

  void _handleError(error) {
    if (!closed) _controller.addError(error);
  }

  void _connectionClosed(_HttpConnection connection) {
    _connections.remove(connection);
  }

  _HttpSessionManager get _sessionManager {
    // Lazy init.
    if (_sessionManagerInstance == null) {
      _sessionManagerInstance = new _HttpSessionManager();
    }
    return _sessionManagerInstance;
  }

  HttpConnectionsInfo connectionsInfo() {
    HttpConnectionsInfo result = new HttpConnectionsInfo();
    result.total = _connections.length;
    _connections.forEach((_HttpConnection conn) {
      if (conn._isActive) {
        result.active++;
      } else if (conn._isIdle) {
        result.idle++;
      } else {
        assert(conn._isClosing);
        result.closing++;
      }
    });
    return result;
  }

  _HttpSessionManager _sessionManagerInstance;

  // Indicated if the http server has been closed.
  bool closed = false;

  // The server listen socket.
  final ServerSocket _serverSocket;
  final bool _closeServer;

  // Set of currently connected clients.
  final Set<_HttpConnection> _connections = new Set<_HttpConnection>();
  final StreamController<HttpRequest> _controller
      = new StreamController<HttpRequest>();

  // TODO(ajohnsen): Use close queue?
}


class _ProxyConfiguration {
  static const String PROXY_PREFIX = "PROXY ";
  static const String DIRECT_PREFIX = "DIRECT";

  _ProxyConfiguration(String configuration) : proxies = new List<_Proxy>() {
    if (configuration == null) {
      throw new HttpException("Invalid proxy configuration $configuration");
    }
    List<String> list = configuration.split(";");
    list.forEach((String proxy) {
      proxy = proxy.trim();
      if (!proxy.isEmpty) {
        if (proxy.startsWith(PROXY_PREFIX)) {
          String username;
          String password;
          // Skip the "PROXY " prefix.
          proxy = proxy.substring(PROXY_PREFIX.length).trim();
          // Look for proxy authentication.
          int at = proxy.indexOf("@");
          if (at != -1) {
            String userinfo = proxy.substring(0, at).trim();
            proxy = proxy.substring(at + 1).trim();
            int colon = userinfo.indexOf(":");
            if (colon == -1 || colon == 0 || colon == proxy.length - 1) {
              throw new HttpException(
                  "Invalid proxy configuration $configuration");
            }
            username = userinfo.substring(0, colon).trim();
            password = userinfo.substring(colon + 1).trim();
          }
          // Look for proxy host and port.
          int colon = proxy.indexOf(":");
          if (colon == -1 || colon == 0 || colon == proxy.length - 1) {
            throw new HttpException(
                "Invalid proxy configuration $configuration");
          }
          String host = proxy.substring(0, colon).trim();
          String portString = proxy.substring(colon + 1).trim();
          int port;
          try {
            port = int.parse(portString);
          } on FormatException catch (e) {
            throw new HttpException(
                "Invalid proxy configuration $configuration, "
                "invalid port '$portString'");
          }
          proxies.add(new _Proxy(host, port, username, password));
        } else if (proxy.trim() == DIRECT_PREFIX) {
          proxies.add(new _Proxy.direct());
        } else {
          throw new HttpException("Invalid proxy configuration $configuration");
        }
      }
    });
  }

  const _ProxyConfiguration.direct()
      : proxies = const [const _Proxy.direct()];

  final List<_Proxy> proxies;
}


class _Proxy {
  const _Proxy(
      this.host, this.port, this.username, this.password) : isDirect = false;
  const _Proxy.direct() : host = null, port = null,
                          username = null, password = null, isDirect = true;

  bool get isAuthenticated => username != null;

  final String host;
  final int port;
  final String username;
  final String password;
  final bool isDirect;
}


class _HttpConnectionInfo implements HttpConnectionInfo {
  static _HttpConnectionInfo create(Socket socket) {
    if (socket == null) return null;
    try {
      _HttpConnectionInfo info = new _HttpConnectionInfo._();
      info.remoteHost = socket.remoteHost;
      info.remotePort = socket.remotePort;
      info.localPort = socket.port;
      return info;
    } catch (e) { }
    return null;
  }

  _HttpConnectionInfo._();

  String remoteHost;
  int remotePort;
  int localPort;
}


class _DetachedSocket extends Stream<List<int>> implements Socket {
  final Stream<List<int>> _incoming;
  final Socket _socket;

  _DetachedSocket(this._socket, this._incoming);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {void onError(error),
                                        void onDone(),
                                        bool cancelOnError}) {
    return _incoming.listen(onData,
                            onError: onError,
                            onDone: onDone,
                            cancelOnError: cancelOnError);
  }

  Encoding get encoding => _socket.encoding;

  void set encoding(Encoding value) {
    _socket.encoding = value;
  }

  void write(Object obj) => _socket.write(obj);

  void writeln([Object obj = ""]) => _socket.writeln(obj);

  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);

  void writeAll(Iterable objects, [String separator = ""]) {
    _socket.writeAll(objects, separator);
  }

  void add(List<int> bytes) => _socket.add(bytes);

  void addError(error) => _socket.addError(error);

  Future<Socket> addStream(Stream<List<int>> stream) {
    return _socket.addStream(stream);
  }

  void destroy() => _socket.destroy();

  Future close() => _socket.close();

  Future<Socket> get done => _socket.done;

  int get port => _socket.port;

  String get remoteHost => _socket.remoteHost;

  int get remotePort => _socket.remotePort;

  bool setOption(SocketOption option, bool enabled) {
    return _socket.setOption(option, enabled);
  }
}


class _AuthenticationScheme {
  static const UNKNOWN = const _AuthenticationScheme(-1);
  static const BASIC = const _AuthenticationScheme(0);
  static const DIGEST = const _AuthenticationScheme(1);

  const _AuthenticationScheme(this._scheme);

  factory _AuthenticationScheme.fromString(String scheme) {
    if (scheme.toLowerCase() == "basic") return BASIC;
    if (scheme.toLowerCase() == "digest") return DIGEST;
    return UNKNOWN;
  }

  String toString() {
    if (this == BASIC) return "Basic";
    if (this == DIGEST) return "Digest";
    return "Unknown";
  }

  final int _scheme;
}


class _Credentials {
  _Credentials(this.uri, this.realm, this.credentials);

  _AuthenticationScheme get scheme => credentials.scheme;

  bool applies(Uri uri, _AuthenticationScheme scheme) {
    if (scheme != null && credentials.scheme != scheme) return false;
    if (uri.domain != this.uri.domain) return false;
    int thisPort =
        this.uri.port == 0 ? HttpClient.DEFAULT_HTTP_PORT : this.uri.port;
    int otherPort = uri.port == 0 ? HttpClient.DEFAULT_HTTP_PORT : uri.port;
    if (otherPort != thisPort) return false;
    return uri.path.startsWith(this.uri.path);
  }

  void authorize(HttpClientRequest request) {
    credentials.authorize(this, request);
    used = true;
  }

  bool used = false;
  Uri uri;
  String realm;
  _HttpClientCredentials credentials;

  // Digest specific fields.
  String nonce;
  String algorithm;
  String qop;
}


class _ProxyCredentials {
  _ProxyCredentials(this.host, this.port, this.realm, this.credentials);

  _AuthenticationScheme get scheme => credentials.scheme;

  bool applies(_Proxy proxy, _AuthenticationScheme scheme) {
    return proxy.host == host && proxy.port == port;
  }

  void authorize(HttpClientRequest request) {
    credentials.authorizeProxy(this, request);
  }

  String host;
  int port;
  String realm;
  _HttpClientCredentials credentials;
}


abstract class _HttpClientCredentials implements HttpClientCredentials {
  _AuthenticationScheme get scheme;
  void authorize(_Credentials credentials, HttpClientRequest request);
  void authorizeProxy(_ProxyCredentials credentials, HttpClientRequest request);
}


class _HttpClientBasicCredentials
    extends _HttpClientCredentials
    implements HttpClientBasicCredentials {
  _HttpClientBasicCredentials(this.username,
                              this.password);

  _AuthenticationScheme get scheme => _AuthenticationScheme.BASIC;

  String authorization() {
    // There is no mentioning of username/password encoding in RFC
    // 2617. However there is an open draft for adding an additional
    // accept-charset parameter to the WWW-Authenticate and
    // Proxy-Authenticate headers, see
    // http://tools.ietf.org/html/draft-reschke-basicauth-enc-06. For
    // now always use UTF-8 encoding.
    String auth =
        CryptoUtils.bytesToBase64(_encodeString("$username:$password"));
    return "Basic $auth";
  }

  void authorize(_Credentials _, HttpClientRequest request) {
    request.headers.set(HttpHeaders.AUTHORIZATION, authorization());
  }

  void authorizeProxy(_ProxyCredentials _, HttpClientRequest request) {
    request.headers.set(HttpHeaders.PROXY_AUTHORIZATION, authorization());
  }

  String username;
  String password;
}


class _HttpClientDigestCredentials
    extends _HttpClientCredentials
    implements HttpClientDigestCredentials {
  _HttpClientDigestCredentials(this.username,
                               this.password);

  _AuthenticationScheme get scheme => _AuthenticationScheme.DIGEST;

  void authorize(_Credentials credentials, HttpClientRequest request) {
    // TODO(sgjesse): Implement!!!
    throw new UnsupportedError("Digest authentication not yet supported");
  }

  void authorizeProxy(_ProxyCredentials credentials,
                      HttpClientRequest request) {
    // TODO(sgjesse): Implement!!!
    throw new UnsupportedError("Digest authentication not yet supported");
  }

  String username;
  String password;
}


class _RedirectInfo implements RedirectInfo {
  const _RedirectInfo(int this.statusCode,
                      String this.method,
                      Uri this.location);
  final int statusCode;
  final String method;
  final Uri location;
}
