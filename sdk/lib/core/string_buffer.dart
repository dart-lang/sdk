// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The StringBuffer class is useful for concatenating strings
 * efficiently. Only on a call to [toString] are the strings
 * concatenated to a single String.
 */
class StringBuffer implements StringSink {

  /** Creates the string buffer with an initial content. */
  external StringBuffer([Object content = ""]);

  /**
   * Returns the length of the content that has been accumulated so far.
   * This is a constant-time operation.
   */
  external int get length;

  /** Returns whether the buffer is empty. This is a constant-time operation. */
  bool get isEmpty => length == 0;

  /**
   * Converts [obj] to a string and adds it to the buffer.
   *
   * *Deprecated*. Use [write] instead.
   */
  @deprecated
  void add(Object obj) => write(obj);

  /// Adds the contents of [obj], converted to a string, to the buffer.
  external void write(Object obj);

  /// Adds the string representation of [charCode] to the buffer.
  external void writeCharCode(int charCode);

  void writeAll(Iterable objects) {
    for (Object obj in objects) write(obj);
  }

  void writeln(Object obj) {
    write(obj);
    write("\n");
  }

  /**
   * Adds the string representation of [charCode] to the buffer.
   *
   * *Deprecated* Use [writeCharCode] instead.
   */
  @deprecated
  void addCharCode(int charCode) {
    writeCharCode(charCode);
  }

  /**
   * Adds all items in [objects] to the buffer.
   *
   * *Deprecated*. Use [writeAll] instead.
   */
  @deprecated
  void addAll(Iterable objects) {
    for (Object obj in objects) write(obj);
  }

  /**
   * Clears the string buffer.
   *
   * *Deprecated*.
   */
  @deprecated
  external void clear();

  /// Returns the contents of buffer as a concatenated string.
  external String toString();
}
