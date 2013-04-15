// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the Stream.single method.
library stream_single_test;

import "package:expect/expect.dart";
import 'dart:async';
import '../../../pkg/unittest/lib/unittest.dart';

main() {
  test("subscription.asStream success", () {
    Stream stream = new Stream.fromIterable([1, 2, 3]);
    var output = [];
    var subscription = stream.listen((x) { output.add(x); });
    subscription.asFuture(output).then(expectAsync1((o) {
      Expect.listEquals([1, 2, 3], o);
    }));
  });

  test("subscription.asStream success2", () {
    StreamController controller = new StreamController();
    [1, 2, 3].forEach(controller.add);
    controller.close();
    Stream stream = controller.stream;
    var output = [];
    var subscription = stream.listen((x) { output.add(x); });
    subscription.asFuture(output).then(expectAsync1((o) {
      Expect.listEquals([1, 2, 3], o);
    }));
  });

  test("subscription.asStream success 3", () {
    Stream stream = new Stream.fromIterable([1, 2, 3]).map((x) => x);
    var output = [];
    var subscription = stream.listen((x) { output.add(x); });
    subscription.asFuture(output).then(expectAsync1((o) {
      Expect.listEquals([1, 2, 3], o);
    }));
  });

  test("subscription.asStream failure", () {
    StreamController controller = new StreamController();
    [1, 2, 3].forEach(controller.add);
    controller.addError("foo");
    controller.close();
    Stream stream = controller.stream;
    var output = [];
    var subscription = stream.listen((x) { output.add(x); });
    subscription.asFuture(output).catchError(expectAsync1((error) {
      Expect.equals(error, "foo");
    }));
  });

  test("subscription.asStream failure2", () {
    Stream stream = new Stream.fromIterable([1, 2, 3, 4])
      .map((x) {
        if (x == 4) throw "foo";
        return x;
      });
    var output = [];
    var subscription = stream.listen((x) { output.add(x); });
    subscription.asFuture(output).catchError(expectAsync1((error) {
      Expect.equals(error, "foo");
    }));
  });
}
