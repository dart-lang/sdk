// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The StringBuffer class is useful for concatenating strings
 * efficiently. Only on a call to [toString] are the strings
 * concatenated to a single String.
 */
abstract class StringBuffer {

  /// Creates the string buffer with an initial content.
  factory StringBuffer([Object content = ""]) => new _StringBufferImpl(content);

  /// Returns the length of the buffer.
  int get length;

  // Returns whether the buffer is empty.
  bool get isEmpty;

  /// Converts [obj] to a string and adds it to the buffer.
  void add(Object obj);

  /// Adds the string representation of [charCode] to the buffer.
  void addCharCode(int charCode);

  /// Adds all items in [objects] to the buffer.
  void addAll(Collection objects);

  /// Clears the string buffer.
  void clear();

  /// Returns the contents of buffer as a concatenated string.
  String toString();
}

class _StringBufferImpl implements StringBuffer {

  List<String> _buffer;
  int _length;

  /// Creates the string buffer with an initial content.
  _StringBufferImpl(Object content) {
    clear();
    add(content);
  }

  /// Returns the length of the buffer.
  int get length => _length;

  bool get isEmpty => _length == 0;

  /// Adds [obj] to the buffer.
  void add(Object obj) {
    // TODO(srdjan): The following four lines could be replaced by
    // '$obj', but apparently this is too slow on the Dart VM.
    String str = obj.toString();
    if (str is !String) {
      throw new ArgumentError('toString() did not return a string');
    }
    if (str.isEmpty) return;
    _buffer.add(str);
    _length += str.length;
  }

  /// Adds all items in [objects] to the buffer.
  void addAll(Collection objects) {
    for (Object obj in objects) add(obj);
  }

  /// Adds the string representation of [charCode] to the buffer.
  void addCharCode(int charCode) {
    add(new String.fromCharCodes([charCode]));
  }

  /// Clears the string buffer.
  void clear() {
    _buffer = new List<String>();
    _length = 0;
  }

  /// Returns the contents of buffer as a concatenated string.
  String toString() {
    if (_buffer.length == 0) return "";
    if (_buffer.length == 1) return _buffer[0];
    String result = Strings.concatAll(_buffer);
    _buffer.clear();
    _buffer.add(result);
    // Since we track the length at each add operation, there is no
    // need to update it in this function.
    return result;
  }
}
