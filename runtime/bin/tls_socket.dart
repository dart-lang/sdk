// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TlsSocket extends Socket, Hashable default _TlsSocket {
  /**
   * Constructs a new secure socket and connect it to the given
   * host on the given port. The returned socket is not yet connected
   * but ready for registration of callbacks.
   */
  TlsSocket(String host, int port);
}
