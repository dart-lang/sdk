// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'dart:_internal' as dart_internal;

/// Similar to `Isolate.spawn<T>()` but supports `newIsolateGroup`.
Future<Isolate> internalSpawn<T>(void entryPoint(T message), T message,
    {SendPort onExit,
    SendPort onError,
    bool newIsolateGroup,
    String debugName}) async {
  newIsolateGroup ??= false;
  final packageConfig = null;
  final paused = false;
  final bool errorsAreFatal = null;
  final readyPort = new RawReceivePort();
  try {
    dart_internal.spawnFunction(
        readyPort.sendPort,
        Platform.script.toString(),
        entryPoint,
        message,
        paused,
        errorsAreFatal,
        onExit,
        onError,
        packageConfig,
        newIsolateGroup,
        debugName);
    return await _spawnCommon(readyPort);
  } catch (e, st) {
    readyPort.close();
    return await new Future<Isolate>.error(e, st);
  }
}

/// A copy of `dart:isolate`s internal `Isolate._spawnCommon()`.
Future<Isolate> _spawnCommon(RawReceivePort readyPort) {
  final completer = new Completer<Isolate>.sync();
  readyPort.handler = (readyMessage) {
    readyPort.close();
    if (readyMessage is List && readyMessage.length == 2) {
      SendPort controlPort = readyMessage[0];
      List capabilities = readyMessage[1];
      completer.complete(new Isolate(controlPort,
          pauseCapability: capabilities[0],
          terminateCapability: capabilities[1]));
    } else if (readyMessage is String) {
      // We encountered an error while starting the new isolate.
      completer.completeError(new IsolateSpawnException(
          'Unable to spawn isolate: ${readyMessage}'));
    } else {
      // This shouldn't happen.
      completer.completeError(new IsolateSpawnException(
          "Internal error: unexpected format for ready message: "
          "'${readyMessage}'"));
    }
  };
  return completer.future;
}

/// Spawns the [staticClosure] in a detached isolate group.
Future<Isolate> spawnInDetachedGroup<T>(
    void staticClosure(T message), T message,
    {SendPort onExit, SendPort onError}) async {
  _IG0([staticClosure, message]);
}

// This is the isolate group of "main". We spawn another one.
_IG0(args) => internalSpawn(_IG1, args, newIsolateGroup: true);

// This is an intermediate isolate group. The actual code we run in a new IG and
// this one will die.
_IG1(args) => internalSpawn(_IG2, args, newIsolateGroup: true);

// Run the actual code
_IG2(args) => args[0](args[1]);

extension SendPortSendAndExit on SendPort {
  void sendAndExit(var message) {
    dart_internal.sendAndExit(this, message);
  }
}
