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

  bool hasSubscriber = false;

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
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    hasSubscriber = true;
    return _stream
        .handleError((error) {
          throw new HttpException(error.message, uri: uri);
        })
        .listen(onData,
                onError: onError,
                onDone: onDone,
                cancelOnError: cancelOnError);
  }

  // Is completed once all data have been received.
  Future get dataDone => _dataCompleter.future;

  void close(bool closing) {
    fullBodyRead = true;
    hasSubscriber = true;
    _dataCompleter.complete(closing);
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
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    return _incoming.listen(onData,
                            onError: onError,
                            onDone: onDone,
                            cancelOnError: cancelOnError);
  }

  Uri get uri => _incoming.uri;

  String get method => _incoming.method;

  HttpSession get session {
    if (_session != null) {
      if (_session._destroyed) {
        // It's destroyed, clear it.
        _session = null;
        // Create new session object by calling recursive.
        return session;
      }
      // It's already mapped, use it.
      return _session;
    }
    // Create session, store it in connection, and return.
    return _session = _httpServer._sessionManager.createSession();
  }

  HttpConnectionInfo get connectionInfo => _httpConnection.connectionInfo;

  X509Certificate get certificate {
    var socket = _httpConnection._socket;
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
      : super(_incoming) {
    // Set uri for potential exceptions.
    _incoming.uri = _httpRequest.uri;
  }

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
              new RedirectException("Redirect loop detected", redirects));
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
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    var stream = _incoming;
    if (headers.value(HttpHeaders.CONTENT_ENCODING) == "gzip") {
      stream = stream.transform(GZIP.decoder);
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

  Future<HttpClientResponse> _authenticate(bool proxyAuth) {
    Future<HttpClientResponse> retry() {
      // Drain body and retry.
      return drain().then((_) {
          return _httpClient._openUrlFromRequest(_httpRequest.method,
                                                 _httpRequest.uri,
                                                 _httpRequest)
              .then((request) => request.close());
          });
    }

    List<String> authChallenge() {
      if (proxyAuth) {
        return headers[HttpHeaders.PROXY_AUTHENTICATE];
      } else {
        return headers[HttpHeaders.WWW_AUTHENTICATE];
      }
    }

    _Credentials findCredentials(_AuthenticationScheme scheme) {
      if (proxyAuth) {
        return  _httpClient._findProxyCredentials(_httpRequest._proxy, scheme);
      } else {
        return _httpClient._findCredentials(_httpRequest.uri, scheme);
      }
    }

    void removeCredentials(_Credentials cr) {
      if (proxyAuth) {
        _httpClient._removeProxyCredentials(cr);
      } else {
        _httpClient._removeCredentials(cr);
      }
    }

    Future requestAuthentication(_AuthenticationScheme scheme, String realm) {
      if (proxyAuth) {
        if (_httpClient._authenticateProxy == null) {
          return new Future.value(false);
        }
        var proxy = _httpRequest._proxy;
        return _httpClient._authenticateProxy(proxy.host,
                                              proxy.port,
                                              scheme.toString(),
                                              realm);
      } else {
        if (_httpClient._authenticate == null) {
          return new Future.value(false);
        }
        return _httpClient._authenticate(_httpRequest.uri,
                                         scheme.toString(),
                                         realm);
      }
    }

    List<String> challenge = authChallenge();
    assert(challenge != null || challenge.length == 1);
    _HeaderValue header =
        _HeaderValue.parse(challenge[0], parameterSeparator: ",");
    _AuthenticationScheme scheme =
        new _AuthenticationScheme.fromString(header.value);
    String realm = header.parameters["realm"];

    // See if any matching credentials are available.
    _Credentials cr = findCredentials(scheme);
    if (cr != null) {
      // For basic authentication don't retry already used credentials
      // as they must have already been added to the request causing
      // this authenticate response.
      if (cr.scheme == _AuthenticationScheme.BASIC && !cr.used) {
        // Credentials where found, prepare for retrying the request.
        return retry();
      }

      // Digest authentication only supports the MD5 algorithm.
      if (cr.scheme == _AuthenticationScheme.DIGEST &&
          (header.parameters["algorithm"] == null ||
           header.parameters["algorithm"].toLowerCase() == "md5")) {
        if (cr.nonce == null || cr.nonce == header.parameters["nonce"]) {
          // If the nonce is not set then this is the first authenticate
          // response for these credentials. Set up authentication state.
          if (cr.nonce == null) {
            cr.nonce = header.parameters["nonce"];
            cr.algorithm = "MD5";
            cr.qop = header.parameters["qop"];
            cr.nonceCount = 0;
          }
          // Credentials where found, prepare for retrying the request.
          return retry();
        } else if (header.parameters["stale"] != null &&
                   header.parameters["stale"].toLowerCase() == "true") {
          // If stale is true retry with new nonce.
          cr.nonce = header.parameters["nonce"];
          // Credentials where found, prepare for retrying the request.
          return retry();
        }
      }
    }

    // Ask for more credentials if none found or the one found has
    // already been used. If it has already been used it must now be
    // invalid and is removed.
    if (cr != null) {
      removeCredentials(cr);
      cr = null;
    }
    return requestAuthentication(scheme, realm).then((credsAvailable) {
      if (credsAvailable) {
        cr = _httpClient._findCredentials(_httpRequest.uri, scheme);
        return retry();
      } else {
        // No credentials available, complete with original response.
        return this;
      }
    });
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
  final Uri _uri;

  final _HttpHeaders headers;

  _HttpOutboundMessage(Uri this._uri,
                       String protocolVersion,
                       _HttpOutgoing outgoing)
      : _outgoing = outgoing,
        _headersSink = new IOSink(outgoing, encoding: ASCII),
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
    return Encoding.getByName(charset);
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

  void addError(error, [StackTrace stackTrace]) {
    _dataSink.addError(error, stackTrace);
  }

  Future<T> addStream(Stream<List<int>> stream) {
    return _dataSink.addStream(stream);
  }

  Future flush() {
    return _dataSink.flush();
  }

  Future close() {
    return _dataSink.close();
  }

  Future<T> get done => _dataSink.done;

  Future _writeHeaders({bool drainRequest: true}) {
    if (_headersWritten) return new Future.value();
    _headersWritten = true;
    headers._synchronize();  // Be sure the 'chunked' option is updated.
    _dataSink.encoding = encoding;
    bool isServerSide = this is _HttpResponse;
    if (isServerSide) {
      var response = this;
      if (headers.chunkedTransferEncoding) {
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
      if (drainRequest && !response._httpRequest._incoming.hasSubscriber) {
        return response._httpRequest.drain()
            // TODO(ajohnsen): Timeout on drain?
            .catchError((_) {})  // Ignore errors.
            .then((_) => _writeHeader());
      }
    }
    return new Future.sync(_writeHeader);
  }

  Future _addStream(Stream<List<int>> stream) {
    return _writeHeaders()
        .then((_) {
          int contentLength = headers.contentLength;
          if (_ignoreBody) {
            stream.drain().catchError((_) {});
            return _headersSink.close();
          }
          stream = stream.transform(const _BufferTransformer());
          if (headers.chunkedTransferEncoding) {
            if (_asGZip) {
              stream = stream.transform(GZIP.encoder);
            }
            stream = stream.transform(const _ChunkedTransformer());
          } else if (contentLength >= 0) {
            stream = stream.transform(
                new _ContentLengthValidator(contentLength, _uri));
          }
          return _headersSink.addStream(stream);
        });
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
        _headersSink.addError(new HttpException(
            "No content while contentLength was specified to be greater "
            "than 0: ${headers.contentLength}.",
            uri: _uri));
        return _headersSink.done;
      }
    }
    return _writeHeaders().then((_) => _headersSink.close());
  }

  void _writeHeader();  // TODO(ajohnsen): Better name.
}


class _HttpOutboundConsumer implements StreamConsumer {
  final _HttpOutboundMessage _outbound;
  StreamController _controller;
  StreamSubscription _subscription;
  Completer _closeCompleter = new Completer();
  Completer _completer;
  bool _socketError = false;

  _HttpOutboundConsumer(_HttpOutboundMessage this._outbound);

  void _cancel() {
    if (_subscription != null) {
      StreamSubscription subscription = _subscription;
      _subscription = null;
      subscription.cancel();
    }
  }

  bool _ignoreError(error)
    => error is SocketException && _outbound is HttpResponse;

  _ensureController() {
    if (_controller != null) return;
    _controller = new StreamController(sync: true,
                                       onPause: () => _subscription.pause(),
                                       onResume: () => _subscription.resume(),
                                       onListen: () => _subscription.resume(),
                                       onCancel: _cancel);
    _outbound._addStream(_controller.stream)
        .then((_) {
                _cancel();
                _done();
                _closeCompleter.complete(_outbound);
              },
              onError: (error, [StackTrace stackTrace]) {
                _socketError = true;
                if (_ignoreError(error)) {
                  _cancel();
                  _done();
                  _closeCompleter.complete(_outbound);
                } else {
                  if (!_done(error)) {
                    _closeCompleter.completeError(error, stackTrace);
                  }
                }
              });
  }

  bool _done([error, StackTrace stackTrace]) {
    if (_completer == null) return false;
    if (error != null) {
      _completer.completeError(error, stackTrace);
    } else {
      _completer.complete(_outbound);
    }
    _completer = null;
    return true;
  }

  Future addStream(var stream) {
    // If we saw a socket error subscribe and then cancel, to ignore any data
    // on the stream.
    if (_socketError) {
      stream.listen(null).cancel();
      return new Future.value(_outbound);
    }
    _completer = new Completer();
    _subscription = stream.listen(
        (data) => _controller.add(data),
        onDone: _done,
        onError: (e, s) => _controller.addError(e, s),
        cancelOnError: true);
    // Pause the first request.
    if (_controller == null) _subscription.pause();
    _ensureController();
    return _completer.future;
  }

  Future close() {
    Future closeOutbound() {
      if (_socketError) return new Future.value(_outbound);
      return _outbound._close()
          .catchError((_) {}, test: _ignoreError)
          .then((_) => _outbound);
    }
    if (_controller == null) return closeOutbound();
    _controller.close();
    return _closeCompleter.future.then((_) => closeOutbound());
  }
}


class _BufferTransformerSink implements EventSink<List<int>> {
  static const int MIN_CHUNK_SIZE = 4 * 1024;
  static const int MAX_BUFFER_SIZE = 16 * 1024;

  final BytesBuilder _builder = new BytesBuilder();
  final EventSink<List<int>> _outSink;

  _BufferTransformerSink(this._outSink);

  void add(List<int> data) {
    // TODO(ajohnsen): Use timeout?
    if (data.length == 0) return;
    if (data.length >= MIN_CHUNK_SIZE) {
      flush();
      _outSink.add(data);
    } else {
      _builder.add(data);
      if (_builder.length >= MAX_BUFFER_SIZE) {
        flush();
      }
    }
  }

  void addError(Object error, [StackTrace stackTrace]) {
    _outSink.addError(error, stackTrace);
  }

  void close() {
    flush();
    _outSink.close();
  }

  void flush() {
    if (_builder.length > 0) {
      // takeBytes will clear the BytesBuilder.
      _outSink.add(_builder.takeBytes());
    }
  }
}

class _BufferTransformer implements StreamTransformer<List<int>, List<int>> {
  const _BufferTransformer();

  Stream<List<int>> bind(Stream<List<int>> stream) {
    return new Stream<List<int>>.eventTransformed(
        stream,
        (EventSink outSink) => new _BufferTransformerSink(outSink));
  }
}


class _HttpResponse extends _HttpOutboundMessage<HttpResponse>
    implements HttpResponse {
  int _statusCode = 200;
  String _reasonPhrase;
  List<Cookie> _cookies;
  _HttpRequest _httpRequest;
  Duration _deadline;
  Timer _deadlineTimer;

  _HttpResponse(Uri uri,
                String protocolVersion,
                _HttpOutgoing outgoing,
                String serverHeader)
      : super(uri, protocolVersion, outgoing) {
    if (serverHeader != null) headers.set('Server', serverHeader);
  }

  List<Cookie> get cookies {
    if (_cookies == null) _cookies = new List<Cookie>();
    return _cookies;
  }

  int get statusCode => _statusCode;
  void set statusCode(int statusCode) {
    if (_headersWritten) throw new StateError("Header already sent");
    _statusCode = statusCode;
  }

  String get reasonPhrase => _findReasonPhrase(statusCode);
  void set reasonPhrase(String reasonPhrase) {
    if (_headersWritten) throw new StateError("Header already sent");
    _reasonPhrase = reasonPhrase;
  }

  Future redirect(Uri location, {int status: HttpStatus.MOVED_TEMPORARILY}) {
    if (_headersWritten) throw new StateError("Header already sent");
    statusCode = status;
    headers.set("Location", location.toString());
    return close();
  }

  Future<Socket> detachSocket() {
    if (_headersWritten) throw new StateError("Headers already sent");
    deadline = null;  // Be sure to stop any deadline.
    var future = _httpRequest._httpConnection.detachSocket();
    _writeHeaders(drainRequest: false).then((_) => close());
    // Close connection so the socket is 'free'.
    close();
    done.catchError((_) {
      // Catch any error on done, as they automatically will be
      // propagated to the websocket.
    });
    return future;
  }

  HttpConnectionInfo get connectionInfo => _httpRequest.connectionInfo;

  Duration get deadline => _deadline;

  void set deadline(Duration d) {
    if (_deadlineTimer != null) _deadlineTimer.cancel();
    _deadline = d;

    if (_deadline == null) return;
    _deadlineTimer = new Timer(_deadline, () {
      _outgoing.socket.destroy();
    });
  }

  void _writeHeader() {
    var builder = new BytesBuilder();
    writeSP() => builder.add(const [_CharCode.SP]);
    writeCRLF() => builder.add(const [_CharCode.CR, _CharCode.LF]);

    // Write status line.
    if (headers.protocolVersion == "1.1") {
      builder.add(_Const.HTTP11);
    } else {
      builder.add(_Const.HTTP10);
    }
    writeSP();
    builder.add(statusCode.toString().codeUnits);
    writeSP();
    builder.add(reasonPhrase.codeUnits);
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
    headers._write(builder);
    writeCRLF();
    _headersSink.add(builder.takeBytes());
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
                     Uri uri,
                     String this.method,
                     _Proxy this._proxy,
                     _HttpClient this._httpClient,
                     _HttpClientConnection this._httpClientConnection)
      : super(uri, "1.1", outgoing),
        uri = uri {
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
        future = response.drain()
          .then((_) => response.redirect());
      } else {
        // End with exception, too many redirects.
        future = response.drain()
            .then((_) => new Future.error(
                new RedirectException("Redirect limit exceeded",
                                      response.redirects)));
      }
    } else if (response._shouldAuthenticateProxy) {
      future = response._authenticate(true);
    } else if (response._shouldAuthenticate) {
      future = response._authenticate(false);
    } else {
      future = new Future<HttpClientResponse>.value(response);
    }
    future.then(
        (v) => _responseCompleter.complete(v),
        onError: _responseCompleter.completeError);
  }

  void _onError(error, StackTrace stackTrace) {
    _responseCompleter.completeError(error, stackTrace);
  }

  // Generate the request URI based on the method and proxy.
  String _requestUri() {
    // Generate the request URI starting from the path component.
    String uriStartingFromPath() {
      String result = uri.path;
      if (result.length == 0) result = "/";
      if (uri.query != "") {
        if (uri.fragment != "") {
          result = "${result}?${uri.query}#${uri.fragment}";
        } else {
          result = "${result}?${uri.query}";
        }
      }
      return result;
    }

    if (_proxy.isDirect) {
      return uriStartingFromPath();
    } else {
      if (method == "CONNECT") {
        // For the connect method the request URI is the host:port of
        // the requested destination of the tunnel (see RFC 2817
        // section 5.2)
        return "${uri.host}:${uri.port}";
      } else {
        if (_httpClientConnection._proxyTunnel) {
          return uriStartingFromPath();
        } else {
          return uri.toString();
        }
      }
    }
  }

  void _writeHeader() {
    var builder = new BytesBuilder();

    writeSP() => builder.add(const [_CharCode.SP]);

    writeCRLF() => builder.add(const [_CharCode.CR, _CharCode.LF]);

    // Write the request method.
    builder.add(method.codeUnits);
    writeSP();
    // Write the request URI.
    builder.add(_requestUri().codeUnits);
    writeSP();
    // Write HTTP/1.1.
    builder.add(_Const.HTTP11);
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
    headers._write(builder);
    writeCRLF();
    _headersSink.add(builder.takeBytes());
  }
}


class _ChunkedTransformerSink implements EventSink<List<int>> {

  int _pendingFooter = 0;
  final EventSink<List<int>> _outSink;

  _ChunkedTransformerSink(this._outSink);

  void add(List<int> data) {
    _outSink.add(_chunkHeader(data.length));
    if (data.length > 0) _outSink.add(data);
    _pendingFooter = 2;
  }

  void addError(Object error, [StackTrace stackTrace]) {
    _outSink.addError(error, stackTrace);
  }

  void close() {
    add(const []);
    _outSink.close();
  }

  List<int> _chunkHeader(int length) {
    const hexDigits = const [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
                             0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46];
    if (length == 0) {
      if (_pendingFooter == 2) return _footerAndChunk0Length;
      return _chunk0Length;
    }
    int size = _pendingFooter;
    int len = length;
    // Compute a fast integer version of (log(length + 1) / log(16)).ceil().
    while (len > 0) {
      size++;
      len >>= 4;
    }
    var footerAndHeader = new Uint8List(size + 2);
    if (_pendingFooter == 2) {
      footerAndHeader[0] = _CharCode.CR;
      footerAndHeader[1] = _CharCode.LF;
    }
    int index = size;
    while (index > _pendingFooter) {
      footerAndHeader[--index] = hexDigits[length & 15];
      length = length >> 4;
    }
    footerAndHeader[size + 0] = _CharCode.CR;
    footerAndHeader[size + 1] = _CharCode.LF;
    return footerAndHeader;
  }

  static List<int> get _footerAndChunk0Length => new Uint8List.fromList(
      const [_CharCode.CR, _CharCode.LF, 0x30, _CharCode.CR, _CharCode.LF,
             _CharCode.CR, _CharCode.LF]);

  static List<int> get _chunk0Length => new Uint8List.fromList(
      const [0x30, _CharCode.CR, _CharCode.LF, _CharCode.CR, _CharCode.LF]);
}

// Transformer that transforms data to HTTP Chunked Encoding.
class _ChunkedTransformer implements StreamTransformer<List<int>, List<int>> {
  const _ChunkedTransformer();

  Stream<List<int>> bind(Stream<List<int>> stream) {
    return new Stream<List<int>>.eventTransformed(
        stream,
        (EventSink<List<int>> sink) => new _ChunkedTransformerSink(sink));
  }
}

// Transformer that validates the content length.
class _ContentLengthValidator
    implements StreamTransformer<List<int>, List<int>>, EventSink<List<int>> {
  final int expectedContentLength;
  final Uri uri;
  int _bytesWritten = 0;

  EventSink<List<int>> _outSink;

  _ContentLengthValidator(int this.expectedContentLength, Uri this.uri);

  Stream<List<int>> bind(Stream<List<int>> stream) {
    return new Stream.eventTransformed(
        stream,
        (EventSink sink) {
          if (_outSink != null) {
            throw new StateError("Validator transformer already used");
          }
          _outSink = sink;
          return this;
        });
  }

  void add(List<int> data) {
    _bytesWritten += data.length;
    if (_bytesWritten > expectedContentLength) {
      _outSink.addError(new HttpException(
          "Content size exceeds specified contentLength. "
          "$_bytesWritten bytes written while expected "
          "$expectedContentLength. "
          "[${new String.fromCharCodes(data)}]",
          uri: uri));
      _outSink.close();
    } else {
      _outSink.add(data);
    }
  }

  void addError(Object error, [StackTrace stackTrace]) {
    _outSink.addError(error, stackTrace);
  }

  void close() {
    if (_bytesWritten < expectedContentLength) {
      _outSink.addError(new HttpException(
          "Content size below specified contentLength. "
          " $_bytesWritten bytes written while expected "
          "$expectedContentLength.",
          uri: uri));
    }
    _outSink.close();
  }
}


// Extends StreamConsumer as this is an internal type, only used to pipe to.
class _HttpOutgoing implements StreamConsumer<List<int>> {
  final Completer _doneCompleter = new Completer();
  final Socket socket;

  _HttpOutgoing(Socket this.socket);

  Future addStream(Stream<List<int>> stream) {
    return socket.addStream(stream)
        .catchError((error) {
          _doneCompleter.completeError(error);
          throw error;
        });
  }

  Future close() {
    _doneCompleter.complete(socket);
    return new Future.value();
  }

  Future get done => _doneCompleter.future;
}

class _HttpClientConnection {
  final String key;
  final Socket _socket;
  final bool _proxyTunnel;
  final _HttpParser _httpParser;
  StreamSubscription _subscription;
  final _HttpClient _httpClient;
  bool _dispose = false;
  Timer _idleTimer;
  bool closed = false;
  Uri _currentUri;

  Completer<_HttpIncoming> _nextResponseCompleter;
  Future _streamFuture;

  _HttpClientConnection(String this.key,
                        Socket this._socket,
                        _HttpClient this._httpClient,
                        [this._proxyTunnel = false])
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
          if (_nextResponseCompleter == null) {
            throw new HttpException("Unexpected response.", uri: _currentUri);
          }
          _nextResponseCompleter.complete(incoming);
          _nextResponseCompleter = null;
        },
        onError: (error, [StackTrace stackTrace]) {
          if (_nextResponseCompleter != null) {
            _nextResponseCompleter.completeError(
                new HttpException(error.message, uri: _currentUri),
                stackTrace);
            _nextResponseCompleter = null;
          }
        },
        onDone: () {
          if (_nextResponseCompleter != null) {
            _nextResponseCompleter.completeError(new HttpException(
                "Connection closed before response was received",
                uri: _currentUri));
            _nextResponseCompleter = null;
          }
          close();
        });
  }

  _HttpClientRequest send(Uri uri, int port, String method, _Proxy proxy) {
    if (closed) {
      throw new HttpException(
          "Socket closed before request was sent", uri: uri);
    }
    _currentUri = uri;
    // Start with pausing the parser.
    _subscription.pause();
    _ProxyCredentials proxyCreds;  // Credentials used to authorize proxy.
    _SiteCredentials creds;  // Credentials used to authorize this request.
    var outgoing = new _HttpOutgoing(_socket);
    // Create new request object, wrapping the outgoing connection.
    var request = new _HttpClientRequest(outgoing,
                                         uri,
                                         method,
                                         proxy,
                                         _httpClient,
                                         this);
    request.headers.host = uri.host;
    request.headers.port = port;
    request.headers.set(HttpHeaders.ACCEPT_ENCODING, "gzip");
    if (_httpClient.userAgent != null) {
      request.headers.set('User-Agent', _httpClient.userAgent);
    }
    if (proxy.isAuthenticated) {
      // If the proxy configuration contains user information use that
      // for proxy basic authorization.
      String auth = _CryptoUtils.bytesToBase64(
          UTF8.encode("${proxy.username}:${proxy.password}"));
      request.headers.set(HttpHeaders.PROXY_AUTHORIZATION, "Basic $auth");
    } else if (!proxy.isDirect && _httpClient._proxyCredentials.length > 0) {
      proxyCreds = _httpClient._findProxyCredentials(proxy);
      if (proxyCreds != null) {
        proxyCreds.authorize(request);
      }
    }
    if (uri.userInfo != null && !uri.userInfo.isEmpty) {
      // If the URL contains user information use that for basic
      // authorization.
      String auth =
          _CryptoUtils.bytesToBase64(UTF8.encode(uri.userInfo));
      request.headers.set(HttpHeaders.AUTHORIZATION, "Basic $auth");
    } else {
      // Look for credentials.
      creds = _httpClient._findCredentials(uri);
      if (creds != null) {
        creds.authorize(request);
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
                _currentUri = null;
                incoming.dataDone.then((_) {
                  if (!_dispose &&
                      incoming.headers.persistentConnection &&
                      request.persistentConnection) {
                    // Return connection, now we are done.
                    _httpClient._returnConnection(this);
                    _subscription.resume();
                  } else {
                    destroy();
                  }
                });
                // For digest authentication if proxy check if the proxy
                // requests the client to start using a new nonce for proxy
                // authentication.
                if (proxyCreds != null &&
                    proxyCreds.scheme == _AuthenticationScheme.DIGEST) {
                  var authInfo = incoming.headers["proxy-authentication-info"];
                  if (authInfo != null && authInfo.length == 1) {
                    var header =
                        _HeaderValue.parse(
                            authInfo[0], parameterSeparator: ',');
                    var nextnonce = header.parameters["nextnonce"];
                    if (nextnonce != null) proxyCreds.nonce = nextnonce;
                  }
                }
                // For digest authentication check if the server requests the
                // client to start using a new nonce.
                if (creds != null &&
                    creds.scheme == _AuthenticationScheme.DIGEST) {
                  var authInfo = incoming.headers["authentication-info"];
                  if (authInfo != null && authInfo.length == 1) {
                    var header =
                        _HeaderValue.parse(
                            authInfo[0], parameterSeparator: ',');
                    var nextnonce = header.parameters["nextnonce"];
                    if (nextnonce != null) creds.nonce = nextnonce;
                  }
                }
                request._onIncoming(incoming);
              })
              // If we see a state error, we failed to get the 'first'
              // element.
              .catchError((error) {
                throw new HttpException(
                    "Connection closed before data was received", uri: uri);
              }, test: (error) => error is StateError)
              .catchError((error, stackTrace) {
                // We are done with the socket.
                destroy();
                request._onError(error, stackTrace);
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
    closed = true;
    _httpClient._connectionClosed(this);
    _socket.destroy();
  }

  void close() {
    closed = true;
    _httpClient._connectionClosed(this);
    _streamFuture
          // TODO(ajohnsen): Add timeout.
        .then((_) => _socket.destroy());
  }

  Future<_HttpClientConnection> createProxyTunnel(host, port, proxy, callback) {
    _HttpClientRequest request =
        send(new Uri(host: host, port: port),
             port,
             "CONNECT",
             proxy);
    if (proxy.isAuthenticated) {
      // If the proxy configuration contains user information use that
      // for proxy basic authorization.
      String auth = _CryptoUtils.bytesToBase64(
          UTF8.encode("${proxy.username}:${proxy.password}"));
      request.headers.set(HttpHeaders.PROXY_AUTHORIZATION, "Basic $auth");
    }
    return request.close()
        .then((response) {
          if (response.statusCode != HttpStatus.OK) {
            throw "Proxy failed to establish tunnel "
                  "(${response.statusCode} ${response.reasonPhrase})";
          }
          var socket = response._httpRequest._httpClientConnection._socket;
          return SecureSocket.secure(
              socket, host: host, onBadCertificate: callback);
        })
        .then((secureSocket) {
          String key = _HttpClientConnection.makeKey(true, host, port);
          return new _HttpClientConnection(
              key, secureSocket, request._httpClient, true);
        });
  }

  HttpConnectionInfo get connectionInfo => _HttpConnectionInfo.create(_socket);

  static makeKey(bool isSecure, String host, int port) {
    return isSecure ? "ssh:$host:$port" : "$host:$port";
  }

  void stopTimer() {
    if (_idleTimer != null) {
      _idleTimer.cancel();
      _idleTimer = null;
    }
  }

  void startTimer() {
    assert(_idleTimer == null);
    _idleTimer = new Timer(
        _httpClient.idleTimeout,
        () {
          _idleTimer = null;
          close();
        });
  }
}

class _ConnnectionInfo {
  _ConnnectionInfo(_HttpClientConnection this.connection, _Proxy this.proxy);
  final _HttpClientConnection connection;
  final _Proxy proxy;
}


class _HttpClient implements HttpClient {
  // TODO(ajohnsen): Use eviction timeout.
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
  Duration _idleTimeout = const Duration(seconds: 15);
  Function _badCertificateCallback;

  Timer _noActiveTimer;

  Duration get idleTimeout => _idleTimeout;

  String userAgent = _getHttpVersion();

  void set idleTimeout(Duration timeout) {
    _idleTimeout = timeout;
    _idleConnections.values.forEach(
        (l) => l.forEach((c) {
          // Reset timer. This is fine, as it's not happening often.
          c.stopTimer();
          c.startTimer();
        }));
  }

  set badCertificateCallback(bool callback(X509Certificate cert,
                                           String host,
                                           int port)) {
    _badCertificateCallback = callback;
  }


  Future<HttpClientRequest> open(String method,
                                 String host,
                                 int port,
                                 String path) {
    // TODO(sgjesse): The path set here can contain both query and
    // fragment. They should be cracked and set correctly.
    return _openUrl(method, new Uri(
        scheme: "http", host: host, port: port, path: path));
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
    _credentials.add(new _SiteCredentials(url, realm, cr));
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
    if (method != "CONNECT") {
      if (uri.host.isEmpty ||
          (uri.scheme != "http" && uri.scheme != "https")) {
        throw new ArgumentError("Unsupported scheme '${uri.scheme}' in $uri");
      }
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
    return _getConnection(uri.host, port, proxyConf, isSecure)
        .then((info) {
          send(info) {
            return info.connection.send(uri,
                                        port,
                                        method.toUpperCase(),
                                        info.proxy);
          }
          // If the connection was closed before the request was sent, create
          // and use another connection.
          if (info.connection.closed) {
            return _getConnection(uri.host, port, proxyConf, isSecure)
                .then(send);
          }
          return send(info);
        });
  }

  Future<HttpClientRequest> _openUrlFromRequest(String method,
                                                Uri uri,
                                                _HttpClientRequest previous) {
    // If the new URI is relative (to either '/' or some sub-path),
    // construct a full URI from the previous one.
    Uri resolved = previous.uri.resolveUri(uri);
    return openUrl(method, resolved).then((_HttpClientRequest request) {
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
    if (!_idleConnections.containsKey(connection.key)) {
      _idleConnections[connection.key] = new LinkedHashSet();
    }
    _idleConnections[connection.key].add(connection);
    connection.startTimer();
    _updateTimers();
  }

  // Remove a closed connnection from the active set.
  void _connectionClosed(_HttpClientConnection connection) {
    connection.stopTimer();
    _activeConnections.remove(connection);
    if (_idleConnections.containsKey(connection.key)) {
      _idleConnections[connection.key].remove(connection);
      if (_idleConnections[connection.key].isEmpty) {
        _idleConnections.remove(connection.key);
      }
    }
    _updateTimers();
  }

  void _updateTimers() {
    if (_activeConnections.isEmpty) {
      if (!_idleConnections.isEmpty && _noActiveTimer == null) {
        _noActiveTimer = new Timer(const Duration(milliseconds: 100), () {
          _noActiveTimer = null;
          if (_activeConnections.isEmpty) {
            close();
            _closing = false;
          }
        });
      }
    } else if (_noActiveTimer != null) {
      _noActiveTimer.cancel();
      _noActiveTimer = null;
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
      String key = _HttpClientConnection.makeKey(isSecure, host, port);
      if (_idleConnections.containsKey(key)) {
        var connection = _idleConnections[key].first;
        _idleConnections[key].remove(connection);
        if (_idleConnections[key].isEmpty) {
          _idleConnections.remove(key);
        }
        connection.stopTimer();
        _activeConnections.add(connection);
        _updateTimers();
        return new Future.value(new _ConnnectionInfo(connection, proxy));
      }
      var currentBadCertificateCallback = _badCertificateCallback;
      bool callback(X509Certificate certificate) =>
          currentBadCertificateCallback == null ? false :
          currentBadCertificateCallback(certificate, uriHost, uriPort);
      return (isSecure && proxy.isDirect
                  ? SecureSocket.connect(host,
                                         port,
                                         sendClientCertificate: true,
                                         onBadCertificate: callback)
                  : Socket.connect(host, port))
        .then((socket) {
          socket.setOption(SocketOption.TCP_NODELAY, true);
          var connection = new _HttpClientConnection(key, socket, this);
          if (isSecure && !proxy.isDirect) {
            connection._dispose = true;
            return connection.createProxyTunnel(
                uriHost, uriPort, proxy, callback)
                .then((tunnel) {
                  _activeConnections.add(tunnel);
                  return new _ConnnectionInfo(tunnel, proxy);
                });
          } else {
            _activeConnections.add(connection);
            return new _ConnnectionInfo(connection, proxy);
          }
        }, onError: (error) {
          // Continue with next proxy.
          return connect(error);
        });
    }
    return connect(new HttpException("No proxies given"));
  }

  _SiteCredentials _findCredentials(Uri url, [_AuthenticationScheme scheme]) {
    // Look for credentials.
    _SiteCredentials cr =
        _credentials.fold(null, (prev, value) {
          if (value.applies(url, scheme)) {
            if (prev == null) return value;
            return value.uri.path.length > prev.uri.path.length ? value : prev;
          } else {
            return prev;
          }
        });
    return cr;
  }

  _ProxyCredentials _findProxyCredentials(_Proxy proxy,
                                          [_AuthenticationScheme scheme]) {
    // Look for credentials.
    var it = _proxyCredentials.iterator;
    while (it.moveNext()) {
      if (it.current.applies(proxy, scheme)) {
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

  void _removeProxyCredentials(_Credentials cr) {
    int index = _proxyCredentials.indexOf(cr);
    if (index != -1) {
      _proxyCredentials.removeAt(index);
    }
  }

  static String _findProxyFromEnvironment(Uri url,
                                          Map<String, String> environment) {
    checkNoProxy(String option) {
      if (option == null) return null;
      Iterator<String> names = option.split(",").map((s) => s.trim()).iterator;
      while (names.moveNext()) {
        if (url.host.endsWith(names.current)) {
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
      pos = option.indexOf("/");
      if (pos >= 0) {
        option = option.substring(0, pos);
      }
      if (option.indexOf(":") == -1) option = "$option:1080";
      return "PROXY $option";
    }

    // Default to using the process current environment.
    if (environment == null) environment = _platformEnvironmentCache;

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

  static Map<String, String> _platformEnvironmentCache = Platform.environment;
}


class _HttpConnection extends LinkedListEntry<_HttpConnection> {
  static const _ACTIVE = 0;
  static const _IDLE = 1;
  static const _CLOSING = 2;
  static const _DETACHED = 3;

  int _state = _IDLE;

  final Socket _socket;
  final _HttpServer _httpServer;
  final _HttpParser _httpParser;
  StreamSubscription _subscription;
  Timer _idleTimer;

  Future _streamFuture;

  _HttpConnection(Socket this._socket, _HttpServer this._httpServer)
      : _httpParser = new _HttpParser.requestParser() {
    _startTimeout();
    _socket.pipe(_httpParser);
    _subscription = _httpParser.listen(
        (incoming) {
          _stopTimeout();
          // If the incoming was closed, close the connection.
          incoming.dataDone.then((closing) {
            if (closing) destroy();
          });
          // Only handle one incoming request at the time. Keep the
          // stream paused until the request has been send.
          _subscription.pause();
          _state = _ACTIVE;
          var outgoing = new _HttpOutgoing(_socket);
          var response = new _HttpResponse(incoming.uri,
                                           incoming.headers.protocolVersion,
                                           outgoing,
                                           _httpServer.serverHeader);
          var request = new _HttpRequest(response, incoming, _httpServer, this);
          _streamFuture = outgoing.done
              .then((_) {
                response.deadline = null;
                if (_state == _DETACHED) return;
                if (response.persistentConnection &&
                    request.persistentConnection &&
                    incoming.fullBodyRead &&
                    !_httpParser.upgrade &&
                    !_httpServer.closed) {
                  _state = _IDLE;
                  _startTimeout();
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
          // Ignore failed requests that was closed before headers was received.
          destroy();
        });
  }

  void _startTimeout() {
    assert(_state == _IDLE);
    _stopTimeout();
    if (_httpServer.idleTimeout == null) return;
    _idleTimer = new Timer(_httpServer.idleTimeout, () {
      destroy();
    });
  }

  void _stopTimeout() {
    if (_idleTimer != null) _idleTimer.cancel();
  }

  void destroy() {
    _stopTimeout();
    if (_state == _CLOSING || _state == _DETACHED) return;
    _state = _CLOSING;
    _socket.destroy();
    _httpServer._connectionClosed(this);
  }

  Future<Socket> detachSocket() {
    _stopTimeout();
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
  String serverHeader = _getHttpVersion();

  Duration idleTimeout = const Duration(seconds: 120);

  static Future<HttpServer> bind(address, int port, int backlog) {
    return ServerSocket.bind(address, port, backlog: backlog).then((socket) {
      return new _HttpServer._(socket, true);
    });
  }

  static Future<HttpServer> bindSecure(address,
                                       int port,
                                       int backlog,
                                       String certificate_name,
                                       bool requestClientCertificate) {
    return SecureServerSocket.bind(
        address,
        port,
        certificate_name,
        backlog: backlog,
        requestClientCertificate: requestClientCertificate)
        .then((socket) {
          return new _HttpServer._(socket, true);
        });
  }

  _HttpServer._(this._serverSocket, this._closeServer) {
    _controller = new StreamController<HttpRequest>(sync: true,
                                                    onCancel: close);
  }

  _HttpServer.listenOn(ServerSocket this._serverSocket)
      : _closeServer = false {
    _controller = new StreamController<HttpRequest>(sync: true,
                                                    onCancel: close);
  }

  StreamSubscription<HttpRequest> listen(void onData(HttpRequest event),
                                         {Function onError,
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

  Future close({bool force: false}) {
    closed = true;
    Future result;
    if (_serverSocket != null && _closeServer) {
      result = _serverSocket.close();
    } else {
      result = new Future.value();
    }
    if (force) {
      for (var c in _connections.toList()) {
        c.destroy();
      }
      assert(_connections.isEmpty);
    } else {
      for (var c in _connections.where((c) => c._isIdle).toList()) {
        c.destroy();
      }
    }
    _maybeCloseSessionManager();
    return result;
  }

  void _maybeCloseSessionManager() {
    if (closed &&
        _connections.isEmpty &&
        _sessionManagerInstance != null) {
      _sessionManagerInstance.close();
      _sessionManagerInstance = null;
    }
  }

  int get port {
    if (closed) throw new HttpException("HttpServer is not bound to a socket");
    return _serverSocket.port;
  }

  InternetAddress get address {
    if (closed) throw new HttpException("HttpServer is not bound to a socket");
    return _serverSocket.address;
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
    _maybeCloseSessionManager();
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

  // The server listen socket. Untyped as it can be both ServerSocket and
  // SecureServerSocket.
  final _serverSocket;
  final bool _closeServer;

  // Set of currently connected clients.
  final LinkedList<_HttpConnection> _connections
      = new LinkedList<_HttpConnection>();
  StreamController<HttpRequest> _controller;
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
      _HttpConnectionInfo info = new _HttpConnectionInfo();
      info.remoteAddress = socket.remoteAddress;
      info.remotePort = socket.remotePort;
      info.localPort = socket.port;
      return info;
    } catch (e) { }
    return null;
  }

  InternetAddress remoteAddress;
  int remotePort;
  int localPort;
}


class _DetachedSocket extends Stream<List<int>> implements Socket {
  final Stream<List<int>> _incoming;
  final Socket _socket;

  _DetachedSocket(this._socket, this._incoming);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {Function onError,
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

  void addError(error, [StackTrace stackTrace]) =>
      _socket.addError(error, stackTrace);

  Future<Socket> addStream(Stream<List<int>> stream) {
    return _socket.addStream(stream);
  }

  void destroy() => _socket.destroy();

  Future flush() => _socket.flush();

  Future close() => _socket.close();

  Future<Socket> get done => _socket.done;

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  InternetAddress get remoteAddress => _socket.remoteAddress;

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


abstract class _Credentials {
  _HttpClientCredentials credentials;
  String realm;
  bool used = false;

  // Digest specific fields.
  String ha1;
  String nonce;
  String algorithm;
  String qop;
  int nonceCount;

  _Credentials(this.credentials, this.realm) {
    if (credentials.scheme == _AuthenticationScheme.DIGEST) {
      // Calculate the H(A1) value once. There is no mentioning of
      // username/password encoding in RFC 2617. However there is an
      // open draft for adding an additional accept-charset parameter to
      // the WWW-Authenticate and Proxy-Authenticate headers, see
      // http://tools.ietf.org/html/draft-reschke-basicauth-enc-06. For
      // now always use UTF-8 encoding.
      _HttpClientDigestCredentials creds = credentials;
      var hasher = new _MD5();
      hasher.add(UTF8.encode(creds.username));
      hasher.add([_CharCode.COLON]);
      hasher.add(realm.codeUnits);
      hasher.add([_CharCode.COLON]);
      hasher.add(UTF8.encode(creds.password));
      ha1 = _CryptoUtils.bytesToHex(hasher.close());
    }
  }

  _AuthenticationScheme get scheme => credentials.scheme;

  void authorize(HttpClientRequest request);
}

class _SiteCredentials extends _Credentials {
  Uri uri;

  _SiteCredentials(this.uri, realm, _HttpClientCredentials creds)
  : super(creds, realm);

  bool applies(Uri uri, _AuthenticationScheme scheme) {
    if (scheme != null && credentials.scheme != scheme) return false;
    if (uri.host != this.uri.host) return false;
    int thisPort =
        this.uri.port == 0 ? HttpClient.DEFAULT_HTTP_PORT : this.uri.port;
    int otherPort = uri.port == 0 ? HttpClient.DEFAULT_HTTP_PORT : uri.port;
    if (otherPort != thisPort) return false;
    return uri.path.startsWith(this.uri.path);
  }

  void authorize(HttpClientRequest request) {
    // Digest credentials cannot be used without a nonce from the
    // server.
    if (credentials.scheme == _AuthenticationScheme.DIGEST &&
        nonce == null) {
      return;
    }
    credentials.authorize(this, request);
    used = true;
  }
}


class _ProxyCredentials extends _Credentials {
  String host;
  int port;

  _ProxyCredentials(this.host,
                    this.port,
                    realm,
                    _HttpClientCredentials creds)
  : super(creds, realm);

  bool applies(_Proxy proxy, _AuthenticationScheme scheme) {
    if (scheme != null && credentials.scheme != scheme) return false;
    return proxy.host == host && proxy.port == port;
  }

  void authorize(HttpClientRequest request) {
    // Digest credentials cannot be used without a nonce from the
    // server.
    if (credentials.scheme == _AuthenticationScheme.DIGEST &&
        nonce == null) {
      return;
    }
    credentials.authorizeProxy(this, request);
  }
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
        _CryptoUtils.bytesToBase64(UTF8.encode("$username:$password"));
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

  String authorization(_Credentials credentials, _HttpClientRequest request) {
    String requestUri = request._requestUri();
    _MD5 hasher = new _MD5();
    hasher.add(request.method.codeUnits);
    hasher.add([_CharCode.COLON]);
    hasher.add(requestUri.codeUnits);
    var ha2 = _CryptoUtils.bytesToHex(hasher.close());

    String qop;
    String cnonce;
    String nc;
    var x;
    hasher = new _MD5();
    hasher.add(credentials.ha1.codeUnits);
    hasher.add([_CharCode.COLON]);
    if (credentials.qop == "auth") {
      qop = credentials.qop;
      cnonce = _CryptoUtils.bytesToHex(_IOCrypto.getRandomBytes(4));
      ++credentials.nonceCount;
      nc = credentials.nonceCount.toRadixString(16);
      nc = "00000000".substring(0, 8 - nc.length + 1) + nc;
      hasher.add(credentials.nonce.codeUnits);
      hasher.add([_CharCode.COLON]);
      hasher.add(nc.codeUnits);
      hasher.add([_CharCode.COLON]);
      hasher.add(cnonce.codeUnits);
      hasher.add([_CharCode.COLON]);
      hasher.add(credentials.qop.codeUnits);
      hasher.add([_CharCode.COLON]);
      hasher.add(ha2.codeUnits);
    } else {
      hasher.add(credentials.nonce.codeUnits);
      hasher.add([_CharCode.COLON]);
      hasher.add(ha2.codeUnits);
    }
    var response = _CryptoUtils.bytesToHex(hasher.close());

    StringBuffer buffer = new StringBuffer();
    buffer.write('Digest ');
    buffer.write('username="$username"');
    buffer.write(', realm="${credentials.realm}"');
    buffer.write(', nonce="${credentials.nonce}"');
    buffer.write(', uri="$requestUri"');
    buffer.write(', algorithm="${credentials.algorithm}"');
    if (qop == "auth") {
      buffer.write(', qop="$qop"');
      buffer.write(', cnonce="$cnonce"');
      buffer.write(', nc="$nc"');
    }
    buffer.write(', response="$response"');
    return buffer.toString();
  }

  void authorize(_Credentials credentials, HttpClientRequest request) {
    request.headers.set(HttpHeaders.AUTHORIZATION,
                        authorization(credentials, request));
  }

  void authorizeProxy(_ProxyCredentials credentials,
                      HttpClientRequest request) {
    request.headers.set(HttpHeaders.PROXY_AUTHORIZATION,
                        authorization(credentials, request));
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

String _getHttpVersion() {
  var version = Platform.version;
  // Only include major and minor version numbers.
  int index = version.indexOf('.', version.indexOf('.') + 1);
  version = version.substring(0, index);
  return 'Dart/$version (dart:io)';
}
