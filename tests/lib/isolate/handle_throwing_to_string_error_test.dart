// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library handle_throwing_to_string_error_test;

import "dart:isolate";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class ThrowingToStringError {
  @override
  String toString() => throw ThrowingToStringError();
}

class ThrowingToStringStackTrace implements StackTrace {
  @override
  String toString() => throw ThrowingToStringStackTrace();
}

void isolateMain() {
  Error.throwWithStackTrace(
    ThrowingToStringError(),
    ThrowingToStringStackTrace(),
  );
}

void main() async {
  asyncStart();
  final errorPort = ReceivePort();
  Isolate.spawn((_) => isolateMain(), null, onError: errorPort.sendPort);
  var errorAndStack = await errorPort.first as List<Object?>;
  Expect.listEquals([
    "Instance of 'ThrowingToStringError'",
    "Instance of 'ThrowingToStringStackTrace'",
  ], errorAndStack);
  asyncEnd();
}
