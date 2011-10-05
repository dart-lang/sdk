// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Output is written to a given output stream. Such an output stream can
 * be an endpoint, e.g., a socket or a file, or another output stream.
 * Multiple output streams can be chained together to operate collaboratively
 * on a given output.
 */
interface OutputStream {
  /**
   * Writes [len] bytes into [buffer] buffer starting at [offset] offset].
   * If write succeedes true is returned. Otherwise false is returned
   * and [callback] callback is invoked on completion.
   */
  bool write(List<int> buffer, int offset, int len, void callback());
}

