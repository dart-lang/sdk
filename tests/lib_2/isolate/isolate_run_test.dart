// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:isolate';
import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

void main() async {
  asyncStart();
  // Sending result back.
  await testValue();
  await testAsyncValue();
  // Sending error from computation back.
  await testError();
  await testAsyncError();
  // Sending uncaught async error back.
  await testUncaughtError();
  // Not sending anything back before isolate dies.
  await testIsolateHangs();
  await testIsolateKilled();
  await testIsolateExits();
  asyncEnd();
}

final StackTrace stack = StackTrace.fromString("Known Stacktrace");
final ArgumentError error = ArgumentError.value(42, "name");

var variable = 0;

Future<void> testValue() async {
  var value = await Isolate.run<int>(() {
    variable = 1; // Changed in other isolate!
    Expect.equals(1, variable);
    return 42;
  });
  Expect.equals(42, value);
  Expect.equals(0, variable);
}

Future<void> testAsyncValue() async {
  var value = await Isolate.run<int>(() async {
    variable = 1;
    return 42;
  });
  Expect.equals(42, value);
  Expect.equals(0, variable);
}

Future<void> testError() async {
  var e = await asyncExpectThrows<ArgumentError>(Isolate.run<int>(() {
    variable = 1;
    Error.throwWithStackTrace(error, stack);
  }));
  Expect.equals(42, e.invalidValue);
  Expect.equals("name", e.name);
  Expect.equals(0, variable);
}

Future<void> testAsyncError() async {
  var e = await asyncExpectThrows<ArgumentError>(Isolate.run<int>(() async {
    variable = 1;
    Error.throwWithStackTrace(error, stack);
  }));
  Expect.equals(42, e.invalidValue);
  Expect.equals("name", e.name);
  Expect.equals(0, variable);
}

Future<void> testUncaughtError() async {
  var e = await asyncExpectThrows<RemoteError>(Isolate.run<int>(() async {
    variable = 1;
    unawaited(Future.error(error, stack)); // Uncaught error
    await Completer().future; // Never completes.
    return -1;
  }));

  Expect.type<RemoteError>(e);
  Expect.equals(error.toString(), e.toString());
  Expect.equals(0, variable);
}

Future<void> testIsolateHangs() async {
  var e = await asyncExpectThrows<RemoteError>(Isolate.run<int>(() async {
    variable = 1;
    await Completer<Never>().future; // Never completes.
    // Isolate should end while hanging here, because its event loop is empty.
  }));
  Expect.type<RemoteError>(e);
  Expect.equals("Computation ended without result", e.toString());
  Expect.equals(0, variable);
}

Future<void> testIsolateKilled() async {
  var e = await asyncExpectThrows<RemoteError>(Isolate.run<int>(() async {
    variable = 1;
    Isolate.current.kill(); // Send kill request.
    await Completer<Never>().future; // Never completes.
    // Isolate should get killed while hanging here.
  }));
  Expect.type<RemoteError>(e);
  Expect.equals("Computation ended without result", e.toString());
  Expect.equals(0, variable);
}

Future<void> testIsolateExits() async {
  var e = await asyncExpectThrows<RemoteError>(Isolate.run<int>(() async {
    variable = 1;
    Isolate.exit(); // Dies here without sending anything back.
  }));
  Expect.type<RemoteError>(e);
  Expect.equals("Computation ended without result", e.toString());
  Expect.equals(0, variable);
}
