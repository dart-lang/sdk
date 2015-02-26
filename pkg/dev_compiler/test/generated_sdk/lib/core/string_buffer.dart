// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A class for concatenating strings efficiently.
 *
 * Allows for the incremental building of a string using write*() methods.
 * The strings are concatenated to a single string only when [toString] is
 * called.
 */
class StringBuffer implements StringSink {

  /** Creates the string buffer with an initial content. */
  StringBuffer([Object content = ""]) : _contents = '$content';

  /**
   * Returns the length of the content that has been accumulated so far.
   * This is a constant-time operation.
   */
  int get length => _contents.length;

  /** Returns whether the buffer is empty. This is a constant-time operation. */
  bool get isEmpty => length == 0;

  /**
   * Returns whether the buffer is not empty. This is a constant-time
   * operation.
   */
  bool get isNotEmpty => !isEmpty;

  /// Adds the contents of [obj], converted to a string, to the buffer.
  void write(Object obj) {
    _writeString('$obj');
  }

  /// Adds the string representation of [charCode] to the buffer.
  void writeCharCode(int charCode) {
    _writeString(new String.fromCharCode(charCode));
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  void writeln([Object obj = ""]) {
    write(obj);
    write("\n");
  }

  /**
   * Clears the string buffer.
   */
  void clear() {
    _contents = "";
  }

  /// Returns the contents of buffer as a concatenated string.
  String toString() => Primitives.flattenString(_contents);

  String _contents;

  void _writeString(str) {
    _contents = Primitives.stringConcatUnchecked(_contents, str);
  }
}
