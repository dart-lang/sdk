// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

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
    if (len == null) len = buffer.length;
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
    if (_clientCloseHandler != null) {
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
    if (_closing) return;
    _closing = true;
    if (!_pendingWrites.isEmpty) {
      // Mark the socket for close when all data is written.
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
    _socket._onWrite = null;
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
    if (_closing || _closed) {
      if (_error) return false;
      _error = true;
      var e = new StreamException.streamClosed();
      if (_onError != null) {
        _onError(e);
        return false;
      } else {
        throw e;
      }
    }
    int bytesWritten = 0;
    if (_pendingWrites.isEmpty) {
      // If nothing is buffered write as much as possible and buffer
      // the rest.
      try {
        bytesWritten = _socket.writeList(buffer, offset, len);
        if (bytesWritten == len) return true;
      } catch (e) {
        if (_error) return false;
        _error = true;
        if (_onError != null) {
          _onError(e);
          return false;
        } else {
          throw e;
        }
      }
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
        if (_onError != null) _onError(e);
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
    destroy();
    if (_error) return true;
    if (_onError != null) {
      _onError(e);
      return true;
    } else {
      throw e;
    }
  }

  Socket _socket;
  _BufferList _pendingWrites;
  Function _onNoPendingWrites;
  Function _onClosed;
  bool _closing = false;
  bool _closed = false;
  bool _error = false;
}
