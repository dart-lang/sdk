// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [ListInputStream] makes it possible to use the [InputStream]
 * interface to stream over data that is received in chunks as lists
 * of integers.
 *
 * When a new list of integers is received it can be written to the
 * [ListInputStream] using the [write] method. The [markEndOfStream]
 * method must be called when the last data has been written to the
 * [ListInputStream].
 */
interface ListInputStream extends InputStream default _ListInputStream {
  /**
   * Create an empty [ListInputStream] to which data can be written
   * using the [write] method.
   */
  ListInputStream();

  /**
   * Write more data to be streamed over to the [ListInputStream].
   */
  void write(List<int> data);

  /**
   * Notify the [ListInputStream] that no more data will be written to
   * it.
   */
  void markEndOfStream();
}


/**
 * [ListOutputStream] makes it possible to use the [OutputStream]
 * interface to write data to a [List] of integers.
 */
interface ListOutputStream extends OutputStream default _ListOutputStream {
  /**
   * Create a [ListOutputStream].
   */
  ListOutputStream();

  /**
   * Get the contents written to the [ListOutputStream].
   */
  List<int> contents();
}
