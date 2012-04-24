// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

class _IsolateMirrorImpl implements IsolateMirror {
  _IsolateMirrorImpl(this.port, this.debugName) {}

  final SendPort port;
  final String debugName;

  static _make(SendPort port, String debugName) {
    return new _IsolateMirrorImpl(port, debugName);
  }
}

class _Mirrors {
  static Future<IsolateMirror> isolateMirrorOf(SendPort port) {
    Completer<IsolateMirror> completer = new Completer<IsolateMirror>();
    String request = '{ "command": "isolateMirrorOf" }';
    ReceivePort rp = new ReceivePort();
    if (!send(port, request, rp.toSendPort())) {
      throw new Exception("Unable to send mirror request to port $port");
    }
    rp.receive((message, _) {
        rp.close();
        completer.complete(_Mirrors.processResponse(
            port, "isolateMirrorOf", message));
      });
    return completer.future;
  }

  static bool send(SendPort port, String request, SendPort replyTo)
      native "Mirrors_send";

  static processResponse(SendPort port, String command, String response)
      native "Mirrors_processResponse";
}
