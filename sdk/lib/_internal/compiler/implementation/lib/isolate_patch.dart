// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import 'dart:_isolate_helper' show IsolateNatives,
                                   lazyPort,
                                   ReceivePortImpl,
                                   CloseToken,
                                   JsIsolateSink;

patch class _Isolate {
  patch static ReceivePort get port {
    if (lazyPort == null) {
      lazyPort = new ReceivePort();
    }
    return lazyPort;
  }

  patch static SendPort spawnFunction(void topLevelFunction(),
      [bool unhandledExceptionCallback(IsolateUnhandledException e)]) {
    if (unhandledExceptionCallback != null) {
      // TODO(9012): Implement the UnhandledExceptionCallback.
      throw new UnimplementedError(
          "spawnFunction with unhandledExceptionCallback");
    }
    return IsolateNatives.spawnFunction(topLevelFunction);
  }

  patch static SendPort spawnUri(String uri) {
    return IsolateNatives.spawn(null, uri, false);
  }
}

patch bool _isCloseToken(var object) {
  return identical(object, const CloseToken());
}

/** Default factory for receive ports. */
patch class ReceivePort {
  patch factory ReceivePort() {
    return new ReceivePortImpl();
  }
}

patch class MessageBox {
  patch MessageBox.oneShot() : this._oneShot(new ReceivePort());
  MessageBox._oneShot(ReceivePort receivePort)
      : stream = new IsolateStream._fromOriginalReceivePortOneShot(receivePort),
        sink = new JsIsolateSink.fromPort(receivePort.toSendPort());

  patch MessageBox() : this._(new ReceivePort());
  MessageBox._(ReceivePort receivePort)
      : stream = new IsolateStream._fromOriginalReceivePort(receivePort),
        sink = new JsIsolateSink.fromPort(receivePort.toSendPort());
}

patch IsolateSink streamSpawnFunction(
    void topLevelFunction(),
    [bool unhandledExceptionCallback(IsolateUnhandledException e)]) {
  SendPort sendPort = spawnFunction(topLevelFunction,
                                    unhandledExceptionCallback);
  return new JsIsolateSink.fromPort(sendPort);
}
