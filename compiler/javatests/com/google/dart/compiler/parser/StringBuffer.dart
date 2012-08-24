// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The StringBuffer class is useful for concatenating strings
 * efficiently. Only on a call to [toString] are the strings
 * concatenated to a single String.
 */
class StringBuffer implements OutputStream {
  /**
   * Creates the string buffer with an initial content.
   */
  StringBuffer([String content = ""]) {
    clear();
    append(content);
  }

  /// From OutputStream. Appends [str] to the buffer.
  void writeString(String str) {
    append(str);
  }

  /// From OutputStream. Appends the [charCode] to the buffer.
  void writeCharCode(int charCode) {
    throw "StringBuffer.writeCharCode Unimplemented";
  }

  void writeByte(int value) {
    throw "StringBuffer.writeByte unimplemented";
  }

  void writeByteArray(Array<int> buffer, int offset, int length) {
    throw "StringBuffer.writeByteArray unimplemented";
  }

  void close() {}
  void flush() {}


  /**
   * Returns the length of the buffer.
   */
  int get length {
    return length_;
  }

  /**
   * Appends [str] to the buffer.
   */
  void append(String str) {
    if (str === null || str.isEmpty()) return;
    buffer_.add(str);
    length_ += str.length;
  }

  /**
   * Appends all items in [strings] to the buffer.
   */
  void appendAll(Collection<String> strings) {
    strings.forEach((str) { append(str); });
  }

  /**
   * Clears the string buffer.
   */
  void clear() {
    buffer_ = new GrowableArray<String>(4);
    length_ = 0;
  }

  /**
   * Returns the contents of buffer as a concatenated string.
   */
  String toString() {
    if (buffer_.length == 0) return "";
    if (buffer_.length == 1) return buffer_[0];
    String result = StringBase.concatAll(_buffer);
    buffer_.clear();
    buffer_.add(result);
    // Since we track the length at each append operation, there is no
    // need to update it in this function.
    return result;
  }

  GrowableArray<String> buffer_;
  int length_;
  final bool closed = false;
}
