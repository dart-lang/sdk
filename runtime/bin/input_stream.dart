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
   * Reads [len] bytes into [buffer] buffer starting at [offset] offset.
   * [callback] callback is invoked on completion unless it is null.
   */
  bool read(List<int> buffer, int offset, int len, void callback());

  /**
   * Reads data from the stream into a buffer until a given [pattern] occurs and
   * hands that buffer over as an input to the registered [callback].
   * The callback is not invoked if a read error occurs.
   */
  void readUntil(List<int> pattern, void callback(List<int> buffer));
}
