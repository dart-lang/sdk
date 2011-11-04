// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Output is written to a given output stream. Such an output stream can
 * be an endpoint, e.g., a socket or a file, or another output stream.
 * Multiple output streams can be chained together to operate collaboratively
 * on a given output.
 *
 * An output stream provides internal buffering of the data written
 * through all calls to [write] and [writeFrom] if data cannot be
 * written immediately to the communication channel. The callback set
 * through [noPendingWriteHandler] can be used to to keep the rate of
 * writing in sync with the rate the system can actually write data to
 * the underlying communication channel.
 */
interface OutputStream {
  /**
   * Writes the content of [buffer] to the stream. This will pass
   * ownership of the specified buffer to the system and the caller
   * should not change it. Returns true if the data could be written
   * to the underlying communication channel immediately. Otherwise
   * the data is buffered by the output stream and will be sent as
   * soon as possible.
   */
  bool write(List<int> buffer);

  /**
   * Writes [len] bytes from buffer [buffer] starting at offset
   * [offset] to the output stream. If [offset] is not specified the
   * default is 0. If [len] is not specified the default is the length
   * of the buffer passed. The system will copy the data to be written
   * so the caller can safely change [buffer] afterwards. Returns true
   * if the data could be written to the underlying communication
   * channel immediately. Otherwise the data is buffered by the output
   * stream and will be sent as soon as possible.
   */
  bool writeFrom(List<int> buffer, [int offset, int len]);

  /**
   * Indicate that all data has been written to the output
   * stream. When all data has been written to the communication
   * channel it will be closed.
   */
  void close();

  /**
   * Close the communication channel immediately ignoring any buffered
   * data.
   */
  void destroy();

  /**
   * The no pending write handler gets called when the internal OS
   * buffers have been flushed. This callback can be used to keep the
   * rate of writing in sync with the rate the system can write data
   * to the underlying communication channel.
   */
  void set noPendingWriteHandler(void callback());

  /*
   * The close handler gets called when the underlying communication
   * channel has been closed.
   */
  void set closeHandler(void callback());

  /**
   * The error handler gets called when the underlying communication
   * channel gets into some kind of error situation.
   */
  void set errorHandler(void callback());
}

