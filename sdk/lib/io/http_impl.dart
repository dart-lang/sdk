// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:io";

const int _OUTGOING_BUFFER_SIZE = 8 * 1024;

typedef void _BytesConsumer(List<int> bytes);

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

  _HttpIncoming(this.headers, this._transferLength, this._stream);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    hasSubscriber = true;
    return _stream.handleError((error) {
      throw new HttpException(error.message, uri: uri);
    }).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
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

  _HttpInboundMessage(this._incoming);

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

  Uri _requestedUri;

  _HttpRequest(this.response, _HttpIncoming _incoming, this._httpServer,
      this._httpConnection)
      : super(_incoming) {
    if (headers.protocolVersion == "1.1") {
      response.headers
        ..chunkedTransferEncoding = true
        ..persistentConnection = headers.persistentConnection;
    }

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
      {Function onError, void onDone(), bool cancelOnError}) {
    return _incoming.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Uri get uri => _incoming.uri;

  Uri get requestedUri {
    if (_requestedUri == null) {
      var proto = headers['x-forwarded-proto'];
      var scheme = proto != null
          ? proto.first
          : _httpConnection._socket is SecureSocket ? "https" : "http";
      var hostList = headers['x-forwarded-host'];
      String host;
      if (hostList != null) {
        host = hostList.first;
      } else {
        hostList = headers['host'];
        if (hostList != null) {
          host = hostList.first;
        } else {
          host = "${_httpServer.address.host}:${_httpServer.port}";
        }
      }
      _requestedUri = Uri.parse("$scheme://$host$uri");
    }
    return _requestedUri;
  }

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

class _HttpClientResponse extends _HttpInboundMessage
    implements HttpClientResponse {
  List<RedirectInfo> get redirects => _httpRequest._responseRedirects;

  // The HttpClient this response belongs to.
  final _HttpClient _httpClient;

  // The HttpClientRequest of this response.
  final _HttpClientRequest _httpRequest;

  _HttpClientResponse(
      _HttpIncoming _incoming, this._httpRequest, this._httpClient)
      : super(_incoming) {
    // Set uri for potential exceptions.
    _incoming.uri = _httpRequest.uri;
  }

  int get statusCode => _incoming.statusCode;
  String get reasonPhrase => _incoming.reasonPhrase;

  X509Certificate get certificate {
    var socket = _httpRequest._httpClientConnection._socket;
    if (socket is SecureSocket) return socket.peerCertificate;
    throw new UnsupportedError("Socket is not a SecureSocket");
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

  Future<HttpClientResponse> redirect(
      [String method, Uri url, bool followLoops]) {
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
    return _httpClient
        ._openUrlFromRequest(method, url, _httpRequest)
        .then((request) {
      request._responseRedirects
        ..addAll(this.redirects)
        ..add(new _RedirectInfo(statusCode, method, url));
      return request.close();
    });
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    if (_incoming.upgraded) {
      // If upgraded, the connection is already 'removed' form the client.
      // Since listening to upgraded data is 'bogus', simply close and
      // return empty stream subscription.
      _httpRequest._httpClientConnection.destroy();
      return new Stream<List<int>>.empty().listen(null, onDone: onDone);
    }
    var stream = _incoming;
    if (_httpClient.autoUncompress &&
        headers.value(HttpHeaders.CONTENT_ENCODING) == "gzip") {
      stream = stream.transform(GZIP.decoder);
    }
    return stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
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
        challenge != null &&
        challenge.length == 1;
  }

  bool get _shouldAuthenticate {
    // Only try to authenticate if there is a challenge in the response.
    List<String> challenge = headers[HttpHeaders.WWW_AUTHENTICATE];
    return statusCode == HttpStatus.UNAUTHORIZED &&
        challenge != null &&
        challenge.length == 1;
  }

  Future<HttpClientResponse> _authenticate(bool proxyAuth) {
    Future<HttpClientResponse> retry() {
      // Drain body and retry.
      return drain().then((_) {
        return _httpClient
            ._openUrlFromRequest(
                _httpRequest.method, _httpRequest.uri, _httpRequest)
            .then((request) => request.close());
      });
    }

    List<String> authChallenge() {
      return proxyAuth
          ? headers[HttpHeaders.PROXY_AUTHENTICATE]
          : headers[HttpHeaders.WWW_AUTHENTICATE];
    }

    _Credentials findCredentials(_AuthenticationScheme scheme) {
      return proxyAuth
          ? _httpClient._findProxyCredentials(_httpRequest._proxy, scheme)
          : _httpClient._findCredentials(_httpRequest.uri, scheme);
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
        return _httpClient._authenticateProxy(
            proxy.host, proxy.port, scheme.toString(), realm);
      } else {
        if (_httpClient._authenticate == null) {
          return new Future.value(false);
        }
        return _httpClient._authenticate(
            _httpRequest.uri, scheme.toString(), realm);
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
            cr
              ..nonce = header.parameters["nonce"]
              ..algorithm = "MD5"
              ..qop = header.parameters["qop"]
              ..nonceCount = 0;
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

abstract class _HttpOutboundMessage<T> extends _IOSinkImpl {
  // Used to mark when the body should be written. This is used for HEAD
  // requests and in error handling.
  bool _encodingSet = false;

  bool _bufferOutput = true;

  final Uri _uri;
  final _HttpOutgoing _outgoing;

  final _HttpHeaders headers;

  _HttpOutboundMessage(Uri uri, String protocolVersion, _HttpOutgoing outgoing,
      {_HttpHeaders initialHeaders})
      : _uri = uri,
        headers = new _HttpHeaders(protocolVersion,
            defaultPortForScheme: uri.scheme == 'https'
                ? HttpClient.DEFAULT_HTTPS_PORT
                : HttpClient.DEFAULT_HTTP_PORT,
            initialHeaders: initialHeaders),
        _outgoing = outgoing,
        super(outgoing, null) {
    _outgoing.outbound = this;
    _encodingMutable = false;
  }

  int get contentLength => headers.contentLength;
  void set contentLength(int contentLength) {
    headers.contentLength = contentLength;
  }

  bool get persistentConnection => headers.persistentConnection;
  void set persistentConnection(bool p) {
    headers.persistentConnection = p;
  }

  bool get bufferOutput => _bufferOutput;
  void set bufferOutput(bool bufferOutput) {
    if (_outgoing.headersWritten) throw new StateError("Header already sent");
    _bufferOutput = bufferOutput;
  }

  Encoding get encoding {
    if (_encodingSet && _outgoing.headersWritten) {
      return _encoding;
    }
    var charset;
    if (headers.contentType != null && headers.contentType.charset != null) {
      charset = headers.contentType.charset;
    } else {
      charset = "iso-8859-1";
    }
    return Encoding.getByName(charset);
  }

  void add(List<int> data) {
    if (data.length == 0) return;
    super.add(data);
  }

  void write(Object obj) {
    if (!_encodingSet) {
      _encoding = encoding;
      _encodingSet = true;
    }
    super.write(obj);
  }

  void _writeHeader();

  bool get _isConnectionClosed => false;
}

class _HttpResponse extends _HttpOutboundMessage<HttpResponse>
    implements HttpResponse {
  int _statusCode = 200;
  String _reasonPhrase;
  List<Cookie> _cookies;
  _HttpRequest _httpRequest;
  Duration _deadline;
  Timer _deadlineTimer;

  _HttpResponse(Uri uri, String protocolVersion, _HttpOutgoing outgoing,
      HttpHeaders defaultHeaders, String serverHeader)
      : super(uri, protocolVersion, outgoing, initialHeaders: defaultHeaders) {
    if (serverHeader != null) headers.set('server', serverHeader);
  }

  bool get _isConnectionClosed => _httpRequest._httpConnection._isClosing;

  List<Cookie> get cookies {
    if (_cookies == null) _cookies = new List<Cookie>();
    return _cookies;
  }

  int get statusCode => _statusCode;
  void set statusCode(int statusCode) {
    if (_outgoing.headersWritten) throw new StateError("Header already sent");
    _statusCode = statusCode;
  }

  String get reasonPhrase => _findReasonPhrase(statusCode);
  void set reasonPhrase(String reasonPhrase) {
    if (_outgoing.headersWritten) throw new StateError("Header already sent");
    _reasonPhrase = reasonPhrase;
  }

  Future redirect(Uri location, {int status: HttpStatus.MOVED_TEMPORARILY}) {
    if (_outgoing.headersWritten) throw new StateError("Header already sent");
    statusCode = status;
    headers.set("location", location.toString());
    return close();
  }

  Future<Socket> detachSocket({bool writeHeaders: true}) {
    if (_outgoing.headersWritten) throw new StateError("Headers already sent");
    deadline = null; // Be sure to stop any deadline.
    var future = _httpRequest._httpConnection.detachSocket();
    if (writeHeaders) {
      var headersFuture =
          _outgoing.writeHeaders(drainRequest: false, setOutgoing: false);
      assert(headersFuture == null);
    } else {
      // Imitate having written the headers.
      _outgoing.headersWritten = true;
    }
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
      _httpRequest._httpConnection.destroy();
    });
  }

  void _writeHeader() {
    BytesBuilder buffer = new _CopyingBytesBuilder(_OUTGOING_BUFFER_SIZE);

    // Write status line.
    if (headers.protocolVersion == "1.1") {
      buffer.add(_Const.HTTP11);
    } else {
      buffer.add(_Const.HTTP10);
    }
    buffer.addByte(_CharCode.SP);
    buffer.add(statusCode.toString().codeUnits);
    buffer.addByte(_CharCode.SP);
    buffer.add(reasonPhrase.codeUnits);
    buffer.addByte(_CharCode.CR);
    buffer.addByte(_CharCode.LF);

    var session = _httpRequest._session;
    if (session != null && !session._destroyed) {
      // Mark as not new.
      session._isNew = false;
      // Make sure we only send the current session id.
      bool found = false;
      for (int i = 0; i < cookies.length; i++) {
        if (cookies[i].name.toUpperCase() == _DART_SESSION_ID) {
          cookies[i]
            ..value = session.id
            ..httpOnly = true
            ..path = "/";
          found = true;
        }
      }
      if (!found) {
        var cookie = new Cookie(_DART_SESSION_ID, session.id);
        cookies.add(cookie
          ..httpOnly = true
          ..path = "/");
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
    headers._build(buffer);
    buffer.addByte(_CharCode.CR);
    buffer.addByte(_CharCode.LF);
    Uint8List headerBytes = buffer.takeBytes();
    _outgoing.setHeader(headerBytes, headerBytes.length);
  }

  String _findReasonPhrase(int statusCode) {
    if (_reasonPhrase != null) {
      return _reasonPhrase;
    }

    switch (statusCode) {
      case HttpStatus.CONTINUE:
        return "Continue";
      case HttpStatus.SWITCHING_PROTOCOLS:
        return "Switching Protocols";
      case HttpStatus.OK:
        return "OK";
      case HttpStatus.CREATED:
        return "Created";
      case HttpStatus.ACCEPTED:
        return "Accepted";
      case HttpStatus.NON_AUTHORITATIVE_INFORMATION:
        return "Non-Authoritative Information";
      case HttpStatus.NO_CONTENT:
        return "No Content";
      case HttpStatus.RESET_CONTENT:
        return "Reset Content";
      case HttpStatus.PARTIAL_CONTENT:
        return "Partial Content";
      case HttpStatus.MULTIPLE_CHOICES:
        return "Multiple Choices";
      case HttpStatus.MOVED_PERMANENTLY:
        return "Moved Permanently";
      case HttpStatus.FOUND:
        return "Found";
      case HttpStatus.SEE_OTHER:
        return "See Other";
      case HttpStatus.NOT_MODIFIED:
        return "Not Modified";
      case HttpStatus.USE_PROXY:
        return "Use Proxy";
      case HttpStatus.TEMPORARY_REDIRECT:
        return "Temporary Redirect";
      case HttpStatus.BAD_REQUEST:
        return "Bad Request";
      case HttpStatus.UNAUTHORIZED:
        return "Unauthorized";
      case HttpStatus.PAYMENT_REQUIRED:
        return "Payment Required";
      case HttpStatus.FORBIDDEN:
        return "Forbidden";
      case HttpStatus.NOT_FOUND:
        return "Not Found";
      case HttpStatus.METHOD_NOT_ALLOWED:
        return "Method Not Allowed";
      case HttpStatus.NOT_ACCEPTABLE:
        return "Not Acceptable";
      case HttpStatus.PROXY_AUTHENTICATION_REQUIRED:
        return "Proxy Authentication Required";
      case HttpStatus.REQUEST_TIMEOUT:
        return "Request Time-out";
      case HttpStatus.CONFLICT:
        return "Conflict";
      case HttpStatus.GONE:
        return "Gone";
      case HttpStatus.LENGTH_REQUIRED:
        return "Length Required";
      case HttpStatus.PRECONDITION_FAILED:
        return "Precondition Failed";
      case HttpStatus.REQUEST_ENTITY_TOO_LARGE:
        return "Request Entity Too Large";
      case HttpStatus.REQUEST_URI_TOO_LONG:
        return "Request-URI Too Large";
      case HttpStatus.UNSUPPORTED_MEDIA_TYPE:
        return "Unsupported Media Type";
      case HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE:
        return "Requested range not satisfiable";
      case HttpStatus.EXPECTATION_FAILED:
        return "Expectation Failed";
      case HttpStatus.INTERNAL_SERVER_ERROR:
        return "Internal Server Error";
      case HttpStatus.NOT_IMPLEMENTED:
        return "Not Implemented";
      case HttpStatus.BAD_GATEWAY:
        return "Bad Gateway";
      case HttpStatus.SERVICE_UNAVAILABLE:
        return "Service Unavailable";
      case HttpStatus.GATEWAY_TIMEOUT:
        return "Gateway Time-out";
      case HttpStatus.HTTP_VERSION_NOT_SUPPORTED:
        return "Http Version not supported";
      default:
        return "Status $statusCode";
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

  final Completer<HttpClientResponse> _responseCompleter =
      new Completer<HttpClientResponse>();

  final _Proxy _proxy;

  Future<HttpClientResponse> _response;

  // TODO(ajohnsen): Get default value from client?
  bool _followRedirects = true;

  int _maxRedirects = 5;

  List<RedirectInfo> _responseRedirects = [];

  _HttpClientRequest(_HttpOutgoing outgoing, Uri uri, this.method, this._proxy,
      this._httpClient, this._httpClientConnection)
      : uri = uri,
        super(uri, "1.1", outgoing) {
    // GET and HEAD have 'content-length: 0' by default.
    if (method == "GET" || method == "HEAD") {
      contentLength = 0;
    } else {
      headers.chunkedTransferEncoding = true;
    }
  }

  Future<HttpClientResponse> get done {
    if (_response == null) {
      _response = Future.wait([_responseCompleter.future, super.done],
          eagerError: true).then((list) => list[0]);
    }
    return _response;
  }

  Future<HttpClientResponse> close() {
    super.close();
    return done;
  }

  int get maxRedirects => _maxRedirects;
  void set maxRedirects(int maxRedirects) {
    if (_outgoing.headersWritten) throw new StateError("Request already sent");
    _maxRedirects = maxRedirects;
  }

  bool get followRedirects => _followRedirects;
  void set followRedirects(bool followRedirects) {
    if (_outgoing.headersWritten) throw new StateError("Request already sent");
    _followRedirects = followRedirects;
  }

  HttpConnectionInfo get connectionInfo => _httpClientConnection.connectionInfo;

  void _onIncoming(_HttpIncoming incoming) {
    var response = new _HttpClientResponse(incoming, this, _httpClient);
    Future<HttpClientResponse> future;
    if (followRedirects && response.isRedirect) {
      if (response.redirects.length < maxRedirects) {
        // Redirect and drain response.
        future = response
            .drain()
            .then<HttpClientResponse>((_) => response.redirect());
      } else {
        // End with exception, too many redirects.
        future = response.drain().then<HttpClientResponse>((_) {
          return new Future<HttpClientResponse>.error(new RedirectException(
              "Redirect limit exceeded", response.redirects));
        });
      }
    } else if (response._shouldAuthenticateProxy) {
      future = response._authenticate(true);
    } else if (response._shouldAuthenticate) {
      future = response._authenticate(false);
    } else {
      future = new Future<HttpClientResponse>.value(response);
    }
    future.then((v) => _responseCompleter.complete(v),
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
      if (result.isEmpty) result = "/";
      if (uri.hasQuery) {
        result = "${result}?${uri.query}";
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
          return uri.removeFragment().toString();
        }
      }
    }
  }

  void _writeHeader() {
    BytesBuilder buffer = new _CopyingBytesBuilder(_OUTGOING_BUFFER_SIZE);

    // Write the request method.
    buffer.add(method.codeUnits);
    buffer.addByte(_CharCode.SP);
    // Write the request URI.
    buffer.add(_requestUri().codeUnits);
    buffer.addByte(_CharCode.SP);
    // Write HTTP/1.1.
    buffer.add(_Const.HTTP11);
    buffer.addByte(_CharCode.CR);
    buffer.addByte(_CharCode.LF);

    // Add the cookies to the headers.
    if (!cookies.isEmpty) {
      StringBuffer sb = new StringBuffer();
      for (int i = 0; i < cookies.length; i++) {
        if (i > 0) sb.write("; ");
        sb..write(cookies[i].name)..write("=")..write(cookies[i].value);
      }
      headers.add(HttpHeaders.COOKIE, sb.toString());
    }

    headers._finalize();

    // Write headers.
    headers._build(buffer);
    buffer.addByte(_CharCode.CR);
    buffer.addByte(_CharCode.LF);
    Uint8List headerBytes = buffer.takeBytes();
    _outgoing.setHeader(headerBytes, headerBytes.length);
  }
}

// Used by _HttpOutgoing as a target of a chunked converter for gzip
// compression.
class _HttpGZipSink extends ByteConversionSink {
  final _BytesConsumer _consume;
  _HttpGZipSink(this._consume);

  void add(List<int> chunk) {
    _consume(chunk);
  }

  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    if (chunk is Uint8List) {
      _consume(new Uint8List.view(chunk.buffer, start, end - start));
    } else {
      _consume(chunk.sublist(start, end - start));
    }
  }

  void close() {}
}

// The _HttpOutgoing handles all of the following:
//  - Buffering
//  - GZip compression
//  - Content-Length validation.
//  - Errors.
//
// Most notable is the GZip compression, that uses a double-buffering system,
// one before gzip (_gzipBuffer) and one after (_buffer).
class _HttpOutgoing implements StreamConsumer<List<int>> {
  static const List<int> _footerAndChunk0Length = const [
    _CharCode.CR,
    _CharCode.LF,
    0x30,
    _CharCode.CR,
    _CharCode.LF,
    _CharCode.CR,
    _CharCode.LF
  ];

  static const List<int> _chunk0Length = const [
    0x30,
    _CharCode.CR,
    _CharCode.LF,
    _CharCode.CR,
    _CharCode.LF
  ];

  final Completer<Socket> _doneCompleter = new Completer<Socket>();
  final Socket socket;

  bool ignoreBody = false;
  bool headersWritten = false;

  Uint8List _buffer;
  int _length = 0;

  Future _closeFuture;

  bool chunked = false;
  int _pendingChunkedFooter = 0;

  int contentLength;
  int _bytesWritten = 0;

  bool _gzip = false;
  ByteConversionSink _gzipSink;
  // _gzipAdd is set iff the sink is being added to. It's used to specify where
  // gzipped data should be taken (sometimes a controller, sometimes a socket).
  _BytesConsumer _gzipAdd;
  Uint8List _gzipBuffer;
  int _gzipBufferLength = 0;

  bool _socketError = false;

  _HttpOutboundMessage outbound;

  _HttpOutgoing(this.socket);

  // Returns either a future or 'null', if it was able to write headers
  // immediately.
  Future writeHeaders({bool drainRequest: true, bool setOutgoing: true}) {
    if (headersWritten) return null;
    headersWritten = true;
    Future drainFuture;
    bool gzip = false;
    if (outbound is _HttpResponse) {
      // Server side.
      _HttpResponse response = outbound;
      if (response._httpRequest._httpServer.autoCompress &&
          outbound.bufferOutput &&
          outbound.headers.chunkedTransferEncoding) {
        List acceptEncodings =
            response._httpRequest.headers[HttpHeaders.ACCEPT_ENCODING];
        List contentEncoding = outbound.headers[HttpHeaders.CONTENT_ENCODING];
        if (acceptEncodings != null &&
            acceptEncodings
                .expand((list) => list.split(","))
                .any((encoding) => encoding.trim().toLowerCase() == "gzip") &&
            contentEncoding == null) {
          outbound.headers.set(HttpHeaders.CONTENT_ENCODING, "gzip");
          gzip = true;
        }
      }
      if (drainRequest && !response._httpRequest._incoming.hasSubscriber) {
        drainFuture = response._httpRequest.drain().catchError((_) {});
      }
    } else {
      drainRequest = false;
    }
    if (!ignoreBody) {
      if (setOutgoing) {
        int contentLength = outbound.headers.contentLength;
        if (outbound.headers.chunkedTransferEncoding) {
          chunked = true;
          if (gzip) this.gzip = true;
        } else if (contentLength >= 0) {
          this.contentLength = contentLength;
        }
      }
      if (drainFuture != null) {
        return drainFuture.then((_) => outbound._writeHeader());
      }
    }
    outbound._writeHeader();
    return null;
  }

  Future addStream(Stream<List<int>> stream) {
    if (_socketError) {
      stream.listen(null).cancel();
      return new Future.value(outbound);
    }
    if (ignoreBody) {
      stream.drain().catchError((_) {});
      var future = writeHeaders();
      if (future != null) {
        return future.then((_) => close());
      }
      return close();
    }
    StreamSubscription<List<int>> sub;
    // Use new stream so we are able to pause (see below listen). The
    // alternative is to use stream.extand, but that won't give us a way of
    // pausing.
    var controller = new StreamController<List<int>>(
        onPause: () => sub.pause(), onResume: () => sub.resume(), sync: true);

    void onData(List<int> data) {
      if (_socketError) return;
      if (data.length == 0) return;
      if (chunked) {
        if (_gzip) {
          _gzipAdd = controller.add;
          _addGZipChunk(data, _gzipSink.add);
          _gzipAdd = null;
          return;
        }
        _addChunk(_chunkHeader(data.length), controller.add);
        _pendingChunkedFooter = 2;
      } else {
        if (contentLength != null) {
          _bytesWritten += data.length;
          if (_bytesWritten > contentLength) {
            controller.addError(new HttpException(
                "Content size exceeds specified contentLength. "
                "$_bytesWritten bytes written while expected "
                "$contentLength. "
                "[${new String.fromCharCodes(data)}]"));
            return;
          }
        }
      }
      _addChunk(data, controller.add);
    }

    sub = stream.listen(onData,
        onError: controller.addError,
        onDone: controller.close,
        cancelOnError: true);
    // Write headers now that we are listening to the stream.
    if (!headersWritten) {
      var future = writeHeaders();
      if (future != null) {
        // While incoming is being drained, the pauseFuture is non-null. Pause
        // output until it's drained.
        sub.pause(future);
      }
    }
    return socket.addStream(controller.stream).then((_) {
      return outbound;
    }, onError: (error, stackTrace) {
      // Be sure to close it in case of an error.
      if (_gzip) _gzipSink.close();
      _socketError = true;
      _doneCompleter.completeError(error, stackTrace);
      if (_ignoreError(error)) {
        return outbound;
      } else {
        throw error;
      }
    });
  }

  Future close() {
    // If we are already closed, return that future.
    if (_closeFuture != null) return _closeFuture;
    // If we earlier saw an error, return immediate. The notification to
    // _Http*Connection is already done.
    if (_socketError) return new Future.value(outbound);
    if (outbound._isConnectionClosed) return new Future.value(outbound);
    if (!headersWritten && !ignoreBody) {
      if (outbound.headers.contentLength == -1) {
        // If no body was written, ignoreBody is false (it's not a HEAD
        // request) and the content-length is unspecified, set contentLength to
        // 0.
        outbound.headers.chunkedTransferEncoding = false;
        outbound.headers.contentLength = 0;
      } else if (outbound.headers.contentLength > 0) {
        var error = new HttpException(
            "No content even though contentLength was specified to be "
            "greater than 0: ${outbound.headers.contentLength}.",
            uri: outbound._uri);
        _doneCompleter.completeError(error);
        return _closeFuture = new Future.error(error);
      }
    }
    // If contentLength was specified, validate it.
    if (contentLength != null) {
      if (_bytesWritten < contentLength) {
        var error = new HttpException(
            "Content size below specified contentLength. "
            " $_bytesWritten bytes written but expected "
            "$contentLength.",
            uri: outbound._uri);
        _doneCompleter.completeError(error);
        return _closeFuture = new Future.error(error);
      }
    }

    Future finalize() {
      // In case of chunked encoding (and gzip), handle remaining gzip data and
      // append the 'footer' for chunked encoding.
      if (chunked) {
        if (_gzip) {
          _gzipAdd = socket.add;
          if (_gzipBufferLength > 0) {
            _gzipSink.add(
                new Uint8List.view(_gzipBuffer.buffer, 0, _gzipBufferLength));
          }
          _gzipBuffer = null;
          _gzipSink.close();
          _gzipAdd = null;
        }
        _addChunk(_chunkHeader(0), socket.add);
      }
      // Add any remaining data in the buffer.
      if (_length > 0) {
        socket.add(new Uint8List.view(_buffer.buffer, 0, _length));
      }
      // Clear references, for better GC.
      _buffer = null;
      // And finally flush it. As we support keep-alive, never close it from
      // here. Once the socket is flushed, we'll be able to reuse it (signaled
      // by the 'done' future).
      return socket.flush().then((_) {
        _doneCompleter.complete(socket);
        return outbound;
      }, onError: (error, stackTrace) {
        _doneCompleter.completeError(error, stackTrace);
        if (_ignoreError(error)) {
          return outbound;
        } else {
          throw error;
        }
      });
    }

    var future = writeHeaders();
    if (future != null) {
      return _closeFuture = future.whenComplete(finalize);
    }
    return _closeFuture = finalize();
  }

  Future<Socket> get done => _doneCompleter.future;

  void setHeader(List<int> data, int length) {
    assert(_length == 0);
    _buffer = data;
    _length = length;
  }

  void set gzip(bool value) {
    _gzip = value;
    if (_gzip) {
      _gzipBuffer = new Uint8List(_OUTGOING_BUFFER_SIZE);
      assert(_gzipSink == null);
      _gzipSink = new ZLibEncoder(gzip: true)
          .startChunkedConversion(new _HttpGZipSink((data) {
        // We are closing down prematurely, due to an error. Discard.
        if (_gzipAdd == null) return;
        _addChunk(_chunkHeader(data.length), _gzipAdd);
        _pendingChunkedFooter = 2;
        _addChunk(data, _gzipAdd);
      }));
    }
  }

  bool _ignoreError(error) =>
      (error is SocketException || error is TlsException) &&
      outbound is HttpResponse;

  void _addGZipChunk(List<int> chunk, void add(List<int> data)) {
    if (!outbound.bufferOutput) {
      add(chunk);
      return;
    }
    if (chunk.length > _gzipBuffer.length - _gzipBufferLength) {
      add(new Uint8List.view(_gzipBuffer.buffer, 0, _gzipBufferLength));
      _gzipBuffer = new Uint8List(_OUTGOING_BUFFER_SIZE);
      _gzipBufferLength = 0;
    }
    if (chunk.length > _OUTGOING_BUFFER_SIZE) {
      add(chunk);
    } else {
      _gzipBuffer.setRange(
          _gzipBufferLength, _gzipBufferLength + chunk.length, chunk);
      _gzipBufferLength += chunk.length;
    }
  }

  void _addChunk(List<int> chunk, void add(List<int> data)) {
    if (!outbound.bufferOutput) {
      if (_buffer != null) {
        // If _buffer is not null, we have not written the header yet. Write
        // it now.
        add(new Uint8List.view(_buffer.buffer, 0, _length));
        _buffer = null;
        _length = 0;
      }
      add(chunk);
      return;
    }
    if (chunk.length > _buffer.length - _length) {
      add(new Uint8List.view(_buffer.buffer, 0, _length));
      _buffer = new Uint8List(_OUTGOING_BUFFER_SIZE);
      _length = 0;
    }
    if (chunk.length > _OUTGOING_BUFFER_SIZE) {
      add(chunk);
    } else {
      _buffer.setRange(_length, _length + chunk.length, chunk);
      _length += chunk.length;
    }
  }

  List<int> _chunkHeader(int length) {
    const hexDigits = const [
      0x30,
      0x31,
      0x32,
      0x33,
      0x34,
      0x35,
      0x36,
      0x37,
      0x38,
      0x39,
      0x41,
      0x42,
      0x43,
      0x44,
      0x45,
      0x46
    ];
    if (length == 0) {
      if (_pendingChunkedFooter == 2) return _footerAndChunk0Length;
      return _chunk0Length;
    }
    int size = _pendingChunkedFooter;
    int len = length;
    // Compute a fast integer version of (log(length + 1) / log(16)).ceil().
    while (len > 0) {
      size++;
      len >>= 4;
    }
    var footerAndHeader = new Uint8List(size + 2);
    if (_pendingChunkedFooter == 2) {
      footerAndHeader[0] = _CharCode.CR;
      footerAndHeader[1] = _CharCode.LF;
    }
    int index = size;
    while (index > _pendingChunkedFooter) {
      footerAndHeader[--index] = hexDigits[length & 15];
      length = length >> 4;
    }
    footerAndHeader[size + 0] = _CharCode.CR;
    footerAndHeader[size + 1] = _CharCode.LF;
    return footerAndHeader;
  }
}

class _HttpClientConnection {
  final String key;
  final Socket _socket;
  final bool _proxyTunnel;
  final SecurityContext _context;
  final _HttpParser _httpParser;
  StreamSubscription _subscription;
  final _HttpClient _httpClient;
  bool _dispose = false;
  Timer _idleTimer;
  bool closed = false;
  Uri _currentUri;

  Completer<_HttpIncoming> _nextResponseCompleter;
  Future<Socket> _streamFuture;

  _HttpClientConnection(this.key, this._socket, this._httpClient,
      [this._proxyTunnel = false, this._context])
      : _httpParser = new _HttpParser.responseParser() {
    _httpParser.listenToStream(_socket);

    // Set up handlers on the parser here, so we are sure to get 'onDone' from
    // the parser.
    _subscription = _httpParser.listen((incoming) {
      // Only handle one incoming response at the time. Keep the
      // stream paused until the response have been processed.
      _subscription.pause();
      // We assume the response is not here, until we have send the request.
      if (_nextResponseCompleter == null) {
        throw new HttpException(
            "Unexpected response (unsolicited response without request).",
            uri: _currentUri);
      }

      // Check for status code '100 Continue'. In that case just
      // consume that response as the final response will follow
      // it. There is currently no API for the client to wait for
      // the '100 Continue' response.
      if (incoming.statusCode == 100) {
        incoming.drain().then((_) {
          _subscription.resume();
        }).catchError((error, [StackTrace stackTrace]) {
          _nextResponseCompleter.completeError(
              new HttpException(error.message, uri: _currentUri), stackTrace);
          _nextResponseCompleter = null;
        });
      } else {
        _nextResponseCompleter.complete(incoming);
        _nextResponseCompleter = null;
      }
    }, onError: (error, [StackTrace stackTrace]) {
      if (_nextResponseCompleter != null) {
        _nextResponseCompleter.completeError(
            new HttpException(error.message, uri: _currentUri), stackTrace);
        _nextResponseCompleter = null;
      }
    }, onDone: () {
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
      throw new HttpException("Socket closed before request was sent",
          uri: uri);
    }
    _currentUri = uri;
    // Start with pausing the parser.
    _subscription.pause();
    _ProxyCredentials proxyCreds; // Credentials used to authorize proxy.
    _SiteCredentials creds; // Credentials used to authorize this request.
    var outgoing = new _HttpOutgoing(_socket);
    // Create new request object, wrapping the outgoing connection.
    var request =
        new _HttpClientRequest(outgoing, uri, method, proxy, _httpClient, this);
    // For the Host header an IPv6 address must be enclosed in []'s.
    var host = uri.host;
    if (host.contains(':')) host = "[$host]";
    request.headers
      ..host = host
      ..port = port
      .._add(HttpHeaders.ACCEPT_ENCODING, "gzip");
    if (_httpClient.userAgent != null) {
      request.headers._add('user-agent', _httpClient.userAgent);
    }
    if (proxy.isAuthenticated) {
      // If the proxy configuration contains user information use that
      // for proxy basic authorization.
      String auth = _CryptoUtils
          .bytesToBase64(UTF8.encode("${proxy.username}:${proxy.password}"));
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
      String auth = _CryptoUtils.bytesToBase64(UTF8.encode(uri.userInfo));
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
    _httpParser.isHead = method == "HEAD";
    _streamFuture = outgoing.done.then<Socket>((Socket s) {
      // Request sent, set up response completer.
      _nextResponseCompleter = new Completer();

      // Listen for response.
      _nextResponseCompleter.future.then((incoming) {
        _currentUri = null;
        incoming.dataDone.then((closing) {
          if (incoming.upgraded) {
            _httpClient._connectionClosed(this);
            startTimer();
            return;
          }
          if (closed) return;
          if (!closing &&
              !_dispose &&
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
                _HeaderValue.parse(authInfo[0], parameterSeparator: ',');
            var nextnonce = header.parameters["nextnonce"];
            if (nextnonce != null) proxyCreds.nonce = nextnonce;
          }
        }
        // For digest authentication check if the server requests the
        // client to start using a new nonce.
        if (creds != null && creds.scheme == _AuthenticationScheme.DIGEST) {
          var authInfo = incoming.headers["authentication-info"];
          if (authInfo != null && authInfo.length == 1) {
            var header =
                _HeaderValue.parse(authInfo[0], parameterSeparator: ',');
            var nextnonce = header.parameters["nextnonce"];
            if (nextnonce != null) creds.nonce = nextnonce;
          }
        }
        request._onIncoming(incoming);
      })
          // If we see a state error, we failed to get the 'first'
          // element.
          .catchError((error) {
        throw new HttpException("Connection closed before data was received",
            uri: uri);
      }, test: (error) => error is StateError).catchError((error, stackTrace) {
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

  Future<_HttpClientConnection> createProxyTunnel(String host, int port,
      _Proxy proxy, bool callback(X509Certificate certificate)) {
    _HttpClientRequest request =
        send(new Uri(host: host, port: port), port, "CONNECT", proxy);
    if (proxy.isAuthenticated) {
      // If the proxy configuration contains user information use that
      // for proxy basic authorization.
      String auth = _CryptoUtils
          .bytesToBase64(UTF8.encode("${proxy.username}:${proxy.password}"));
      request.headers.set(HttpHeaders.PROXY_AUTHORIZATION, "Basic $auth");
    }
    return request.close().then((response) {
      if (response.statusCode != HttpStatus.OK) {
        throw "Proxy failed to establish tunnel "
            "(${response.statusCode} ${response.reasonPhrase})";
      }
      var socket = (response as _HttpClientResponse)
          ._httpRequest
          ._httpClientConnection
          ._socket;
      return SecureSocket.secure(socket,
          host: host, context: _context, onBadCertificate: callback);
    }).then((secureSocket) {
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
    _idleTimer = new Timer(_httpClient.idleTimeout, () {
      _idleTimer = null;
      close();
    });
  }
}

class _ConnectionInfo {
  final _HttpClientConnection connection;
  final _Proxy proxy;

  _ConnectionInfo(this.connection, this.proxy);
}

class _ConnectionTarget {
  // Unique key for this connection target.
  final String key;
  final String host;
  final int port;
  final bool isSecure;
  final SecurityContext context;
  final Set<_HttpClientConnection> _idle = new HashSet();
  final Set<_HttpClientConnection> _active = new HashSet();
  final Queue _pending = new ListQueue();
  int _connecting = 0;

  _ConnectionTarget(
      this.key, this.host, this.port, this.isSecure, this.context);

  bool get isEmpty => _idle.isEmpty && _active.isEmpty && _connecting == 0;

  bool get hasIdle => _idle.isNotEmpty;

  bool get hasActive => _active.isNotEmpty || _connecting > 0;

  _HttpClientConnection takeIdle() {
    assert(hasIdle);
    _HttpClientConnection connection = _idle.first;
    _idle.remove(connection);
    connection.stopTimer();
    _active.add(connection);
    return connection;
  }

  _checkPending() {
    if (_pending.isNotEmpty) {
      _pending.removeFirst()();
    }
  }

  void addNewActive(_HttpClientConnection connection) {
    _active.add(connection);
  }

  void returnConnection(_HttpClientConnection connection) {
    assert(_active.contains(connection));
    _active.remove(connection);
    _idle.add(connection);
    connection.startTimer();
    _checkPending();
  }

  void connectionClosed(_HttpClientConnection connection) {
    assert(!_active.contains(connection) || !_idle.contains(connection));
    _active.remove(connection);
    _idle.remove(connection);
    _checkPending();
  }

  void close(bool force) {
    for (var c in _idle.toList()) {
      c.close();
    }
    if (force) {
      for (var c in _active.toList()) {
        c.destroy();
      }
    }
  }

  Future<_ConnectionInfo> connect(
      String uriHost, int uriPort, _Proxy proxy, _HttpClient client) {
    if (hasIdle) {
      var connection = takeIdle();
      client._connectionsChanged();
      return new Future.value(new _ConnectionInfo(connection, proxy));
    }
    if (client.maxConnectionsPerHost != null &&
        _active.length + _connecting >= client.maxConnectionsPerHost) {
      var completer = new Completer<_ConnectionInfo>();
      _pending.add(() {
        completer.complete(connect(uriHost, uriPort, proxy, client));
      });
      return completer.future;
    }
    var currentBadCertificateCallback = client._badCertificateCallback;

    bool callback(X509Certificate certificate) {
      if (currentBadCertificateCallback == null) return false;
      return currentBadCertificateCallback(certificate, uriHost, uriPort);
    }

    Future socketFuture = (isSecure && proxy.isDirect
        ? SecureSocket.connect(host, port,
            context: context, onBadCertificate: callback)
        : Socket.connect(host, port));
    _connecting++;
    return socketFuture.then((socket) {
      _connecting--;
      socket.setOption(SocketOption.TCP_NODELAY, true);
      var connection =
          new _HttpClientConnection(key, socket, client, false, context);
      if (isSecure && !proxy.isDirect) {
        connection._dispose = true;
        return connection
            .createProxyTunnel(uriHost, uriPort, proxy, callback)
            .then((tunnel) {
          client
              ._getConnectionTarget(uriHost, uriPort, true)
              .addNewActive(tunnel);
          return new _ConnectionInfo(tunnel, proxy);
        });
      } else {
        addNewActive(connection);
        return new _ConnectionInfo(connection, proxy);
      }
    }, onError: (error) {
      _connecting--;
      _checkPending();
      throw error;
    });
  }
}

typedef bool BadCertificateCallback(X509Certificate cr, String host, int port);

class _HttpClient implements HttpClient {
  bool _closing = false;
  bool _closingForcefully = false;
  final Map<String, _ConnectionTarget> _connectionTargets =
      new HashMap<String, _ConnectionTarget>();
  final List<_Credentials> _credentials = [];
  final List<_ProxyCredentials> _proxyCredentials = [];
  final SecurityContext _context;
  Function _authenticate;
  Function _authenticateProxy;
  Function _findProxy = HttpClient.findProxyFromEnvironment;
  Duration _idleTimeout = const Duration(seconds: 15);
  BadCertificateCallback _badCertificateCallback;

  Duration get idleTimeout => _idleTimeout;

  int maxConnectionsPerHost;

  bool autoUncompress = true;

  String userAgent = _getHttpVersion();

  _HttpClient(this._context);

  void set idleTimeout(Duration timeout) {
    _idleTimeout = timeout;
    for (var c in _connectionTargets.values) {
      for (var idle in c._idle) {
        // Reset timer. This is fine, as it's not happening often.
        idle.stopTimer();
        idle.startTimer();
      }
    }
  }

  set badCertificateCallback(
      bool callback(X509Certificate cert, String host, int port)) {
    _badCertificateCallback = callback;
  }

  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    const int hashMark = 0x23;
    const int questionMark = 0x3f;
    int fragmentStart = path.length;
    int queryStart = path.length;
    for (int i = path.length - 1; i >= 0; i--) {
      var char = path.codeUnitAt(i);
      if (char == hashMark) {
        fragmentStart = i;
        queryStart = i;
      } else if (char == questionMark) {
        queryStart = i;
      }
    }
    String query = null;
    if (queryStart < fragmentStart) {
      query = path.substring(queryStart + 1, fragmentStart);
      path = path.substring(0, queryStart);
    }
    Uri uri = new Uri(
        scheme: "http", host: host, port: port, path: path, query: query);
    return _openUrl(method, uri);
  }

  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _openUrl(method, url);

  Future<HttpClientRequest> get(String host, int port, String path) =>
      open("get", host, port, path);

  Future<HttpClientRequest> getUrl(Uri url) => _openUrl("get", url);

  Future<HttpClientRequest> post(String host, int port, String path) =>
      open("post", host, port, path);

  Future<HttpClientRequest> postUrl(Uri url) => _openUrl("post", url);

  Future<HttpClientRequest> put(String host, int port, String path) =>
      open("put", host, port, path);

  Future<HttpClientRequest> putUrl(Uri url) => _openUrl("put", url);

  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open("delete", host, port, path);

  Future<HttpClientRequest> deleteUrl(Uri url) => _openUrl("delete", url);

  Future<HttpClientRequest> head(String host, int port, String path) =>
      open("head", host, port, path);

  Future<HttpClientRequest> headUrl(Uri url) => _openUrl("head", url);

  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open("patch", host, port, path);

  Future<HttpClientRequest> patchUrl(Uri url) => _openUrl("patch", url);

  void close({bool force: false}) {
    _closing = true;
    _closingForcefully = force;
    _closeConnections(_closingForcefully);
    assert(!_connectionTargets.values.any((s) => s.hasIdle));
    assert(
        !force || !_connectionTargets.values.any((s) => s._active.isNotEmpty));
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

  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials cr) {
    _proxyCredentials.add(new _ProxyCredentials(host, port, realm, cr));
  }

  set findProxy(String f(Uri uri)) => _findProxy = f;

  Future<_HttpClientRequest> _openUrl(String method, Uri uri) {
    // Ignore any fragments on the request URI.
    uri = uri.removeFragment();

    if (method == null) {
      throw new ArgumentError(method);
    }
    if (method != "CONNECT") {
      if (uri.host.isEmpty) {
        throw new ArgumentError("No host specified in URI $uri");
      } else if (uri.scheme != "http" && uri.scheme != "https") {
        throw new ArgumentError(
            "Unsupported scheme '${uri.scheme}' in URI $uri");
      }
    }

    bool isSecure = (uri.scheme == "https");
    int port = uri.port;
    if (port == 0) {
      port = isSecure
          ? HttpClient.DEFAULT_HTTPS_PORT
          : HttpClient.DEFAULT_HTTP_PORT;
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
        .then((_ConnectionInfo info) {
      _HttpClientRequest send(_ConnectionInfo info) {
        return info.connection
            .send(uri, port, method.toUpperCase(), info.proxy);
      }

      // If the connection was closed before the request was sent, create
      // and use another connection.
      if (info.connection.closed) {
        return _getConnection(uri.host, port, proxyConf, isSecure).then(send);
      }
      return send(info);
    });
  }

  Future<_HttpClientRequest> _openUrlFromRequest(
      String method, Uri uri, _HttpClientRequest previous) {
    // If the new URI is relative (to either '/' or some sub-path),
    // construct a full URI from the previous one.
    Uri resolved = previous.uri.resolveUri(uri);
    return _openUrl(method, resolved).then((_HttpClientRequest request) {
      request
        // Only follow redirects if initial request did.
        ..followRedirects = previous.followRedirects
        // Allow same number of redirects.
        ..maxRedirects = previous.maxRedirects;
      // Copy headers.
      for (var header in previous.headers._headers.keys) {
        if (request.headers[header] == null) {
          request.headers.set(header, previous.headers[header]);
        }
      }
      return request
        ..headers.chunkedTransferEncoding = false
        ..contentLength = 0;
    });
  }

  // Return a live connection to the idle pool.
  void _returnConnection(_HttpClientConnection connection) {
    _connectionTargets[connection.key].returnConnection(connection);
    _connectionsChanged();
  }

  // Remove a closed connection from the active set.
  void _connectionClosed(_HttpClientConnection connection) {
    connection.stopTimer();
    var connectionTarget = _connectionTargets[connection.key];
    if (connectionTarget != null) {
      connectionTarget.connectionClosed(connection);
      if (connectionTarget.isEmpty) {
        _connectionTargets.remove(connection.key);
      }
      _connectionsChanged();
    }
  }

  void _connectionsChanged() {
    if (_closing) {
      _closeConnections(_closingForcefully);
    }
  }

  void _closeConnections(bool force) {
    for (var connectionTarget in _connectionTargets.values.toList()) {
      connectionTarget.close(force);
    }
  }

  _ConnectionTarget _getConnectionTarget(String host, int port, bool isSecure) {
    String key = _HttpClientConnection.makeKey(isSecure, host, port);
    return _connectionTargets.putIfAbsent(key, () {
      return new _ConnectionTarget(key, host, port, isSecure, _context);
    });
  }

  // Get a new _HttpClientConnection, from the matching _ConnectionTarget.
  Future<_ConnectionInfo> _getConnection(String uriHost, int uriPort,
      _ProxyConfiguration proxyConf, bool isSecure) {
    Iterator<_Proxy> proxies = proxyConf.proxies.iterator;

    Future<_ConnectionInfo> connect(error) {
      if (!proxies.moveNext()) return new Future.error(error);
      _Proxy proxy = proxies.current;
      String host = proxy.isDirect ? uriHost : proxy.host;
      int port = proxy.isDirect ? uriPort : proxy.port;
      return _getConnectionTarget(host, port, isSecure)
          .connect(uriHost, uriPort, proxy, this)
          // On error, continue with next proxy.
          .catchError(connect);
    }

    // Make sure we go through the event loop before taking a
    // connection from the pool. For long-running synchronous code the
    // server might have closed the connection, so this lowers the
    // probability of getting a connection that was already closed.
    return new Future<_ConnectionInfo>(
        () => connect(new HttpException("No proxies given")));
  }

  _SiteCredentials _findCredentials(Uri url, [_AuthenticationScheme scheme]) {
    // Look for credentials.
    _SiteCredentials cr =
        _credentials.fold(null, (_SiteCredentials prev, value) {
      var siteCredentials = value as _SiteCredentials;
      if (siteCredentials.applies(url, scheme)) {
        if (prev == null) return value;
        return siteCredentials.uri.path.length > prev.uri.path.length
            ? siteCredentials
            : prev;
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
    return null;
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

  static String _findProxyFromEnvironment(
      Uri url, Map<String, String> environment) {
    checkNoProxy(String option) {
      if (option == null) return null;
      Iterator<String> names = option.split(",").map((s) => s.trim()).iterator;
      while (names.moveNext()) {
        var name = names.current;
        if ((name.startsWith("[") &&
                name.endsWith("]") &&
                "[${url.host}]" == name) ||
            (name.isNotEmpty && url.host.endsWith(name))) {
          return "DIRECT";
        }
      }
      return null;
    }

    checkProxy(String option) {
      if (option == null) return null;
      option = option.trim();
      if (option.isEmpty) return null;
      int pos = option.indexOf("://");
      if (pos >= 0) {
        option = option.substring(pos + 3);
      }
      pos = option.indexOf("/");
      if (pos >= 0) {
        option = option.substring(0, pos);
      }
      // Add default port if no port configured.
      if (option.indexOf("[") == 0) {
        var pos = option.lastIndexOf(":");
        if (option.indexOf("]") > pos) option = "$option:1080";
      } else {
        if (option.indexOf(":") == -1) option = "$option:1080";
      }
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

class _HttpConnection extends LinkedListEntry<_HttpConnection>
    with _ServiceObject {
  static const _ACTIVE = 0;
  static const _IDLE = 1;
  static const _CLOSING = 2;
  static const _DETACHED = 3;

  // Use HashMap, as we don't need to keep order.
  static Map<int, _HttpConnection> _connections =
      new HashMap<int, _HttpConnection>();

  final /*_ServerSocket*/ _socket;
  final _HttpServer _httpServer;
  final _HttpParser _httpParser;
  int _state = _IDLE;
  StreamSubscription _subscription;
  bool _idleMark = false;
  Future _streamFuture;

  _HttpConnection(this._socket, this._httpServer)
      : _httpParser = new _HttpParser.requestParser() {
    try {
      _socket._owner = this;
    } catch (_) {
      print(_);
    }
    _connections[_serviceId] = this;
    _httpParser.listenToStream(_socket as Object/*=Socket*/);
    _subscription = _httpParser.listen((incoming) {
      _httpServer._markActive(this);
      // If the incoming was closed, close the connection.
      incoming.dataDone.then((closing) {
        if (closing) destroy();
      });
      // Only handle one incoming request at the time. Keep the
      // stream paused until the request has been send.
      _subscription.pause();
      _state = _ACTIVE;
      var outgoing = new _HttpOutgoing(_socket);
      var response = new _HttpResponse(
          incoming.uri,
          incoming.headers.protocolVersion,
          outgoing,
          _httpServer.defaultResponseHeaders,
          _httpServer.serverHeader);
      var request = new _HttpRequest(response, incoming, _httpServer, this);
      _streamFuture = outgoing.done.then((_) {
        response.deadline = null;
        if (_state == _DETACHED) return;
        if (response.persistentConnection &&
            request.persistentConnection &&
            incoming.fullBodyRead &&
            !_httpParser.upgrade &&
            !_httpServer.closed) {
          _state = _IDLE;
          _idleMark = false;
          _httpServer._markIdle(this);
          // Resume the subscription for incoming requests as the
          // request is now processed.
          _subscription.resume();
        } else {
          // Close socket, keep-alive not used or body sent before
          // received data was handled.
          destroy();
        }
      }, onError: (_) {
        destroy();
      });
      outgoing.ignoreBody = request.method == "HEAD";
      response._httpRequest = request;
      _httpServer._handleRequest(request);
    }, onDone: () {
      destroy();
    }, onError: (error) {
      // Ignore failed requests that was closed before headers was received.
      destroy();
    });
  }

  void markIdle() {
    _idleMark = true;
  }

  bool get isMarkedIdle => _idleMark;

  void destroy() {
    if (_state == _CLOSING || _state == _DETACHED) return;
    _state = _CLOSING;
    _socket.destroy();
    _httpServer._connectionClosed(this);
    _connections.remove(_serviceId);
  }

  Future<Socket> detachSocket() {
    _state = _DETACHED;
    // Remove connection from server.
    _httpServer._connectionClosed(this);

    _HttpDetachedIncoming detachedIncoming = _httpParser.detachIncoming();

    return _streamFuture.then((_) {
      _connections.remove(_serviceId);
      return new _DetachedSocket(_socket, detachedIncoming);
    });
  }

  HttpConnectionInfo get connectionInfo => _HttpConnectionInfo.create(_socket);

  bool get _isActive => _state == _ACTIVE;
  bool get _isIdle => _state == _IDLE;
  bool get _isClosing => _state == _CLOSING;
  bool get _isDetached => _state == _DETACHED;

  String get _serviceTypePath => 'io/http/serverconnections';
  String get _serviceTypeName => 'HttpServerConnection';

  Map _toJSON(bool ref) {
    var name = "${_socket.address.host}:${_socket.port} <-> "
        "${_socket.remoteAddress.host}:${_socket.remotePort}";
    var r = <String, dynamic>{
      'id': _servicePath,
      'type': _serviceType(ref),
      'name': name,
      'user_name': name,
    };
    if (ref) {
      return r;
    }
    r['server'] = _httpServer._toJSON(true);
    try {
      r['socket'] = _socket._toJSON(true);
    } catch (_) {
      r['socket'] = {
        'id': _servicePath,
        'type': '@Socket',
        'name': 'UserSocket',
        'user_name': 'UserSocket',
      };
    }
    switch (_state) {
      case _ACTIVE:
        r['state'] = "Active";
        break;
      case _IDLE:
        r['state'] = "Idle";
        break;
      case _CLOSING:
        r['state'] = "Closing";
        break;
      case _DETACHED:
        r['state'] = "Detached";
        break;
      default:
        r['state'] = 'Unknown';
        break;
    }
    return r;
  }
}

// HTTP server waiting for socket connections.
class _HttpServer extends Stream<HttpRequest>
    with _ServiceObject
    implements HttpServer {
  // Use default Map so we keep order.
  static Map<int, _HttpServer> _servers = new Map<int, _HttpServer>();

  String serverHeader;
  final HttpHeaders defaultResponseHeaders = _initDefaultResponseHeaders();
  bool autoCompress = false;

  Duration _idleTimeout;
  Timer _idleTimer;

  static Future<HttpServer> bind(
      address, int port, int backlog, bool v6Only, bool shared) {
    return ServerSocket
        .bind(address, port, backlog: backlog, v6Only: v6Only, shared: shared)
        .then((socket) {
      return new _HttpServer._(socket, true);
    });
  }

  static Future<HttpServer> bindSecure(
      address,
      int port,
      SecurityContext context,
      int backlog,
      bool v6Only,
      bool requestClientCertificate,
      bool shared) {
    return SecureServerSocket
        .bind(address, port, context,
            backlog: backlog,
            v6Only: v6Only,
            requestClientCertificate: requestClientCertificate,
            shared: shared)
        .then((socket) {
      return new _HttpServer._(socket, true);
    });
  }

  _HttpServer._(this._serverSocket, this._closeServer) {
    _controller =
        new StreamController<HttpRequest>(sync: true, onCancel: close);
    idleTimeout = const Duration(seconds: 120);
    _servers[_serviceId] = this;
    _serverSocket._owner = this;
  }

  _HttpServer.listenOn(this._serverSocket) : _closeServer = false {
    _controller =
        new StreamController<HttpRequest>(sync: true, onCancel: close);
    idleTimeout = const Duration(seconds: 120);
    _servers[_serviceId] = this;
    try {
      _serverSocket._owner = this;
    } catch (_) {}
  }

  static HttpHeaders _initDefaultResponseHeaders() {
    var defaultResponseHeaders = new _HttpHeaders('1.1');
    defaultResponseHeaders.contentType = ContentType.TEXT;
    defaultResponseHeaders.set('X-Frame-Options', 'SAMEORIGIN');
    defaultResponseHeaders.set('X-Content-Type-Options', 'nosniff');
    defaultResponseHeaders.set('X-XSS-Protection', '1; mode=block');
    return defaultResponseHeaders;
  }

  Duration get idleTimeout => _idleTimeout;

  void set idleTimeout(Duration duration) {
    if (_idleTimer != null) {
      _idleTimer.cancel();
      _idleTimer = null;
    }
    _idleTimeout = duration;
    if (_idleTimeout != null) {
      _idleTimer = new Timer.periodic(_idleTimeout, (_) {
        for (var idle in _idleConnections.toList()) {
          if (idle.isMarkedIdle) {
            idle.destroy();
          } else {
            idle.markIdle();
          }
        }
      });
    }
  }

  StreamSubscription<HttpRequest> listen(void onData(HttpRequest event),
      {Function onError, void onDone(), bool cancelOnError}) {
    _serverSocket.listen((Socket socket) {
      socket.setOption(SocketOption.TCP_NODELAY, true);
      // Accept the client connection.
      _HttpConnection connection = new _HttpConnection(socket, this);
      _idleConnections.add(connection);
    }, onError: (error, stackTrace) {
      // Ignore HandshakeExceptions as they are bound to a single request,
      // and are not fatal for the server.
      if (error is! HandshakeException) {
        _controller.addError(error, stackTrace);
      }
    }, onDone: _controller.close);
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future close({bool force: false}) {
    closed = true;
    Future result;
    if (_serverSocket != null && _closeServer) {
      result = _serverSocket.close();
    } else {
      result = new Future.value();
    }
    idleTimeout = null;
    if (force) {
      for (var c in _activeConnections.toList()) {
        c.destroy();
      }
      assert(_activeConnections.isEmpty);
    }
    for (var c in _idleConnections.toList()) {
      c.destroy();
    }
    _maybePerformCleanup();
    return result;
  }

  void _maybePerformCleanup() {
    if (closed &&
        _idleConnections.isEmpty &&
        _activeConnections.isEmpty &&
        _sessionManagerInstance != null) {
      _sessionManagerInstance.close();
      _sessionManagerInstance = null;
      _servers.remove(_serviceId);
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

  void _handleRequest(_HttpRequest request) {
    if (!closed) {
      _controller.add(request);
    } else {
      request._httpConnection.destroy();
    }
  }

  void _connectionClosed(_HttpConnection connection) {
    // Remove itself from either idle or active connections.
    connection.unlink();
    _maybePerformCleanup();
  }

  void _markIdle(_HttpConnection connection) {
    _activeConnections.remove(connection);
    _idleConnections.add(connection);
  }

  void _markActive(_HttpConnection connection) {
    _idleConnections.remove(connection);
    _activeConnections.add(connection);
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
    result.total = _activeConnections.length + _idleConnections.length;
    _activeConnections.forEach((_HttpConnection conn) {
      if (conn._isActive) {
        result.active++;
      } else {
        assert(conn._isClosing);
        result.closing++;
      }
    });
    _idleConnections.forEach((_HttpConnection conn) {
      result.idle++;
      assert(conn._isIdle);
    });
    return result;
  }

  String get _serviceTypePath => 'io/http/servers';
  String get _serviceTypeName => 'HttpServer';

  Map<String, dynamic> _toJSON(bool ref) {
    var r = <String, dynamic>{
      'id': _servicePath,
      'type': _serviceType(ref),
      'name': '${address.host}:$port',
      'user_name': '${address.host}:$port',
    };
    if (ref) {
      return r;
    }
    try {
      r['socket'] = _serverSocket._toJSON(true);
    } catch (_) {
      r['socket'] = {
        'id': _servicePath,
        'type': '@Socket',
        'name': 'UserSocket',
        'user_name': 'UserSocket',
      };
    }
    r['port'] = port;
    r['address'] = address.host;
    r['active'] = _activeConnections.map((c) => c._toJSON(true)).toList();
    r['idle'] = _idleConnections.map((c) => c._toJSON(true)).toList();
    r['closed'] = closed;
    return r;
  }

  _HttpSessionManager _sessionManagerInstance;

  // Indicated if the http server has been closed.
  bool closed = false;

  // The server listen socket. Untyped as it can be both ServerSocket and
  // SecureServerSocket.
  final dynamic /*ServerSocket|SecureServerSocket*/ _serverSocket;
  final bool _closeServer;

  // Set of currently connected clients.
  final LinkedList<_HttpConnection> _activeConnections =
      new LinkedList<_HttpConnection>();
  final LinkedList<_HttpConnection> _idleConnections =
      new LinkedList<_HttpConnection>();
  StreamController<HttpRequest> _controller;
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
          int colon = proxy.lastIndexOf(":");
          if (colon == -1 || colon == 0 || colon == proxy.length - 1) {
            throw new HttpException(
                "Invalid proxy configuration $configuration");
          }
          String host = proxy.substring(0, colon).trim();
          if (host.startsWith("[") && host.endsWith("]")) {
            host = host.substring(1, host.length - 1);
          }
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

  const _ProxyConfiguration.direct() : proxies = const [const _Proxy.direct()];

  final List<_Proxy> proxies;
}

class _Proxy {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool isDirect;

  const _Proxy(this.host, this.port, this.username, this.password)
      : isDirect = false;
  const _Proxy.direct()
      : host = null,
        port = null,
        username = null,
        password = null,
        isDirect = true;

  bool get isAuthenticated => username != null;
}

class _HttpConnectionInfo implements HttpConnectionInfo {
  InternetAddress remoteAddress;
  int remotePort;
  int localPort;

  static _HttpConnectionInfo create(Socket socket) {
    if (socket == null) return null;
    try {
      _HttpConnectionInfo info = new _HttpConnectionInfo();
      return info
        ..remoteAddress = socket.remoteAddress
        ..remotePort = socket.remotePort
        ..localPort = socket.port;
    } catch (e) {}
    return null;
  }
}

class _DetachedSocket extends Stream<List<int>> implements Socket {
  final Stream<List<int>> _incoming;
  final Socket _socket;

  _DetachedSocket(this._socket, this._incoming);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _incoming.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Encoding get encoding => _socket.encoding;

  void set encoding(Encoding value) {
    _socket.encoding = value;
  }

  void write(Object obj) {
    _socket.write(obj);
  }

  void writeln([Object obj = ""]) {
    _socket.writeln(obj);
  }

  void writeCharCode(int charCode) {
    _socket.writeCharCode(charCode);
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    _socket.writeAll(objects, separator);
  }

  void add(List<int> bytes) {
    _socket.add(bytes);
  }

  void addError(error, [StackTrace stackTrace]) =>
      _socket.addError(error, stackTrace);

  Future addStream(Stream<List<int>> stream) {
    return _socket.addStream(stream);
  }

  void destroy() {
    _socket.destroy();
  }

  Future flush() => _socket.flush();

  Future<Socket> close() => _socket.close();

  Future<Socket> get done => _socket.done;

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  InternetAddress get remoteAddress => _socket.remoteAddress;

  int get remotePort => _socket.remotePort;

  bool setOption(SocketOption option, bool enabled) {
    return _socket.setOption(option, enabled);
  }

  Map _toJSON(bool ref) {
    return (_socket as dynamic)._toJSON(ref);
  }

  void set _owner(owner) {
    (_socket as dynamic)._owner = owner;
  }
}

class _AuthenticationScheme {
  final int _scheme;

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
      var hasher = new _MD5()
        ..add(UTF8.encode(creds.username))
        ..add([_CharCode.COLON])
        ..add(realm.codeUnits)
        ..add([_CharCode.COLON])
        ..add(UTF8.encode(creds.password));
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
    if (credentials.scheme == _AuthenticationScheme.DIGEST && nonce == null) {
      return;
    }
    credentials.authorize(this, request);
    used = true;
  }
}

class _ProxyCredentials extends _Credentials {
  String host;
  int port;

  _ProxyCredentials(this.host, this.port, realm, _HttpClientCredentials creds)
      : super(creds, realm);

  bool applies(_Proxy proxy, _AuthenticationScheme scheme) {
    if (scheme != null && credentials.scheme != scheme) return false;
    return proxy.host == host && proxy.port == port;
  }

  void authorize(HttpClientRequest request) {
    // Digest credentials cannot be used without a nonce from the
    // server.
    if (credentials.scheme == _AuthenticationScheme.DIGEST && nonce == null) {
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

class _HttpClientBasicCredentials extends _HttpClientCredentials
    implements HttpClientBasicCredentials {
  String username;
  String password;

  _HttpClientBasicCredentials(this.username, this.password);

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
}

class _HttpClientDigestCredentials extends _HttpClientCredentials
    implements HttpClientDigestCredentials {
  String username;
  String password;

  _HttpClientDigestCredentials(this.username, this.password);

  _AuthenticationScheme get scheme => _AuthenticationScheme.DIGEST;

  String authorization(_Credentials credentials, _HttpClientRequest request) {
    String requestUri = request._requestUri();
    _MD5 hasher = new _MD5()
      ..add(request.method.codeUnits)
      ..add([_CharCode.COLON])
      ..add(requestUri.codeUnits);
    var ha2 = _CryptoUtils.bytesToHex(hasher.close());

    String qop;
    String cnonce;
    String nc;
    var x;
    hasher = new _MD5()..add(credentials.ha1.codeUnits)..add([_CharCode.COLON]);
    if (credentials.qop == "auth") {
      qop = credentials.qop;
      cnonce = _CryptoUtils.bytesToHex(_IOCrypto.getRandomBytes(4));
      ++credentials.nonceCount;
      nc = credentials.nonceCount.toRadixString(16);
      nc = "00000000".substring(0, 8 - nc.length + 1) + nc;
      hasher
        ..add(credentials.nonce.codeUnits)
        ..add([_CharCode.COLON])
        ..add(nc.codeUnits)
        ..add([_CharCode.COLON])
        ..add(cnonce.codeUnits)
        ..add([_CharCode.COLON])
        ..add(credentials.qop.codeUnits)
        ..add([_CharCode.COLON])
        ..add(ha2.codeUnits);
    } else {
      hasher
        ..add(credentials.nonce.codeUnits)
        ..add([_CharCode.COLON])
        ..add(ha2.codeUnits);
    }
    var response = _CryptoUtils.bytesToHex(hasher.close());

    StringBuffer buffer = new StringBuffer()
      ..write('Digest ')
      ..write('username="$username"')
      ..write(', realm="${credentials.realm}"')
      ..write(', nonce="${credentials.nonce}"')
      ..write(', uri="$requestUri"')
      ..write(', algorithm="${credentials.algorithm}"');
    if (qop == "auth") {
      buffer
        ..write(', qop="$qop"')
        ..write(', cnonce="$cnonce"')
        ..write(', nc="$nc"');
    }
    buffer.write(', response="$response"');
    return buffer.toString();
  }

  void authorize(_Credentials credentials, HttpClientRequest request) {
    request.headers
        .set(HttpHeaders.AUTHORIZATION, authorization(credentials, request));
  }

  void authorizeProxy(
      _ProxyCredentials credentials, HttpClientRequest request) {
    request.headers.set(
        HttpHeaders.PROXY_AUTHORIZATION, authorization(credentials, request));
  }
}

class _RedirectInfo implements RedirectInfo {
  final int statusCode;
  final String method;
  final Uri location;
  const _RedirectInfo(this.statusCode, this.method, this.location);
}

String _getHttpVersion() {
  var version = Platform.version;
  // Only include major and minor version numbers.
  int index = version.indexOf('.', version.indexOf('.') + 1);
  version = version.substring(0, index);
  return 'Dart/$version (dart:io)';
}
