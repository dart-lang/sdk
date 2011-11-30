// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SocketInputStream implements InputStream {
  SocketInputStream(Socket socket) : _socket = socket;

  List<int> read([int len]) {
    int bytesToRead = available();
    if (bytesToRead == 0) return null;
    if (len !== null) {
      if (len <= 0) {
        throw new StreamException("Illegal length $len");
      } else if (bytesToRead > len) {
        bytesToRead = len;
      }
    }
    List<int> buffer = new List<int>(bytesToRead);
    int bytesRead = _socket.readList(buffer, 0, bytesToRead);
    if (bytesRead < bytesToRead) {
      List<int> newBuffer = new List<int>(bytesRead);
      newBuffer.copyFrom(buffer, 0, 0, bytesRead);
      return newBuffer;
    } else {
      return buffer;
    }
  }

  int readInto(List<int> buffer, int offset, int len) {
    if (offset === null) offset = 0;
    if (len === null) len = buffer.length;
    if (offset < 0) throw new StreamException("Illegal offset $offset");
    if (len < 0) throw new StreamException("Illegal length $len");
    return _socket.readList(buffer, offset, len);
  }

  int available() => _socket.available();

  void set dataHandler(void callback()) {
    _socket.dataHandler = callback;
  }

  void set closeHandler(void callback()) {
    _socket.closeHandler = callback;
  }

  void set errorHandler(void callback()) {
    _socket.errorHandler = callback;
  }

  Socket _socket;
}


class SocketOutputStream implements OutputStream {
  SocketOutputStream(Socket socket)
      : _socket = socket, _pendingWrites = new _BufferList();

  bool write(List<int> buffer, [bool copyBuffer = true]) {
    return _write(buffer, 0, buffer.length, copyBuffer);
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    return _write(
        buffer, offset, (len == null) ? buffer.length - offset : len, true);
  }

  void close() {
    if (!_pendingWrites.isEmpty()) {
      // Mark the socket for close when all data is written.
      _closing = true;
      _socket.writeHandler = _writeHandler;
    } else {
      // Close the socket for writing.
      _socket._closeWrite();
      _closed = true;
    }
  }

  void destroy() {
    _socket.writeHandler = null;
    _pendingWrites.clear();
    _socket.close();
    _closed = true;
  }

  void set noPendingWriteHandler(void callback()) {
    _noPendingWriteHandler = callback;
    if (_noPendingWriteHandler != null) {
      _socket.writeHandler = _writeHandler;
    }
  }

  void set closeHandler(void callback()) {
    _socket.closeHandler = callback;
  }

  void set errorHandler(void callback()) {
    _streamErrorHandler = callback;
    if (_streamErrorHandler != null) {
      _socket.errorHandler = _errorHandler;
    } else {
      _socket.errorHandler = null;
    }
  }

  bool _write(List<int> buffer, int offset, int len, bool copyBuffer) {
    if (_closing || _closed) throw new StreamException("Stream closed");
    int bytesWritten = 0;
    if (_pendingWrites.isEmpty()) {
      // If nothing is buffered write as much as possible and buffer
      // the rest.
      bytesWritten = _socket.writeList(buffer, offset, len);
      if (bytesWritten == len) return true;
    }

    // Place remaining data on the pending writes queue.
    int notWrittenOffset = offset + bytesWritten;
    if (copyBuffer) {
      List<int> newBuffer =
          buffer.getRange(notWrittenOffset, len - bytesWritten);
      _pendingWrites.add(newBuffer);
    } else {
      assert(offset + len == buffer.length);
      _pendingWrites.add(buffer, notWrittenOffset);
    }
    _socket.writeHandler = _writeHandler;
    return false;
  }

  void _writeHandler() {
    // Write as much buffered data to the socket as possible.
    while (!_pendingWrites.isEmpty()) {
      List<int> buffer = _pendingWrites.first;
      int offset = _pendingWrites.index;
      int bytesToWrite = buffer.length - offset;
      int bytesWritten = _socket.writeList(buffer, offset, bytesToWrite);
      _pendingWrites.removeBytes(bytesWritten);
      if (bytesWritten < bytesToWrite) {
        _socket.writeHandler = _writeHandler;
        return;
      }
    }

    // All buffered data was written.
    if (_closing) {
      _socket._closeWrite();
      _closed = true;
    } else {
      if (_noPendingWriteHandler != null) _noPendingWriteHandler();
    }
    if (_noPendingWriteHandler == null) _socket.writeHandler = null;
  }

  void _errorHandler() {
    close();
    if (_streamErrorHandler != null) _streamErrorHandler();
  }

  Socket _socket;
  _BufferList _pendingWrites;
  var _noPendingWriteHandler;
  var _streamErrorHandler;
  bool _closing = false;
  bool _closed = false;
}
