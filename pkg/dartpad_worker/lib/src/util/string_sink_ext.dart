// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

extension StreamSinkStringExt on StreamSink<String> {
  /// Wraps this [StreamSink] as a [StringSink].
  StringSink asStringSink() => _StreamStringSink(this);
}

final class _StreamStringSink implements StringSink {
  final StreamSink<String> _sink;

  _StreamStringSink(this._sink);

  @override
  void write(Object? obj) => _sink.add('$obj');

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      _sink.add(objects.join(separator));

  @override
  void writeCharCode(int charCode) => _sink.add(String.fromCharCode(charCode));

  @override
  void writeln([Object? obj = '']) => _sink.add('$obj\n');
}
