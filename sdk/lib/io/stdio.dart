// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_io;

const int _STDIO_HANDLE_TYPE_TERMINAL = 0;
const int _STDIO_HANDLE_TYPE_PIPE = 1;
const int _STDIO_HANDLE_TYPE_FILE = 2;
const int _STDIO_HANDLE_TYPE_SOCKET = 3;
const int _STDIO_HANDLE_TYPE_OTHER = -1;


InputStream _stdin;
OutputStream _stdout;
OutputStream _stderr;


InputStream _getStdioInputStream() {
  switch (_StdIOUtils._getStdioHandleType(0)) {
    case _STDIO_HANDLE_TYPE_TERMINAL:
    case _STDIO_HANDLE_TYPE_PIPE:
    case _STDIO_HANDLE_TYPE_SOCKET:
      Socket s = new _Socket._internalReadOnly();
      _StdIOUtils._getStdioHandle(s, 0);
      s._closed = false;
      return s.inputStream;
    case _STDIO_HANDLE_TYPE_FILE:
      return new _FileInputStream.fromStdio(0);
    default:
      throw new FileIOException("Unsupported stdin type");
  }
}


OutputStream _getStdioOutputStream(int fd) {
  assert(fd == 1 || fd == 2);
  switch (_StdIOUtils._getStdioHandleType(fd)) {
    case _STDIO_HANDLE_TYPE_TERMINAL:
    case _STDIO_HANDLE_TYPE_PIPE:
    case _STDIO_HANDLE_TYPE_SOCKET:
      Socket s = new _Socket._internalWriteOnly();
      _StdIOUtils._getStdioHandle(s, fd);
      s._closed = false;
      return s.outputStream;
    case _STDIO_HANDLE_TYPE_FILE:
      return new _FileOutputStream.fromStdio(fd);
    default:
      throw new FileIOException("Unsupported stdin type");
  }
}


InputStream get stdin {
  if (_stdin == null) {
    _stdin = _getStdioInputStream();
  }
  return _stdin;
}


OutputStream get stdout {
  if (_stdout == null) {
    _stdout = _getStdioOutputStream(1);
  }
  return _stdout;
}


OutputStream get stderr {
  if (_stderr == null) {
    _stderr = _getStdioOutputStream(2);
  }
  return _stderr;
}


class _StdIOUtils {
  external static _getStdioHandle(Socket socket, int num);
  external static _getStdioHandleType(int num);
}
