// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

const int _STDIO_HANDLE_TYPE_TERMINAL = 0;
const int _STDIO_HANDLE_TYPE_PIPE = 1;
const int _STDIO_HANDLE_TYPE_FILE = 2;
const int _STDIO_HANDLE_TYPE_SOCKET = 3;
const int _STDIO_HANDLE_TYPE_OTHER = 4;


class _StdStream extends Stream<List<int>> {
  final Stream<List<int>> _stream;

  _StdStream(this._stream);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    return _stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }
}


/**
 * [Stdin] allows both synchronous and asynchronous reads from the standard
 * input stream.
 *
 * Mixing synchronous and asynchronous reads is undefined.
 */
class Stdin extends _StdStream implements Stream<List<int>> {
  Stdin._(Stream<List<int>> stream) : super(stream);

  /**
   * Synchronously read a line from stdin. This call will block until a full
   * line is available.
   *
   * The argument [encoding] can be used to changed how the input should be
   * decoded. Default is [SYSTEM_ENCODING].
   *
   * If [retainNewlines] is `false`, the returned String will not contain the
   * final newline. If `true`, the returned String will contain the line
   * terminator. Default is `false`.
   *
   * If end-of-file is reached after any bytes have been read from stdin,
   * that data is returned.
   * Returns `null` if no bytes preceeded the end of input.
   */
  String readLineSync({Encoding encoding: SYSTEM_ENCODING,
                       bool retainNewlines: false}) {
    const CR = 13;
    const LF = 10;
    final List line = [];
    // On Windows, if lineMode is disabled, only CR is received.
    bool crIsNewline = Platform.isWindows &&
        (stdioType(stdin) == StdioType.TERMINAL) &&
        !lineMode;
    if (retainNewlines) {
      int byte;
      do {
        byte = readByteSync();
        if (byte < 0) {
          break;
        }
        line.add(byte);
      } while (byte != LF && !(byte == CR && crIsNewline));
      if (line.isEmpty) {
        return null;
      }
    } else if (crIsNewline) {
      // CR and LF are both line terminators, neither is retained.
      while (true) {
        int byte = readByteSync();
        if (byte < 0) {
          if (line.isEmpty) return null;
          break;
        }
        if (byte == LF || byte == CR) break;
        line.add(byte);
      }
    } else {
      // Case having to hande CR LF as a single unretained line terminator.
      outer: while (true) {
        int byte = readByteSync();
        if (byte == LF) break;
        if (byte == CR) {
          do {
            byte = readByteSync();
            if (byte == LF) break outer;

            line.add(CR);
          } while (byte == CR);
          // Fall through and handle non-CR character.
        }
        if (byte < 0) {
          if (line.isEmpty) return null;
          break;
        }
        line.add(byte);
      }
    }
    return encoding.decode(line);
  }

  /**
   * Check if echo mode is enabled on [stdin].
   */
  external bool get echoMode;

  /**
   * Enable or disable echo mode on [stdin].
   *
   * If disabled, input from to console will not be echoed.
   *
   * Default depends on the parent process, but usually enabled.
   */
  external void set echoMode(bool enabled);

  /**
   * Check if line mode is enabled on [stdin].
   */
  external bool get lineMode;

  /**
   * Enable or disable line mode on [stdin].
   *
   * If enabled, characters are delayed until a new-line character is entered.
   * If disabled, characters will be available as typed.
   *
   * Default depends on the parent process, but usually enabled.
   */
  external void set lineMode(bool enabled);

  /**
   * Synchronously read a byte from stdin. This call will block until a byte is
   * available.
   *
   * If at end of file, -1 is returned.
   */
  external int readByteSync();
}


/**
 * [Stdout] exposes methods to query the terminal for properties.
 *
 * Use [hasTerminal] to test if there is a terminal associated to stdout.
 */
class Stdout extends _StdSink implements IOSink {
  Stdout._(IOSink sink) : super(sink);

  /**
   * Returns true if there is a terminal attached to stdout.
   */
  external bool get hasTerminal;

  /**
   * Get the number of columns of the terminal.
   *
   * If no terminal is attached to stdout, a [StdoutException] is thrown. See
   * [hasTerminal] for more info.
   */
  external int get terminalColumns;

  /**
   * Get the number of lines of the terminal.
   *
   * If no terminal is attached to stdout, a [StdoutException] is thrown. See
   * [hasTerminal] for more info.
   */
  external int get terminalLines;
}


class StdoutException implements IOException {
  final String message;
  final OSError osError;

  const StdoutException(this.message, [this.osError]);

  String toString() {
    return "StdoutException: $message${osError == null ? "" : ", $osError"}";
  }
}


class _StdSink implements IOSink {
  final IOSink _sink;

  _StdSink(this._sink);

  Encoding get encoding => _sink.encoding;
  void set encoding(Encoding encoding) {
    _sink.encoding = encoding;
  }
  void write(object) => _sink.write(object);
  void writeln([object = "" ]) => _sink.writeln(object);
  void writeAll(objects, [sep = ""]) => _sink.writeAll(objects, sep);
  void add(List<int> data) => _sink.add(data);
  void addError(error, [StackTrace stackTrace]) =>
      _sink.addError(error, stackTrace);
  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);
  Future addStream(Stream<List<int>> stream) => _sink.addStream(stream);
  Future flush() => _sink.flush();
  Future close() => _sink.close();
  Future get done => _sink.done;
}

/// The type of object a standard IO stream is attached to.
class StdioType {
  static const StdioType TERMINAL = const StdioType._("terminal");
  static const StdioType PIPE = const StdioType._("pipe");
  static const StdioType FILE = const StdioType._("file");
  static const StdioType OTHER = const StdioType._("other");
  final String name;
  const StdioType._(this.name);
  String toString() => "StdioType: $name";
}


Stdin _stdin;
Stdout _stdout;
IOSink _stderr;


/// The standard input stream of data read by this program.
Stdin get stdin {
  if (_stdin == null) {
    _stdin = _StdIOUtils._getStdioInputStream();
  }
  return _stdin;
}


/// The standard output stream of data written by this program.
Stdout get stdout {
  if (_stdout == null) {
    _stdout = _StdIOUtils._getStdioOutputStream(1);
  }
  return _stdout;
}


/// The standard output stream of errors written by this program.
IOSink get stderr {
  if (_stderr == null) {
    _stderr = _StdIOUtils._getStdioOutputStream(2);
  }
  return _stderr;
}


/// For a stream, returns whether it is attached to a file, pipe, terminal, or
/// something else.
StdioType stdioType(object) {
  if (object is _StdStream) {
    object = object._stream;
  } else if (object == stdout || object == stderr) {
    switch (_StdIOUtils._getStdioHandleType(object == stdout ? 1 : 2)) {
      case _STDIO_HANDLE_TYPE_TERMINAL: return StdioType.TERMINAL;
      case _STDIO_HANDLE_TYPE_PIPE: return StdioType.PIPE;
      case _STDIO_HANDLE_TYPE_FILE:  return StdioType.FILE;
    }
  }
  if (object is _FileStream) {
    return StdioType.FILE;
  }
  if (object is Socket) {
    switch (_StdIOUtils._socketType(object._nativeSocket)) {
      case _STDIO_HANDLE_TYPE_TERMINAL: return StdioType.TERMINAL;
      case _STDIO_HANDLE_TYPE_PIPE: return StdioType.PIPE;
      case _STDIO_HANDLE_TYPE_FILE:  return StdioType.FILE;
    }
  }
  if (object is IOSink) {
    try {
      if (object._target is _FileStreamConsumer) {
        return StdioType.FILE;
      }
    } catch (e) {
      // Only the interface implemented, _sink not available.
    }
  }
  return StdioType.OTHER;
}


class _StdIOUtils {
  external static _getStdioOutputStream(int fd);
  external static Stdin _getStdioInputStream();
  external static int _socketType(nativeSocket);
  external static _getStdioHandleType(int fd);
}
