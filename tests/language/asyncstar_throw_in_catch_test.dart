// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class Tracer {
  final String expected;
  final String name;
  int counter = 0;

  Tracer(this.expected, [this.name]);

  void trace(msg) {
    if (name != null) {
      print("Tracing $name: $msg");
    }
    Expect.equals(expected[counter], msg);
    counter++;
  }

  void done() {
    Expect.equals(expected.length, counter, "Received too few traces");
  }
}

foo1(Tracer tracer) async* {
  try {
    tracer.trace("a");
    await new Future.value(3);
    tracer.trace("b");
    throw "Error";
  } catch (e) {
    tracer.trace("c");
    yield 1;
    tracer.trace("d");
    yield 2;
    tracer.trace("e");
    await new Future.error("Error2");
  } finally {
    tracer.trace("f");
  }
  tracer.trace("g");
}

test() async {
  Tracer tracer;

  Completer foo1Done = new Completer();
  tracer = new Tracer("abcdf");
  var subscription;
  subscription = foo1(tracer).listen((event) async {
    await subscription.cancel();
    tracer.done();
    foo1Done.complete(null);
  });
  await foo1Done.future;
}


void main() {
  asyncTest(test);
}