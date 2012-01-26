// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [SocketInputStream] makes it possible to stream over data received
 * from a [Socket].
 */
interface SocketInputStream extends InputStream default _SocketInputStream {
  /**
   * Create a [SocketInputStream] for streaming from a [Socket].
   */
  SocketInputStream(Socket socket);

}

/**
 * [SocketOutputStream] makes it possible to stream data to a
 * [Socket].
 */
interface SocketOutputStream extends OutputStream default _SocketOutputStream {
  /**
   * Create a [SocketOutputStream] for streaming to a [Socket].
   */
  SocketOutputStream(Socket socket);
}
