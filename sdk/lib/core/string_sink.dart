// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

abstract class StringSink {

  /**
   * Converts [obj] to a String by invoking [:toString:] and adds the result to
   * this [StringSink].
   */
  void write(Object obj);

  /**
   * Converts [obj] to a String by invoking [:toString:] and adds the result to
   * this [StringSink]. Then adds a new line.
   */
  void print(Object obj);

  /**
   * Writes the [charCode] to this [StringSink].
   *
   * This method is equivalent to [:write(new String.fromCharCode(charCode)):].
   */
  void writeCharCode(int charCode);
}
