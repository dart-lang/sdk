// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instrumentation;

/**
 * The interface used by client code to communicate with an instrumentation
 * server.
 */
abstract class InstrumentationServer {
  /**
   * Pass the given [message] to the instrumentation server so that it will be
   * logged with other messages.
   */
  void log(String message);

  /**
   * Signal that the client is done communicating with the instrumentation
   * server. This method should be invoked exactly one time and no other methods
   * should be invoked on this instance after this method has been invoked.
   */
  void shutdown();
}

/**
 * An [InstrumentationServer] that ignores all instrumentation requests sent to
 * it. It can be used when no instrumentation data is to be collected as a way
 * to avoid needing to check for null values.
 */
class NullInstrumentationServer implements InstrumentationServer {
  /**
   * Initialize a newly created instance of this class.
   */
  const NullInstrumentationServer();

  @override
  void log(String message) {
  }

  @override
  void shutdown() {
  }
}
