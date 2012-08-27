// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The StringBuffer class is useful for concatenating strings
 * efficiently. Only on a call to [toString] are the strings
 * concatenated to a single String.
 */
class StringBufferImpl implements StringBuffer {
  /**
   * Creates the string buffer with an initial content.
   */
  StringBufferImpl([Object content = ""]) {
    clear();
    add(content);
  }

  /**
   * Returns the length of the buffer.
   */
  int get length() {
    return _length;
  }

  bool isEmpty() {
    return _length === 0;
  }

  /**
   * Adds [obj] to the buffer. Returns [this].
   */
  StringBuffer add(Object obj) {
    String str = obj.toString();
    if (str === null || str.isEmpty()) {
      return this;
    }
    _buffer.add(str);
    _length += str.length;
    return this;
  }

  /**
   * Adds all items in [objects] to the buffer. Returns [this].
   */
  StringBuffer addAll(Collection objects) {
    for (Object obj in objects) {
      add(obj);
    }
    return this;
  }

  /**
   * Adds the string representation of [charCode] to the buffer.
   * Returns [this].
   */
  StringBuffer addCharCode(int charCode) {
    return add(new String.fromCharCodes([charCode]));
  }

  /**
   * Clears the string buffer. Returns [this].
   */
  StringBuffer clear() {
    _buffer = new List<String>();
    _length = 0;
    return this;
  }

  /**
   * Returns the contents of buffer as a concatenated string.
   */
  String toString() {
    if (_buffer.length === 0) return "";
    if (_buffer.length === 1) return _buffer[0];
    String result = StringImplementation.concatAll(_buffer);
    _buffer.clear();
    _buffer.add(result);
    // Since we track the length at each add operation, there is no
    // need to update it in this function.
    return result;
  }

  List<String> _buffer;
  int _length;
}
