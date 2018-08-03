// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Helper functions for running code in a Zone.
library testing.zone_helper;

import 'dart:async' show Completer, Future, ZoneSpecification, runZoned;

import 'dart:io' show exit, stderr;

import 'dart:isolate' show Capability, Isolate, ReceivePort;

import 'log.dart' show logUncaughtError;

Future runGuarded(Future f(),
    {void printLineOnStdout(line),
    void handleLateError(error, StackTrace stackTrace)}) {
  var printWrapper;
  if (printLineOnStdout != null) {
    printWrapper = (_1, _2, _3, String line) {
      printLineOnStdout(line);
    };
  }

  Completer completer = new Completer();

  handleUncaughtError(error, StackTrace stackTrace) {
    logUncaughtError(error, stackTrace);
    if (!completer.isCompleted) {
      completer.completeError(error, stackTrace);
    } else if (handleLateError != null) {
      handleLateError(error, stackTrace);
    } else {
      String errorString = "error.toString() failed.";
      try {
        errorString = "$error";
      } catch (_) {
        // Ignored.
      }
      stderr
          .write("$errorString\n" + (stackTrace == null ? "" : "$stackTrace"));
      stderr.flush();
      exit(255);
    }
  }

  ZoneSpecification specification = new ZoneSpecification(print: printWrapper);

  ReceivePort errorPort = new ReceivePort();
  Future errorFuture = errorPort.listen((_errors) {
    List errors = _errors;
    Isolate.current.removeErrorListener(errorPort.sendPort);
    errorPort.close();
    var error = errors[0];
    var stackTrace = errors[1];
    if (stackTrace != null) {
      stackTrace = new StackTrace.fromString(stackTrace);
    }
    handleUncaughtError(error, stackTrace);
  }).asFuture();

  Isolate.current.setErrorsFatal(false);
  Isolate.current.addErrorListener(errorPort.sendPort);
  return acknowledgeControlMessages(Isolate.current).then((_) {
    runZoned(() => new Future(f).then(completer.complete),
        zoneSpecification: specification, onError: handleUncaughtError);

    return completer.future.whenComplete(() {
      errorPort.close();
      Isolate.current.removeErrorListener(errorPort.sendPort);
      return acknowledgeControlMessages(Isolate.current)
          .then((_) => errorFuture);
    });
  });
}

/// Ping [isolate] to ensure control messages have been delivered.  Control
/// messages are things like [Isolate.addErrorListener] and
/// [Isolate.addOnExitListener].
Future acknowledgeControlMessages(Isolate isolate, {Capability resume}) {
  ReceivePort ping = new ReceivePort();
  Isolate.current.ping(ping.sendPort);
  if (resume == null) {
    return ping.first;
  } else {
    return ping.first.then((_) => isolate.resume(resume));
  }
}
