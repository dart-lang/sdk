// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:core";

abstract class StringSink {
  /**
   * Converts [obj] to a String by invoking [Object.toString] and 
   * adds the result to `this`.
   */
  void write(Object obj);

  /**
   * Iterates over the given [objects] and [write]s them in sequence.
   */
  void writeAll(Iterable objects, [String separator = ""]);

  /**
   * Converts [obj] to a String by invoking [Object.toString] and 
   * adds the result to `this`, followed by a newline.
   */
  void writeln([Object obj = ""]);

  /**
   * Writes the [charCode] to `this`.
   *
   * This method is equivalent to `write(new String.fromCharCode(charCode))`.
   */
  void writeCharCode(int charCode);
}
