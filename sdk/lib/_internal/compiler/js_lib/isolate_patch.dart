// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import 'dart:_js_helper' show patch;
import 'dart:_isolate_helper' show CapabilityImpl,
                                   CloseToken,
                                   IsolateNatives,
                                   JsIsolateSink,
                                   ReceivePortImpl,
                                   RawReceivePortImpl;

@patch
class Isolate {
  @patch
  static Future<Isolate> spawn(void entryPoint(message), var message,
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

  @patch
  static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message, { bool paused: false,
                                                 Uri packageRoot }) {
    if (packageRoot != null) throw new UnimplementedError("packageRoot");
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

  @patch
  void _pause(Capability resumeCapability) {
    var message = new List(3)
        ..[0] = "pause"
        ..[1] = pauseCapability
        ..[2] = resumeCapability;
    controlPort.send(message);
  }

  @patch
  void resume(Capability resumeCapability) {
    var message = new List(2)
        ..[0] = "resume"
        ..[1] = resumeCapability;
    controlPort.send(message);
  }

  @patch
  void addOnExitListener(SendPort responsePort) {
    // TODO(lrn): Can we have an internal method that checks if the receiving
    // isolate of a SendPort is still alive?
    var message = new List(2)
        ..[0] = "add-ondone"
        ..[1] = responsePort;
    controlPort.send(message);
  }

  @patch
  void removeOnExitListener(SendPort responsePort) {
    var message = new List(2)
        ..[0] = "remove-ondone"
        ..[1] = responsePort;
    controlPort.send(message);
  }

  @patch
  void setErrorsFatal(bool errorsAreFatal) {
    var message = new List(3)
        ..[0] = "set-errors-fatal"
        ..[1] = terminateCapability
        ..[2] = errorsAreFatal;
    controlPort.send(message);
  }

  @patch
  void kill([int priority = BEFORE_NEXT_EVENT]) {
    controlPort.send(["kill", terminateCapability, priority]);
  }

  @patch
  void ping(SendPort responsePort, [int pingType = IMMEDIATE]) {
    var message = new List(3)
        ..[0] = "ping"
        ..[1] = responsePort
        ..[2] = pingType;
    controlPort.send(message);
  }

  @patch
  void addErrorListener(SendPort port) {
    var message = new List(2)
        ..[0] = "getErrors"
        ..[1] = port;
    controlPort.send(message);
  }

  @patch
  void removeErrorListener(SendPort port) {
    var message = new List(2)
        ..[0] = "stopErrors"
        ..[1] = port;
    controlPort.send(message);
  }
}

/** Default factory for receive ports. */
@patch
class ReceivePort {
  @patch
  factory ReceivePort() = ReceivePortImpl;

  @patch
  factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) {
    return new ReceivePortImpl.fromRawReceivePort(rawPort);
  }
}

@patch
class RawReceivePort {
  @patch
  factory RawReceivePort([void handler(event)]) {
    return new RawReceivePortImpl(handler);
  }
}

@patch
class Capability {
  @patch
  factory Capability() = CapabilityImpl;
}
