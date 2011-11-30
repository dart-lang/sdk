// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("builtin");
#import("dart:nativewrappers");
#import("dart:coreimpl");

void print(arg) {
  _Logger._printString(arg.toString());
}

void exit(int status) {
  if (status is !int) {
    throw new IllegalArgumentException("int status expected");
  }
  _exit(status);
}

Socket _stdin;
InputStream get stdin() {
  if (_stdin == null) {
    _stdin = new _Socket._internalReadOnly();
    _getStdioHandle(_stdin, 0);
  }
  return _stdin.inputStream;
}

Socket _stdout;
OutputStream get stdout() {
  if (_stdout == null) {
    _stdout = new _Socket._internalWriteOnly();
    _getStdioHandle(_stdout, 1);
  }
  return _stdout.outputStream;
}

Socket _stderr;
OutputStream get stderr() {
  if (_stderr == null) {
    _stderr = new _Socket._internalWriteOnly();
    _getStdioHandle(_stderr, 2);
  }
  return _stderr.outputStream;
}

_exit(int status) native "Exit";

_getStdioHandle(Socket socket, int num) native "Socket_GetStdioHandle";

class _Logger {
  static void _printString(String s) native "Logger_PrintString";
}
