// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A [StringSink] that writes into multiple [StringSink]s.
class TeeStringSink implements StringSink {
  final Set<StringSink> _sinks = {};

  bool addSink(StringSink sink) {
    return _sinks.add(sink);
  }

  bool removeSink(StringSink sink) {
    return _sinks.remove(sink);
  }

  @override
  void write(Object? obj) {
    if (_sinks.isEmpty) return;

    for (var sink in _sinks) {
      sink.write(obj);
    }
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    if (_sinks.isEmpty) return;

    for (var sink in _sinks) {
      sink.writeAll(objects, separator);
    }
  }

  @override
  void writeCharCode(int charCode) {
    if (_sinks.isEmpty) return;

    for (var sink in _sinks) {
      sink.writeCharCode(charCode);
    }
  }

  @override
  void writeln([Object? obj = '']) {
    if (_sinks.isEmpty) return;

    for (var sink in _sinks) {
      sink.writeln(obj);
    }
  }
}
