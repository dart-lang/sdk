// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Global constants.
class _Const {
  // Bytes for "HTTP/1.0".
  static final HTTP10 = const [72, 84, 84, 80, 47, 49, 46, 48];
  // Bytes for "HTTP/1.1".
  static final HTTP11 = const [72, 84, 84, 80, 47, 49, 46, 49];

  static final END_CHUNKED = const [0x30, 13, 10, 13, 10];
}

// Frequently used character codes.
class _CharCode {
  static final int HT = 9;
  static final int LF = 10;
  static final int CR = 13;
  static final int SP = 32;
  static final int COLON = 58;
}


// States of the HTTP parser state machine.
class _State {
  static final int START = 0;
  static final int METHOD_OR_HTTP_VERSION = 1;
  static final int REQUEST_LINE_METHOD = 2;
  static final int REQUEST_LINE_URI = 3;
  static final int REQUEST_LINE_HTTP_VERSION = 4;
  static final int REQUEST_LINE_ENDING = 5;
  static final int RESPONSE_LINE_STATUS_CODE = 6;
  static final int RESPONSE_LINE_REASON_PHRASE = 7;
  static final int RESPONSE_LINE_ENDING = 8;
  static final int HEADER_START = 9;
  static final int HEADER_FIELD = 10;
  static final int HEADER_VALUE_START = 11;
  static final int HEADER_VALUE = 12;
  static final int HEADER_VALUE_FOLDING_OR_ENDING = 13;
  static final int HEADER_VALUE_FOLD_OR_END = 14;
  static final int HEADER_ENDING = 15;
  static final int CHUNK_SIZE_STARTING_CR = 16;
  static final int CHUNK_SIZE_STARTING_LF = 17;
  static final int CHUNK_SIZE = 18;
  static final int CHUNK_SIZE_ENDING = 19;
  static final int CHUNKED_BODY_DONE_CR = 20;
  static final int CHUNKED_BODY_DONE_LF = 21;
  static final int BODY = 22;
}


/**
 * HTTP parser which parses the HTTP stream as data is supplied
 * through the writeList method. As the data is parsed the events
 *   RequestStart
 *   UriReceived
 *   HeaderReceived
 *   HeadersComplete
 *   DataReceived
 *   DataEnd
 * are generated.
 * Currently only HTTP requests with Content-Length header are supported.
 */
class HttpParser {
  HttpParser()
      : _state = _State.START,
        _failure = false,
        _headerField = new StringBuffer(),
        _headerValue = new StringBuffer(),
        _method_or_status_code = new StringBuffer(),
        _uri_or_reason_phrase = new StringBuffer();

  // From RFC 2616.
  // generic-message = start-line
  //                   *(message-header CRLF)
  //                   CRLF
  //                   [ message-body ]
  // start-line      = Request-Line | Status-Line
  // Request-Line    = Method SP Request-URI SP HTTP-Version CRLF
  // Status-Line     = HTTP-Version SP Status-Code SP Reason-Phrase CRLF
  // message-header  = field-name ":" [ field-value ]
  int writeList(List<int> buffer, int offset, int count) {
    int index = offset;
    int lastIndex = offset + count;
    while ((index < lastIndex) && !_failure) {
      int byte = buffer[index];
      switch (_state) {
        case _State.START:
          _contentLength = 0;
          _keepAlive = false;
          _chunked = false;

          if (byte == _Const.HTTP11[0]) {
            // Start parsing HTTP method.
            _httpVersionIndex = 1;
            _state = _State.METHOD_OR_HTTP_VERSION;
          } else {
            // Start parsing method.
            _method_or_status_code.addCharCode(byte);
            _state = _State.REQUEST_LINE_METHOD;
          }
          break;

        case _State.METHOD_OR_HTTP_VERSION:
          if (_httpVersionIndex < _Const.HTTP11.length &&
              byte == _Const.HTTP11[_httpVersionIndex]) {
            // Continue parsing HTTP version.
            _httpVersionIndex++;
          } else if (_httpVersionIndex == _Const.HTTP11.length &&
                     byte == _CharCode.SP) {
            // HTTP version parsed.
            _state = _State.RESPONSE_LINE_STATUS_CODE;
          } else {
            // Did not parse HTTP version. Expect method instead.
            for (int i = 0; i < _httpVersionIndex; i++) {
              _method_or_status_code.addCharCode(_Const.HTTP11[i]);
            }
            _state = _State.REQUEST_LINE_URI;
          }
          break;

        case _State.REQUEST_LINE_METHOD:
          if (byte == _CharCode.SP) {
            _state = _State.REQUEST_LINE_URI;
          } else {
            _method_or_status_code.addCharCode(byte);
          }
          break;

        case _State.REQUEST_LINE_URI:
          if (byte == _CharCode.SP) {
            _state = _State.REQUEST_LINE_HTTP_VERSION;
            _httpVersionIndex = 0;
          } else {
            _uri_or_reason_phrase.addCharCode(byte);
          }
          break;

        case _State.REQUEST_LINE_HTTP_VERSION:
          if (_httpVersionIndex < _Const.HTTP11.length) {
            _expect(byte, _Const.HTTP11[_httpVersionIndex]);
            _httpVersionIndex++;
          } else {
            _expect(byte, _CharCode.CR);
            _state = _State.REQUEST_LINE_ENDING;
          }
          break;

        case _State.REQUEST_LINE_ENDING:
          _expect(byte, _CharCode.LF);
          if (requestStart != null) {
            requestStart(_method_or_status_code.toString(),
                         _uri_or_reason_phrase.toString());
          }
          _method_or_status_code.clear();
          _uri_or_reason_phrase.clear();
          _state = _State.HEADER_START;
          break;

        case _State.RESPONSE_LINE_STATUS_CODE:
          if (byte == _CharCode.SP) {
            _state = _State.RESPONSE_LINE_REASON_PHRASE;
          } else {
            if (byte < 0x30 && 0x39 < byte) {
              _failure = true;
            } else {
              _method_or_status_code.addCharCode(byte);
            }
          }
          break;

        case _State.RESPONSE_LINE_REASON_PHRASE:
          if (byte == _CharCode.CR) {
            _state = _State.RESPONSE_LINE_ENDING;
          } else {
            _uri_or_reason_phrase.addCharCode(byte);
          }
          break;

        case _State.RESPONSE_LINE_ENDING:
          _expect(byte, _CharCode.LF);
          // TODO(sgjesse): Check for valid status code.
          if (responseStart != null) {
            responseStart(Math.parseInt(_method_or_status_code.toString()),
                          _uri_or_reason_phrase.toString());
          }
          _method_or_status_code.clear();
          _uri_or_reason_phrase.clear();
          _state = _State.HEADER_START;
          break;

        case _State.HEADER_START:
          if (byte == _CharCode.CR) {
            _state = _State.HEADER_ENDING;
          } else {
            // Start of new header field.
            _headerField.addCharCode(_toLowerCase(byte));
            _state = _State.HEADER_FIELD;
          }
          break;

        case _State.HEADER_FIELD:
          if (byte == _CharCode.COLON) {
            _state = _State.HEADER_VALUE_START;
          } else {
            _headerField.addCharCode(_toLowerCase(byte));
          }
          break;

        case _State.HEADER_VALUE_START:
          if (byte != _CharCode.SP && byte != _CharCode.HT) {
            // Start of new header value.
            _headerValue.addCharCode(byte);
            _state = _State.HEADER_VALUE;
          }
          break;

        case _State.HEADER_VALUE:
          if (byte == _CharCode.CR) {
            _state = _State.HEADER_VALUE_FOLDING_OR_ENDING;
          } else {
            _headerValue.addCharCode(byte);
          }
          break;

        case _State.HEADER_VALUE_FOLDING_OR_ENDING:
          _expect(byte, _CharCode.LF);
          _state = _State.HEADER_VALUE_FOLD_OR_END;
          break;

        case _State.HEADER_VALUE_FOLD_OR_END:
          if (byte == _CharCode.SP || byte == _CharCode.HT) {
            _state = _State.HEADER_VALUE_START;
          } else {
            String headerField = _headerField.toString();
            String headerValue =_headerValue.toString();
            // Ignore the Content-Length header if Transfer-Encoding
            // is chunked (RFC 2616 section 4.4)
            if (headerField == "content-length" && !_chunked) {
              _contentLength = Math.parseInt(headerValue);
            } else if (headerField == "connection" &&
                       headerValue == "keep-alive") {
              _keepAlive = true;
            } else if (headerField == "transfer-encoding" &&
                       headerValue == "chunked") {
              _chunked = true;
              _contentLength = -1;
            }
            if (headerReceived != null) {
              headerReceived(headerField, headerValue);
            }
            _headerField.clear();
            _headerValue.clear();

            if (byte == _CharCode.CR) {
              _state = _State.HEADER_ENDING;
            } else {
              // Start of new header field.
              _headerField.addCharCode(_toLowerCase(byte));
              _state = _State.HEADER_FIELD;
            }
          }
          break;

        case _State.HEADER_ENDING:
          _expect(byte, _CharCode.LF);
          if (headersComplete != null) headersComplete();

          // If there is no data get ready to process the next request.
          if (_chunked) {
            _state = _State.CHUNK_SIZE;
            _remainingContent = 0;
          } else if (_contentLength == 0) {
            if (dataEnd != null) dataEnd();
            _state = _State.START;
          } else if (_contentLength > 0) {
            _remainingContent = _contentLength;
            _state = _State.BODY;
          } else {
            // TODO(sgjesse): Error handling.
          }
          break;

        case _State.CHUNK_SIZE_STARTING_CR:
          _expect(byte, _CharCode.CR);
          _state = _State.CHUNK_SIZE_STARTING_LF;
          break;

        case _State.CHUNK_SIZE_STARTING_LF:
          _expect(byte, _CharCode.LF);
          _state = _State.CHUNK_SIZE;
          break;

        case _State.CHUNK_SIZE:
          if (byte == _CharCode.CR) {
            _state = _State.CHUNK_SIZE_ENDING;
          } else {
            int value = _expectHexDigit(byte);
            _remainingContent = _remainingContent * 16 + value;
          }
          break;

        case _State.CHUNK_SIZE_ENDING:
          _expect(byte, _CharCode.LF);
          if (_remainingContent > 0) {
            _state = _State.BODY;
          } else {
            _state = _State.CHUNKED_BODY_DONE_CR;
          }
          break;

        case _State.CHUNKED_BODY_DONE_CR:
          _expect(byte, _CharCode.CR);
          _state = _State.CHUNKED_BODY_DONE_LF;
          break;

        case _State.CHUNKED_BODY_DONE_LF:
          _expect(byte, _CharCode.LF);
          if (dataEnd != null) dataEnd();
          _state = _State.START;
          break;

        case _State.BODY:
          // The body is not handled one byte at the time but in blocks.
          int dataAvailable = lastIndex - index;
          ByteArray data;
          if (dataAvailable <= _remainingContent) {
            data = new ByteArray(dataAvailable);
            data.setRange(0, dataAvailable, buffer, index);
          } else {
            data = new ByteArray(_remainingContent);
            data.setRange(0, _remainingContent, buffer, index);
          }

          if (dataReceived != null) dataReceived(data);
          _remainingContent -= data.length;
          index += data.length;
          if (_remainingContent == 0) {
            if (!_chunked) {
              if (dataEnd != null) dataEnd();
              _state = _State.START;
            } else {
              _state = _State.CHUNK_SIZE_STARTING_CR;
            }
          }

          // Hack - as we always do index++ below.
          index--;
          break;

        default:
          // Should be unreachable.
          assert(false);
      }

      // Move to the next byte.
      index++;
    }

    // Return the number of bytes parsed.
    return index - offset;
  }

  int get contentLength() => _contentLength;
  bool get keepAlive() => _keepAlive;

  int _toLowerCase(int byte) {
    final int aCode = "A".charCodeAt(0);
    final int zCode = "Z".charCodeAt(0);
    final int delta = "a".charCodeAt(0) - aCode;
    return (aCode <= byte && byte <= zCode) ? byte + delta : byte;
  }

  int _expect(int val1, int val2) {
    if (val1 != val2) {
      _failure = true;
    }
  }

  int _expectHexDigit(int byte) {
    if (0x30 <= byte && byte <= 0x39) {
      return byte - 0x30;  // 0 - 9
    } else if (0x41 <= byte && byte <= 0x46) {
      return byte - 0x41 + 10;  // A - F
    } else if (0x61 <= byte && byte <= 0x66) {
      return byte - 0x61 + 10;  // a - f
    } else {
      _failure = true;
      return 0;
    }
  }

  int _state;
  bool _failure;
  int _httpVersionIndex;
  StringBuffer _method_or_status_code;
  StringBuffer _uri_or_reason_phrase;
  StringBuffer _headerField;
  StringBuffer _headerValue;

  int _contentLength;
  bool _keepAlive;
  bool _chunked;

  int _remainingContent;

  // Callbacks.
  Function requestStart;
  Function responseStart;
  Function headerReceived;
  Function headersComplete;
  Function dataReceived;
  Function dataEnd;
}


// Utility class for encoding a string into UTF-8 byte stream.
class _UTF8Encoder {
  static List<int> encodeString(String string) {
    int size = _encodingSize(string);
    ByteArray result = new ByteArray(size);
    _encodeString(string, result);
    return result;
  }

  static int _encodingSize(String string) => _encodeString(string, null);

  static int _encodeString(String string, List<int> buffer) {
    int pos = 0;
    int length = string.length;
    for (int i = 0; i < length; i++) {
      int additionalBytes;
      int charCode = string.charCodeAt(i);
      if (charCode <= 0x007F) {
        additionalBytes = 0;
        if (buffer != null) buffer[pos] = charCode;
      } else if (charCode <= 0x07FF) {
        // 110xxxxx (xxxxx is top 5 bits).
        if (buffer != null) buffer[pos] = ((charCode >> 6) & 0x1F) | 0xC0;
        additionalBytes = 1;
      } else if (charCode <= 0xFFFF) {
        // 1110xxxx (xxxx is top 4 bits)
        if (buffer != null) buffer[pos] = ((charCode >> 12) & 0x0F)| 0xE0;
        additionalBytes = 2;
      } else {
        // 11110xxx (xxx is top 3 bits)
        if (buffer != null) buffer[pos] = ((charCode >> 18) & 0x07) | 0xF0;
        additionalBytes = 3;
      }
      pos++;
      if (buffer != null) {
        for (int i = additionalBytes; i > 0; i--) {
          // 10xxxxxx (xxxxxx is next 6 bits from the top).
          buffer[pos++] = ((charCode >> (6 * (i - 1))) & 0x3F) | 0x80;
        }
      } else {
        pos += additionalBytes;
      }
    }
    return pos;
  }
}


class _HttpRequestResponseBase {
  _HttpRequestResponseBase(_HttpConnectionBase this._httpConnection)
      : _contentLength = -1,
        _keepAlive = false,
        _headers = new Map();

  int get contentLength() => _contentLength;
  bool get keepAlive() => _keepAlive;

  void _setHeader(String name, String value) {
    _headers[name] = value;
  }

  bool _write(List<int> data, bool copyBuffer) {
    bool allWritten = true;
    if (data.length > 0) {
      if (_contentLength < 0) {
        // Write chunk size if transfer encoding is chunked.
        _writeHexString(data.length);
        _writeCRLF();
        _httpConnection.outputStream.write(data, copyBuffer);
        allWritten = _writeCRLF();
      } else {
        allWritten = _httpConnection.outputStream.write(data, copyBuffer);
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
        _httpConnection.outputStream.writeFrom(data, offset, count);
        allWritten = _writeCRLF();
      } else {
        allWritten = _httpConnection.outputStream.writeFrom(data, offset, count);
      }
    }
    return allWritten;
  }

  bool _writeString(String string) {
    bool allWritten = true;
    if (string.length > 0) {
      // Encode as UTF-8 and write data.
      List<int> data = _UTF8Encoder.encodeString(string);
      allWritten = _writeList(data, 0, data.length);
    }
    return allWritten;
  }

  bool _writeDone() {
    bool allWritten = true;
    if (_contentLength < 0) {
      // Terminate the content if transfer encoding is chunked.
      allWritten = _httpConnection.outputStream.write(_Const.END_CHUNKED);
    }
    return allWritten;
  }

  bool _writeHeaders() {
    List<int> data;

    // Format headers.
    _headers.forEach((String name, String value) {
      data = name.charCodes();
      _httpConnection.outputStream.write(data);
      data = ": ".charCodes();
      _httpConnection.outputStream.write(data);
      data = value.charCodes();
      _httpConnection.outputStream.write(data);
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
    return _httpConnection.outputStream.writeFrom(hex, index, hex.length - index);
  }

  bool _writeCRLF() {
    final CRLF = const [_CharCode.CR, _CharCode.LF];
    return _httpConnection.outputStream.write(CRLF);
  }

  bool _writeSP() {
    final SP = const [_CharCode.SP];
    return _httpConnection.outputStream.write(SP);
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
  Map get headers() => _headers;
  String get queryString() => _queryString;
  Map get queryParameters() => _queryParameters;

  InputStream get inputStream() {
    if (_inputStream == null) {
      _inputStream = new _HttpInputStream(this);
    }
    return _inputStream;
  }

  void _requestStartHandler(String method, String uri) {
    _method = method;
    _uri = uri;
    _parseRequestUri(uri);
  }

  void _headerReceivedHandler(String name, String value) {
    _setHeader(name, value);
  }

  void _headersCompleteHandler() {
    // Prepare for receiving data.
    _buffer = new _BufferList();
  }

  void _dataReceivedHandler(List<int> data) {
    _buffer.add(data);
    if (_inputStream != null) _inputStream._dataReceived();
  }

  void _dataEndHandler() {
    if (_inputStream != null) _inputStream._closeReceived();
  }

  // Escaped characters in uri are expected to have been parsed.
  void _parseRequestUri(String uri) {
    int position;
    position = uri.indexOf("?", 0);
    if (position == -1) {
      _path = HttpUtil.decodeUrlEncodedString(_uri);
      _queryString = null;
      _queryParameters = new Map();
    } else {
      _path = HttpUtil.decodeUrlEncodedString(_uri.substring(0, position));
      _queryString = _uri.substring(position + 1);
      _queryParameters = HttpUtil.splitQueryString(_queryString);
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

  String _method;
  String _uri;
  String _path;
  String _queryString;
  Map<String, String> _queryParameters;
  _HttpInputStream _inputStream;
  _BufferList _buffer;
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
    if (_outputStream != null) return new HttpException("Header already sent");
    _contentLength = contentLength;
  }

  void set keepAlive(bool keepAlive) {
    if (_outputStream != null) return new HttpException("Header already sent");
    _keepAlive = keepAlive;
  }

  int get statusCode() => _statusCode;
  void set statusCode(int statusCode) {
    if (_outputStream != null) return new HttpException("Header already sent");
    _statusCode = statusCode;
  }

  String get reasonPhrase() => _findReasonPhrase(_statusCode);
  void set reasonPhrase(String reasonPhrase) => _reasonPhrase = reasonPhrase;

  // Set a header on the response. NOTE: If the same header is set
  // more than once only the last one will be part of the response.
  void setHeader(String name, String value) {
    if (_outputStream != null) return new HttpException("Header already sent");
    _setHeader(name, value);
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

  bool writeString(String string) {
    // Invoke the output stream getter to make sure the header is sent.
    outputStream;
    return _writeString(string);
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
    _httpConnection.outputStream.noPendingWriteHandler = null;
    // Ensure that any trailing data is written.
    _writeDone();
    // If the connection is closing then close the output stream to
    // fully close the socket.
    if (_httpConnection._closing) {
      _httpConnection.outputStream.close();
    }
  }

  void _streamSetNoPendingWriteHandler(callback()) {
    if (_state != DONE) {
      _httpConnection.outputStream.noPendingWriteHandler = callback;
    }
  }

  void _streamSetCloseHandler(callback()) {
    // TODO(sgjesse): Handle this.
  }

  void _streamSetErrorHandler(callback()) {
    // TODO(sgjesse): Handle this.
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
      default: return "Status " + statusCode.toString();
    }
  }

  bool _writeHeader() {
    List<int> data;
    OutputStream stream = _httpConnection.outputStream;

    // Write status line.
    stream.write(_Const.HTTP11);
    _writeSP();
    data = _statusCode.toString().charCodes();
    stream.write(data);
    _writeSP();
    data = reasonPhrase.charCodes();
    stream.write(data);
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
  _HttpOutputStream _outputStream;
  int _state;
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


class _HttpOutputStream implements OutputStream {
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

  void set noPendingWriteHandler(void callback()) {
    _requestOrResponse._streamSetNoPendingWriteHandler(callback);
  }

  void set closeHandler(void callback()) {
    _requestOrResponse._streamSetCloseHandler(callback);
  }

  void set errorHandler(void callback()) {
    _requestOrResponse._streamSetErrorHandler(callback);
  }

  _HttpRequestResponseBase _requestOrResponse;
}


class _HttpConnectionBase {
  _HttpConnectionBase() : _sendBuffers = new Queue(),
                          _httpParser = new HttpParser();

  void _connectionEstablished(Socket socket) {
    _socket = socket;
    // Register handler for socket events.
    _socket.dataHandler = _dataHandler;
    _socket.closeHandler = _closeHandler;
    _socket.errorHandler = _errorHandler;
  }

  OutputStream get outputStream() {
    return _socket.outputStream;
  }

  void _dataHandler() {
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

  void _closeHandler() {
    // Client closed socket for writing. Socket should still be open
    // for writing the response.
    _closing = true;
    if (_disconnectHandlerCallback != null) _disconnectHandlerCallback();
  }

  void _errorHandler() {
    // If an error occours, treat the socket as closed.
    _closeHandler();
    if (_errorHandlerCallback != null) {
      _errorHandlerCallback("Connection closed while sending data to client.");
    }
  }

  void set disconnectHandler(void callback()) {
    _disconnectHandlerCallback = callback;
  }

  void set errorHandler(void callback(String errorMessage)) {
    _errorHandlerCallback = callback;
  }

  Socket _socket;
  bool _closing = false;  // Is the socket closed by the client?
  HttpParser _httpParser;

  Queue _sendBuffers;

  Function _disconnectHandlerCallback;
  Function _errorHandlerCallback;
}


// HTTP server connection over a socket.
class _HttpConnection extends _HttpConnectionBase {
  _HttpConnection() {
    // Register HTTP parser callbacks.
    _httpParser.requestStart =
        (method, uri) => _requestStartHandler(method, uri);
    _httpParser.responseStart =
        (statusCode, reasonPhrase) =>
            _responseStartHandler(statusCode, reasonPhrase);
    _httpParser.headerReceived =
        (name, value) => _headerReceivedHandler(name, value);
    _httpParser.headersComplete = () => _headersCompleteHandler();
    _httpParser.dataReceived = (data) => _dataReceivedHandler(data);
    _httpParser.dataEnd = () => _dataEndHandler();
  }

  void _requestStartHandler(String method, String uri) {
    // Create new request and response objects for this request.
    _request = new _HttpRequest(this);
    _response = new _HttpResponse(this);
    _request._requestStartHandler(method, uri);
  }

  void _responseStartHandler(int statusCode, String reasonPhrase) {
    // TODO(sgjesse): Error handling.
  }

  void _headerReceivedHandler(String name, String value) {
    _request._headerReceivedHandler(name, value);
  }

  void _headersCompleteHandler() {
    _request._headersCompleteHandler();
    _response.keepAlive = _httpParser.keepAlive;
    if (requestReceived != null) {
      requestReceived(_request, _response);
    }
  }

  void _dataReceivedHandler(List<int> data) {
    _request._dataReceivedHandler(data);
  }

  void _dataEndHandler() {
    _request._dataEndHandler();
  }

  HttpRequest _request;
  HttpResponse _response;

  // Callbacks.
  var requestReceived;
}


// HTTP server waiting for socket connections. The connections are
// managed by the server and as requests are received the request.
class _HttpServer implements HttpServer {
  void listen(String host, int port, [int backlog = 5]) {

    void connectionHandler(Socket socket) {
      // Accept the client connection.
      _HttpConnection connection = new _HttpConnection();
      connection._connectionEstablished(socket);
      connection.requestReceived = _requestHandler;
      _connections.add(connection);
      void disconnectHandler() {
        for (int i = 0; i < _connections.length; i++) {
          if (_connections[i] == connection) {
            _connections.removeRange(i, 1);
            break;
          }
        }
      }
      connection.disconnectHandler = disconnectHandler;
      void errorHandler(String errorMessage) {
        if (_errorHandler != null) _errorHandler(errorMessage);
      }
      connection.errorHandler = errorHandler;
    }

    // TODO(ajohnsen): Use Set once Socket is Hashable.
    _connections = new List<_HttpConnection>();
    _server = new ServerSocket(host, port, backlog);
    _server.connectionHandler = connectionHandler;
  }

  void close() => _server.close();
  int get port() => _server.port;

  void set errorHandler(void handler(String errorMessage)) {
    _errorHandler = handler;
  }

  void set requestHandler(void handler(HttpRequest, HttpResponse)) {
    _requestHandler = handler;
  }

  ServerSocket _server;  // The server listen socket.
  List<_HttpConnection> _connections;  // List of currently connected clients.
  Function _requestHandler;
  Function _errorHandler;
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

  void setHeader(String name, String value) {
    _setHeader(name, value);
  }

  bool writeString(String string) {
    outputStream;
    return _writeString(string);
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
    _httpConnection.outputStream.noPendingWriteHandler = null;
    // Ensure that any trailing data is written.
    _writeDone();
    // If the connection is closing then close the output stream to
    // fully close the socket.
    if (_httpConnection._closing) {
      _httpConnection.outputStream.close();
    }
  }

  void _streamSetNoPendingWriteHandler(callback()) {
    if (_state != DONE) {
      _httpConnection.outputStream.noPendingWriteHandler = callback;
    }
  }

  void _streamSetCloseHandler(callback()) {
    // TODO(sgjesse): Handle this.
  }

  void _streamSetErrorHandler(callback()) {
    // TODO(sgjesse): Handle this.
  }

  void _writeHeader() {
    List<int> data;
    OutputStream stream = _httpConnection.outputStream;

    // Write request line.
    data = _method.toString().charCodes();
    stream.write(data);
    _writeSP();
    data = _uri.toString().charCodes();
    stream.write(data);
    _writeSP();
    stream.write(_Const.HTTP11);
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
  _HttpClientConnection _connection;
  _HttpOutputStream _outputStream;
  int _state;
}


class _HttpClientResponse
    extends _HttpRequestResponseBase implements HttpClientResponse {
  _HttpClientResponse(_HttpClientConnection connection)
      : super(connection) {
    _connection = connection;
  }

  int get statusCode() => _statusCode;
  String get reasonPhrase() => _reasonPhrase;
  Map get headers() => _headers;

  InputStream get inputStream() {
    if (_inputStream == null) {
      _inputStream = new _HttpInputStream(this);
    }
    return _inputStream;
  }

  void _requestStartHandler(String method, String uri) {
    // TODO(sgjesse): Error handling
  }

  void _responseStartHandler(int statusCode, String reasonPhrase) {
    _statusCode = statusCode;
    _reasonPhrase = reasonPhrase;
  }

  void _headerReceivedHandler(String name, String value) {
    _setHeader(name, value);
  }

  void _headersCompleteHandler() {
    _buffer = new _BufferList();
    if (_connection._responseHandler != null) {
      _connection._responseHandler(this);
    }
  }

  void _dataReceivedHandler(List<int> data) {
    _buffer.add(data);
    if (_inputStream != null) _inputStream._dataReceived();
  }

  void _dataEndHandler() {
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

  int _statusCode;
  String _reasonPhrase;

  _HttpClientConnection _connection;
  _HttpInputStream _inputStream;
  _BufferList _buffer;
}


class _HttpClientConnection
    extends _HttpConnectionBase implements HttpClientConnection {
  _HttpClientConnection(_HttpClient this._client);

  void _connectionEstablished(_SocketConnection socketConn) {
    super._connectionEstablished(socketConn._socket);
    _socketConn = socketConn;
    // Register HTTP parser callbacks.
    _httpParser.requestStart =
        (method, uri) => _requestStartHandler(method, uri);
    _httpParser.responseStart =
        (statusCode, reasonPhrase) =>
            _responseStartHandler(statusCode, reasonPhrase);
    _httpParser.headerReceived =
        (name, value) => _headerReceivedHandler(name, value);
    _httpParser.headersComplete = () => _headersCompleteHandler();
    _httpParser.dataReceived = (data) => _dataReceivedHandler(data);
    _httpParser.dataEnd = () => _dataEndHandler();
  }

  HttpClientRequest open(String method, String uri) {
    _request = new _HttpClientRequest(method, uri, this);
    _request.keepAlive = true;
    _response = new _HttpClientResponse(this);
    return _request;
  }

  void _requestStartHandler(String method, String uri) {
    // TODO(sgjesse): Error handling.
  }

  void _responseStartHandler(int statusCode, String reasonPhrase) {
    _response._responseStartHandler(statusCode, reasonPhrase);
  }

  void _headerReceivedHandler(String name, String value) {
    _response._headerReceivedHandler(name, value);
  }

  void _headersCompleteHandler() {
    _response._headersCompleteHandler();
  }

  void _dataReceivedHandler(List<int> data) {
    _response._dataReceivedHandler(data);
  }

  void _dataEndHandler() {
    if (_response.headers["connection"] == "close") {
      _socket.close();
    } else {
      _client._returnSocketConnection(_socketConn);
      _socket = null;
      _socketConn = null;
    }
    _response._dataEndHandler();
  }

  void set requestHandler(void handler(HttpClientRequest request)) {
    _requestHandler = handler;
  }

  void set responseHandler(void handler(HttpClientResponse response)) {
    _responseHandler = handler;
  }

  Function _requestHandler;
  Function _responseHandler;

  _HttpClient _client;
  _SocketConnection _socketConn;
  HttpClientRequest _request;
  HttpClientResponse _response;

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
    _socket.dataHandler = null;
    _socket.closeHandler = null;
    _socket.errorHandler = null;
    _returnTime = new Date.now();
  }

  Duration _idleTime(Date now) => now.difference(_returnTime);

  String _host;
  int _port;
  Socket _socket;
  Date _returnTime;
}


class _HttpClient implements HttpClient {
  static final int DEFAULT_EVICTION_TIMEOUT = 60000;

  _HttpClient() : _openSockets = new Map(), _shutdown = false;

  HttpClientConnection open(
      String method, String host, int port, String path) {
    if (_shutdown) throw new HttpException("HttpClient shutdown");
    return _prepareHttpClientConnection(host, port, method, path);
  }

  HttpClientConnection get(String host, int port, String path) {
    return open("GET", host, port, path);
  }

  HttpClientConnection post(String host, int port, String path) {
    return open("POST", host, port, path);
  }

  void shutdown() {
     _openSockets.forEach(
         void _(String key, Queue<_SocketConnection> connections) {
           while (!connections.isEmpty()) {
             var socketConn = connections.removeFirst();
             socketConn._socket.close();
           }
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
      if (connection._requestHandler != null) {
        connection._requestHandler(request);
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
      socket.connectHandler = () {
        socket.errorHandler = null;
        _SocketConnection socketConn =
            new _SocketConnection(host, port, socket);
        _connectionOpened(socketConn, connection);
      };
      socket.errorHandler = () {
        if (_errorHandler !== null) {
          _errorHandler(HttpStatus.NETWORK_CONNECT_TIMEOUT_ERROR);
        }
      };
    } else {
      _SocketConnection socketConn = socketConnections.removeFirst();
      new Timer((ignored) => _connectionOpened(socketConn, connection), 0);

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
                } else {
                  break;
                }
              }
            });
      }
      _evictionTimer = new Timer.repeating(_handleEviction, 10000);
    }

    // Return connection.
    sockets.addFirst(socketConn);
    socketConn._markReturned();
  }

  void set errorHandler(void callback(int status)) {
    _errorHandler = callback;
  }

  Function _openHandler;
  Function _errorHandler;
  Map<String, Queue<_SocketConnection>> _openSockets;
  Timer _evictionTimer;
  bool _shutdown;  // Has this HTTP client been shutdown?
}


class HttpUtil {
  static String decodeUrlEncodedString(String urlEncoded) {
    void invalidEscape() {
      // TODO(sgjesse): Handle the error.
    }

    StringBuffer result = new StringBuffer();
    for (int ii = 0; urlEncoded.length > ii; ++ii) {
      if ('+' == urlEncoded[ii]) {
        result.add(' ');
      } else if ('%' == urlEncoded[ii] &&
                 urlEncoded.length - 2 > ii) {
        try {
          int charCode =
            Math.parseInt('0x' + urlEncoded.substring(ii + 1, ii + 3));
          if (charCode <= 0x7f) {
            result.add(new String.fromCharCodes([charCode]));
            ii += 2;
          } else {
            invalidEscape();
            return '';
          }
        } catch (BadNumberFormatException ignored) {
          invalidEscape();
          return '';
        }
      } else {
        result.add(urlEncoded[ii]);
      }
    }
    return result.toString();
  }

  static Map<String, String> splitQueryString(String queryString) {
    Map<String, String> result = new Map<String, String>();
    int currentPosition = 0;
    while (currentPosition < queryString.length) {
      int position = queryString.indexOf("=", currentPosition);
      if (position == -1) {
        break;
      }
      String name = queryString.substring(currentPosition, position);
      currentPosition = position + 1;
      position = queryString.indexOf("&", currentPosition);
      String value;
      if (position == -1) {
        value = queryString.substring(currentPosition);
        currentPosition = queryString.length;
      } else {
        value = queryString.substring(currentPosition, position);
        currentPosition = position + 1;
      }
      result[HttpUtil.decodeUrlEncodedString(name)] =
        HttpUtil.decodeUrlEncodedString(value);
    }
    return result;
  }
}
