// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SocketInputStream implements InputStream {
  SocketInputStream(Socket socket) {
    _socket = socket;
  }

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

  int available() {
    return _socket.available();
  }

  void set dataHandler(void callback()) {
    _socket.setDataHandler(callback);
  }

  void set closeHandler(void callback()) {
    _socket.setCloseHandler(callback);
  }

  void set errorHandler(void callback()) {
    _socket.setErrorHandler(callback);
  }

  Socket _socket;
}


class _BufferList2 {
  _BufferList2() {
    clear();
  }

  // Adds a new buffer to the list possibly with an offset of the
  // first byte of interest. The offset can only be specified if the
  // buffer list is empty.
  void add(List<int> buffer, [int offset = 0]) {
    assert(offset == 0 || _buffers.isEmpty());
    _buffers.addLast(buffer);
    _length += buffer.length;
    if (offset != 0) _index = offset;
  }

  List<int> get first() => _buffers.first();
  int get index() => _index;

  void removeBytes(int count) {
    int firstRemaining = first.length - _index;
    assert(count <= firstRemaining);
    if (count == firstRemaining) {
      _buffers.removeFirst();
      _index = 0;
    } else {
      _index += count;
    }
    _length -= count;
  }

  int get length() => _length;

  bool isEmpty() => _buffers.isEmpty();

  void clear() {
    _index = 0;
    _length = 0;
    _buffers = new Queue();
  }

  int _length;  // Total length of pending data.
  Queue<List<int>> _buffers;
  int _index;  // Offset into the first buffer of next write position.
}


class SocketOutputStream implements OutputStream {
  SocketOutputStream(Socket socket)
      : _socket = socket, _pendingWrites = new _BufferList2() {
    _socket.setWriteHandler(_writeHandler);
    _socket.setErrorHandler(_errorHandler);
  }

  bool write(List<int> buffer) {
    return _write(buffer, 0, buffer.length, false);
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    return _write(buffer, offset, (len == null) ? buffer.length : len, true);
  }

  void end() {
    if (_ending || _ended) throw new StreamException("Stream ended");
    _ending = true;
    if (_pendingWrites.isEmpty()) {
      close();
    }
  }

  void close() {
    _socket.setWriteHandler(null);
    _pendingWrites.clear();
    _socket.close();
    _ended = true;
  }

  void set noPendingWriteHandler(void callback()) {
    _noPendingWriteHandler = callback;
    _socket.setWriteHandler(_writeHandler);
  }

  void set closeHandler(void callback()) {
    _socket.setCloseHandler(callback());
  }

  void set errorHandler(void callback()) {
    _streamErrorHandler = callback();
  }

  bool _write(List<int> buffer, int offset, int len, bool copyBuffer) {
    if (_ending || _ended) throw new StreamException("Stream ended");
    if (len == null) len = buffer.length;
    int bytesWritten = 0;
    if (_pendingWrites.isEmpty()) {
      // If nothing is buffered write as much as possible and buffer
      // the rest.
      bytesWritten = _socket.writeList(buffer, offset, len);
      if (bytesWritten == len) return true;
    }

    // Place remaining data on the pending writes queue.
    if (copyBuffer) {
      List<int> newBuffer =
          buffer.getRange(offset + bytesWritten, buffer.length);
      _pendingWrites.add(newBuffer);
    } else {
      _pendingWrites.add(buffer, bytesWritten);
    }
  }

  void _writeHandler() {
    _socket.setWriteHandler(_writeHandler);
    // Write as much buffered data to the socket as possible.
    while (!_pendingWrites.isEmpty()) {
      List<int> buffer = _pendingWrites.first;
      int offset = _pendingWrites.index;
      int bytesToWrite = buffer.length - offset;
      int bytesWritten = _socket.writeList(buffer, offset, bytesToWrite);
      _pendingWrites.removeBytes(bytesWritten);
      if (bytesWritten < bytesToWrite) return;
    }

    // All buffered data was written.
    if (_ending) {
      _socket.close();
      _ended = true;
    } else {
      if (_noPendingWriteHandler != null) _noPendingWriteHandler();
    }
  }

  void _errorHandler() {
    close();
    if (_streamErrorHandler != null) _streamErrorHandler();
  }

  Socket _socket;
  _BufferList2 _pendingWrites;
  bool _ending = false;
  bool _ended = false;
  var _noPendingWriteHandler;
  var _streamErrorHandler;
}
