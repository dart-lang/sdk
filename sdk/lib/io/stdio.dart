// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

const int _STDIO_HANDLE_TYPE_TERMINAL = 0;
const int _STDIO_HANDLE_TYPE_PIPE = 1;
const int _STDIO_HANDLE_TYPE_FILE = 2;
const int _STDIO_HANDLE_TYPE_SOCKET = 3;
const int _STDIO_HANDLE_TYPE_OTHER = -1;


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


class _StdIOUtils {
  external static OutputStream _getStdioOutputStream(int fd);
  external static InputStream _getStdioInputStream();
}
