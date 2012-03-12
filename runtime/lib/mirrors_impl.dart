// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

class _IsolateMirrorImpl implements IsolateMirror {
  _IsolateMirrorImpl(this.port, this.debugName) {}

  final SendPort port;
  final String debugName;

  static buildCommand(List command) {
    command.add('isolateMirrorOf');
  }

  static buildResponse(Map response) native "IsolateMirrorImpl_buildResponse";

  static processResponse(SendPort port, Map response) {
    if (response['ok']) {
      return new _IsolateMirrorImpl(port, response['debugName']);
    }
    return null;
  }
}

class _Mirrors {
  static Future<IsolateMirror> isolateMirrorOf(SendPort port) {
    Completer<IsolateMirror> completer = new Completer<IsolateMirror>();
    List command = new List();
    _IsolateMirrorImpl.buildCommand(command);
    ReceivePort rp = new ReceivePort();
    if (!send(port, command, rp.toSendPort())) {
      throw new Exception("Unable to send mirror request to port $port");
    }
    rp.receive((message, _) {
        rp.close();
        completer.complete(_IsolateMirrorImpl.processResponse(port, message));
      });
    return completer.future;
  }

  static void processCommand(var message, SendPort replyTo) {
    Map response = new Map();
    if (message[0] == 'isolateMirrorOf') {
      _IsolateMirrorImpl.buildResponse(response);
    } else {
      response['ok'] = false;
    }
    replyTo.send(response);
  }

  static bool send(SendPort port, Object message, SendPort replyTo)
      native "Mirrors_send";
}
