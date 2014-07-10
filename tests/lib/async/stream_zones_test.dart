// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

/// StreamController in nested runZoned. Trivial.
test1() {
  var events = [];
  var done = new Completer();
  runZoned(() {
    runZoned(() {
      var c = new StreamController();
      c.stream.listen(
          (x) => events.add("stream: $x"),
           onError: (x) => events.add("stream: error $x"),
           onDone: done.complete);
      c.add(1);
      c.addError(2);
      c.close();
    }, onError: (x) => events.add("rza: error $x"));
  }, onError: (x) => events.add("rzb: error $x"));
  return [done.future, () {
    Expect.listEquals(["stream: 1", "stream: error 2"], events);
  }];
}

/// Adding errors to the stream controller from an outside zone.
test2() {
  var events = [];
  var done = new Completer();
  runZoned(() {
    var c;
    runZoned(() {
      c = new StreamController();
      c.stream.listen(
          (x) => events.add("stream: $x"),
           onError: (x) => events.add("stream: error $x"),
           onDone: done.complete);
    }, onError: (x) => events.add("rza: error $x"));
    c.add(1);
    c.addError(2);
    c.close();
  }, onError: (x) => events.add("rzb: error $x"));
  return [done.future, () {
    Expect.listEquals(["stream: 1", "stream: error 2"], events);
  }];
}

/// Adding errors to the stream controller from a more nested zone.
test3() {
  var events = [];
  var done = new Completer();
  runZoned(() {
    var c = new StreamController();
    c.stream.listen(
        (x) => events.add("stream: $x"),
          onError: (x) => events.add("stream: error $x"),
          onDone: done.complete);
    runZoned(() {
      c.add(1);
      c.addError(2);
      c.close();
    }, onError: (x) => events.add("rza: error $x"));
  }, onError: (x) => events.add("rzb: error $x"));
  return [done.future, () {
    Expect.listEquals(["stream: 1", "stream: error 2"], events);
  }];
}

/// Feeding a stream from a different zone into another controller.
test4() {
  var events = [];
  var done = new Completer();
  runZoned(() {
    var c = new StreamController();
    c.stream.listen(
        (x) => events.add("stream: $x"),
          onError: (x) => events.add("stream: error $x"),
          onDone: done.complete);
    runZoned(() {
      var c2 = new StreamController();
      c.addStream(c2.stream).whenComplete(c.close);
      c2.add(1);
      c2.addError(2);
      c2.close();
    }, onError: (x) => events.add("rza: error $x"));
  }, onError: (x) => events.add("rzb: error $x"));
  return [done.future, () {
    Expect.listEquals(["stream: 1", "stream: error 2"], events);
  }];
}

/// Feeding a stream from a different zone into another controller.
/// This time nesting is reversed wrt test4.
test5() {
  var events = [];
  var done = new Completer();
  runZoned(() {
    var c;
    runZoned(() {
      c = new StreamController();
      c.stream.listen(
          (x) => events.add("stream: $x"),
            onError: (x) => events.add("stream: error $x"),
            onDone: done.complete);
    }, onError: (x) => events.add("rza: error $x"));
    var c2 = new StreamController();
    c.addStream(c2.stream).whenComplete(c.close);
    c2.add(1);
    c2.addError(2);
    c2.close();
  }, onError: (x) => events.add("rzb: error $x"));
  return [done.future, () {
    Expect.listEquals(["stream: 1", "stream: error 2"], events);
  }];
}


test6() {
  var events = [];
  var done = new Completer();
  var c;
  runZoned(() {
    c = new StreamController();
    c.stream.listen(
        (x) => events.add("stream: $x"),
          onError: (x) => events.add("stream: error $x"),
          onDone: done.complete);
  }, onError: (x) => events.add("rza: error $x"));
  runZoned(() {
    var c2 = new StreamController();
    c.addStream(c2.stream).whenComplete(c.close);
    c2.add(1);
    c2.addError(2);
    c2.close();
  }, onError: (x) => events.add("rzb: error $x"));
  return [done.future, () {
    Expect.listEquals(["stream: 1", "stream: error 2"], events);
  }];
}

/// Adding errors to the stream controller from a parallel zone.
test7() {
  var events = [];
  var done = new Completer();
  var c;
  runZoned(() {
    c = new StreamController();
    c.stream.listen(
        (x) => events.add("stream: $x"),
          onError: (x) => events.add("stream: error $x"),
          onDone: done.complete);
  }, onError: (x) => events.add("rza: error $x"));
  runZoned(() {
    c.add(1);
    c.addError(2);
    c.close();
  }, onError: (x) => events.add("rzb: error $x"));
  return [done.future, () {
    Expect.listEquals(["stream: 1", "stream: error 2"], events);
  }];
}

main() {
  asyncStart();

  var tests = [
    test1(),
    test2(),
    test3(),
    test4(),
    test5(),
    test6(),
    test7(),
  ];

  Future.wait(tests.map((l) => l.first)).then((_) {
    // Give time to complete all pending actions.
    Timer.run(() {
      tests.forEach((l) => (l.last)());
      asyncEnd();
    });
  });
}
