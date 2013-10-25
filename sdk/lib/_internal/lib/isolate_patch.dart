// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import 'dart:_isolate_helper' show IsolateNatives,
                                   lazyPort,
                                   ReceivePortImpl,
                                   CloseToken,
                                   JsIsolateSink;

patch class Isolate {
  patch static Future<Isolate> spawn(void entryPoint(message), var message) {
    SendPort controlPort = IsolateNatives.spawnFunction(entryPoint, message);
    return new Future<Isolate>.value(new Isolate._fromControlPort(controlPort));
  }

  patch static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message) {
    if (args is List<String>) {
      for (int i = 0; i < args.length; i++) {
        if (args[i] is! String) {
          throw new ArgumentError("Args must be a list of Strings $args");
        }
      }
    } else if (args != null) {
      throw new ArgumentError("Args must be a list of Strings $args");
    }
    SendPort controlPort = IsolateNatives.spawnUri(uri, args, message);
    return new Future<Isolate>.value(new Isolate._fromControlPort(controlPort));
  }
}

/** Default factory for receive ports. */
patch class ReceivePort {
  patch factory ReceivePort() {
    return new ReceivePortImpl();
  }

  patch factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) {
    throw new UnimplementedError("ReceivePort.fromRawReceivePort");
  }
}

patch class RawReceivePort {
  patch factory RawReceivePort([void handler(event)]) {
    throw new UnimplementedError("RawReceivePort");
  }
}
