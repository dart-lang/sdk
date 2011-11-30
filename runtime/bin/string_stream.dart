// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Interface for decoders decoding binary data into objects of type T.
interface _Decoder<T> {
  // Add more binary data to be decoded. The ownership of the buffer
  // is transfered to the decoder and the caller most not modify it any more.
  int write(List<int> buffer);

  // Returns whether any decoded data is available.
  bool isEmpty();

  // Get the data decoded since the last call to decode.
  T get decoded();
}


class DecoderException implements Exception {
  const DecoderException([String this.message]);
  String toString() => "DecoderException: $message";
  final String message;
}


// Utility class for decoding UTF-8 from data delivered as a stream of
// bytes.
class _StringDecoderBase implements _Decoder<String> {
  _StringDecoderBase()
      : _bufferList = new _BufferList(),
        _result = new List<int>();

  // Add UTF-8 encoded data.
  int write(List<int> buffer) {
    _bufferList.add(buffer);
    // Decode as many bytes into characters as possible.
    while (_bufferList.length > 0) {
      if (!_processNext()) {
        break;
      }
    }
    return buffer.length;
  }

  // Check if any characters have been decoded since the last call to decode.
  bool isEmpty() {
    return _result.isEmpty();
  }

  // Return the string decoded since the last call to decode.
  String get decoded() {
    if (isEmpty()) {
      return null;
    } else {
      String result =  new String.fromCharCodes(_result);
      _result = new List<int>();
      return result;
    }
  }

  abstract bool _processNext();

  _BufferList _bufferList;
  List<int> _result;
}


// Utility class for decoding ascii data delivered as a stream of
// bytes.
class _AsciiDecoder extends _StringDecoderBase {
  // Process the next ascii encoded character.
  bool _processNext() {
    while (_bufferList.length > 0) {
      int byte = _bufferList.next();
      if (byte > 127) {
        throw new DecoderException("Illegal ASCII character $byte");
      }
      _result.add(byte);
    }
    return true;
  }
}


// Utility class for decoding Latin-1 data delivered as a stream of
// bytes.
class _Latin1Decoder extends _StringDecoderBase {
  // Process the next Latin-1 encoded character.
  bool _processNext() {
    while (_bufferList.length > 0) {
      int byte = _bufferList.next();
      _result.add(byte);
    }
    return true;
  }
}


// Utility class for decoding UTF-8 from data delivered as a stream of
// bytes.
class _UTF8Decoder extends _StringDecoderBase {
  // Process the next UTF-8 encoded character.
  bool _processNext() {
    // Peek the next byte to calculate the number of bytes required for
    // the next character.
    int value = _bufferList.peek() & 0xFF;
    if ((value & 0x80) == 0x80) {
      int additionalBytes;
      if ((value & 0xe0) == 0xc0) {  // 110xxxxx
        value = value & 0x1F;
        additionalBytes = 1;
      } else if ((value & 0xf0) == 0xe0) {  // 1110xxxx
        value = value & 0x0F;
        additionalBytes = 2;
      } else {  // 11110xxx
        value = value & 0x07;
        additionalBytes = 3;
      }
      // Check if there are enough bytes to decode the character. Otherwise
      // return false.
      if (_bufferList.length < additionalBytes + 1) {
        return false;
      }
      // Remove the value peeked from the buffer list.
      _bufferList.next();
      for (int i = 0; i < additionalBytes; i++) {
        int byte = _bufferList.next();
        value = value << 6 | (byte & 0x3F);
      }
    } else {
      // Remove the value peeked from the buffer list.
      _bufferList.next();
    }
    _result.add(value);
    return true;
  }
}


class _StringInputStream implements StringInputStream {
  _StringInputStream(InputStream this._input, [String encoding])
      : _encoding = encoding {
    if (_encoding === null) {
      _encoding = "UTF-8";
    }
    if (_encoding == "UTF-8") {
      _decoder = new _UTF8Decoder();
    } else if (_encoding == "ISO-8859-1") {
      _decoder = new _Latin1Decoder();
    } else if (_encoding == "ASCII") {
      _decoder = new _AsciiDecoder();
    } else {
      throw new StreamException("Unsupported encoding $_encoding");
    }
    _input.dataHandler = _dataHandler;
    _input.closeHandler = _closeHandler;
  }

  String read() {
    // If there is buffered data return that first.
    var decodedString = _decoder.decoded;
    if (_buffer !== null) {
      var result = _buffer;
      _resetBuffer();
      if (decodedString !== null) result += decodedString;
      return result;
    } else {
      if (decodedString !== null) {
        return decodedString;
      } else if (_inputClosed) {
        _streamClosed();
        return null;
      } else {
        _readData();
        return _decoder.decoded;
      }
    }
  }

  String readLine() {
    if (_closed) return null;
    // Get line from the buffer if possible.
    if (_buffer !== null) {
      var result = _readLineFromBuffer();
      if (result !== null) return result;
    }
    // Try to fill more data into the buffer and read a line.
    if (_fillBuffer()) {
      if (_eof && _buffer === null) {
        _streamClosed();
        return null;
      }
      return _readLineFromBuffer();
    }
    return null;
  }

  String get encoding() => _encoding;

  bool get closed() => _closed;

  void set dataHandler(void callback()) {
    _clientDataHandler = callback;
  }

  void set closeHandler(void callback()) {
    _clientCloseHandler = callback;
  }

  void _dataHandler() {
    _readData();
    if (!_decoder.isEmpty() && _clientDataHandler !== null) {
      _clientDataHandler();
    }
  }

  void _closeHandler() {
    _inputClosed = true;
    if (_buffer !== null || !_decoder.isEmpty()) {
      // If there is still data buffered in either the buffer or the
      // decoder call the data handler.
      if (_clientDataHandler !== null) _clientDataHandler();
    } else {
      _closed = true;
      if (_clientCloseHandler !== null) _clientCloseHandler();
    }
  }

  void _readData() {
    List<int> data = _input.read();
    if (data !== null) {
      _decoder.write(data);
    }
  }

  String _readLineFromBuffer() {
    // Both \n or \r indicates a new line. If \r is followed by \n the
    // \n is part of the line breaking character.
    for (int i = _bufferLineStart; i < _buffer.length; i++) {
      String char = _buffer[i];
      if (char == '\r') {
        if (i == _buffer.length - 1) {
          if (_eof) {
            var result = _buffer.substring(_bufferLineStart, i);
            _resetBuffer();
            _streamClosed();
            return result;
          } else {
            return null;
          }
        }
        var result = _buffer.substring(_bufferLineStart, i);
        _bufferLineStart = i + 1;
        if (_buffer[_bufferLineStart] == '\n') _bufferLineStart++;
        if (_bufferLineStart == _buffer.length) _resetBuffer();
        return result;
      } else if (char == '\n') {
        var result = _buffer.substring(_bufferLineStart, i);
        _bufferLineStart = i + 1;
        if (_bufferLineStart == _buffer.length) _resetBuffer();
        return result;
      }
    }
    if (_eof) {
      var result = _buffer;
      _resetBuffer();
      _streamClosed();
      return result;
    }
    return null;
  }

  void _resetBuffer() {
    _buffer = null;
    _bufferLineStart = null;
  }

  // Fill decoded data into the buffer. Returns true if more data was
  // added or end of file was reached.
  bool _fillBuffer() {
    if (_eof) return false;
    if (!_inputClosed) _readData();
    var decodedString = _decoder.decoded;
    if (decodedString === null && _inputClosed) {
      _eof = true;
      return true;
    }
    if (_buffer === null) {
      _buffer = decodedString;
      if (_buffer !== null) {
        _bufferLineStart = 0;
        return true;
      }
    } else if (decodedString !== null) {
      _buffer = _buffer.substring(_bufferLineStart) + decodedString;
      _bufferLineStart = 0;
      return true;
    }
    return false;
  }

  void _streamClosed() {
    _closed = true;

    // TODO(sgjesse): Find a better way of scheduling callbacks from
    // the event loop.
    void issueCloseCallback(Timer timer) {
      if (_clientCloseHandler !== null) _clientCloseHandler();
    }
    new Timer(issueCloseCallback, 0, false);
  }

  InputStream _input;
  String _encoding;
  _Decoder _decoder;
  String _buffer;  // String can be buffered here if readLine is used.
  int _bufferLineStart;  // Current offset into _buffer if any.
  bool _inputClosed = false;  // Is the underlying input stream closed?
  bool _closed = false;  // Is this stream closed.
  bool _eof = false;  // Has all data been read from the decoder?
  var _clientDataHandler;
  var _clientCloseHandler;
}
