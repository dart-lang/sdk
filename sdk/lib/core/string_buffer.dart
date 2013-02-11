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
  external factory StringBuffer([Object content = ""]);

  /// Returns the length of the buffer.
  int get length;

  // Returns whether the buffer is empty.
  bool get isEmpty;

  /// Converts [obj] to a string and adds it to the buffer.
  void add(Object obj);

  /// Adds the string representation of [charCode] to the buffer.
  void addCharCode(int charCode);

  /// Adds all items in [objects] to the buffer.
  void addAll(Iterable objects);

  /// Clears the string buffer.
  void clear();

  /// Returns the contents of buffer as a concatenated string.
  String toString();
}
