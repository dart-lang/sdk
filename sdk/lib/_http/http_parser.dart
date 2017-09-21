// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._http;

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

  static const bool T = true;
  static const bool F = false;
  // Loopup-map for the following characters: '()<>@,;:\\"/[]?={} \t'.
  static const SEPARATOR_MAP = const [
    F, F, F, F, F, F, F, F, F, T, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, T, F, T, F, F, F, F, F, T, T, F, F, T, F, F, T, //
    F, F, F, F, F, F, F, F, F, F, T, T, T, T, T, T, T, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, T, T, T, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, T, F, T, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
    F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F
  ];
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

/**
 * The _HttpDetachedStreamSubscription takes a subscription and some extra data,
 * and makes it possible to "inject" the data in from of other data events
 * from the subscription.
 *
 * It does so by overriding pause/resume, so that once the
 * _HttpDetachedStreamSubscription is resumed, it'll deliver the data before
 * resuming the underlaying subscription.
 */
class _HttpDetachedStreamSubscription implements StreamSubscription<List<int>> {
  StreamSubscription<List<int>> _subscription;
  List<int> _injectData;
  bool _isCanceled = false;
  int _pauseCount = 1;
  Function _userOnData;
  bool _scheduled = false;

  _HttpDetachedStreamSubscription(
      this._subscription, this._injectData, this._userOnData);

  bool get isPaused => _subscription.isPaused;

  Future<T> asFuture<T>([T futureValue]) =>
      _subscription.asFuture<T>(futureValue);

  Future cancel() {
    _isCanceled = true;
    _injectData = null;
    return _subscription.cancel();
  }

  void onData(void handleData(List<int> data)) {
    _userOnData = handleData;
    _subscription.onData(handleData);
  }

  void onDone(void handleDone()) {
    _subscription.onDone(handleDone);
  }

  void onError(Function handleError) {
    _subscription.onError(handleError);
  }

  void pause([Future resumeSignal]) {
    if (_injectData == null) {
      _subscription.pause(resumeSignal);
    } else {
      _pauseCount++;
      if (resumeSignal != null) {
        resumeSignal.whenComplete(resume);
      }
    }
  }

  void resume() {
    if (_injectData == null) {
      _subscription.resume();
    } else {
      _pauseCount--;
      _maybeScheduleData();
    }
  }

  void _maybeScheduleData() {
    if (_scheduled) return;
    if (_pauseCount != 0) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (_pauseCount > 0 || _isCanceled) return;
      var data = _injectData;
      _injectData = null;
      // To ensure that 'subscription.isPaused' is false, we resume the
      // subscription here. This is fine as potential events are delayed.
      _subscription.resume();
      if (_userOnData != null) {
        _userOnData(data);
      }
    });
  }
}

class _HttpDetachedIncoming extends Stream<List<int>> {
  final StreamSubscription<List<int>> subscription;
  final List<int> bufferedData;

  _HttpDetachedIncoming(this.subscription, this.bufferedData);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    if (subscription != null) {
      subscription
        ..onData(onData)
        ..onError(onError)
        ..onDone(onDone);
      if (bufferedData == null) {
        return subscription..resume();
      }
      return new _HttpDetachedStreamSubscription(
          subscription, bufferedData, onData)
        ..resume();
    } else {
      // TODO(26379): add test for this branch.
      return new Stream<List<int>>.fromIterable([bufferedData]).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    }
  }
}

/**
 * HTTP parser which parses the data stream given to [consume].
 *
 * If an HTTP parser error occurs, the parser will signal an error to either
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
class _HttpParser extends Stream<_HttpIncoming> {
  // State.
  bool _parserCalled = false;

  // The data that is currently being parsed.
  Uint8List _buffer;
  int _index;

  final bool _requestParser;
  int _state;
  int _httpVersionIndex;
  int _messageType;
  int _statusCode = 0;
  int _statusCodeLength = 0;
  final List<int> _method = [];
  final List<int> _uri_or_reason_phrase = [];
  final List<int> _headerField = [];
  final List<int> _headerValue = [];

  int _httpVersion;
  int _transferLength = -1;
  bool _persistentConnection;
  bool _connectionUpgrade;
  bool _chunked;

  bool _noMessageBody = false;
  int _remainingContent = -1;

  _HttpHeaders _headers;

  // The current incoming connection.
  _HttpIncoming _incoming;
  StreamSubscription<List<int>> _socketSubscription;
  bool _paused = true;
  bool _bodyPaused = false;
  StreamController<_HttpIncoming> _controller;
  StreamController<List<int>> _bodyController;

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
          if (_socketSubscription != null) {
            _socketSubscription.cancel();
          }
        });
    _reset();
  }

  StreamSubscription<_HttpIncoming> listen(void onData(_HttpIncoming event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void listenToStream(Stream<List<int>> stream) {
    // Listen to the stream and handle data accordingly. When a
    // _HttpIncoming is created, _dataPause, _dataResume, _dataDone is
    // given to provide a way of controlling the parser.
    // TODO(ajohnsen): Remove _dataPause, _dataResume and _dataDone and clean up
    // how the _HttpIncoming signals the parser.
    _socketSubscription =
        stream.listen(_onData, onError: _controller.addError, onDone: _onDone);
  }

  void _parse() {
    try {
      _doParse();
    } catch (e, s) {
      _state = _State.FAILURE;
      _reportError(e, s);
    }
  }

  // Process end of headers. Returns true if the parser should stop
  // parsing and return. This will be in case of either an upgrade
  // request or a request or response with an empty body.
  bool _headersEnd() {
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
      _incoming.method = new String.fromCharCodes(_method);
      _incoming.uri =
          Uri.parse(new String.fromCharCodes(_uri_or_reason_phrase));
    } else {
      _incoming.statusCode = _statusCode;
      _incoming.reasonPhrase = new String.fromCharCodes(_uri_or_reason_phrase);
    }
    _method.clear();
    _uri_or_reason_phrase.clear();
    if (_connectionUpgrade) {
      _incoming.upgraded = true;
      _parserCalled = false;
      var tmp = _incoming;
      _closeIncoming();
      _controller.add(tmp);
      return true;
    }
    if (_transferLength == 0 ||
        (_messageType == _MessageType.RESPONSE && _noMessageBody)) {
      _reset();
      var tmp = _incoming;
      _closeIncoming();
      _controller.add(tmp);
      return false;
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
    return true;
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
            _method.add(byte);
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
              _method.add(_Const.HTTP[i]);
            }
            if (byte == _CharCode.SP) {
              _state = _State.REQUEST_LINE_URI;
            } else {
              _method.add(byte);
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
            if (_Const.SEPARATOR_MAP[byte] ||
                byte == _CharCode.CR ||
                byte == _CharCode.LF) {
              throw new HttpException("Invalid request method");
            }
            _method.add(byte);
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
            if (byte == _CharCode.CR) {
              _state = _State.REQUEST_LINE_ENDING;
            } else {
              _expect(byte, _CharCode.LF);
              _messageType = _MessageType.REQUEST;
              _state = _State.HEADER_START;
            }
          }
          break;

        case _State.REQUEST_LINE_ENDING:
          _expect(byte, _CharCode.LF);
          _messageType = _MessageType.REQUEST;
          _state = _State.HEADER_START;
          break;

        case _State.RESPONSE_LINE_STATUS_CODE:
          if (byte == _CharCode.SP) {
            _state = _State.RESPONSE_LINE_REASON_PHRASE;
          } else if (byte == _CharCode.CR) {
            // Some HTTP servers does not follow the spec. and send
            // \r\n right after the status code.
            _state = _State.RESPONSE_LINE_ENDING;
          } else {
            _statusCodeLength++;
            if ((byte < 0x30 && 0x39 < byte) || _statusCodeLength > 3) {
              throw new HttpException("Invalid response status code");
            } else {
              _statusCode = _statusCode * 10 + byte - 0x30;
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
          if (_statusCode < 100 || _statusCode > 599) {
            throw new HttpException("Invalid response status code");
          } else {
            // Check whether this response will never have a body.
            if (_statusCode <= 199 ||
                _statusCode == 204 ||
                _statusCode == 304) {
              _noMessageBody = true;
            }
          }
          _state = _State.HEADER_START;
          break;

        case _State.HEADER_START:
          _headers = new _HttpHeaders(version);
          if (byte == _CharCode.CR) {
            _state = _State.HEADER_ENDING;
          } else if (byte == _CharCode.LF) {
            _state = _State.HEADER_ENDING;
            _index--; // Make the new state see the LF again.
          } else {
            // Start of new header field.
            _headerField.add(_toLowerCaseByte(byte));
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
            _headerField.add(_toLowerCaseByte(byte));
          }
          break;

        case _State.HEADER_VALUE_START:
          if (byte == _CharCode.CR) {
            _state = _State.HEADER_VALUE_FOLDING_OR_ENDING;
          } else if (byte == _CharCode.LF) {
            _state = _State.HEADER_VALUE_FOLD_OR_END;
          } else if (byte != _CharCode.SP && byte != _CharCode.HT) {
            // Start of new header value.
            _headerValue.add(byte);
            _state = _State.HEADER_VALUE;
          }
          break;

        case _State.HEADER_VALUE:
          if (byte == _CharCode.CR) {
            _state = _State.HEADER_VALUE_FOLDING_OR_ENDING;
          } else if (byte == _CharCode.LF) {
            _state = _State.HEADER_VALUE_FOLD_OR_END;
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
                _caseInsensitiveCompare("chunked".codeUnits, _headerValue)) {
              _chunked = true;
            }
            if (headerField == "connection") {
              List<String> tokens = _tokenizeFieldValue(headerValue);
              final bool isResponse = _messageType == _MessageType.RESPONSE;
              final bool isUpgradeCode =
                  (_statusCode == HttpStatus.UPGRADE_REQUIRED) ||
                      (_statusCode == HttpStatus.SWITCHING_PROTOCOLS);
              for (int i = 0; i < tokens.length; i++) {
                final bool isUpgrade = _caseInsensitiveCompare(
                    "upgrade".codeUnits, tokens[i].codeUnits);
                if ((isUpgrade && !isResponse) ||
                    (isUpgrade && isResponse && isUpgradeCode)) {
                  _connectionUpgrade = true;
                }
                _headers._add(headerField, tokens[i]);
              }
            } else {
              _headers._add(headerField, headerValue);
            }
            _headerField.clear();
            _headerValue.clear();

            if (byte == _CharCode.CR) {
              _state = _State.HEADER_ENDING;
            } else if (byte == _CharCode.LF) {
              _state = _State.HEADER_ENDING;
              _index--; // Make the new state see the LF again.
            } else {
              // Start of new header field.
              _headerField.add(_toLowerCaseByte(byte));
              _state = _State.HEADER_FIELD;
            }
          }
          break;

        case _State.HEADER_ENDING:
          _expect(byte, _CharCode.LF);
          if (_headersEnd()) {
            return;
          } else {
            break;
          }
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
          if (_remainingContent >= 0 && dataAvailable > _remainingContent) {
            dataAvailable = _remainingContent;
          }
          // Always present the data as a view. This way we can handle all
          // cases like this, and the user will not experience different data
          // typed (which could lead to polymorphic user code).
          List<int> data = new Uint8List.view(
              _buffer.buffer, _buffer.offsetInBytes + _index, dataAvailable);
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
    // onDone cancels the subscription.
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
      _reportError(
          new HttpException("Connection closed before full body was received"));
    }
    _controller.close();
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

  void set isHead(bool value) {
    if (value) _noMessageBody = true;
  }

  _HttpDetachedIncoming detachIncoming() {
    // Simulate detached by marking as upgraded.
    _state = _State.UPGRADED;
    return new _HttpDetachedIncoming(_socketSubscription, readUnparsedData());
  }

  List<int> readUnparsedData() {
    if (_buffer == null) return null;
    if (_index == _buffer.length) return null;
    var result = _buffer.sublist(_index);
    _releaseBuffer();
    return result;
  }

  void _reset() {
    if (_state == _State.UPGRADED) return;
    _state = _State.START;
    _messageType = _MessageType.UNDETERMINED;
    _headerField.clear();
    _headerValue.clear();
    _method.clear();
    _uri_or_reason_phrase.clear();

    _statusCode = 0;
    _statusCodeLength = 0;

    _httpVersion = _HttpVersion.UNDETERMINED;
    _transferLength = -1;
    _persistentConnection = false;
    _connectionUpgrade = false;
    _chunked = false;

    _noMessageBody = false;
    _remainingContent = -1;

    _headers = null;
  }

  void _releaseBuffer() {
    _buffer = null;
    _index = null;
  }

  static bool _isTokenChar(int byte) {
    return byte > 31 && byte < 128 && !_Const.SEPARATOR_MAP[byte];
  }

  static bool _isValueChar(int byte) {
    return (byte > 31 && byte < 128) ||
        (byte == _CharCode.SP) ||
        (byte == _CharCode.HT);
  }

  static List<String> _tokenizeFieldValue(String headerValue) {
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

  static int _toLowerCaseByte(int x) {
    // Optimized version:
    //  -  0x41 is 'A'
    //  -  0x7f is ASCII mask
    //  -  26 is the number of alpha characters.
    //  -  0x20 is the delta between lower and upper chars.
    return (((x - 0x41) & 0x7f) < 26) ? (x | 0x20) : x;
  }

  // expected should already be lowercase.
  bool _caseInsensitiveCompare(List<int> expected, List<int> value) {
    if (expected.length != value.length) return false;
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] != _toLowerCaseByte(value[i])) return false;
    }
    return true;
  }

  int _expect(int val1, int val2) {
    if (val1 != val2) {
      throw new HttpException("Failed to parse HTTP");
    }
  }

  int _expectHexDigit(int byte) {
    if (0x30 <= byte && byte <= 0x39) {
      return byte - 0x30; // 0 - 9
    } else if (0x41 <= byte && byte <= 0x46) {
      return byte - 0x41 + 10; // A - F
    } else if (0x61 <= byte && byte <= 0x66) {
      return byte - 0x61 + 10; // a - f
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
    incoming = _incoming =
        new _HttpIncoming(_headers, transferLength, _bodyController.stream);
    _bodyPaused = true;
    _pauseStateChanged();
  }

  void _closeIncoming([bool closing = false]) {
    // Ignore multiple close (can happen in re-entrance).
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
}
