// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

const int _STDIO_HANDLE_TYPE_TERMINAL = 0;
const int _STDIO_HANDLE_TYPE_PIPE = 1;
const int _STDIO_HANDLE_TYPE_FILE = 2;
const int _STDIO_HANDLE_TYPE_SOCKET = 3;
const int _STDIO_HANDLE_TYPE_OTHER = 4;

class _Stdin extends Stream<List<int>> {
  final Stream<List<int>> _stdin;

  _Stdin(Stream<List<int>> this._stdin);

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {void onError(AsyncError error),
                                        void onDone(),
                                        bool unsubscribeOnError}) {
    return _stdin.listen(
        onData,
        onError: onError,
        onDone: onDone,
        unsubscribeOnError: unsubscribeOnError);
  }
}

class _StdSink implements IOSink {
  final IOSink _ioSink;

  _StdSink(IOSink this._ioSink);

  Encoding get encoding => _ioSink.encoding;
  void set encoding(Encoding encoding) {
    _ioSink.encoding = encoding;
  }
  void write(object) => _ioSink.write(object);
  void writeln([object = "" ]) => _ioSink.writeln(object);
  void writeAll(objects, [sep = ""]) => _ioSink.writeAll(objects, sep);
  void writeBytes(List<int> data) => _ioSink.writeBytes(data);
  void writeCharCode(int charCode) => _ioSink.writeCharCode(charCode);
  Future<T> consume(Stream<List<int>> stream) => _ioSink.consume(stream);
  Future<T> addStream(Stream<List<int>> stream) => _ioSink.addStream(stream);
  Future<T> writeStream(Stream<List<int>> stream)
      => _ioSink.writeStream(stream);
  Future close() => _ioSink.close();
  Future<T> get done => _ioSink.done;
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


Stream<List<int>> _stdin;
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
  if (object is _Stdin) {
    object = object._stdin;
  } else if (object is _StdSink) {
    object = object._ioSink;
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
  external static Stream<List<int>> _getStdioInputStream();
  external static int _socketType(nativeSocket);
}
