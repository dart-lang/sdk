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

  _StdStream(Stream<List<int>> this._stream);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {void onError(error),
                                        void onDone(),
                                        bool cancelOnError}) {
    return _stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }
}


class _StdinEventSink {
  Function add;
  Function addError;
  Function close;
  _StdinEventSink(this.add, this.addError, this.close);
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
   * line is available. The line will contain the newline character(s).
   *
   * If end-of-file is reached, `null` is returned.
   *
   * If end-of-file is reached after some data has already been read, that data
   * is returned.
   */
  String readLineSync({Encoding encoding: Encoding.SYSTEM,
                       bool retainNewlines: false}) {
    var decoder = new StringDecoder(encoding)._decoder;
    var line = new StringBuffer();
    bool end = false;
    bool lastCharWasCR = false;
    var sink = new _StdinEventSink(
        (char) {
          if (!retainNewlines && char == '\r') {
            if (lastCharWasCR) line.write('\r');
            lastCharWasCR = true;
            return;
          } else if (char == '\n') {
            end = true;
            if (!retainNewlines) return;
          } else if (lastCharWasCR) {
            lastCharWasCR = false;
            line.write('\r');
          }
          line.write(char);
        },
        (error) {
          throw error;
        }, () {
          if (lastCharWasCR) line.write('\r');
        });

    bool empty = true;
    while (!end) {
      int b = readByteSync();
      if (b >= 0) {
        empty = false;
        decoder.handleData([b], sink);
      } else {
        decoder.handleDone(sink);
        break;
      }
    }

    if (empty) return null;
    return line.toString();
  }

  /**
   * Enable or disable echo mode on the [Stdin].
   *
   * If disabled, input from to console will not be echoed.
   *
   * Default depends on the parent process, but usually enabled.
   */
  external void set echoMode(bool enabled);

  /**
   * Enable or disable line mode on the [Stdin].
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


class _StdSink implements IOSink {
  final IOSink _sink;

  _StdSink(IOSink this._sink);

  Encoding get encoding => _sink.encoding;
  void set encoding(Encoding encoding) {
    _sink.encoding = encoding;
  }
  void write(object) => _sink.write(object);
  void writeln([object = "" ]) => _sink.writeln(object);
  void writeAll(objects, [sep = ""]) => _sink.writeAll(objects, sep);
  void add(List<int> data) => _sink.add(data);
  void addError(error) => _sink.addError(error);
  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);
  Future addStream(Stream<List<int>> stream) => _sink.addStream(stream);
  Future close() => _sink.close();
  Future get done => _sink.done;
}

class StdioType {
  static const StdioType TERMINAL = const StdioType._("terminal");
  static const StdioType PIPE = const StdioType._("pipe");
  static const StdioType FILE = const StdioType._("file");
  static const StdioType OTHER = const StdioType._("other");
  final String name;
  const StdioType._(String this.name);
  String toString() => "StdioType: $name";
}


Stdin _stdin;
IOSink _stdout;
IOSink _stderr;


Stream<List<int>> get stdin {
  if (_stdin == null) {
    _stdin = _StdIOUtils._getStdioInputStream();
  }
  return _stdin;
}


IOSink get stdout {
  if (_stdout == null) {
    _stdout = _StdIOUtils._getStdioOutputStream(1);
  }
  return _stdout;
}


IOSink get stderr {
  if (_stderr == null) {
    _stderr = _StdIOUtils._getStdioOutputStream(2);
  }
  return _stderr;
}


StdioType stdioType(object) {
  if (object is _StdStream) {
    object = object._stream;
  } else if (object is _StdSink) {
    object = object._sink;
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
  external static IOSink _getStdioOutputStream(int fd);
  external static Stdin _getStdioInputStream();
  external static int _socketType(nativeSocket);
}
