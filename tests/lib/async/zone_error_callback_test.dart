// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  asyncStart();
  testNoChange();
  testWithReplacement();
  asyncEnd();
}

class MockStack implements StackTrace {
  final int id;
  const MockStack(this.id);
  String toString() => "MocKStack($id)";
}

const stack1 = const MockStack(1);
const stack2 = const MockStack(2);

class SomeError implements Error {
  final int id;
  const SomeError(this.id);
  StackTrace get stackTrace => stack2;
  String toString() => "SomeError($id)";
}

const error1 = const SomeError(1);
const error2 = const SomeError(2);

Null expectError(e, s) {
  // Remember one asyncStart per use of this callback.
  Expect.identical(error1, e);
  Expect.identical(stack1, s);
  asyncEnd();
  return null;
}

Null expectErrorOnly(e, s) {
  // Remember one asyncStart per use of this callback.
  Expect.identical(error1, e);
  asyncEnd();
  return null;
}

AsyncError replace(self, parent, zone, e, s) {
  if (e == "ignore") return null; // For testing handleError throwing.
  Expect.identical(error1, e); // Ensure replacement only called once
  return new AsyncError(error2, stack2);
}

var replaceZoneSpec = new ZoneSpecification(errorCallback: replace);

// Expectation after replacing.
Null expectReplaced(e, s) {
  Expect.identical(error2, e);
  Expect.identical(stack2, s);
  asyncEnd();
  return null;
}

void testProgrammaticErrors(expectError) {
  {
    asyncStart();
    Completer c = new Completer();
    c.future.catchError(expectError);
    c.completeError(error1, stack1);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream.listen(null, onError: expectError, cancelOnError: true);
    controller.addError(error1, stack1);
  }

  {
    asyncStart();
    StreamController controller = new StreamController(sync: true);
    controller.stream.listen(null, onError: expectError, cancelOnError: true);
    controller.addError(error1, stack1);
  }

  {
    asyncStart();
    StreamController controller = new StreamController.broadcast();
    controller.stream.listen(null, onError: expectError, cancelOnError: true);
    controller.addError(error1, stack1);
  }

  {
    asyncStart();
    StreamController controller = new StreamController.broadcast(sync: true);
    controller.stream.listen(null, onError: expectError, cancelOnError: true);
    controller.addError(error1, stack1);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .asBroadcastStream()
        .listen(null, onError: expectError, cancelOnError: true);
    controller.addError(error1, stack1);
  }

  {
    asyncStart();
    StreamController controller = new StreamController(sync: true);
    controller.stream
        .asBroadcastStream()
        .listen(null, onError: expectError, cancelOnError: true);
    controller.addError(error1, stack1);
  }

  {
    asyncStart();
    Future f = new Future.error(error1, stack1);
    f.catchError(expectError);
  }
}

void testThrownErrors(expectErrorOnly) {
  // Throw error in non-registered callback.
  {
    asyncStart();
    Future f = new Future(() => throw error1);
    f.catchError(expectErrorOnly);
  }

  {
    asyncStart();
    Future f = new Future.microtask(() => throw error1);
    f.catchError(expectErrorOnly);
  }

  {
    asyncStart();
    Future f = new Future.sync(() => throw error1);
    f.catchError(expectErrorOnly);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .map((x) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .where((x) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream.forEach((x) => throw error1).catchError(expectErrorOnly);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .expand((x) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .asyncMap((x) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .asyncExpand((x) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .handleError((e, s) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.addError("ignore", null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .skipWhile((x) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .takeWhile((x) => throw error1)
        .listen(null, onError: expectErrorOnly, cancelOnError: true);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream.every((x) => throw error1).catchError(expectErrorOnly);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream.any((x) => throw error1).catchError(expectErrorOnly);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .firstWhere((x) => throw error1)
        .catchError(expectErrorOnly);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .lastWhere((x) => throw error1)
        .catchError(expectErrorOnly);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .singleWhere((x) => throw error1)
        .catchError(expectErrorOnly);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .reduce((x, y) => throw error1)
        .catchError(expectErrorOnly);
    controller.add(null);
    controller.add(null);
  }

  {
    asyncStart();
    StreamController controller = new StreamController();
    controller.stream
        .fold(null, (x, y) => throw error1)
        .catchError(expectErrorOnly);
    controller.add(null);
  }
}

testNoChange() {
  void testTransparent() {
    testProgrammaticErrors(expectError);
    testThrownErrors(expectErrorOnly);
  }

  // Run directly.
  testTransparent();

  // Run in a zone that doesn't change callback.
  runZoned(testTransparent,
      zoneSpecification:
          new ZoneSpecification(handleUncaughtError: (s, p, z, e, t) {}));

  // Run in zone that delegates to root zone
  runZoned(testTransparent,
      zoneSpecification: new ZoneSpecification(
          errorCallback: (s, p, z, e, t) => p.errorCallback(z, e, t)));

  // Run in a zone that returns null from the callback.
  runZoned(testTransparent,
      zoneSpecification:
          new ZoneSpecification(errorCallback: (s, p, z, e, t) => null));

  // Run in zone that returns same values.
  runZoned(testTransparent,
      zoneSpecification: new ZoneSpecification(
          errorCallback: (s, p, z, e, t) => new AsyncError(e, t)));

  // Run in zone that returns null, inside zone that does replacement.
  runZoned(() {
    runZoned(testTransparent,
        zoneSpecification:
            new ZoneSpecification(errorCallback: (s, p, z, e, t) => null));
  }, zoneSpecification: replaceZoneSpec);
}

void testWithReplacement() {
  void testReplaced() {
    testProgrammaticErrors(expectReplaced);
    testThrownErrors(expectReplaced);
  }

  // Zone which replaces errors.
  runZoned(testReplaced, zoneSpecification: replaceZoneSpec);

  // Nested zone, only innermost gets to act.
  runZoned(() {
    runZoned(testReplaced, zoneSpecification: replaceZoneSpec);
  }, zoneSpecification: replaceZoneSpec);

  // Use delegation to parent which replaces.
  runZoned(() {
    runZoned(testReplaced,
        zoneSpecification: new ZoneSpecification(
            errorCallback: (s, p, z, e, t) => p.errorCallback(z, e, t)));
  }, zoneSpecification: replaceZoneSpec);
}
