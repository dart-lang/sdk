// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class Tracer {
  final String expected;
  final String name;
  String _trace = "";
  int counter = 0;

  Tracer(this.expected, [this.name]);

  void trace(msg) {
    if (name != null) {
      // Commented out, see https://github.com/dart-lang/dev_compiler/issues/278
      //print("Tracing $name: $msg");
    }
    _trace += msg;
    counter++;
  }

  void done() {
    Expect.equals(expected, _trace);
  }
}

foo1(Tracer tracer) async* {
  try {
    tracer.trace("a");
    await new Future.value(3);
    tracer.trace("b");
    throw "Error";
  } catch (e) {
    Expect.equals("Error", e);
    tracer.trace("c");
    yield 1;
    tracer.trace("d");
    yield 2;
    tracer.trace("e");
    yield 3;
    tracer.trace("f");
  } finally {
    tracer.trace("f");
  }
  tracer.trace("g");
}

foo2(Tracer tracer) async* {
  try {
    tracer.trace("a");
    throw "Error";
  } catch (error) {
    Expect.equals("Error", error);
    tracer.trace("b");
    rethrow;
  } finally {
    tracer.trace("c");
  }
}

foo3(Tracer tracer) async* {
  try {
    tracer.trace("a");
    throw "Error";
  } catch (error) {
    Expect.equals("Error", error);
    tracer.trace("b");
    rethrow;
  } finally {
    tracer.trace("c");
    yield 1;
  }
}

foo4(Tracer tracer) async* {
  try {
    tracer.trace("a");
    await new Future.value(3);
    tracer.trace("b");
    throw "Error";
  } catch (e) {
    Expect.equals("Error", e);
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

runTest(test, expectedTrace, expectedError, shouldCancel) {
  Tracer tracer = new Tracer(expectedTrace, expectedTrace);
  Completer done = new Completer();
  var subscription;
  subscription = test(tracer).listen((event) async {
    tracer.trace("Y");
    if (shouldCancel) {
      await subscription.cancel();
      tracer.trace("C");
      done.complete(null);
    }
  }, onError: (error) {
    Expect.equals(expectedError, error);
    tracer.trace("X");
  }, onDone: () {
    tracer.done();
    done.complete(null);
  });
  return done.future.then((_) => tracer.done());
}

test() async {
  // TODO(sigurdm): These tests are too dependent on scheduling, and buffering
  // behavior.
  await runTest(foo1, "abcdYefC", null, true);
  await runTest(foo2, "abcX", "Error", false);
  await runTest(foo3, "abcYX", "Error", false);
  await runTest(foo4, "abcdYeYfX", "Error2", false);
}

void main() {
  asyncTest(test);
}
