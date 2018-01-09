// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import "dart:async";
import 'dart:_js_helper' show patch;
import 'dart:_isolate_helper'
    show CapabilityImpl, IsolateNatives, ReceivePortImpl, RawReceivePortImpl;

typedef _UnaryFunction(Null arg);

@patch
class Isolate {
  static final _currentIsolateCache = IsolateNatives.currentIsolate;

  // `current` must be a getter, not just a final field,
  // to match the external declaration.
  @patch
  static Isolate get current => _currentIsolateCache;

  @patch
  static Future<Uri> get packageRoot {
    throw new UnsupportedError("Isolate.packageRoot");
  }

  @patch
  static Future<Uri> get packageConfig {
    throw new UnsupportedError("Isolate.packageConfig");
  }

  static Uri _packageBase = Uri.base.resolve(IsolateNatives.packagesBase);

  @patch
  static Future<Uri> resolvePackageUri(Uri packageUri) {
    if (packageUri.scheme != 'package') {
      return new Future<Uri>.value(packageUri);
    }
    return new Future<Uri>.value(
        _packageBase.resolveUri(packageUri.replace(scheme: '')));
  }

  @patch
  static Future<Isolate> spawn<T>(void entryPoint(T message), T message,
      {bool paused: false,
      bool errorsAreFatal,
      SendPort onExit,
      SendPort onError}) {
    bool forcePause =
        (errorsAreFatal != null) || (onExit != null) || (onError != null);
    try {
      // Check for the type of `entryPoint` on the spawning isolate to make
      // error-handling easier.
      if (entryPoint is! _UnaryFunction) {
        throw new ArgumentError(entryPoint);
      }
      // TODO: Consider passing the errorsAreFatal/onExit/onError values
      //       as arguments to the internal spawnUri instead of setting
      //       them after the isolate has been created.
      return IsolateNatives
          .spawnFunction(entryPoint, message, paused || forcePause)
          .then((msg) {
        var isolate = new Isolate(msg[1],
            pauseCapability: msg[2], terminateCapability: msg[3]);
        if (forcePause) {
          if (errorsAreFatal != null) {
            isolate.setErrorsFatal(errorsAreFatal);
          }
          if (onExit != null) {
            isolate.addOnExitListener(onExit);
          }
          if (onError != null) {
            isolate.addErrorListener(onError);
          }
          if (!paused) {
            isolate.resume(isolate.pauseCapability);
          }
        }
        return isolate;
      });
    } catch (e, st) {
      return new Future<Isolate>.error(e, st);
    }
  }

  @patch
  static Future<Isolate> spawnUri(Uri uri, List<String> args, var message,
      {bool paused: false,
      SendPort onExit,
      SendPort onError,
      bool errorsAreFatal,
      bool checked,
      Map<String, String> environment,
      Uri packageRoot,
      Uri packageConfig,
      bool automaticPackageResolution: false}) {
    if (environment != null) throw new UnimplementedError("environment");
    if (packageRoot != null) throw new UnimplementedError("packageRoot");
    if (packageConfig != null) throw new UnimplementedError("packageConfig");
    // TODO(lrn): Figure out how to handle the automaticPackageResolution
    // parameter.
    bool forcePause =
        (errorsAreFatal != null) || (onExit != null) || (onError != null);
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
      // TODO: Handle [packageRoot] somehow, possibly by throwing.
      // TODO: Consider passing the errorsAreFatal/onExit/onError values
      //       as arguments to the internal spawnUri instead of setting
      //       them after the isolate has been created.
      return IsolateNatives
          .spawnUri(uri, args, message, paused || forcePause)
          .then((msg) {
        var isolate = new Isolate(msg[1],
            pauseCapability: msg[2], terminateCapability: msg[3]);
        if (forcePause) {
          if (errorsAreFatal != null) {
            isolate.setErrorsFatal(errorsAreFatal);
          }
          if (onExit != null) {
            isolate.addOnExitListener(onExit);
          }
          if (onError != null) {
            isolate.addErrorListener(onError);
          }
          if (!paused) {
            isolate.resume(isolate.pauseCapability);
          }
        }
        return isolate;
      });
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
  void addOnExitListener(SendPort responsePort, {Object response}) {
    // TODO(lrn): Can we have an internal method that checks if the receiving
    // isolate of a SendPort is still alive?
    var message = new List(3)
      ..[0] = "add-ondone"
      ..[1] = responsePort
      ..[2] = response;
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
  void kill({int priority: beforeNextEvent}) {
    controlPort.send(["kill", terminateCapability, priority]);
  }

  @patch
  void ping(SendPort responsePort, {Object response, int priority: immediate}) {
    var message = new List(4)
      ..[0] = "ping"
      ..[1] = responsePort
      ..[2] = priority
      ..[3] = response;
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
  factory RawReceivePort([Function handler]) {
    return new RawReceivePortImpl(handler);
  }
}

@patch
class Capability {
  @patch
  factory Capability() = CapabilityImpl;
}
