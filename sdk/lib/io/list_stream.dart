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
abstract class ListInputStream implements InputStream {
  /**
   * Create an empty [ListInputStream] to which data can be written
   * using the [write] method.
   */
  factory ListInputStream() =>  new _ListInputStream();

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
abstract class ListOutputStream implements OutputStream {
  /**
   * Create a [ListOutputStream].
   */
  factory ListOutputStream() => new _ListOutputStream();

  /**
   * Reads all available data from the stream. If no data is available `null`
   * will be returned.
   */
  List<int> read();

  /**
   * Sets the handler that gets called when data is available.
   */
  void set onData(void callback());
}
