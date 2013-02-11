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

  /// Creates the string buffer with an initial content.
  external StringBuffer([Object content = ""]);

  /// Returns the length of the buffer.
  external int get length;

  /// Returns whether the buffer is empty.
  bool get isEmpty => length == 0;

  /**
   * Converts [obj] to a string and adds it to the buffer.
   *
   * *Deprecated*. Use [write] instead.
   */
  @deprecated
  void add(Object obj) => write(obj);

  void write(Object obj) {
    // TODO(srdjan): The following four lines could be replaced by
    // '$obj', but apparently this is too slow on the Dart VM.
    String str = obj.toString();
    if (str is! String) {
      throw new ArgumentError('toString() did not return a string');
    }
    if (str.isEmpty) return;
    _write(str);
  }


  void print(Object obj) {
    write(obj);
    _write("\n");
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

  /// Adds the string representation of [charCode] to the buffer.
  void writeCharCode(int charCode) {
    _write(new String.fromCharCode(charCode));
  }

  /**
   * Adds all items in [objects] to the buffer.
   *
   * *Deprecated*. Use [:objects.forEach(buffer.write):] instead.
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

  external void _write(String str);
}
