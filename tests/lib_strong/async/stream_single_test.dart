// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the Stream.single method.
library stream_single_test;

import "package:expect/expect.dart";
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'event_helper.dart';

main() {
  test("single", () {
    StreamController c = new StreamController(sync: true);
    Future f = c.stream.single;
    f.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    new Events.fromIterable([42]).replay(c);
  });

  test("single empty", () {
    StreamController c = new StreamController(sync: true);
    Future f = c.stream.single;
    f.catchError(expectAsync((error) {
      Expect.isTrue(error is StateError);
    }));
    new Events.fromIterable([]).replay(c);
  });

  test("single error", () {
    StreamController c = new StreamController(sync: true);
    Future f = c.stream.single;
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..error("error")
      ..close();
    errorEvents.replay(c);
  });

  test("single error 2", () {
    StreamController c = new StreamController(sync: true);
    Future f = c.stream.single;
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..error("error")
      ..error("error2")
      ..close();
    errorEvents.replay(c);
  });

  test("single error 3", () {
    StreamController c = new StreamController(sync: true);
    Future f = c.stream.single;
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..add(499)
      ..error("error")
      ..close();
    errorEvents.replay(c);
  });
}
