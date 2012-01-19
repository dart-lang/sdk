// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Input streams are used to read data sequentially from some data
 * source. All input streams are non-blocking. They each have a number
 * of read calls which will always return without any IO related
 * blocking. If the requested data is not available a read call will
 * return [:null:]. All input streams have one or more handlers which
 * will trigger when data is available.
 *
 * The following example shows a data handler in an ordinary input
 * stream which will be called when some data is available and a call
 * to read will not return [:null:].
 *
 * [:
 *    InputStream input = ...
 *    input.dataHandler = () {
 *      var data = input.read();
 *      ...
 *    };
 * :]
 *
 * If for some reason the data from an input stream cannot be handled
 * by the application immediately setting the data handler to [:null:]
 * will avoid further callbacks until it is set to a function
 * again. While the data handler is not active system flow control
 * will be used to avoid buffering more data than needed.
 *
 * Always set up appropriate handlers when using input streams.
 */

/**
 * Basic input stream which supplies binary data.
 */
interface InputStream {
  /**
   * Reads data from the stream. Returns a system allocated buffer
   * with up to [len] bytes. If no value is passed for [len] all
   * available data will be returned. If no data is available null will
   * be returned.
   */
  List<int> read([int len]);

  /**
   * Reads up to [len] bytes into buffer [buffer] starting at offset
   * [offset]. Returns the number of bytes actually read which might
   * be zero. If [offset] is not specified 0 is used. If [len] is not
   * specified the length of [buffer] is used.
   */
  int readInto(List<int> buffer, [int offset, int len]);

  /**
   * Returns the number of bytes available for immediate reading.
   */
  int available();

  /**
   * Pipe the content of this input stream directly to the output
   * stream [output]. The default behavior is to close the output when
   * all the data from the input stream have been written. Specifying
   * [:false:] for the optional argument [close] keeps the output
   * stream open after writing all data from the input stream. The
   * default value for [close] is [:true:].
   */
  void pipe(OutputStream output, [bool close]);

  /**
   * Close the underlying communication channel to avoid getting any
   * more data. In normal situations, where all data is read from the
   * stream until the close handler is called, calling [close] is not
   * required. When [close] is used the close handler will still be
   * called.
   */
  void close();

  /**
   * Returns whether the stream is closed. There will be no more data
   * to read.
   */
  bool get closed();

  /**
   * Sets the handler that gets called when data is available.
   */
  void set dataHandler(void callback());

  /**
   * Sets the handler that gets called when there will be no more data
   * available in the stream.
   */
  void set closeHandler(void callback());

  /**
   * Sets the handler that gets called when the underlying
   * communication channel gets into some kind of error situation.
   */
  void set errorHandler(void callback());
}


/**
 * A string input stream wraps a basic input stream and supplies
 * string data. This data can be read either as string chunks or as
 * lines separated by line termination character sequences.
 */
interface StringInputStream default _StringInputStream {
  /**
   * Decodes a binary input stream into characters using the specified
   * encoding.
   */
  StringInputStream(InputStream input, [String encoding]);

  /**
   * Reads as many characters as is available from the stream. If no data is
   * available null will be returned.
   */
  String read();

  /**
   * Reads the next line from the stream. The line ending characters
   * will not be part of the returned string. If a full line is not
   * available null will be returned.
   */
  String readLine();

  /**
   * Returns whether the stream has been closed. There might still be
   * more data to read.
   */
  bool get closed();

  /**
   * Returns the encoding used to decode the binary data into characters.
   */
  String get encoding();

  /**
   * Sets the handler that gets called when data is available. The two
   * handlers [dataHandler] and [lineHandler] are mutually exclusive
   * and setting one will remove the other.
   */
  void set dataHandler(void callback());

  /**
   * Sets the handler that gets called when a line is available. The
   * two handlers [dataHandler] and [lineHandler] are mutually
   * exclusive and setting one will remove the other.
   */
  void set lineHandler(void callback());

  /**
   * Sets the handler that gets called when there will be no more data
   * available in the stream.
   */
  void set closeHandler(void callback());

  /**
   * Sets the handler that gets called when the underlying
   * communication channel gets into some kind of error situation.
   */
  void set errorHandler(void callback());
}


/**
 * A chunked input stream wraps a basic input stream and supplies
 * binary data in configurable chunk sizes.
 */
interface ChunkedInputStream default _ChunkedInputStream {
  /**
   * Adds buffering to an input stream and provide the ability to read
   * the data in known size chunks.
   */
  ChunkedInputStream(InputStream input, [int chunkSize]);

  /**
   * Reads [chunkSize] bytes from the stream. If [chunkSize] bytes are
   * not currently available null is returned. When the stream is
   * closed the last call can return with less than [chunkSize] bytes.
   */
  List<int> read();

  /**
   * Returns whether the stream has been closed. There might still be
   * more data to read.
   */
  bool get closed();

  /**
   * Returns the chunk size used by this stream.
   */
  int get chunkSize();

  /**
   * Sets the chunk size used by this stream.
   */
  void set chunkSize(int chunkSize);

  /**
   * Sets the handler that gets called when at least [chunkSize] bytes
   * of data is available or the underlying stream has been closed and
   * there is still unread data.
   */
  void set dataHandler(void callback());

  /**
   * Sets the handler that gets called when there will be no more data
   * available in the stream.
   */
  void set closeHandler(void callback());

  /**
   * Sets the handler that gets called when the underlying
   * communication channel gets into some kind of error situation.
   */
  void set errorHandler(void callback());
}


class StreamException implements Exception {
  const StreamException([String this.message = ""]);
  const StreamException.streamClosed() : message = "Stream closed";
  String toString() => "StreamException: $message";
  final String message;
}
