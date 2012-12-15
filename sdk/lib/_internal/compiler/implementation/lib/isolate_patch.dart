// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

patch ReceivePort get port {
  if (lazyPort == null) {
    lazyPort = new ReceivePort();
  }
  return lazyPort;
}

patch SendPort spawnFunction(void topLevelFunction(),
    [bool UnhandledExceptionCallback(IsolateUnhandledException e)]) {
  return IsolateNatives.spawnFunction(topLevelFunction);
}

patch SendPort spawnUri(String uri) {
  return IsolateNatives.spawn(null, uri, false);
}


/** Default factory for receive ports. */
patch class ReceivePort {
  patch factory ReceivePort() {
    return new ReceivePortImpl();
  }
}

patch class Timer {
  patch factory Timer(int milliseconds, void callback(Timer timer)) {
    if (!hasWindow()) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    return new TimerImpl(milliseconds, callback);
  }

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliseconds] millisecond until cancelled.
   */
  patch factory Timer.repeating(int milliseconds, void callback(Timer timer)) {
    if (!hasWindow()) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    return new TimerImpl.repeating(milliseconds, callback);
  }
}
