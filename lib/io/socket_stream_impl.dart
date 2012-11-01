// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SocketInputStream implements InputStream {
  _SocketInputStream(Socket socket) : _socket = socket {
    if (_socket._closed) _closed = true;
    _socket.onClosed = _onClosed;
  }

  List<int> read([int len]) {
    return _socket.read(len);
  }

  int readInto(List<int> buffer, [int offset = 0, int len]) {
    if (_closed) return null;
    if (len === null) len = buffer.length;
    if (offset < 0) throw new StreamException("Illegal offset $offset");
    if (len < 0) throw new StreamException("Illegal length $len");
    return _socket.readList(buffer, offset, len);
  }

  int available() => _socket.available();

  void pipe(OutputStream output, {bool close: true}) {
    _pipe(this, output, close: close);
  }

  void close() {
    if (!_closed) {
      _socket.close();
    }
  }

  bool get closed => _closed;

  void set onData(void callback()) {
    _socket._onData = callback;
  }

  void set onClosed(void callback()) {
    _clientCloseHandler = callback;
    _socket._onClosed = _onClosed;
  }

  void set onError(void callback(e)) {
    _onError = callback;
  }

  void _onClosed() {
    _closed = true;
    if (_clientCloseHandler !== null) {
      _clientCloseHandler();
    }
  }

  bool _onSocketError(e) {
    close();
    if (_onError != null) {
      _onError(e);
      return true;
    } else {
      return false;
    }
  }

  Socket _socket;
  bool _closed = false;
  Function _clientCloseHandler;
  Function _onError;
}


class _SocketOutputStream
    extends _BaseOutputStream implements OutputStream {
  _SocketOutputStream(Socket socket)
      : _socket = socket, _pendingWrites = new _BufferList();

  bool write(List<int> buffer, [bool copyBuffer = true]) {
    return _write(buffer, 0, buffer.length, copyBuffer);
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    return _write(
        buffer, offset, (len == null) ? buffer.length - offset : len, true);
  }

  void flush() {
    // Nothing to do on a socket output stream.
  }

  void close() {
    if (_closing && _closed) return;
    if (!_pendingWrites.isEmpty) {
      // Mark the socket for close when all data is written.
      _closing = true;
      _socket._onWrite = _onWrite;
    } else {
      // Close the socket for writing.
      _socket._closeWrite();
      _closed = true;
      // Invoke the callback asynchronously.
      new Timer(0, (t) {
        if (_onClosed != null) _onClosed();
      });
    }
  }

  void destroy() {
    _socket.onWrite = null;
    _pendingWrites.clear();
    _socket.close();
    _closed = true;
  }

  bool get closed => _closed;

  void set onNoPendingWrites(void callback()) {
    _onNoPendingWrites = callback;
    if (_onNoPendingWrites != null) {
      _socket._onWrite = _onWrite;
    }
  }

  void set onClosed(void callback()) {
    _onClosed = callback;
  }

  bool _write(List<int> buffer, int offset, int len, bool copyBuffer) {
    if (_closing || _closed) throw new StreamException("Stream closed");
    int bytesWritten = 0;
    if (_pendingWrites.isEmpty) {
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
    _socket._onWrite = _onWrite;
    return false;
  }

  void _onWrite() {
    // Write as much buffered data to the socket as possible.
    while (!_pendingWrites.isEmpty) {
      List<int> buffer = _pendingWrites.first;
      int offset = _pendingWrites.index;
      int bytesToWrite = buffer.length - offset;
      int bytesWritten;
      try {
        bytesWritten = _socket.writeList(buffer, offset, bytesToWrite);
      } catch (e) {
        _pendingWrites.clear();
        _onSocketError(e);
        return;
      }
      _pendingWrites.removeBytes(bytesWritten);
      if (bytesWritten < bytesToWrite) {
        _socket._onWrite = _onWrite;
        return;
      }
    }

    // All buffered data was written.
    if (_closing) {
      _socket._closeWrite();
      _closed = true;
      if (_onClosed != null) {
        _onClosed();
      }
    } else {
      if (_onNoPendingWrites != null) _onNoPendingWrites();
    }
    if (_onNoPendingWrites == null) {
      _socket._onWrite = null;
    } else {
      _socket._onWrite = _onWrite;
    }
  }

  bool _onSocketError(e) {
    close();
    if (_onError != null) {
      _onError(e);
      return true;
    } else {
      return false;
    }
  }

  Socket _socket;
  _BufferList _pendingWrites;
  Function _onNoPendingWrites;
  Function _onClosed;
  bool _closing = false;
  bool _closed = false;
}
