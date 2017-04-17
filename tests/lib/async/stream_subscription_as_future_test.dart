// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the Stream.single method.
library stream_single_test;

import "package:expect/expect.dart";
import 'dart:async';
import 'package:unittest/unittest.dart';

main() {
  test("subscription.asFuture success", () {
    Stream stream = new Stream.fromIterable([1, 2, 3]);
    var output = [];
    var subscription = stream.listen((x) {
      output.add(x);
    });
    subscription.asFuture(output).then(expectAsync((o) {
      Expect.listEquals([1, 2, 3], o);
    }));
  });

  test("subscription.asFuture success2", () {
    StreamController controller = new StreamController(sync: true);
    [1, 2, 3].forEach(controller.add);
    controller.close();
    Stream stream = controller.stream;
    var output = [];
    var subscription = stream.listen((x) {
      output.add(x);
    });
    subscription.asFuture(output).then(expectAsync((o) {
      Expect.listEquals([1, 2, 3], o);
    }));
  });

  test("subscription.asFuture success 3", () {
    Stream stream = new Stream.fromIterable([1, 2, 3]).map((x) => x);
    var output = [];
    var subscription = stream.listen((x) {
      output.add(x);
    });
    subscription.asFuture(output).then(expectAsync((o) {
      Expect.listEquals([1, 2, 3], o);
    }));
  });

  test("subscription.asFuture different type", () {
    Stream stream = new Stream<int>.fromIterable([1, 2, 3]);
    var asyncCallback = expectAsync(() => {});
    var output = [];
    var subscription = stream.listen((x) {
      output.add(x);
    });
    subscription.asFuture("string").then((String o) {
      Expect.listEquals([1, 2, 3], output);
      Expect.equals("string", o);
      asyncCallback();
    });
  });

  test("subscription.asFuture failure", () {
    StreamController controller = new StreamController(sync: true);
    [1, 2, 3].forEach(controller.add);
    controller.addError("foo");
    controller.close();
    Stream stream = controller.stream;
    var output = [];
    var subscription = stream.listen((x) {
      output.add(x);
    });
    subscription.asFuture(output).catchError(expectAsync((error) {
      Expect.equals(error, "foo");
    }));
  });

  test("subscription.asFuture failure2", () {
    Stream stream = new Stream.fromIterable([1, 2, 3, 4]).map((x) {
      if (x == 4) throw "foo";
      return x;
    });
    var output = [];
    var subscription = stream.listen((x) {
      output.add(x);
    });
    subscription.asFuture(output).catchError(expectAsync((error) {
      Expect.equals(error, "foo");
    }));
  });

  test("subscription.asFuture delayed cancel", () {
    var completer = new Completer();
    var controller =
        new StreamController(onCancel: () => completer.future, sync: true);
    [1, 2, 3].forEach(controller.add);
    controller.addError("foo");
    controller.close();
    Stream stream = controller.stream;
    var output = [];
    var subscription = stream.listen((x) {
      output.add(x);
    });
    bool catchErrorHasRun = false;
    subscription.asFuture(output).catchError(expectAsync((error) {
      Expect.equals(error, "foo");
      catchErrorHasRun = true;
    }));
    Timer.run(expectAsync(() {
      Expect.isFalse(catchErrorHasRun);
      completer.complete();
    }));
  });

  test("subscription.asFuture failure in cancel", () {
    runZoned(() {
      var completer = new Completer();
      var controller =
          new StreamController(onCancel: () => completer.future, sync: true);
      [1, 2, 3].forEach(controller.add);
      controller.addError("foo");
      controller.close();
      Stream stream = controller.stream;
      var output = [];
      var subscription = stream.listen((x) {
        output.add(x);
      });
      bool catchErrorHasRun = false;
      subscription.asFuture(output).catchError(expectAsync((error) {
        Expect.equals(error, "foo");
        catchErrorHasRun = true;
      }));
      Timer.run(expectAsync(() {
        Expect.isFalse(catchErrorHasRun);
        completer.completeError(499);
      }));
    }, onError: expectAsync((e) {
      Expect.equals(499, e);
    }));
  });
}
