// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

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
  static const int AMPERSAND = 38;
  static const int COMMA = 44;
  static const int DASH = 45;
  static const int SLASH = 47;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int COLON = 58;
  static const int SEMI_COLON = 59;
  static const int EQUAL = 61;
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
  static const int FAILURE = 27;

  static const int FIRST_BODY_STATE = CHUNK_SIZE_STARTING_CR;
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

class _HttpDetachedIncoming extends Stream<List<int>> {
  StreamController<List<int>> controller;
  final StreamSubscription subscription;

  List<int> bufferedData;
  bool paused;

  Completer resumeCompleter;

  _HttpDetachedIncoming(StreamSubscription this.subscription,
                        List<int> this.bufferedData) {
    controller = new StreamController<List<int>>(
        sync: true,
        onListen: resume,
        onPause: pause,
        onResume: resume,
        onCancel: () => subscription.cancel());
    if (subscription == null) {
      // Socket was already closed.
      if (bufferedData != null) controller.add(bufferedData);
      controller.close();
    } else {
      pause();
      subscription.resume();
      subscription.onData(controller.add);
      subscription.onDone(controller.close);
      subscription.onError(controller.addError);
    }
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    return controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  void resume() {
    paused = false;
    if (bufferedData != null) {
      var data = bufferedData;
      bufferedData = null;
      controller.add(data);
      // If the consumer pauses again after the carry-over data, we'll not
      // continue our subscriber until the next resume.
      if (paused) return;
    }
    if (resumeCompleter != null) {
      resumeCompleter.complete();
      resumeCompleter = null;
    }
  }

  void pause() {
    paused = true;
    if (resumeCompleter == null) {
      resumeCompleter = new Completer();
      subscription.pause(resumeCompleter.future);
    }
  }
}


/**
 * HTTP parser which parses the data stream given to [consume].
 *
 * If an HTTP parser error occours, the parser will signal an error to either
 * the current _HttpIncoming or the _parser itself.
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
class _HttpParser
    extends Stream<_HttpIncoming>
    implements StreamConsumer<List<int>> {

  factory _HttpParser.requestParser() {
    return new _HttpParser._(true);
  }

  factory _HttpParser.responseParser() {
    return new _HttpParser._(false);
  }

  _HttpParser._(this._requestParser) {
    _controller = new StreamController<_HttpIncoming>(
        sync: true,
        onListen: () {
          _socketSubscription.resume();
          _paused = false;
        },
        onPause: () {
          _paused = true;
          _pauseStateChanged();
        },
        onResume: () {
          _paused = false;
          _pauseStateChanged();
        },
        onCancel: () {
          try {
            _socketSubscription.cancel();
          } catch (e) {
          }
        });
    _reset();
  }


  StreamSubscription<_HttpIncoming> listen(void onData(_HttpIncoming event),
                                           {Function onError,
                                            void onDone(),
                                            bool cancelOnError}) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  Future<_HttpParser> addStream(Stream<List<int>> stream) {
    // Listen to the stream and handle data accordingly. When a
    // _HttpIncoming is created, _dataPause, _dataResume, _dataDone is
    // given to provide a way of controlling the parser.
    // TODO(ajohnsen): Remove _dataPause, _dataResume and _dataDone and clean up
    // how the _HttpIncoming signals the parser.
    var completer = new Completer();
    _socketSubscription = stream.listen(
        _onData,
        onError: _onError,
        onDone: () {
          completer.complete(this);
        });
    _socketSubscription.pause();
    return completer.future;
  }

  Future<_HttpParser> close() {
    _onDone();
    return new Future.value(this);
  }

  void _parse() {
    try {
      _doParse();
    } catch (e, s) {
      _state = _State.FAILURE;
      _reportError(e, s);
    }
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
  void _doParse() {
    assert(!_parserCalled);
    _parserCalled = true;
    if (_state == _State.CLOSED) {
      throw new HttpException("Data on closed connection");
    }
    if (_state == _State.FAILURE) {
      throw new HttpException("Data on failed connection");
    }
    while (_buffer != null &&
           _index < _buffer.length &&
           _state != _State.FAILURE &&
           _state != _State.UPGRADED) {
      // Depending on _incoming, we either break on _bodyPaused or _paused.
      if ((_incoming != null && _bodyPaused) ||
          (_incoming == null && _paused)) {
        _parserCalled = false;
        return;
      }
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
              throw new HttpException("Invalid request method");
            }
            _method_or_status_code.add(byte);
            if (!_requestParser) {
              throw new HttpException("Invalid response line");
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
              throw new HttpException("Invalid request line");
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
                throw new HttpException("Invalid response line");
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
            throw new HttpException("Invalid response line");
          }
          break;

        case _State.REQUEST_LINE_METHOD:
          if (byte == _CharCode.SP) {
            _state = _State.REQUEST_LINE_URI;
          } else {
            if (_Const.SEPARATORS_AND_CR_LF.indexOf(byte) != -1) {
              throw new HttpException("Invalid request method");
            }
            _method_or_status_code.add(byte);
          }
          break;

        case _State.REQUEST_LINE_URI:
          if (byte == _CharCode.SP) {
            if (_uri_or_reason_phrase.length == 0) {
              throw new HttpException("Invalid request URI");
            }
            _state = _State.REQUEST_LINE_HTTP_VERSION;
            _httpVersionIndex = 0;
          } else {
            if (byte == _CharCode.CR || byte == _CharCode.LF) {
              throw new HttpException("Invalid request URI");
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
              throw new HttpException("Invalid response line");
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
              throw new HttpException("Invalid response status code");
            }
            _state = _State.RESPONSE_LINE_REASON_PHRASE;
          } else {
            if (byte < 0x30 && 0x39 < byte) {
              throw new HttpException("Invalid response status code");
            } else {
              _method_or_status_code.add(byte);
            }
          }
          break;

        case _State.RESPONSE_LINE_REASON_PHRASE:
          if (byte == _CharCode.CR) {
            _state = _State.RESPONSE_LINE_ENDING;
          } else {
            if (byte == _CharCode.CR || byte == _CharCode.LF) {
              throw new HttpException("Invalid response reason phrase");
            }
            _uri_or_reason_phrase.add(byte);
          }
          break;

        case _State.RESPONSE_LINE_ENDING:
          _expect(byte, _CharCode.LF);
          _messageType == _MessageType.RESPONSE;
          _statusCode = int.parse(
              new String.fromCharCodes(_method_or_status_code));
          if (_statusCode < 100 || _statusCode > 599) {
            throw new HttpException("Invalid response status code");
          } else {
            // Check whether this response will never have a body.
            _noMessageBody = _statusCode <= 199 || _statusCode == 204 ||
                _statusCode == 304;
          }
          _state = _State.HEADER_START;
          break;

        case _State.HEADER_START:
          _headers = new _HttpHeaders(version);
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
              throw new HttpException("Invalid header field name");
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
            if (headerField == "transfer-encoding" &&
                       headerValue.toLowerCase() == "chunked") {
              _chunked = true;
            }
            if (headerField == "connection") {
              List<String> tokens = _tokenizeFieldValue(headerValue);
              for (int i = 0; i < tokens.length; i++) {
                if (tokens[i].toLowerCase() == "upgrade") {
                  _connectionUpgrade = true;
                }
                _headers.add(headerField, tokens[i]);
              }
            } else {
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
          _headers._mutable = false;

          _transferLength = _headers.contentLength;
          // Ignore the Content-Length header if Transfer-Encoding
          // is chunked (RFC 2616 section 4.4)
          if (_chunked) _transferLength = -1;

          // If a request message has neither Content-Length nor
          // Transfer-Encoding the message must not have a body (RFC
          // 2616 section 4.3).
          if (_messageType == _MessageType.REQUEST &&
              _transferLength < 0 &&
              _chunked == false) {
            _transferLength = 0;
          }
          if (_connectionUpgrade) {
            _state = _State.UPGRADED;
            _transferLength = 0;
          }
          _createIncoming(_transferLength);
          if (_requestParser) {
            _incoming.method =
                new String.fromCharCodes(_method_or_status_code);
            _incoming.uri =
                Uri.parse(
                    new String.fromCharCodes(_uri_or_reason_phrase));
          } else {
            _incoming.statusCode = _statusCode;
            _incoming.reasonPhrase =
                new String.fromCharCodes(_uri_or_reason_phrase);
          }
          _method_or_status_code.clear();
          _uri_or_reason_phrase.clear();
          if (_connectionUpgrade) {
            _incoming.upgraded = true;
            _parserCalled = false;
            var tmp = _incoming;
            _closeIncoming();
            _controller.add(tmp);
            return;
          }
          if (_transferLength == 0 ||
              (_messageType == _MessageType.RESPONSE &&
               (_noMessageBody || _responseToMethod == "HEAD"))) {
            _reset();
            var tmp = _incoming;
            _closeIncoming();
            _controller.add(tmp);
            break;
          } else if (_chunked) {
            _state = _State.CHUNK_SIZE;
            _remainingContent = 0;
          } else if (_transferLength > 0) {
            _remainingContent = _transferLength;
            _state = _State.BODY;
          } else {
            // Neither chunked nor content length. End of body
            // indicated by close.
            _state = _State.BODY;
          }
          _parserCalled = false;
          _controller.add(_incoming);
          return;

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
          _reset();
          _closeIncoming();
          break;

        case _State.BODY:
          // The body is not handled one byte at a time but in blocks.
          _index--;
          int dataAvailable = _buffer.length - _index;
          List<int> data;
          if (_remainingContent == -1 ||
              dataAvailable <= _remainingContent) {
            if (_index == 0) {
              data = _buffer;
            } else {
              data = new Uint8List(dataAvailable);
              data.setRange(0, dataAvailable, _buffer, _index);
            }
          } else {
            data = new Uint8List(_remainingContent);
            data.setRange(0, _remainingContent, _buffer, _index);
          }
          _bodyController.add(data);
          if (_remainingContent != -1) {
            _remainingContent -= data.length;
          }
          _index += data.length;
          if (_remainingContent == 0) {
            if (!_chunked) {
              _reset();
              _closeIncoming();
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

    _parserCalled = false;
    if (_buffer != null && _index == _buffer.length) {
      // If all data is parsed release the buffer and resume receiving
      // data.
      _releaseBuffer();
      if (_state != _State.UPGRADED && _state != _State.FAILURE) {
        _socketSubscription.resume();
      }
    }
  }

  void _onData(List<int> buffer) {
    _socketSubscription.pause();
    assert(_buffer == null);
    _buffer = buffer;
    _index = 0;
    _parse();
  }

  void _onDone() {
    // onDone cancles the subscription.
    _socketSubscription = null;
    if (_state == _State.CLOSED || _state == _State.FAILURE) return;

    if (_incoming != null) {
      if (_state != _State.UPGRADED &&
          !(_state == _State.START && !_requestParser) &&
          !(_state == _State.BODY && !_chunked && _transferLength == -1)) {
        _bodyController.addError(
              new HttpException("Connection closed while receiving data"));
      }
      _closeIncoming(true);
      _controller.close();
      return;
    }
    // If the connection is idle the HTTP stream is closed.
    if (_state == _State.START) {
      if (!_requestParser) {
        _reportError(new HttpException(
                    "Connection closed before full header was received"));
      }
      _controller.close();
      return;
    }

    if (_state == _State.UPGRADED) {
      _controller.close();
      return;
    }

    if (_state < _State.FIRST_BODY_STATE) {
      _state = _State.FAILURE;
      // Report the error through the error callback if any. Otherwise
      // throw the error.
      _reportError(new HttpException(
                  "Connection closed before full header was received"));
      _controller.close();
      return;
    }

    if (!_chunked && _transferLength == -1) {
      _state = _State.CLOSED;
    } else {
      _state = _State.FAILURE;
      // Report the error through the error callback if any. Otherwise
      // throw the error.
      _reportError(new HttpException(
                  "Connection closed before full body was received"));
    }
    _controller.close();
  }

  void _onError(e, [StackTrace stackTrace]) {
    _controller.addError(e, stackTrace);
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

  int get messageType => _messageType;
  int get transferLength => _transferLength;
  bool get upgrade => _connectionUpgrade && _state == _State.UPGRADED;
  bool get persistentConnection => _persistentConnection;

  void set responseToMethod(String method) { _responseToMethod = method; }

  _HttpDetachedIncoming detachIncoming() {
    return new _HttpDetachedIncoming(_socketSubscription,
                                     readUnparsedData());
  }

  List<int> readUnparsedData() {
    if (_buffer == null) return null;
    if (_index == _buffer.length) return null;
    var result = _buffer.sublist(_index);
    _releaseBuffer();
    return result;
  }

  _reset() {
    if (_state == _State.UPGRADED) return;
    _state = _State.START;
    _messageType = _MessageType.UNDETERMINED;
    _headerField = new List();
    _headerValue = new List();
    _method_or_status_code = new List();
    _uri_or_reason_phrase = new List();

    _statusCode = 0;

    _httpVersion = _HttpVersion.UNDETERMINED;
    _transferLength = -1;
    _persistentConnection = false;
    _connectionUpgrade = false;
    _chunked = false;

    _noMessageBody = false;
    _responseToMethod = null;
    _remainingContent = -1;

    _headers = null;
  }

  _releaseBuffer() {
    _buffer = null;
    _index = null;
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
    final int aCode = "A".codeUnitAt(0);
    final int zCode = "Z".codeUnitAt(0);
    final int delta = "a".codeUnitAt(0) - aCode;
    return (aCode <= byte && byte <= zCode) ? byte + delta : byte;
  }

  int _expect(int val1, int val2) {
    if (val1 != val2) {
      throw new HttpException("Failed to parse HTTP");
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
      throw new HttpException("Failed to parse HTTP");
    }
  }

  void _createIncoming(int transferLength) {
    assert(_incoming == null);
    assert(_bodyController == null);
    assert(!_bodyPaused);
    var incoming;
    _bodyController = new StreamController<List<int>>(
        sync: true,
        onListen: () {
          if (incoming != _incoming) return;
          assert(_bodyPaused);
          _bodyPaused = false;
          _pauseStateChanged();
        },
        onPause: () {
          if (incoming != _incoming) return;
          assert(!_bodyPaused);
          _bodyPaused = true;
          _pauseStateChanged();
        },
        onResume: () {
          if (incoming != _incoming) return;
          assert(_bodyPaused);
          _bodyPaused = false;
          _pauseStateChanged();
        },
        onCancel: () {
          if (incoming != _incoming) return;
          if (_socketSubscription != null) {
            _socketSubscription.cancel();
          }
          _closeIncoming(true);
          _controller.close();
        });
    incoming = _incoming = new _HttpIncoming(
        _headers, transferLength, _bodyController.stream);
    _bodyPaused = true;
    _pauseStateChanged();
  }

  void _closeIncoming([bool closing = false]) {
    // Ignore multiple close (can happend in re-entrance).
    if (_incoming == null) return;
    var tmp = _incoming;
    tmp.close(closing);
    _incoming = null;
    if (_bodyController != null) {
      _bodyController.close();
      _bodyController = null;
    }
    _bodyPaused = false;
    _pauseStateChanged();
  }

  void _pauseStateChanged() {
    if (_incoming != null) {
      if (!_bodyPaused && !_parserCalled) {
        _parse();
      }
    } else {
      if (!_paused && !_parserCalled) {
        _parse();
      }
    }
  }

  void _reportError(error, [stackTrace]) {
    if (_socketSubscription != null) _socketSubscription.cancel();
    _state = _State.FAILURE;
    _controller.addError(error, stackTrace);
    _controller.close();
  }

  // State.
  bool _parserCalled = false;

  // The data that is currently being parsed.
  List<int> _buffer;
  int _index;

  final bool _requestParser;
  int _state;
  int _httpVersionIndex;
  int _messageType;
  int _statusCode = 0;
  List _method_or_status_code;
  List _uri_or_reason_phrase;
  List _headerField;
  List _headerValue;

  int _httpVersion;
  int _transferLength = -1;
  bool _persistentConnection;
  bool _connectionUpgrade;
  bool _chunked;

  bool _noMessageBody;
  String _responseToMethod;  // Indicates the method used for the request.
  int _remainingContent = -1;

  _HttpHeaders _headers;

  // The current incoming connection.
  _HttpIncoming _incoming;
  StreamSubscription _socketSubscription;
  bool _paused = true;
  bool _bodyPaused = false;
  StreamController<_HttpIncoming> _controller;
  StreamController<List<int>> _bodyController;
}
