// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

abstract interface class StringSink {
  /// Writes the string representation of [object].
  ///
  /// Converts [object] to a string using `object.toString()`.
  void write(Object? object);

  /// Iterates over the given [objects] and [write]s them in sequence.
  void writeAll(Iterable<dynamic> objects, [String separator = ""]);

  /// Writes [object] followed by a newline, `"\n"`.
  ///
  /// Calling `writeln(null)` will write the `"null"` string before the
  /// newline.
  void writeln([Object? object = ""]);

  /// Writes the character represented by [charCode].
  ///
  /// Equivalent to `write(String.fromCharCode(charCode))`.
  void writeCharCode(int charCode);
}
