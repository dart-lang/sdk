// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper functions and classes for running a set of unittests in a
// remote isolate.
// Used to test Isolate.spawn because dartium/drt does not allow it in the DOM
// isolate.

import "dart:isolate";
import "package:unittest/unittest.dart";
@MirrorsUsed(symbols: "main", targets: "main", override: "*")
import "dart:mirrors";

/**
 * Use this function at the beginning of the main method:
 *
 *     void main([args, port]) {
 *       if (testRemote(main, port)) return;
 *       // the usual test.
 *     }
 *
 * Remember to import unittest using the URI `package:inittest/unittest.dart`.
 * Otherwise it won't be sharing the `unittestConfiguration` with this library,
 * and the override set below won't work.
 *
 * Returns `true` if the tests are being run remotely, and
 * `false` if the tests should be run locally.
 */
bool testRemote(Function main, SendPort port) {
  if (port != null) {
    unittestConfiguration = new RemoteConfiguration(port);
    return false;
  }
  var testResponses = new Map<String, List>();

  ClosureMirror closure = reflect(main);
  LibraryMirror library = closure.function.owner;

  var receivePort = new ReceivePort();
  void remoteAction(message) {
    switch (message[0]) {
      case "testStart":
        String name = message[1];
        testResponses[name] = null;
        break;
      case "testResult":
      case "testResultChanged":
        String name = message[1];
        testResponses[name] = message;
        break;
      case "logMessage":
        break; // Ignore.
      case "summary":
        throw message[1]; // Uncaught error.
      case "done":
        receivePort.close();
        _simulateTests(testResponses);
        break;
    }
  }

  try {
    Isolate.spawnUri(library.uri, null, receivePort.sendPort);
    receivePort.listen(remoteAction);
    return true;
  } catch (e) {
    // spawnUri is only supported by dart2js if web workers are available.
    // If the spawnUri fails, run the tests locally instead, since we are
    // not in a browser anyway.
    //
    // That is, we assume that either Isolate.spawn or Isolate.spawnUri must
    // work, so if spawnUri doesn't work, we can run the tests directly.
    receivePort.close();
    return false;
  }
}

class RemoteConfiguration implements Configuration {
  final SendPort _port;
  Duration timeout = const Duration(minutes: 2);

  RemoteConfiguration(this._port);

  bool get autoStart => true;

  void onInit() {}

  void onStart() {}

  void onTestStart(TestCase testCase) {
    _port.send(["testStart", testCase.description]);
  }

  void onTestResult(TestCase testCase) {
    _port.send([
      "testResult",
      testCase.description,
      testCase.result,
      testCase.message
    ]);
  }

  void onTestResultChanged(TestCase testCase) {
    _port.send([
      "testResultChanged",
      testCase.description,
      testCase.result,
      testCase.message
    ]);
  }

  void onLogMessage(TestCase testCase, String message) {
    _port.send(["logMessage", testCase.description, message]);
  }

  void onDone(bool success) {
    _port.send(["done", success]);
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    if (uncaughtError != null) {
      _port.send(["summary", uncaughtError]);
    }
  }
}

void _simulateTests(Map<String, List> responses) {
  // Start all unit tests in the same event.
  responses.forEach((name, response) {
    test(name, () {
      var result = response[2];
      var message = response[3];
      if (result == FAIL) {
        fail(message);
      } else if (result == ERROR) {
        throw message;
      }
    });
  });
}
