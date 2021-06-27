// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A class for concatenating strings efficiently.
///
/// Allows for the incremental building of a string using `write*()` methods.
/// The strings are concatenated to a single string only when [toString] is
/// called.
class StringBuffer implements StringSink {
  /// Creates the string buffer with an initial content.
  external StringBuffer([Object content = ""]);

  /// Returns the length of the content that has been accumulated so far.
  /// This is a constant-time operation.
  external int get length;

  /// Returns whether the buffer is empty. This is a constant-time operation.
  bool get isEmpty => length == 0;

  /// Returns whether the buffer is not empty. This is a constant-time
  /// operation.
  bool get isNotEmpty => !isEmpty;

  /// Adds the string representation of [object] to the buffer.
  external void write(Object? object);

  /// Adds the string representation of [charCode] to the buffer.
  ///
  /// Equivalent to `write(String.fromCharCode(charCode))`.
  external void writeCharCode(int charCode);

  /// Writes all [objects] separated by [separator].
  ///
  /// Writes each individual object in [objects] in iteration order,
  /// and writes [separator] between any two objects.
  external void writeAll(Iterable<dynamic> objects, [String separator = ""]);

  external void writeln([Object? obj = ""]);

  /// Clears the string buffer.
  external void clear();

  /// Returns the contents of buffer as a single string.
  external String toString();
}
