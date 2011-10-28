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


class SocketOutputStream implements OutputStream {
  SocketOutputStream(Socket socket) : _socket = socket;

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
