// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Basic input stream which supplies binary data.
 *
 * Input streams are used to read data sequentially from some data
 * source. All input streams are non-blocking. They each have a number
 * of read calls which will always return without any IO related
 * blocking. If the requested data is not available a read call will
 * return `null`. All input streams have one or more handlers which
 * will trigger when data is available.
 *
 * The following example shows a data handler in an ordinary input
 * stream which will be called when some data is available and a call
 * to read will not return `null`.
 *
 *     InputStream input = ...
 *     input.onData = () {
 *       var data = input.read();
 *       ...
 *     };
 *
 * If for some reason the data from an input stream cannot be handled
 * by the application immediately setting the data handler to `null`
 * will avoid further callbacks until it is set to a function
 * again. While the data handler is not active system flow control
 * will be used to avoid buffering more data than needed.
 *
 * Always set up appropriate handlers when using input streams.
 *
 */
abstract class InputStream {
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
   * `false` for the optional argument [close] keeps the output
   * stream open after writing all data from the input stream.
   */
  void pipe(OutputStream output, {bool close: true});

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
  bool get closed;

  /**
   * Sets the handler that gets called when data is available.
   */
  void set onData(void callback());

  /**
   * Sets the handler that gets called when there will be no more data
   * available in the stream.
   */
  void set onClosed(void callback());

  /**
   * Sets the handler that gets called when the underlying
   * communication channel gets into some kind of error situation.
   */
  void set onError(void callback(e));
}


/**
 * String encodings.
 */
class Encoding {
  static const Encoding UTF_8 = const Encoding._internal("UTF-8");
  static const Encoding ISO_8859_1 = const Encoding._internal("ISO-8859-1");
  static const Encoding ASCII = const Encoding._internal("ASCII");
  /**
   * SYSTEM encoding is the current code page on Windows and UTF-8 on
   * Linux and Mac.
   */
  static const Encoding SYSTEM = const Encoding._internal("SYSTEM");
  const Encoding._internal(String this.name);
  final String name;
}


class StreamException implements Exception {
  const StreamException([String this.message = ""]);
  const StreamException.streamClosed() : message = "Stream closed";
  String toString() => "StreamException: $message";
  final String message;
}
