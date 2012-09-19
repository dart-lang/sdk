// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [SocketInputStream] makes it possible to stream over data received
 * from a [Socket].
 */
abstract class SocketInputStream implements InputStream {
  /**
   * Create a [SocketInputStream] for streaming from a [Socket].
   */
  factory SocketInputStream(Socket socket) => new _SocketInputStream(socket);
}

/**
 * [SocketOutputStream] makes it possible to stream data to a
 * [Socket].
 */
abstract class SocketOutputStream implements OutputStream {
  /**
   * Create a [SocketOutputStream] for streaming to a [Socket].
   */
  factory SocketOutputStream(Socket socket) => new _SocketOutputStream(socket);
}
