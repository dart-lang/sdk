// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import 'dart:_isolate_helper' show CapabilityImpl,
                                   CloseToken,
                                   IsolateNatives,
                                   JsIsolateSink,
                                   ReceivePortImpl,
                                   RawReceivePortImpl;

patch class Isolate {
  patch static Future<Isolate> spawn(void entryPoint(message), var message,
                                     { bool paused: false }) {
    try {
      return IsolateNatives.spawnFunction(entryPoint, message, paused)
          .then((msg) => new Isolate(msg[1],
                                     pauseCapability: msg[2],
                                     terminateCapability: msg[3]));
    } catch (e, st) {
      return new Future<Isolate>.error(e, st);
    }
  }

  patch static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message, { bool paused: false }) {
    try {
      if (args is List<String>) {
        for (int i = 0; i < args.length; i++) {
          if (args[i] is! String) {
            throw new ArgumentError("Args must be a list of Strings $args");
          }
        }
      } else if (args != null) {
        throw new ArgumentError("Args must be a list of Strings $args");
      }
      return IsolateNatives.spawnUri(uri, args, message, paused)
          .then((msg) => new Isolate(msg[1],
                                     pauseCapability: msg[2],
                                     terminateCapability: msg[3]));
    } catch (e, st) {
      return new Future<Isolate>.error(e, st);
    }
  }
}

/** Default factory for receive ports. */
patch class ReceivePort {
  patch factory ReceivePort() = ReceivePortImpl;

  patch factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) {
    return new ReceivePortImpl.fromRawReceivePort(rawPort);
  }
}

patch class RawReceivePort {
  patch factory RawReceivePort([void handler(event)]) {
    return new RawReceivePortImpl(handler);
  }
}

patch class Capability {
  patch factory Capability() = CapabilityImpl;
}
