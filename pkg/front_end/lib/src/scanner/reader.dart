// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * An object used by the scanner to read the characters to be scanned.
 */
abstract class CharacterReader {
  /**
   * The current offset relative to the beginning of the source. Return the
   * initial offset if the scanner has not yet scanned the source code, and one
   * (1) past the end of the source code if the entire source code has been
   * scanned.
   */
  int get offset;

  /**
   * Set the current offset relative to the beginning of the source to the given
   * [offset]. The new offset must be between the initial offset and one (1)
   * past the end of the source code.
   */
  void set offset(int offset);

  /**
   * Advance the current position and return the character at the new current
   * position.
   */
  int advance();

  /**
   * Return the substring of the source code between the [start] offset and the
   * modified current position. The current position is modified by adding the
   * [endDelta], which is the number of characters after the current location to
   * be included in the string, or the number of characters before the current
   * location to be excluded if the offset is negative.
   */
  String getString(int start, int endDelta);

  /**
   * Return the character at the current position without changing the current
   * position.
   */
  int peek();
}
