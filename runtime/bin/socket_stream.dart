// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SocketInputStream implements InputStream {
  SocketInputStream(Socket socket) {
    _socket = socket;
    _buffer = null;
  }

  bool read(List<int> buffer, int offset, int len, void callback()) {
    // Read data just out of the buffer.
    if (_buffer !== null && len <= _buffer.length) {
      buffer.copyFrom(_buffer, 0, offset, len);
      int remainder = _buffer.length - len;
      if (remainder > 0) {
        List<int> newBuffer = new List<int>(remainder);
        newBuffer.copyFrom(_buffer, 0, len, remainder);
        _buffer = newBuffer;
      } else {
        _buffer = null;
      }
      return true;
    }
    // Read data out of the buffer if available and from the socket.
    else {
      int bytesRead = 0;
      if (_buffer !== null) {
        buffer.copyFrom(_buffer, offset, 0, _buffer.length);
        bytesRead = _buffer.length;
        _buffer = null;
      }

      bytesRead +=
          _socket.readList(buffer, offset + bytesRead, len - bytesRead);

      if (bytesRead == len) {
        return true;
      }

      void doRead() {
        bytesRead +=
            _socket.readList(buffer, offset + bytesRead, len - bytesRead);
        if (bytesRead < len) {
          _socket.setDataHandler(doRead);
        } else {
          assert(bytesRead == len);
          _socket.setDataHandler(null);
          if (callback !== null) {
            callback();
          }
        }
      }

      _socket.setDataHandler(doRead);
      return false;
    }
  }

  int _matchPattern(List<int> buffer, List<int> pattern, int start) {
    int j;
    if (pattern.length > buffer.length) {
      return -1;
    }
    for (int i = start; i < (buffer.length - pattern.length + 1); i++) {
      for (j = 0; j < pattern.length; j++) {
        if (buffer[i + j] != pattern[j]) {
          break;
        }
      }
      if (j == pattern.length) {
        return i;
      }
    }
    return -1;
  }

  /*
   * Appends the newBuffer to the buffer (if available), sets the buffer to
   * null, and returns the merged buffer.
   */
  List<int> _getBufferedData(List<int> newBuffer, int appendingBufferSpace) {
    List<int> buffer;
    int newDataStart = 0;
    if (_buffer !== null) {
      buffer = new List<int>(_buffer.length + appendingBufferSpace);
      buffer.copyFrom(_buffer, 0, 0, _buffer.length);
      newDataStart = _buffer.length;
      _buffer = null;
    } else {
      buffer = new List<int>(appendingBufferSpace);
    }
    buffer.copyFrom(newBuffer, 0, newDataStart, appendingBufferSpace);
    return buffer;
  }

  void readUntil(List<int> pattern, void callback(List<int> resultBuffer)) {
    void doRead() {
      List<int> newBuffer;
      if (_buffer != null) {
        newBuffer = _buffer;
      } else {
        int size = _socket.available();
        List<int> buffer = new List<int>(size);
        int result = _socket.readList(buffer, 0, size);
        if (result > 0) {
          // TODO(hpayer): Avoid copying of data before pattern matching.
          newBuffer = _getBufferedData(buffer, result);
        }
      }

      int index = _matchPattern(newBuffer, pattern, 0);
      // If pattern was found return the data including pattern and store the
      // remainder in the buffer.
      if (index != -1) {
        int finalBufferSize = index + pattern.length;
        List<int> finalBuffer = new List<int>(finalBufferSize);
        finalBuffer.copyFrom(newBuffer, 0, 0, finalBufferSize);
        if (finalBufferSize < newBuffer.length) {
          List<int> remainder =
              new List<int>(newBuffer.length - finalBufferSize);
          remainder.copyFrom(newBuffer, finalBufferSize, 0, remainder.length);
          _buffer = remainder;
        } else {
          _buffer = null;
        }
        _socket.setDataHandler(null);
        callback(finalBuffer);
      } else {
        _buffer = newBuffer;
        _socket.setDataHandler(doRead);
      }
    }

    // Register callback for data available.
    _socket.setDataHandler(doRead);

    // If data is already buffered schedule a data available callback.
    if (_buffer != null) {
      _socket._scheduleEvent(_SocketBase._IN_EVENT);
    }
  }

  Socket _socket;

  /*
   * Read and readUntil read data out of that buffer first before reading new
   * data out of the socket.
   */
  List<int> _buffer;
}

class SocketOutputStream implements OutputStream {
  SocketOutputStream(Socket socket) {
    _socket = socket;
  }

  bool write(List<int> buffer, int offset, int len, void callback()) {
    int bytesWritten = _socket.writeList(buffer, offset, len);

    void finishWrite() {
      bytesWritten += _socket.writeList(
          buffer, offset + bytesWritten, len - bytesWritten);
      if (bytesWritten < len) {
        _socket.setWriteHandler(finishWrite);
      } else {
        assert(bytesWritten == len);
        if (callback !== null) {
          callback();
        }
      }
    }

    if (bytesWritten == len) {
      return true;
    }
    _socket.setWriteHandler(finishWrite);
    return false;
  }

  Socket _socket;
}
