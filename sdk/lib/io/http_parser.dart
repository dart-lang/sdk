// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Global constants.
class _Const {
  // Bytes for "HTTP".
  static const HTTP = const [72, 84, 84, 80];
  // Bytes for "HTTP/1.".
  static const HTTP1DOT = const [72, 84, 84, 80, 47, 49, 46];
  // Bytes for "HTTP/1.0".
  static const HTTP10 = const [72, 84, 84, 80, 47, 49, 46, 48];
  // Bytes for "HTTP/1.1".
  static const HTTP11 = const [72, 84, 84, 80, 47, 49, 46, 49];

  static const END_CHUNKED = const [0x30, 13, 10, 13, 10];

  // Bytes for '()<>@,;:\\"/[]?={} \t'.
  static const SEPARATORS = const [40, 41, 60, 62, 64, 44, 59, 58, 92, 34, 47,
                                   91, 93, 63, 61, 123, 125, 32, 9];

  // Bytes for '()<>@,;:\\"/[]?={} \t\r\n'.
  static const SEPARATORS_AND_CR_LF = const [40, 41, 60, 62, 64, 44, 59, 58, 92,
                                             34, 47, 91, 93, 63, 61, 123, 125,
                                             32, 9, 13, 10];
}


// Frequently used character codes.
class _CharCode {
  static const int HT = 9;
  static const int LF = 10;
  static const int CR = 13;
  static const int SP = 32;
  static const int COMMA = 44;
  static const int DASH = 45;
  static const int SLASH = 47;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int COLON = 58;
  static const int SEMI_COLON = 59;
}


// States of the HTTP parser state machine.
class _State {
  static const int START = 0;
  static const int METHOD_OR_RESPONSE_HTTP_VERSION = 1;
  static const int RESPONSE_HTTP_VERSION = 2;
  static const int REQUEST_LINE_METHOD = 3;
  static const int REQUEST_LINE_URI = 4;
  static const int REQUEST_LINE_HTTP_VERSION = 5;
  static const int REQUEST_LINE_ENDING = 6;
  static const int RESPONSE_LINE_STATUS_CODE = 7;
  static const int RESPONSE_LINE_REASON_PHRASE = 8;
  static const int RESPONSE_LINE_ENDING = 9;
  static const int HEADER_START = 10;
  static const int HEADER_FIELD = 11;
  static const int HEADER_VALUE_START = 12;
  static const int HEADER_VALUE = 13;
  static const int HEADER_VALUE_FOLDING_OR_ENDING = 14;
  static const int HEADER_VALUE_FOLD_OR_END = 15;
  static const int HEADER_ENDING = 16;

  static const int CHUNK_SIZE_STARTING_CR = 17;
  static const int CHUNK_SIZE_STARTING_LF = 18;
  static const int CHUNK_SIZE = 19;
  static const int CHUNK_SIZE_EXTENSION = 20;
  static const int CHUNK_SIZE_ENDING = 21;
  static const int CHUNKED_BODY_DONE_CR = 22;
  static const int CHUNKED_BODY_DONE_LF = 23;
  static const int BODY = 24;
  static const int CLOSED = 25;
  static const int UPGRADED = 26;
  static const int CANCELED = 27;
  static const int FAILURE = 28;

  static const int FIRST_BODY_STATE = CHUNK_SIZE_STARTING_CR;
  static const int FIRST_PARSE_STOP_STATE = CLOSED;
}

// HTTP version of the request or response being parsed.
class _HttpVersion {
  static const int UNDETERMINED = 0;
  static const int HTTP10 = 1;
  static const int HTTP11 = 2;
}

// States of the HTTP parser state machine.
class _MessageType {
  static const int UNDETERMINED = 0;
  static const int REQUEST = 1;
  static const int RESPONSE = 0;
}


/**
 * HTTP parser which parses the HTTP stream as data is supplied
 * through the [:writeList:] and [:connectionClosed:] methods. As the
 * data is parsed the following callbacks are called:
 *
 *   [:requestStart:]
 *   [:responseStart:]
 *   [:dataReceived:]
 *   [:dataEnd:]
 *   [:closed:]
 *   [:error:]
 *
 * If an HTTP parser error occours it is possible to get an exception
 * thrown from the [:writeList:] and [:connectionClosed:] methods if
 * the error callback is not set.
 *
 * The connection upgrades (e.g. switching from HTTP/1.1 to the
 * WebSocket protocol) is handled in a special way. If connection
 * upgrade is specified in the headers, then on the callback to
 * [:responseStart:] the [:upgrade:] property on the [:HttpParser:]
 * object will be [:true:] indicating that from now on the protocol is
 * not HTTP anymore and no more callbacks will happen, that is
 * [:dataReceived:] and [:dataEnd:] are not called in this case as
 * there is no more HTTP data. After the upgrade the method
 * [:readUnparsedData:] can be used to read any remaining bytes in the
 * HTTP parser which are part of the protocol the connection is
 * upgrading to. These bytes cannot be processed by the HTTP parser
 * and should be handled according to whatever protocol is being
 * upgraded to.
 */
class _HttpParser {
  _HttpParser.requestParser() {
    _requestParser = true;
    _reset();
  }
  _HttpParser.responseParser() {
    _requestParser = false;
    _reset();
  }

  // From RFC 2616.
  // generic-message = start-line
  //                   *(message-header CRLF)
  //                   CRLF
  //                   [ message-body ]
  // start-line      = Request-Line | Status-Line
  // Request-Line    = Method SP Request-URI SP HTTP-Version CRLF
  // Status-Line     = HTTP-Version SP Status-Code SP Reason-Phrase CRLF
  // message-header  = field-name ":" [ field-value ]
  void _parse() {
    try {
      if (_state == _State.CLOSED) {
        throw new HttpParserException("Data on closed connection");
      }
      if (_state == _State.UPGRADED) {
        throw new HttpParserException("Data on upgraded connection");
      }
      if (_state == _State.FAILURE) {
        throw new HttpParserException("Data on failed connection");
      }
      if (_state == _State.CANCELED) {
        throw new HttpParserException("Data on canceled connection");
      }
      while (_buffer != null &&
             _index < _lastIndex &&
             _state <= _State.FIRST_PARSE_STOP_STATE) {
        int byte = _buffer[_index++];
        switch (_state) {
          case _State.START:
            if (byte == _Const.HTTP[0]) {
              // Start parsing method or HTTP version.
              _httpVersionIndex = 1;
              _state = _State.METHOD_OR_RESPONSE_HTTP_VERSION;
            } else {
              // Start parsing method.
              if (!_isTokenChar(byte)) {
                throw new HttpParserException("Invalid request method");
              }
              _method_or_status_code.add(byte);
              if (!_requestParser) {
                throw new HttpParserException("Invalid response line");
              }
              _state = _State.REQUEST_LINE_METHOD;
            }
            break;

          case _State.METHOD_OR_RESPONSE_HTTP_VERSION:
            if (_httpVersionIndex < _Const.HTTP.length &&
                byte == _Const.HTTP[_httpVersionIndex]) {
              // Continue parsing HTTP version.
              _httpVersionIndex++;
            } else if (_httpVersionIndex == _Const.HTTP.length &&
                       byte == _CharCode.SLASH) {
              // HTTP/ parsed. As method is a token this cannot be a
              // method anymore.
              _httpVersionIndex++;
              if (_requestParser) {
                throw new HttpParserException("Invalid request line");
              }
              _state = _State.RESPONSE_HTTP_VERSION;
            } else {
              // Did not parse HTTP version. Expect method instead.
              for (int i = 0; i < _httpVersionIndex; i++) {
                _method_or_status_code.add(_Const.HTTP[i]);
              }
              if (byte == _CharCode.SP) {
                _state = _State.REQUEST_LINE_URI;
              } else {
                _method_or_status_code.add(byte);
                _httpVersion = _HttpVersion.UNDETERMINED;
                if (!_requestParser) {
                  throw new HttpParserException("Invalid response line");
                }
                _state = _State.REQUEST_LINE_METHOD;
              }
            }
            break;

          case _State.RESPONSE_HTTP_VERSION:
            if (_httpVersionIndex < _Const.HTTP1DOT.length) {
              // Continue parsing HTTP version.
              _expect(byte, _Const.HTTP1DOT[_httpVersionIndex]);
              _httpVersionIndex++;
            } else if (_httpVersionIndex == _Const.HTTP1DOT.length &&
                       byte == _CharCode.ONE) {
              // HTTP/1.1 parsed.
              _httpVersion = _HttpVersion.HTTP11;
              _persistentConnection = true;
              _httpVersionIndex++;
            } else if (_httpVersionIndex == _Const.HTTP1DOT.length &&
                       byte == _CharCode.ZERO) {
              // HTTP/1.0 parsed.
              _httpVersion = _HttpVersion.HTTP10;
              _persistentConnection = false;
              _httpVersionIndex++;
            } else if (_httpVersionIndex == _Const.HTTP1DOT.length + 1) {
              _expect(byte, _CharCode.SP);
              // HTTP version parsed.
              _state = _State.RESPONSE_LINE_STATUS_CODE;
            } else {
              throw new HttpParserException("Invalid response line");
            }
            break;

          case _State.REQUEST_LINE_METHOD:
            if (byte == _CharCode.SP) {
              _state = _State.REQUEST_LINE_URI;
            } else {
              if (_Const.SEPARATORS_AND_CR_LF.indexOf(byte) != -1) {
                throw new HttpParserException("Invalid request method");
              }
              _method_or_status_code.add(byte);
            }
            break;

          case _State.REQUEST_LINE_URI:
            if (byte == _CharCode.SP) {
              if (_uri_or_reason_phrase.length == 0) {
                throw new HttpParserException("Invalid request URI");
              }
              _state = _State.REQUEST_LINE_HTTP_VERSION;
              _httpVersionIndex = 0;
            } else {
              if (byte == _CharCode.CR || byte == _CharCode.LF) {
                throw new HttpParserException("Invalid request URI");
              }
              _uri_or_reason_phrase.add(byte);
            }
            break;

          case _State.REQUEST_LINE_HTTP_VERSION:
            if (_httpVersionIndex < _Const.HTTP1DOT.length) {
              _expect(byte, _Const.HTTP11[_httpVersionIndex]);
              _httpVersionIndex++;
            } else if (_httpVersionIndex == _Const.HTTP1DOT.length) {
              if (byte == _CharCode.ONE) {
                // HTTP/1.1 parsed.
                _httpVersion = _HttpVersion.HTTP11;
                _persistentConnection = true;
                _httpVersionIndex++;
              } else if (byte == _CharCode.ZERO) {
                // HTTP/1.0 parsed.
                _httpVersion = _HttpVersion.HTTP10;
                _persistentConnection = false;
                _httpVersionIndex++;
              } else {
                throw new HttpParserException("Invalid response line");
              }
            } else {
              _expect(byte, _CharCode.CR);
              _state = _State.REQUEST_LINE_ENDING;
            }
            break;

          case _State.REQUEST_LINE_ENDING:
            _expect(byte, _CharCode.LF);
            _messageType = _MessageType.REQUEST;
            _state = _State.HEADER_START;
            break;

          case _State.RESPONSE_LINE_STATUS_CODE:
            if (byte == _CharCode.SP) {
              if (_method_or_status_code.length != 3) {
                throw new HttpParserException("Invalid response status code");
              }
              _state = _State.RESPONSE_LINE_REASON_PHRASE;
            } else {
              if (byte < 0x30 && 0x39 < byte) {
                throw new HttpParserException("Invalid response status code");
              } else {
                _method_or_status_code.add(byte);
              }
            }
            break;

          case _State.RESPONSE_LINE_REASON_PHRASE:
            if (byte == _CharCode.CR) {
              if (_uri_or_reason_phrase.length == 0) {
                throw new HttpParserException("Invalid response reason phrase");
              }
              _state = _State.RESPONSE_LINE_ENDING;
            } else {
              if (byte == _CharCode.CR || byte == _CharCode.LF) {
                throw new HttpParserException("Invalid response reason phrase");
              }
              _uri_or_reason_phrase.add(byte);
            }
            break;

          case _State.RESPONSE_LINE_ENDING:
            _expect(byte, _CharCode.LF);
            _messageType == _MessageType.RESPONSE;
             _statusCode = parseInt(new String.fromCharCodes(_method_or_status_code));
            if (_statusCode < 100 || _statusCode > 599) {
              throw new HttpParserException("Invalid response status code");
            } else {
              // Check whether this response will never have a body.
              _noMessageBody =
                  _statusCode <= 199 || _statusCode == 204 || _statusCode == 304;
            }
            _state = _State.HEADER_START;
            break;

          case _State.HEADER_START:
            if (byte == _CharCode.CR) {
              _state = _State.HEADER_ENDING;
            } else {
              // Start of new header field.
              _headerField.add(_toLowerCase(byte));
              _state = _State.HEADER_FIELD;
            }
            break;

          case _State.HEADER_FIELD:
            if (byte == _CharCode.COLON) {
              _state = _State.HEADER_VALUE_START;
            } else {
              if (!_isTokenChar(byte)) {
                throw new HttpParserException("Invalid header field name");
              }
              _headerField.add(_toLowerCase(byte));
            }
            break;

          case _State.HEADER_VALUE_START:
            if (byte == _CharCode.CR) {
              _state = _State.HEADER_VALUE_FOLDING_OR_ENDING;
            } else if (byte != _CharCode.SP && byte != _CharCode.HT) {
              // Start of new header value.
              _headerValue.add(byte);
              _state = _State.HEADER_VALUE;
            }
            break;

          case _State.HEADER_VALUE:
            if (byte == _CharCode.CR) {
              _state = _State.HEADER_VALUE_FOLDING_OR_ENDING;
            } else {
              _headerValue.add(byte);
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
              String headerField = new String.fromCharCodes(_headerField);
              String headerValue = new String.fromCharCodes(_headerValue);
              bool reportHeader = true;
              if (headerField == "content-length" && !_chunked) {
                // Ignore the Content-Length header if Transfer-Encoding
                // is chunked (RFC 2616 section 4.4)
                _contentLength = parseInt(headerValue);
              } else if (headerField == "connection") {
                List<String> tokens = _tokenizeFieldValue(headerValue);
                for (int i = 0; i < tokens.length; i++) {
                  String token = tokens[i].toLowerCase();
                  if (token == "keep-alive") {
                    _persistentConnection = true;
                  } else if (token == "close") {
                    _persistentConnection = false;
                  } else if (token == "upgrade") {
                    _connectionUpgrade = true;
                  }
                  _headers.add(headerField, token);

                }
                reportHeader = false;
              } else if (headerField == "transfer-encoding" &&
                         headerValue.toLowerCase() == "chunked") {
                // Ignore the Content-Length header if Transfer-Encoding
                // is chunked (RFC 2616 section 4.4)
                _chunked = true;
                _contentLength = -1;
              }
              if (reportHeader) {
                _headers.add(headerField, headerValue);
              }
              _headerField.clear();
              _headerValue.clear();

              if (byte == _CharCode.CR) {
                _state = _State.HEADER_ENDING;
              } else {
                // Start of new header field.
                _headerField.add(_toLowerCase(byte));
                _state = _State.HEADER_FIELD;
              }
            }
            break;

          case _State.HEADER_ENDING:
            _expect(byte, _CharCode.LF);
            // If a request message has neither Content-Length nor
            // Transfer-Encoding the message must not have a body (RFC
            // 2616 section 4.3).
            if (_messageType == _MessageType.REQUEST &&
                _contentLength < 0 &&
                _chunked == false) {
              _contentLength = 0;
            }
            if (_connectionUpgrade) {
              _state = _State.UPGRADED;
            }
            if (_requestParser) {
              requestStart(new String.fromCharCodes(_method_or_status_code),
                           new String.fromCharCodes(_uri_or_reason_phrase),
                           version,
                           _headers);
            } else {
              responseStart(_statusCode,
                            new String.fromCharCodes(_uri_or_reason_phrase),
                            version,
                            _headers);
            }
            if (_state == _State.CANCELED) continue;
            _method_or_status_code.clear();
            _uri_or_reason_phrase.clear();
            if (!_connectionUpgrade) {
              _method_or_status_code.clear();
              _uri_or_reason_phrase.clear();
              if (_chunked) {
                _state = _State.CHUNK_SIZE;
                _remainingContent = 0;
              } else if (_contentLength == 0 ||
                         (_messageType == _MessageType.RESPONSE &&
                          (_noMessageBody || _responseToMethod == "HEAD"))) {
                // If there is no message body get ready to process the
                // next request.
                _bodyEnd();
                if (_state == _State.CANCELED) continue;
                _reset();
              } else if (_contentLength > 0) {
                _remainingContent = _contentLength;
                _state = _State.BODY;
              } else {
                // Neither chunked nor content length. End of body
                // indicated by close.
                _state = _State.BODY;
              }
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
            } else if (byte == _CharCode.SEMI_COLON) {
              _state = _State.CHUNK_SIZE_EXTENSION;
            } else {
              int value = _expectHexDigit(byte);
              _remainingContent = _remainingContent * 16 + value;
            }
            break;

          case _State.CHUNK_SIZE_EXTENSION:
            if (byte == _CharCode.CR) {
              _state = _State.CHUNK_SIZE_ENDING;
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
            _bodyEnd();
            if (_state == _State.CANCELED) continue;
            _reset();
            break;

          case _State.BODY:
            // The body is not handled one byte at a time but in blocks.
            _index--;
            int dataAvailable = _lastIndex - _index;
            List<int> data;
            if (_remainingContent == null ||
                dataAvailable <= _remainingContent) {
              data = new Uint8List(dataAvailable);
              data.setRange(0, dataAvailable, _buffer, _index);
            } else {
              data = new Uint8List(_remainingContent);
              data.setRange(0, _remainingContent, _buffer, _index);
            }

            dataReceived(data);
            if (_state == _State.CANCELED) continue;
            if (_remainingContent != null) {
              _remainingContent -= data.length;
            }
            _index += data.length;
            if (_remainingContent == 0) {
              if (!_chunked) {
                _bodyEnd();
                if (_state == _State.CANCELED) continue;
                _reset();
              } else {
                _state = _State.CHUNK_SIZE_STARTING_CR;
              }
            }
            break;

          case _State.FAILURE:
            // Should be unreachable.
            assert(false);
            break;

          default:
            // Should be unreachable.
            assert(false);
            break;
        }
      }
    } catch (e) {
      _state = _State.FAILURE;
      error(e);
    }

    // If all data is parsed or not needed due to failure there is no
    // need to hold on to the buffer.
    if (_state != _State.UPGRADED) _releaseBuffer();
  }

  void streamData(List<int> buffer) {
    assert(_buffer == null);
    _buffer = buffer;
    _index = 0;
    _lastIndex = buffer.length;
    _parse();
  }

  void streamDone() {
    String type() => _requestParser ? "request" : "response";

    // If the connection is idle the HTTP stream is closed.
    if (_state == _State.START) {
      if (_requestParser) {
        closed();
      } else {
        error(
            new HttpParserException(
                "Connection closed before full ${type()} header was received"));
      }
      return;
    }

    if (_state < _State.FIRST_BODY_STATE) {
      _state = _State.FAILURE;
      // Report the error through the error callback if any. Otherwise
      // throw the error.
      error(
          new HttpParserException(
                "Connection closed before full ${type()} header was received"));
      return;
    }

    if (!_chunked && _contentLength == -1) {
      dataEnd(true);
      _state = _State.CLOSED;
      closed();
    } else {
      _state = _State.FAILURE;
      // Report the error through the error callback if any. Otherwise
      // throw the error.
      error(
          new HttpParserException(
                "Connection closed before full ${type()} body was received"));
    }
  }

  void streamError(e) {
    // Don't report errors when HTTP parser is in idle state. Clients
    // can close the connection and cause a connection reset by peer
    // error which is OK.
    if (_state == _State.START) {
      closed();
      return;
    }
    error(e);
  }

  String get version {
    switch (_httpVersion) {
      case _HttpVersion.HTTP10:
        return "1.0";
      case _HttpVersion.HTTP11:
        return "1.1";
    }
    return null;
  }

  void cancel() {
    _state = _State.CANCELED;
  }

  int get messageType => _messageType;
  int get contentLength => _contentLength;
  bool get upgrade => _connectionUpgrade && _state == _State.UPGRADED;
  bool get persistentConnection => _persistentConnection;

  void set responseToMethod(String method) { _responseToMethod = method; }

  List<int> readUnparsedData() {
    if (_buffer == null) return [];
    if (_index == _lastIndex) return [];
    var result = _buffer.getRange(_index, _lastIndex - _index);
    _releaseBuffer();
    return result;
  }

  void _bodyEnd() {
    dataEnd(_messageType == _MessageType.RESPONSE && !_persistentConnection);
  }

  _reset() {
    _state = _State.START;
    _messageType = _MessageType.UNDETERMINED;
    _headerField = new List();
    _headerValue = new List();
    _method_or_status_code = new List();
    _uri_or_reason_phrase = new List();

    _httpVersion = _HttpVersion.UNDETERMINED;
    _contentLength = -1;
    _persistentConnection = false;
    _connectionUpgrade = false;
    _chunked = false;

    _noMessageBody = false;
    _responseToMethod = null;
    _remainingContent = null;

    _headers = new _HttpHeaders();
  }

  _releaseBuffer() {
    _buffer = null;
    _index = null;
    _lastIndex = null;
  }

  bool _isTokenChar(int byte) {
    return byte > 31 && byte < 128 && _Const.SEPARATORS.indexOf(byte) == -1;
  }

  List<String> _tokenizeFieldValue(String headerValue) {
    List<String> tokens = new List<String>();
    int start = 0;
    int index = 0;
    while (index < headerValue.length) {
      if (headerValue[index] == ",") {
        tokens.add(headerValue.substring(start, index));
        start = index + 1;
      } else if (headerValue[index] == " " || headerValue[index] == "\t") {
        start++;
      }
      index++;
    }
    tokens.add(headerValue.substring(start, index));
    return tokens;
  }

  int _toLowerCase(int byte) {
    final int aCode = "A".charCodeAt(0);
    final int zCode = "Z".charCodeAt(0);
    final int delta = "a".charCodeAt(0) - aCode;
    return (aCode <= byte && byte <= zCode) ? byte + delta : byte;
  }

  int _expect(int val1, int val2) {
    if (val1 != val2) {
      throw new HttpParserException("Failed to parse HTTP");
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
      throw new HttpParserException("Failed to parse HTTP");
    }
  }

  // The data that is currently being parsed.
  List<int> _buffer;
  int _index;
  int _lastIndex;

  bool _requestParser;
  int _state;
  int _httpVersionIndex;
  int _messageType;
  int _statusCode;
  List _method_or_status_code;
  List _uri_or_reason_phrase;
  List _headerField;
  List _headerValue;

  int _httpVersion;
  int _contentLength;
  bool _persistentConnection;
  bool _connectionUpgrade;
  bool _chunked;

  bool _noMessageBody;
  String _responseToMethod;  // Indicates the method used for the request.
  int _remainingContent;

  _HttpHeaders _headers = new _HttpHeaders();

  // Callbacks.
  Function requestStart;
  Function responseStart;
  Function dataReceived;
  Function dataEnd;
  Function error;
  Function closed;
}


class HttpParserException implements Exception {
  const HttpParserException([String this.message = ""]);
  String toString() => "HttpParserException: $message";
  final String message;
}
