// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class _StdIOUtils {
  @patch
  static Stdin _getStdioInputStream() {
    switch (_getStdioHandleType(0)) {
      case _STDIO_HANDLE_TYPE_TERMINAL:
      case _STDIO_HANDLE_TYPE_PIPE:
      case _STDIO_HANDLE_TYPE_SOCKET:
        return new Stdin._(new _Socket._readPipe(0));
      case _STDIO_HANDLE_TYPE_FILE:
        return new Stdin._(new _FileStream.forStdin());
      default:
        throw new FileSystemException(
            "Couldn't determine file type of stdin (fd 0)");
    }
  }

  @patch
  static _getStdioOutputStream(int fd) {
    assert(fd == 1 || fd == 2);
    switch (_getStdioHandleType(fd)) {
      case _STDIO_HANDLE_TYPE_TERMINAL:
      case _STDIO_HANDLE_TYPE_PIPE:
      case _STDIO_HANDLE_TYPE_SOCKET:
      case _STDIO_HANDLE_TYPE_FILE:
        return new Stdout._(new IOSink(new _StdConsumer(fd)), fd);
      default:
        throw new FileSystemException(
            "Couldn't determine file type of stdio handle (fd $fd)");
    }
  }

  @patch
  static int _socketType(Socket socket) {
    if (socket is _Socket) return _nativeSocketType(socket._nativeSocket);
    return null;
  }

  static int _nativeSocketType(_NativeSocket nativeSocket) {
    var result = _getSocketType(nativeSocket);
    if (result is OSError) {
      throw new FileSystemException("Error retrieving socket type", "", result);
    }
    return result;
  }

  @patch
  static _getStdioHandleType(int fd) native "File_GetStdioHandleType";
}

@patch
class Stdin {
  @patch
  int readByteSync() {
    var result = _readByte();
    if (result is OSError) {
      throw new StdinException("Error reading byte from stdin", result);
    }
    return result;
  }

  @patch
  bool get echoMode {
    var result = _echoMode();
    if (result is OSError) {
      throw new StdinException("Error getting terminal echo mode", result);
    }
    return result;
  }

  @patch
  void set echoMode(bool enabled) {
    if (!_EmbedderConfig._maySetEchoMode) {
      throw new UnsupportedError(
          "This embedder disallows setting Stdin.echoMode");
    }
    var result = _setEchoMode(enabled);
    if (result is OSError) {
      throw new StdinException("Error setting terminal echo mode", result);
    }
  }

  @patch
  bool get lineMode {
    var result = _lineMode();
    if (result is OSError) {
      throw new StdinException("Error getting terminal line mode", result);
    }
    return result;
  }

  @patch
  void set lineMode(bool enabled) {
    if (!_EmbedderConfig._maySetLineMode) {
      throw new UnsupportedError(
          "This embedder disallows setting Stdin.lineMode");
    }
    var result = _setLineMode(enabled);
    if (result is OSError) {
      throw new StdinException("Error setting terminal line mode", result);
    }
  }

  @patch
  bool get supportsAnsiEscapes {
    var result = _supportsAnsiEscapes();
    if (result is OSError) {
      throw new StdinException("Error determining ANSI support", result);
    }
    return result;
  }

  static _echoMode() native "Stdin_GetEchoMode";
  static _setEchoMode(bool enabled) native "Stdin_SetEchoMode";
  static _lineMode() native "Stdin_GetLineMode";
  static _setLineMode(bool enabled) native "Stdin_SetLineMode";
  static _readByte() native "Stdin_ReadByte";
  static _supportsAnsiEscapes() native "Stdin_AnsiSupported";
}

@patch
class Stdout {
  @patch
  bool _hasTerminal(int fd) {
    try {
      _terminalSize(fd);
      return true;
    } catch (_) {
      return false;
    }
  }

  @patch
  int _terminalColumns(int fd) => _terminalSize(fd)[0];
  @patch
  int _terminalLines(int fd) => _terminalSize(fd)[1];

  static List _terminalSize(int fd) {
    var size = _getTerminalSize(fd);
    if (size is! List) {
      throw new StdoutException("Could not get terminal size", size);
    }
    return size;
  }

  static _getTerminalSize(int fd) native "Stdout_GetTerminalSize";

  @patch
  static bool _supportsAnsiEscapes(int fd) {
    var result = _getAnsiSupported(fd);
    if (result is! bool) {
      throw new StdoutException("Error determining ANSI support", result);
    }
    return result;
  }

  static _getAnsiSupported(int fd) native "Stdout_AnsiSupported";
}

_getStdioHandle(_NativeSocket socket, int num) native "Socket_GetStdioHandle";
_getSocketType(_NativeSocket nativeSocket) native "Socket_GetType";
