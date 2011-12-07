// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Input is read from a given input stream. Such an input stream can
 * be an endpoint, e.g., a socket or a file, or another input stream.
 * Multiple input streams can be chained together to operate collaboratively
 * on a given input.
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


interface StringInputStream factory _StringInputStream {
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
   * will not be part og the returned string. If a full line is not
   * available null will be returned. The line break character(s) are
   * discarded.
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
   * handlers [dataHandler} and [lineHandler] are mutually exclusive
   * and setting one will remove the other.
   */
  void set dataHandler(void callback());

  /**
   * Sets the handler that gets called when a line is available. The
   * two handlers [dataHandler} and [lineHandler] are mutually
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


interface ChunkedInputStream factory _ChunkedInputStream {
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
  String toString() => "StreamException: $message";
  final String message;
}
