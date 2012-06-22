// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The StringBuffer class is useful for concatenating strings
 * efficiently. Only on a call to [toString] are the strings
 * concatenated to a single String.
 */
interface StringBuffer default StringBufferImpl {
  /**
   * Creates the string buffer with an initial content.
   */
  StringBuffer([Object content]);

  /**
   * Returns the length of the buffer.
   */
  int get length();

  /**
   * Returns whether the buffer is empty.
   */
  bool isEmpty();

  /**
   * Converts [obj] to a string and adds it to the buffer. Returns [:this:].
   */
  StringBuffer add(Object obj);

  /**
   * Adds the string representation of [charCode] to the buffer.
   * Returns [this].
   */
  StringBuffer addCharCode(int charCode);

  /**
   * Adds all items in [objects] to the buffer. Returns [:this:].
   */
  StringBuffer addAll(Collection objects);

  /**
   * Clears the string buffer. Returns [:this:].
   */
  StringBuffer clear();

  /**
   * Returns the contents of buffer as a concatenated string.
   */
  String toString();
}
