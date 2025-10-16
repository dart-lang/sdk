// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A [StringSink] that writes into a `StreamSink<String>`.
class StreamStringSink implements StringSink {
  final StreamSink<String> _sink;

  StreamStringSink(this._sink);

  @override
  void write(Object? obj) {
    _sink.add('$obj');
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    _sink.add(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    _sink.add(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object? obj = '']) {
    _sink.add('$obj\n');
  }
}
