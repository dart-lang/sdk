// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

Console _console;

Console get console {
  if (_console == null) {
    _console = new Console._();
  }
  return _console;
}

/**
 * [Console] provides synchronous write access to stdout and stderr.
 *
 * The direct access to stdout and stderr through [stdout] and [stderr]
 * provides non-blocking async operations.
 */
class Console {
  final ConsoleSink _stdout;
  final ConsoleSink _stderr;

  Console._()
      : _stdout = new ConsoleSink._(1),
        _stderr = new ConsoleSink._(2);

  /**
   * Write to stdout.
   */
  ConsoleSink get log => _stdout;

  /**
   * Write to stderr.
   */
  ConsoleSink get error => _stderr;
}

/**
 * Sink class used for console writing.
 *
 * This class has a call method so you can call it directly. Calling
 * it directly is the same as calling its `writeln` method.
 */
class ConsoleSink implements Sink<List<int>>, StringSink {
  IOSink _sink;

  ConsoleSink._(int fd) {
    _sink = new IOSink(new _ConsoleConsumer(fd));
  }

  void call(Object message) => _sink.writeln(message);

  void add(List<int> data) => _sink.add(data);

  void close() {}

  void write(Object obj) => _sink.write(obj);

  void writeAll(Iterable objects, [String separator=""]) =>
      _sink.writeAll(objects, separator);

  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);

  void writeln([Object obj=""]) => _sink.writeln(obj);
}

class _ConsoleConsumer implements StreamConsumer<List<int>> {
  final _file;

  _ConsoleConsumer(int fd) : _file = _File._openStdioSync(fd);

  Future addStream(Stream<List<int>> stream) {
    var completer = new Completer();
    var sub;
    sub = stream.listen(
        (data) {
          try {
            _file.writeFromSync(data);
          } catch (e, s) {
            sub.cancel();
            completer.completeError(e, s);
          }
        },
        onError: completer.completeError,
        onDone: completer.complete,
        cancelOnError: true);
    return completer.future;
  }

  Future close() {
    _file.closeSync();
    return new Future.value();
  }
}
