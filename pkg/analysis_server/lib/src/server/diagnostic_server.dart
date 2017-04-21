// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/**
 * A handle to start, and return the current port of, a diagnostic server.
 */
abstract class DiagnosticServer {
  /**
   * Return the port of the diagnostic web server. If the server is not running
   * this call will start the server.
   */
  Future<int> getServerPort();
}
