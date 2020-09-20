// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class _StdIOUtils {
  @patch
  static Stdin _getStdioInputStream(int fd) {
    final type = _getStdioHandleType(fd);
    if (type is OSError) {
      throw FileSystemException(
          "Failed to get type of stdio handle (fd $fd)", "", type);
    }
    switch (type) {
      case _stdioHandleTypeTerminal:
      case _stdioHandleTypePipe:
      case _stdioHandleTypeSocket:
      case _stdioHandleTypeOther:
        return new Stdin._(new _Socket._readPipe(fd), fd);
      case _stdioHandleTypeFile:
        return new Stdin._(new _FileStream.forStdin(), fd);
    }
    throw new UnsupportedError("Unexpected handle type $type");
  }

  @patch
  static _getStdioOutputStream(int fd) {
    final type = _getStdioHandleType(fd);
    if (type is OSError) {
      throw FileSystemException(
          "Failed to get type of stdio handle (fd $fd)", "", type);
    }
    return new Stdout._(new IOSink(new _StdConsumer(fd)), fd);
  }

  @patch
  static int? _socketType(Socket socket) {
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
    var result = _readByte(_fd);
    if (result is OSError) {
      throw new StdinException("Error reading byte from stdin", result);
    }
    return result;
  }

  @patch
  bool get echoMode {
    var result = _echoMode(_fd);
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
    var result = _setEchoMode(_fd, enabled);
    if (result is OSError) {
      throw new StdinException("Error setting terminal echo mode", result);
    }
  }

  @patch
  bool get lineMode {
    var result = _lineMode(_fd);
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
    var result = _setLineMode(_fd, enabled);
    if (result is OSError) {
      throw new StdinException("Error setting terminal line mode", result);
    }
  }

  @patch
  bool get supportsAnsiEscapes {
    var result = _supportsAnsiEscapes(_fd);
    if (result is OSError) {
      throw new StdinException("Error determining ANSI support", result);
    }
    return result;
  }

  static _echoMode(int fd) native "Stdin_GetEchoMode";
  static _setEchoMode(int fd, bool enabled) native "Stdin_SetEchoMode";
  static _lineMode(int fd) native "Stdin_GetLineMode";
  static _setLineMode(int fd, bool enabled) native "Stdin_SetLineMode";
  static _readByte(int fd) native "Stdin_ReadByte";
  static _supportsAnsiEscapes(int fd) native "Stdin_AnsiSupported";
}

@patch
class Stdout {
  @patch
  bool _hasTerminal(int fd) => _getTerminalSize(fd) is List;
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

bool _getStdioHandle(_NativeSocket socket, int num)
    native "Socket_GetStdioHandle";
_getSocketType(_NativeSocket nativeSocket) native "Socket_GetType";
