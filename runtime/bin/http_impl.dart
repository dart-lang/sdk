// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _HttpRequestResponseBase {
  _HttpRequestResponseBase(_HttpConnectionBase this._httpConnection)
      : _contentLength = -1,
        _keepAlive = false,
        _headers = new Map();

  int get contentLength() => _contentLength;
  bool get keepAlive() => _keepAlive;
  Map get headers() => _headers;

  void _setHeader(String name, String value) {
    _headers[name.toLowerCase()] = value;
  }

  bool _write(List<int> data, bool copyBuffer) {
    bool allWritten = true;
    if (data.length > 0) {
      if (_contentLength < 0) {
        // Write chunk size if transfer encoding is chunked.
        _writeHexString(data.length);
        _writeCRLF();
        _httpConnection._write(data, copyBuffer);
        allWritten = _writeCRLF();
      } else {
        allWritten = _httpConnection._write(data, copyBuffer);
      }
    }
    return allWritten;
  }

  bool _writeList(List<int> data, int offset, int count) {
    bool allWritten = true;
    if (count > 0) {
      if (_contentLength < 0) {
        // Write chunk size if transfer encoding is chunked.
        _writeHexString(count);
        _writeCRLF();
        _httpConnection._writeFrom(data, offset, count);
        allWritten = _writeCRLF();
      } else {
        allWritten = _httpConnection._writeFrom(data, offset, count);
      }
    }
    return allWritten;
  }

  bool _writeDone() {
    bool allWritten = true;
    if (_contentLength < 0) {
      // Terminate the content if transfer encoding is chunked.
      allWritten = _httpConnection._write(_Const.END_CHUNKED);
    }
    return allWritten;
  }

  bool _writeHeaders() {
    List<int> data;

    // Format headers.
    _headers.forEach((String name, String value) {
      data = name.charCodes();
      _httpConnection._write(data);
      data = ": ".charCodes();
      _httpConnection._write(data);
      data = value.charCodes();
      _httpConnection._write(data);
      _writeCRLF();
    });
    // Terminate header.
    return _writeCRLF();
  }

  bool _writeHexString(int x) {
    final List<int> hexDigits = [0x30, 0x31, 0x32, 0x33, 0x34,
                                 0x35, 0x36, 0x37, 0x38, 0x39,
                                 0x41, 0x42, 0x43, 0x44, 0x45, 0x46];
    ByteArray hex = new ByteArray(10);
    int index = hex.length;
    while (x > 0) {
      index--;
      hex[index] = hexDigits[x % 16];
      x = x >> 4;
    }
    return _httpConnection._writeFrom(hex, index, hex.length - index);
  }

  bool _writeCRLF() {
    final CRLF = const [_CharCode.CR, _CharCode.LF];
    return _httpConnection._write(CRLF);
  }

  bool _writeSP() {
    final SP = const [_CharCode.SP];
    return _httpConnection._write(SP);
  }

  _HttpConnectionBase _httpConnection;
  Map<String, String> _headers;

  // Length of the content body. If this is set to -1 (default value)
  // when starting to send data chunked transfer encoding will be
  // used.
  int _contentLength;
  bool _keepAlive;
}


// Parsed HTTP request providing information on the HTTP headers.
class _HttpRequest extends _HttpRequestResponseBase implements HttpRequest {
  _HttpRequest(_HttpConnection connection) : super(connection);

  String get method() => _method;
  String get uri() => _uri;
  String get path() => _path;
  String get queryString() => _queryString;
  Map get queryParameters() => _queryParameters;

  InputStream get inputStream() {
    if (_inputStream == null) {
      _inputStream = new _HttpInputStream(this);
    }
    return _inputStream;
  }

  void _onRequestStart(String method, String uri) {
    _method = method;
    _uri = uri;
    _parseRequestUri(uri);
  }

  void _onHeaderReceived(String name, String value) {
    _setHeader(name, value);
  }

  void _onHeadersComplete() {
    // Prepare for receiving data.
    _buffer = new _BufferList();
  }

  void _onDataReceived(List<int> data) {
    _buffer.add(data);
    if (_inputStream != null) _inputStream._dataReceived();
  }

  void _onDataEnd() {
    if (_inputStream != null) _inputStream._closeReceived();
  }

  // Escaped characters in uri are expected to have been parsed.
  void _parseRequestUri(String uri) {
    int position;
    position = uri.indexOf("?", 0);
    if (position == -1) {
      _path = _HttpUtils.decodeUrlEncodedString(_uri);
      _queryString = null;
      _queryParameters = new Map();
    } else {
      _path = _HttpUtils.decodeUrlEncodedString(_uri.substring(0, position));
      _queryString = _uri.substring(position + 1);
      _queryParameters = _HttpUtils.splitQueryString(_queryString);
    }
  }

  // Delegate functions for the HttpInputStream implementation.
  int _streamAvailable() {
    return _buffer.length;
  }

  List<int> _streamRead(int bytesToRead) {
    return _buffer.readBytes(bytesToRead);
  }

  int _streamReadInto(List<int> buffer, int offset, int len) {
    List<int> data = _buffer.readBytes(len);
    buffer.setRange(offset, data.length, data);
  }

  void _streamSetErrorHandler(callback(Exception e)) {
    _streamErrorHandler = callback;
  }

  String _method;
  String _uri;
  String _path;
  String _queryString;
  Map<String, String> _queryParameters;
  _HttpInputStream _inputStream;
  _BufferList _buffer;
  Function _streamErrorHandler;
}


// HTTP response object for sending a HTTP response.
class _HttpResponse extends _HttpRequestResponseBase implements HttpResponse {
  static final int START = 0;
  static final int HEADERS_SENT = 1;
  static final int DONE = 2;

  _HttpResponse(_HttpConnection httpConnection)
      : super(httpConnection),
        _statusCode = HttpStatus.OK,
        _state = START;

  void set contentLength(int contentLength) {
    if (_outputStream != null) throw new HttpException("Header already sent");
    _contentLength = contentLength;
  }

  void set keepAlive(bool keepAlive) {
    if (_outputStream != null) throw new HttpException("Header already sent");
    _keepAlive = keepAlive;
  }

  int get statusCode() => _statusCode;
  void set statusCode(int statusCode) {
    if (_outputStream != null) throw new HttpException("Header already sent");
    _statusCode = statusCode;
  }

  String get reasonPhrase() => _findReasonPhrase(_statusCode);
  void set reasonPhrase(String reasonPhrase) {
    if (_outputStream != null) throw new HttpException("Header already sent");
    _reasonPhrase = reasonPhrase;
  }

  Date get expires() => _expires;
  void set expires(Date expires) {
    if (_outputStream != null) throw new HttpException("Header already sent");
    _expires = expires;
    // Format "Expires" header with date in Greenwich Mean Time (GMT).
    String formatted =
        _HttpUtils.formatDate(_expires.changeTimeZone(new TimeZone.utc()));
    _setHeader("Expires", formatted);
  }

  // Set a header on the response. NOTE: If the same header is set
  // more than once only the last one will be part of the response.
  void setHeader(String name, String value) {
    if (_outputStream != null) return new HttpException("Header already sent");
    if (name.toLowerCase() == "expires") {
      expires = _HttpUtils.parseDate(value);
    } else {
      _setHeader(name, value);
    }
  }

  OutputStream get outputStream() {
    if (_state == DONE) throw new HttpException("Response closed");
    if (_outputStream == null) {
      // Ensure that headers are written.
      if (_state == START) {
        _writeHeader();
      }
      _outputStream = new _HttpOutputStream(this);
    }
    return _outputStream;
  }

  // Delegate functions for the HttpOutputStream implementation.
  bool _streamWrite(List<int> buffer, bool copyBuffer) {
    return _write(buffer, copyBuffer);
  }

  bool _streamWriteFrom(List<int> buffer, int offset, int len) {
    return _writeList(buffer, offset, len);
  }

  void _streamClose() {
    _httpConnection._phase = _HttpConnectionBase.PHASE_IDLE;
    _state = DONE;
    // Stop tracking no pending write events.
    _httpConnection._onNoPendingWrites = null;
    // Ensure that any trailing data is written.
    _writeDone();
    // If the connection is closing then close the output stream to
    // fully close the socket.
    if (_httpConnection._closing) {
      _httpConnection._close();
    }
  }

  void _streamSetNoPendingWriteHandler(callback()) {
    if (_state != DONE) {
      _httpConnection._onNoPendingWrites = callback;
    }
  }

  void _streamSetCloseHandler(callback()) {
    // TODO(sgjesse): Handle this.
  }

  void _streamSetErrorHandler(callback(Exception e)) {
    _streamErrorHandler = callback;
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

  bool _writeHeader() {
    List<int> data;

    // Write status line.
    _httpConnection._write(_Const.HTTP11);
    _writeSP();
    data = _statusCode.toString().charCodes();
    _httpConnection._write(data);
    _writeSP();
    data = reasonPhrase.charCodes();
    _httpConnection._write(data);
    _writeCRLF();

    // Determine the value of the "Connection" header
    // based on the keep alive state.
    setHeader("Connection", keepAlive ? "keep-alive" : "close");
    // Determine the value of the "Transfer-Encoding" header based on
    // whether the content length is known.
    if (_contentLength >= 0) {
      setHeader("Content-Length", _contentLength.toString());
    } else {
      setHeader("Transfer-Encoding", "chunked");
    }

    // Write headers.
    bool allWritten = _writeHeaders();
    _state = HEADERS_SENT;
    return allWritten;
  }

  // Response status code.
  int _statusCode;
  String _reasonPhrase;
  Date _expires;
  _HttpOutputStream _outputStream;
  int _state;
  Function _streamErrorHandler;
}


class _HttpInputStream extends _BaseDataInputStream implements InputStream {
  _HttpInputStream(_HttpRequestResponseBase this._requestOrResponse) {
    _checkScheduleCallbacks();
  }

  int available() {
    return _requestOrResponse._streamAvailable();
  }

  void pipe(OutputStream output, [bool close = true]) {
    _pipe(this, output, close: close);
  }

  List<int> _read(int bytesToRead) {
    List<int> result = _requestOrResponse._streamRead(bytesToRead);
    _checkScheduleCallbacks();
    return result;
  }

  void set onError(void callback(Exception e)) {
    _requestOrResponse._streamSetErrorHandler(callback);
  }

  int _readInto(List<int> buffer, int offset, int len) {
    int result = _requestOrResponse._streamReadInto(buffer, offset, len);
    _checkScheduleCallbacks();
    return result;
  }

  void _close() {
    // TODO(sgjesse): Handle this.
  }

  void _dataReceived() {
    super._dataReceived();
  }

  _HttpRequestResponseBase _requestOrResponse;
}


class _HttpOutputStream extends _BaseOutputStream implements OutputStream {
  _HttpOutputStream(_HttpRequestResponseBase this._requestOrResponse);

  bool write(List<int> buffer, [bool copyBuffer = true]) {
    return _requestOrResponse._streamWrite(buffer, copyBuffer);
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    return _requestOrResponse._streamWriteFrom(buffer, offset, len);
  }

  void close() {
    _requestOrResponse._streamClose();
  }

  void destroy() {
    throw "Not implemented";
  }

  void set onNoPendingWrites(void callback()) {
    _requestOrResponse._streamSetNoPendingWriteHandler(callback);
  }

  void set onClosed(void callback()) {
    _requestOrResponse._streamSetCloseHandler(callback);
  }

  void set onError(void callback(Exception e)) {
    _requestOrResponse._streamSetErrorHandler(callback);
  }

  _HttpRequestResponseBase _requestOrResponse;
}


class _HttpConnectionBase implements Hashable {
  static final int PHASE_IDLE = 0;
  static final int PHASE_REQUEST = 1;
  static final int PHASE_RESPONSE = 2;

  _HttpConnectionBase() : _phase = PHASE_IDLE,
                          _sendBuffers = new Queue(),
                          _httpParser = new _HttpParser();

  void _connectionEstablished(Socket socket) {
    _socket = socket;
    // Register handler for socket events.
    _socket.onData = _onData;
    _socket.onClosed = _onClosed;
    _socket.onError = _onError;
  }

  bool _write(List<int> data, [bool copyBuffer = false]) {
    if (!_error) {
      return _socket.outputStream.write(data, copyBuffer);
    }
  }

  bool _writeFrom(List<int> buffer, [int offset, int len]) {
    if (!_error) {
      return _socket.outputStream.writeFrom(buffer, offset, len);
    }
  }

  bool _close() {
    _socket.close();
  }

  void _onData() {
    int available = _socket.available();
    if (available == 0) {
      return;
    }

    ByteArray buffer = new ByteArray(available);
    int bytesRead = _socket.readList(buffer, 0, available);
    if (bytesRead > 0) {
      int parsed = _httpParser.writeList(buffer, 0, bytesRead);
      if (parsed != bytesRead) {
        // TODO(sgjesse): Error handling.
        _socket.close();
      }
    }
  }

  void _onClosed() {
    if (_phase != PHASE_IDLE) {
      // Client closed socket for writing. Socket should still be open
      // for writing the response.
      _closing = true;
    } else {
      // The connection is currently not used by any request just close it.
      _socket.close();
    }
    if (_onDisconnectCallback != null) _onDisconnectCallback();
  }

  void _onError(Exception e) {
    // If an error occurs, make sure to close the socket if one is associated.
    _error = true;
    if (_socket != null) {
      _socket.close();
    }
    if (_onErrorCallback != null) {
      _onErrorCallback(e);
    }
    _propagateError(e);
  }

  abstract void _propagateError(Exception e);

  void set onDisconnect(void callback()) {
    _onDisconnectCallback = callback;
  }

  void set onError(void callback(Exception e)) {
    _onErrorCallback = callback;
  }

  void set _onNoPendingWrites(void callback()) {
    if (!_error) {
      _socket.outputStream.onNoPendingWrites = callback;
    }
  }

  int hashCode() => _socket.hashCode();

  int _phase;
  Socket _socket;
  bool _closing = false;  // Is the socket closed by the client?
  bool _error = false;  // Is the socket closed due to an error?
  _HttpParser _httpParser;

  Queue _sendBuffers;

  Function _onDisconnectCallback;
  Function _onErrorCallback;
}


// HTTP server connection over a socket.
class _HttpConnection extends _HttpConnectionBase {
  _HttpConnection(HttpServer this._server) {
    // Register HTTP parser callbacks.
    _httpParser.requestStart =
        (method, uri) => _onRequestStart(method, uri);
    _httpParser.responseStart =
        (statusCode, reasonPhrase) =>
            _onResponseStart(statusCode, reasonPhrase);
    _httpParser.headerReceived =
        (name, value) => _onHeaderReceived(name, value);
    _httpParser.headersComplete = () => _onHeadersComplete();
    _httpParser.dataReceived = (data) => _onDataReceived(data);
    _httpParser.dataEnd = () => _onDataEnd();
    _httpParser.error = (e) => _onError(e);
  }

  void _onRequestStart(String method, String uri) {
    // Create new request and response objects for this request.
    _phase = PHASE_REQUEST;
    _request = new _HttpRequest(this);
    _response = new _HttpResponse(this);
    _request._onRequestStart(method, uri);
  }

  void _onResponseStart(int statusCode, String reasonPhrase) {
    // TODO(sgjesse): Error handling.
  }

  void _onHeaderReceived(String name, String value) {
    _request._onHeaderReceived(name, value);
  }

  void _onHeadersComplete() {
    _request._onHeadersComplete();
    _response.keepAlive = _httpParser.keepAlive;
    if (requestReceived != null) {
      requestReceived(_request, _response);
    }
  }

  void _onDataReceived(List<int> data) {
    _request._onDataReceived(data);
  }

  void _onDataEnd() {
    // Phase might already have gone to PHASE_IDLE if the response is
    // sent without waiting for request body.
    if (_phase == PHASE_REQUEST) {
      _phase = PHASE_RESPONSE;
    }
    _request._onDataEnd();
  }

  void _propagateError(Exception e) {
    if (_request != null && _request._streamErrorHandler != null) {
      _request._streamErrorHandler(e);
    }
    if (_response != null && _response._streamErrorHandler != null) {
      _response._streamErrorHandler(e);
    }
  }

  HttpServer _server;
  HttpRequest _request;
  HttpResponse _response;

  // Callbacks.
  var requestReceived;
}


// HTTP server waiting for socket connections. The connections are
// managed by the server and as requests are received the request.
class _HttpServer implements HttpServer {
  _HttpServer() : _connections = new Set<_HttpConnection>();

  void listen(String host, int port, [int backlog = 5]) {
    listenOn(new ServerSocket(host, port, backlog));
    _closeServer = true;
  }

  void listenOn(ServerSocket serverSocket) {
    void onConnection(Socket socket) {
      // Accept the client connection.
      _HttpConnection connection = new _HttpConnection(this);
      connection.requestReceived = _onRequest;
      connection.onDisconnect = () => _connections.remove(connection);
      connection.onError = (e) {
        if (_onError != null) _onError(e);
      };
      connection._connectionEstablished(socket);
      _connections.add(connection);
    }
    serverSocket.onConnection = onConnection;
    _server = serverSocket;
    _closeServer = false;
  }

  void close() {
    if (_server !== null && _closeServer) {
      _server.close();
    }
    _server = null;
    for (_HttpConnection connection in _connections) {
      connection._socket.close();
    }
    _connections.clear();
  }

  int get port() {
    if (_server === null) {
      throw new HttpException("The HttpServer is not listening on a port.");
    }
    return _server.port;
  }

  void set onError(void callback(Exception e)) {
    _onError = callback;
  }

  void set onRequest(void callback(HttpRequest, HttpResponse)) {
    _onRequest = callback;
  }

  ServerSocket _server;  // The server listen socket.
  bool _closeServer = false;
  Set<_HttpConnection> _connections;  // Set of currently connected clients.
  Function _onRequest;
  Function _onError;
}


class _HttpClientRequest
    extends _HttpRequestResponseBase implements HttpClientRequest {
  static final int START = 0;
  static final int HEADERS_SENT = 1;
  static final int DONE = 2;

  _HttpClientRequest(String this._method,
                     String this._uri,
                     _HttpClientConnection connection)
      : super(connection),
        _state = START {
    _connection = connection;
    // Default GET requests to have no content.
    if (_method == "GET") {
      _contentLength = 0;
    }
  }

  void set contentLength(int contentLength) => _contentLength = contentLength;
  void set keepAlive(bool keepAlive) => _keepAlive = keepAlive;

  String get host() => _host;
  void set host(String host) {
    _host = host;
    _updateHostHeader();
  }

  int get port() => _port;
  void set port(int port) {
    _port = port;
    _updateHostHeader();
  }

  void setHeader(String name, String value) {
    if (_state != START) throw new HttpException("Header already sent");
    if (name.toLowerCase() == "host") {
      int pos = value.indexOf(":");
      if (pos == -1) {
        _host = value;
        _port = HttpClient.DEFAULT_HTTP_PORT;
      } else {
        _host = value.substring(0, pos);
        if (pos + 1 == value.length) {
          _port = HttpClient.DEFAULT_HTTP_PORT;
        } else {
          _port = Math.parseInt(value.substring(pos + 1));
        }
      }
      _updateHostHeader();
      return;
    }
    _setHeader(name, value);
  }

  OutputStream get outputStream() {
    if (_state == DONE) throw new HttpException("Request closed");
    if (_outputStream == null) {
      // Ensure that headers are written.
      if (_state == START) {
        _writeHeader();
      }
      _outputStream = new _HttpOutputStream(this);
    }
    return _outputStream;
  }

  _updateHostHeader() {
    String portPart = _port == HttpClient.DEFAULT_HTTP_PORT ? "" : ":$_port";
    _setHeader("Host", "$host$portPart");
  }

  // Delegate functions for the HttpOutputStream implementation.
  bool _streamWrite(List<int> buffer, bool copyBuffer) {
    return _write(buffer, copyBuffer);
  }

  bool _streamWriteFrom(List<int> buffer, int offset, int len) {
    return _writeList(buffer, offset, len);
  }

  void _streamClose() {
    _state = DONE;
    // Stop tracking no pending write events.
    _httpConnection._onNoPendingWrites = null;
    // Ensure that any trailing data is written.
    _writeDone();
    // If the connection is closing then close the output stream to
    // fully close the socket.
    if (_httpConnection._closing) {
      _httpConnection._close();
    }
  }

  void _streamSetNoPendingWriteHandler(callback()) {
    if (_state != DONE) {
      _httpConnection._onNoPendingWrites = callback;
    }
  }

  void _streamSetCloseHandler(callback()) {
    // TODO(sgjesse): Handle this.
  }

  void _streamSetErrorHandler(callback(Exception e)) {
    _streamErrorHandler = callback;
  }

  void _writeHeader() {
    List<int> data;

    // Write request line.
    data = _method.toString().charCodes();
    _httpConnection._write(data);
    _writeSP();
    data = _uri.toString().charCodes();
    _httpConnection._write(data);
    _writeSP();
    _httpConnection._write(_Const.HTTP11);
    _writeCRLF();

    // Determine the value of the "Connection" header
    // based on the keep alive state.
    setHeader("Connection", keepAlive ? "keep-alive" : "close");
    // Determine the value of the "Transfer-Encoding" header based on
    // whether the content length is known.
    if (_contentLength >= 0) {
      setHeader("Content-Length", _contentLength.toString());
    } else {
      setHeader("Transfer-Encoding", "chunked");
    }

    // Write headers.
    _writeHeaders();
    _state = HEADERS_SENT;
  }

  String _method;
  String _uri;
  String _host;
  int _port;
  _HttpClientConnection _connection;
  _HttpOutputStream _outputStream;
  int _state;
  Function _streamErrorHandler;
}


class _HttpClientResponse
    extends _HttpRequestResponseBase implements HttpClientResponse {
  _HttpClientResponse(_HttpClientConnection connection)
      : super(connection) {
    _connection = connection;
  }

  int get statusCode() => _statusCode;
  String get reasonPhrase() => _reasonPhrase;

  Date get expires() {
    String str = _headers["expires"];
    if (str == null) return null;
    return _HttpUtils.parseDate(str);
  }

  Map get headers() => _headers;

  InputStream get inputStream() {
    if (_inputStream == null) {
      _inputStream = new _HttpInputStream(this);
    }
    return _inputStream;
  }

  void _onRequestStart(String method, String uri) {
    // TODO(sgjesse): Error handling
  }

  void _onResponseStart(int statusCode, String reasonPhrase) {
    _statusCode = statusCode;
    _reasonPhrase = reasonPhrase;
  }

  void _onHeaderReceived(String name, String value) {
    _setHeader(name, value);
  }

  void _onHeadersComplete() {
    _buffer = new _BufferList();
    if (_connection._onResponse != null) {
      _connection._onResponse(this);
    }
  }

  void _onDataReceived(List<int> data) {
    _buffer.add(data);
    if (_inputStream != null) _inputStream._dataReceived();
  }

  void _onDataEnd() {
    if (_inputStream != null) _inputStream._closeReceived();
  }

  // Delegate functions for the HttpInputStream implementation.
  int _streamAvailable() {
    return _buffer.length;
  }

  List<int> _streamRead(int bytesToRead) {
    return _buffer.readBytes(bytesToRead);
  }

  int _streamReadInto(List<int> buffer, int offset, int len) {
    List<int> data = _buffer.readBytes(len);
    buffer.setRange(offset, data.length, data);
    return data.length;
  }

  void _streamSetErrorHandler(callback(Exception e)) {
    _streamErrorHandler = callback;
  }

  int _statusCode;
  String _reasonPhrase;

  _HttpClientConnection _connection;
  _HttpInputStream _inputStream;
  _BufferList _buffer;
  Function _streamErrorHandler;
}


class _HttpClientConnection
    extends _HttpConnectionBase implements HttpClientConnection {
  _HttpClientConnection(_HttpClient this._client);

  void _connectionEstablished(_SocketConnection socketConn) {
    super._connectionEstablished(socketConn._socket);
    _socketConn = socketConn;
    // Register HTTP parser callbacks.
    _httpParser.requestStart =
        (method, uri) => _onRequestStart(method, uri);
    _httpParser.responseStart =
        (statusCode, reasonPhrase) =>
            _onResponseStart(statusCode, reasonPhrase);
    _httpParser.headerReceived =
        (name, value) => _onHeaderReceived(name, value);
    _httpParser.headersComplete = () => _onHeadersComplete();
    _httpParser.dataReceived = (data) => _onDataReceived(data);
    _httpParser.dataEnd = () => _onDataEnd();
    _httpParser.error = (e) => _onError(e);
    // Tell the HTTP parser the method it is expecting a response to.
    _httpParser.responseToMethod = _method;

    onDisconnect = _onDisconnected;
  }

  void _propagateError(Exception e) {
    if (_response != null && _response._streamErrorHandler != null) {
      _response._streamErrorHandler(e);
    }
  }

  HttpClientRequest open(String method, String uri) {
    _method = method;
    _request = new _HttpClientRequest(method, uri, this);
    _request.keepAlive = true;
    _response = new _HttpClientResponse(this);
    return _request;
  }

  void _onRequestStart(String method, String uri) {
    // TODO(sgjesse): Error handling.
  }

  void _onResponseStart(int statusCode, String reasonPhrase) {
    _response._onResponseStart(statusCode, reasonPhrase);
  }

  void _onHeaderReceived(String name, String value) {
    _response._onHeaderReceived(name, value);
  }

  void _onHeadersComplete() {
    _response._onHeadersComplete();
  }

  void _onDataReceived(List<int> data) {
    _response._onDataReceived(data);
  }

  void _onDataEnd() {
    onDisconnect = null;
    if (_response.headers["connection"] == "close") {
      _socket.close();
    } else {
      _client._returnSocketConnection(_socketConn);
    }
    _socket = null;
    _socketConn = null;
    _response._onDataEnd();
  }

  void set onRequest(void handler(HttpClientRequest request)) {
    _onRequest = handler;
  }

  void set onResponse(void handler(HttpClientResponse response)) {
    _onResponse = handler;
  }

  void _onDisconnected() {
    if (_onErrorCallback !== null) {
      _onErrorCallback(new HttpException(
          "Client disconnected before response was received."));
    }
  }

  Function _onRequest;
  Function _onResponse;

  _HttpClient _client;
  _SocketConnection _socketConn;
  HttpClientRequest _request;
  HttpClientResponse _response;
  String _method;

  // Callbacks.
  var requestReceived;
}


// Class for holding keep-alive sockets in the cache for the HTTP
// client together with the connection information.
class _SocketConnection {
  _SocketConnection(String this._host,
                    int this._port,
                    Socket this._socket);

  void _markReturned() {
    _socket.onData = null;
    _socket.onClosed = null;
    _socket.onError = null;
    _returnTime = new Date.now();
  }

  Duration _idleTime(Date now) => now.difference(_returnTime);

  int hashCode() => _socket.hashCode();

  String _host;
  int _port;
  Socket _socket;
  Date _returnTime;
}


class _HttpClient implements HttpClient {
  static final int DEFAULT_EVICTION_TIMEOUT = 60000;

  _HttpClient() : _openSockets = new Map(),
                  _activeSockets = new Set(),
                  _shutdown = false;

  HttpClientConnection open(
      String method, String host, int port, String path) {
    if (_shutdown) throw new HttpException("HttpClient shutdown");
    return _prepareHttpClientConnection(host, port, method, path);
  }

  HttpClientConnection openUrl(String method, Uri url) {
    if (url.scheme != "http") {
      throw new HttpException("Unsupported URL scheme ${url.scheme}");
    }
    if (url.userInfo != "") {
      throw new HttpException("Unsupported user info ${url.userInfo}");
    }
    int port = url.port == 0 ? HttpClient.DEFAULT_HTTP_PORT : url.port;
    String path;
    if (url.query != "") {
      if (url.fragment != "") {
        path = "${url.path}?${url.query}#${url.fragment}";
      } else {
        path = "${url.path}?${url.query}";
      }
    } else {
      path = url.path;
    }
    return open(method, url.domain, port, path);
  }

  HttpClientConnection get(String host, int port, String path) {
    return open("GET", host, port, path);
  }

  HttpClientConnection getUrl(Uri url) => openUrl("GET", url);

  HttpClientConnection post(String host, int port, String path) {
    return open("POST", host, port, path);
  }

  HttpClientConnection postUrl(Uri url) => openUrl("POST", url);

  void shutdown() {
     _openSockets.forEach((String key, Queue<_SocketConnection> connections) {
       while (!connections.isEmpty()) {
         _SocketConnection socketConn = connections.removeFirst();
         socketConn._socket.close();
       }
     });
     _activeSockets.forEach((_SocketConnection socketConn) {
       socketConn._socket.close();
     });
     if (_evictionTimer != null) {
       _evictionTimer.cancel();
     }
     _shutdown = true;
  }

  String _connectionKey(String host, int port) {
    return "$host:$port";
  }

  HttpClientConnection _prepareHttpClientConnection(
      String host, int port, String method, String path) {

    void _connectionOpened(_SocketConnection socketConn,
                           _HttpClientConnection connection) {
      connection._connectionEstablished(socketConn);
      HttpClientRequest request = connection.open(method, path);
      request.host = host;
      request.port = port;
      if (connection._onRequest != null) {
        connection._onRequest(request);
      } else {
        request.outputStream.close();
      }
    }

    _HttpClientConnection connection = new _HttpClientConnection(this);

    // If there are active connections for this key get the first one
    // otherwise create a new one.
    Queue socketConnections = _openSockets[_connectionKey(host, port)];
    if (socketConnections == null || socketConnections.isEmpty()) {
      Socket socket = new Socket(host, port);
      // Until the connection is established handle connection errors
      // here as the HttpClientConnection object is not yet associated
      // with the socket.
      socket.onError = (Exception e) {
        // Report the error through the HttpClientConnection object to
        // the client.
        connection._onError(e);
      };
      socket.onConnect = () {
        // When the connection is established, clear the error
        // callback as it will now be handled by the
        // HttpClientConnection object which will be associated with
        // the connected socket.
        socket.onError = null;
        _SocketConnection socketConn =
            new _SocketConnection(host, port, socket);
        _activeSockets.add(socketConn);
        _connectionOpened(socketConn, connection);
      };
    } else {
      _SocketConnection socketConn = socketConnections.removeFirst();
      _activeSockets.add(socketConn);
      new Timer(0, (ignored) => _connectionOpened(socketConn, connection));

      // Get rid of eviction timer if there are no more active connections.
      if (socketConnections.isEmpty()) {
        _evictionTimer.cancel();
        _evictionTimer = null;
      }
    }

    return connection;
  }

  void _returnSocketConnection(_SocketConnection socketConn) {
    // If the HTTP client is beeing shutdown don't return the connection.
    if (_shutdown) {
      socketConn._socket.close();
      return;
    };

    String key = _connectionKey(socketConn._host, socketConn._port);

    // Get or create the connection list for this key.
    Queue sockets = _openSockets[key];
    if (sockets == null) {
      sockets = new Queue();
      _openSockets[key] = sockets;
    }

    // If there is currently no eviction timer start one.
    if (_evictionTimer == null) {
      void _handleEviction(Timer timer) {
        Date now = new Date.now();
        _openSockets.forEach(
            void _(String key, Queue<_SocketConnection> connections) {
              // As returned connections are added at the head of the
              // list remove from the tail.
              while (!connections.isEmpty()) {
                _SocketConnection socketConn = connections.last();
                if (socketConn._idleTime(now).inMilliseconds >
                    DEFAULT_EVICTION_TIMEOUT) {
                  connections.removeLast();
                  socketConn._socket.close();
                } else {
                  break;
                }
              }
            });
      }
      _evictionTimer = new Timer.repeating(10000, _handleEviction);
    }

    // Return connection.
    _activeSockets.remove(socketConn);
    sockets.addFirst(socketConn);
    socketConn._markReturned();
  }

  Function _onOpen;
  Map<String, Queue<_SocketConnection>> _openSockets;
  Set<_SocketConnection> _activeSockets;
  Timer _evictionTimer;
  bool _shutdown;  // Has this HTTP client been shutdown?
}
