// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _StdIOUtils {
  static Stdin _getStdioInputStream() {
    switch (_getStdioHandleType(0)) {
      case _STDIO_HANDLE_TYPE_TERMINAL:
      case _STDIO_HANDLE_TYPE_PIPE:
      case _STDIO_HANDLE_TYPE_SOCKET:
        return new Stdin._(new _Socket._readPipe(0));
      case _STDIO_HANDLE_TYPE_FILE:
        return new Stdin._(new _FileStream.forStdin());
      default:
        throw new FileException("Unsupported stdin type");
    }
  }

  static IOSink _getStdioOutputStream(int fd) {
    assert(fd == 1 || fd == 2);
    switch (_getStdioHandleType(fd)) {
      case _STDIO_HANDLE_TYPE_TERMINAL:
      case _STDIO_HANDLE_TYPE_PIPE:
      case _STDIO_HANDLE_TYPE_SOCKET:
        return new _StdSink(new _Socket._writePipe(fd));
      case _STDIO_HANDLE_TYPE_FILE:
        return new _StdSink(new IOSink(new _FileStreamConsumer.fromStdio(fd)));
      default:
        throw new FileException("Unsupported stdin type");
    }
  }

  static int _socketType(nativeSocket) {
    var result = _getSocketType(nativeSocket);
    if (result is OSError) {
      throw new FileException("Error retreiving socket type", result);
    }
    return result;
  }
}

patch class Stdin {
  /* patch */ int readByteSync() native "Stdin_ReadByte";
  /* patch */ void set echoMode(bool enabled) native "Stdin_SetEchoMode";
  /* patch */ void set lineMode(bool enabled) native "Stdin_SetLineMode";
}


_getStdioHandle(_NativeSocket socket, int num) native "Socket_GetStdioHandle";
_getStdioHandleType(int num) native "File_GetStdioHandleType";
_getSocketType(_NativeSocket nativeSocket) native "Socket_GetType";
