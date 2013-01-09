// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _StdIOUtils {
  static InputStream _getStdioInputStream() {
    switch (_getStdioHandleType(0)) {
      case _STDIO_HANDLE_TYPE_TERMINAL:
      case _STDIO_HANDLE_TYPE_PIPE:
      case _STDIO_HANDLE_TYPE_SOCKET:
        Socket s = new _Socket._internalReadOnly();
        _getStdioHandle(s, 0);
        s._closed = false;
        return s.inputStream;
      case _STDIO_HANDLE_TYPE_FILE:
        return new _FileInputStream.fromStdio(0);
      default:
        throw new FileIOException("Unsupported stdin type");
    }
  }

  static OutputStream _getStdioOutputStream(int fd) {
    assert(fd == 1 || fd == 2);
    switch (_getStdioHandleType(fd)) {
      case _STDIO_HANDLE_TYPE_TERMINAL:
      case _STDIO_HANDLE_TYPE_PIPE:
      case _STDIO_HANDLE_TYPE_SOCKET:
        Socket s = new _Socket._internalWriteOnly();
        _getStdioHandle(s, fd);
        s._closed = false;
        return s.outputStream;
      case _STDIO_HANDLE_TYPE_FILE:
        return new _FileOutputStream.fromStdio(fd);
      default:
        throw new FileIOException("Unsupported stdin type");
    }
  }

  static int _socketType(Socket socket) {
    return _getSocketType(socket);
  }
}


_getStdioHandle(Socket socket, int num) native "Socket_GetStdioHandle";
_getStdioHandleType(int num) native "File_GetStdioHandleType";
_getSocketType(Socket socket) native "Socket_GetType";
