// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper for building Dart source with linked positions.
class SourceBuilder {
  final String file;
  final int offset;
  final StringBuffer _buffer = StringBuffer();

  int _exitOffset;

  SourceBuilder(this.file, this.offset);

  /// Returns the exit offset, maybe `null` if not set.
  int get exitOffset {
    if (_exitOffset == null) {
      return null;
    }
    return offset + _exitOffset;
  }

  int get length => _buffer.length;

  /// Appends [s] to the buffer.
  SourceBuilder append(String s) {
    _buffer.write(s);
    return this;
  }

  /// Marks the current offset as an "exit" one.
  void setExitOffset() {
    _exitOffset = _buffer.length;
  }

  @override
  String toString() => _buffer.toString();
}
