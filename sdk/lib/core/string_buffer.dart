// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A class for concatenating strings efficiently.
///
/// Allows for the incremental building of a string using `write*()` methods.
/// The strings are concatenated to a single string only when [toString] is
/// called.
///
/// Example:
/// ```dart
/// final buffer = StringBuffer();
/// ```
/// To add string to buffer, call [write].
/// ```
/// buffer.write('Dart'.toUpperCase());
/// buffer.write(' is open source');
/// print(buffer.length); // 19
/// print(buffer); // DART is open source
/// ```
/// To add linebreak to buffer, call [writeln].
/// ```
/// buffer.writeln();
/// ```
/// To write multiple stings to buffer, call [writeAll].
/// ```
/// const separator = '-';
/// buffer.writeAll(['Dart', 'is', 'fun!'], separator);
/// print(buffer.length); // 32
/// print(buffer);
/// // DART is open source
/// // Dart-is-fun!
/// ```
/// To add the string representation of `charCode` to the buffer,
/// call [writeCharCode].
/// ```
/// buffer.writeCharCode(0x0A); // LF (line feed)
/// buffer.writeCharCode(0x44); // 'D'
/// buffer.writeCharCode(0x61); // 'a'
/// buffer.writeCharCode(0x72); // 'r'
/// buffer.writeCharCode(0x74); // 't'
/// ```
/// To get buffer content as single string, call [toString].
/// ```
/// final text = buffer.toString();
/// print(text);
/// // DART is open source
/// // Dart-is-fun!
/// // Dart
/// ```
/// To clear the buffer, call [clear]
/// ```
/// buffer.clear();
/// print(buffer.isEmpty); // true
/// print(buffer.length); // 0
/// ```
class StringBuffer implements StringSink {
  /// Creates the string buffer with initial content.
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
