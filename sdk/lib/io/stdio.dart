// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

const int _STDIO_HANDLE_TYPE_TERMINAL = 0;
const int _STDIO_HANDLE_TYPE_PIPE = 1;
const int _STDIO_HANDLE_TYPE_FILE = 2;
const int _STDIO_HANDLE_TYPE_SOCKET = 3;
const int _STDIO_HANDLE_TYPE_OTHER = -1;


class StdioType {
  static const StdioType TERMINAL = const StdioType._("terminal");
  static const StdioType PIPE = const StdioType._("pipe");
  static const StdioType FILE = const StdioType._("file");
  static const StdioType OTHER = const StdioType._("other");
  const StdioType._(String this.name);
  final String name;
}


InputStream _stdin;
OutputStream _stdout;
OutputStream _stderr;


InputStream get stdin {
  if (_stdin == null) {
    _stdin = _StdIOUtils._getStdioInputStream();
  }
  return _stdin;
}


OutputStream get stdout {
  if (_stdout == null) {
    _stdout = _StdIOUtils._getStdioOutputStream(1);
  }
  return _stdout;
}


OutputStream get stderr {
  if (_stderr == null) {
    _stderr = _StdIOUtils._getStdioOutputStream(2);
  }
  return _stderr;
}


StdioType stdioType(object) {
  if (object is _FileOutputStream || object is _FileInputStream) {
    return StdioType.FILE;
  }
  if (object is !_SocketOutputStream && object is !_SocketInputStream) {
    return StdioType.OTHER;
  }
  switch (_StdIOUtils._socketType(object._socket)) {
    case _STDIO_HANDLE_TYPE_TERMINAL: return StdioType.TERMINAL;
    case _STDIO_HANDLE_TYPE_PIPE: return StdioType.PIPE;
    case _STDIO_HANDLE_TYPE_FILE:  return StdioType.FILE;
    default: return StdioType.OTHER;
  }
}


class _StdIOUtils {
  external static OutputStream _getStdioOutputStream(int fd);
  external static InputStream _getStdioInputStream();
  external static int _socketType(Socket socket);
}
